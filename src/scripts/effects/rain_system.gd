extends Node3D

@export var rain_sound_path: String = "res://assets/audio/environment/sfx_rain.mp3"
@export var thunder_sound_path: String = "res://assets/audio/environment/sfx_thunder.mp3"

var _audio_player: AudioStreamPlayer
var _thunder_player: AudioStreamPlayer
var _particles: GPUParticles3D
var _lightning_light: DirectionalLight3D
var _thunder_timer: float = 5.0
var _is_storming: bool = false

signal lightning_flashed(intensity: float)

func _ready():
	# Setup Audio
	_audio_player = AudioStreamPlayer.new()
	var stream = load(rain_sound_path)
	if stream:
		_audio_player.stream = stream
		_audio_player.bus = "SFX"
	add_child(_audio_player)
	
	_thunder_player = AudioStreamPlayer.new()
	var t_stream = load(thunder_sound_path)
	if t_stream:
		_thunder_player.stream = t_stream
		_thunder_player.bus = "SFX"
	add_child(_thunder_player)
	
	# Tìm LightningLight trong scene
	_lightning_light = get_tree().root.find_child("LightningLight", true, false)
	
	# Setup Particles
	_particles = GPUParticles3D.new()
	_particles.amount = 80000 # Đẩy lên 80k hạt để mưa thật sự dày đặc trên 400m
	_particles.lifetime = 5.0
	_particles.preprocess = 4.0
	_particles.visibility_aabb = AABB(Vector3(-600, -400, -600), Vector3(1200, 800, 1200))
	
	# Process Material (Simple rain)
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(400, 1, 400)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 0.5
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, -40, 0) # Mưa rơi cực nhanh và mạnh
	
	# Enable Collision
	mat.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	_particles.process_material = mat
	
	# Mesh
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.05, 1.2) # Hạt mưa dài và rõ nét hơn
	var m_mat = StandardMaterial3D.new()
	m_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_mat.albedo_color = Color(0.7, 0.8, 1.0, 0.4)
	m_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mesh.surface_set_material(0, m_mat)
	_particles.draw_pass_1 = mesh
	
	add_child(_particles)
	_particles.emitting = false
	_particles.local_coords = true # Mưa phải dính theo player để không bị "hụt" khi di chuyển ở độ cao 150m

func _process(delta):
	if GameState.is_raining:
		# Luôn cho mưa rơi nếu đang trong trạng thái mưa (để nhìn từ trong nhà ra ngoài vẫn thấy)
		var is_inside = GameState.is_player_inside
		
		# Cập nhật vị trí hệ thống mưa theo người chơi
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# Đặt emitter ở độ cao cực đại (150m) để mưa rơi từ trên mây xuống
			global_position = player.global_position + Vector3(0, 150, 0)
		
		if not _particles.emitting:
			_particles.emitting = true
			
		if not _audio_player.playing:
			_audio_player.play()
			
		# Giảm âm lượng khi ở trong nhà
		if is_inside:
			_audio_player.volume_db = -15.0 # Nghe tiếng mưa nhỏ đi
		else:
			_audio_player.volume_db = 0.0 # Nghe tiếng mưa bình thường
			
		# Sấm chớp
		_handle_thunder(delta)
	else:
		if _particles.emitting:
			_particles.emitting = false
		if _audio_player.playing:
			_audio_player.stop()
		if _lightning_light:
			_lightning_light.light_energy = 0

func _handle_thunder(delta):
	_thunder_timer -= delta
	if _thunder_timer <= 0:
		# Nếu đang trong mode bão (storming) thì sét đánh liên hồi (0.5 - 1.5s)
		if _is_storming:
			_thunder_timer = randf_range(0.5, 1.5)
		else:
			_thunder_timer = randf_range(3.0, 8.0)
		_trigger_lightning()

func set_storm_mode(enabled: bool):
	_is_storming = enabled
	if enabled:
		_thunder_timer = 0.1 # Kích hoạt ngay lập tức

func _trigger_lightning(intensity: float = -1.0):
	if not _lightning_light:
		_lightning_light = get_tree().root.find_child("LightningLight", true, false)
		if not _lightning_light: return
	
	# Xoay nguồn sáng về một hướng ngẫu nhiên trên bầu trời
	_lightning_light.rotation_degrees = Vector3(
		randf_range(-30, -60), # Độ cao (góc xiên từ trên xuống)
		randf_range(0, 360),   # Hướng ngẫu nhiên quanh người chơi
		0
	)
	
	# Nếu intensity = -1 thì dùng random cho sấm sét tự nhiên
	var final_intensity = intensity
	if final_intensity < 0:
		# Mở rộng dải ngẫu nhiên để thấy rõ sự khác biệt giữa các lần chớp
		final_intensity = randf_range(2.0, 12.0) 
	
	var tween = create_tween()
	# Chớp lần 1
	tween.tween_property(_lightning_light, "light_energy", final_intensity, 0.05)
	
	# Phát tín hiệu ngay khi chớp bùng lên
	lightning_flashed.emit(final_intensity)
	
	tween.tween_property(_lightning_light, "light_energy", 0.0, 0.1)
	# Chớp lần 2 (nhẹ hơn)
	tween.tween_interval(0.05)
	tween.tween_property(_lightning_light, "light_energy", final_intensity * 0.6, 0.05)
	tween.tween_property(_lightning_light, "light_energy", 0.0, 0.2)
	
	# Tiếng sấm trễ một chút
	var delay = randf_range(0.5, 2.0)
	get_tree().create_timer(delay).timeout.connect(func():
		if GameState.is_raining and _thunder_player:
			_thunder_player.play()
	)

# Hàm gọi từ script khác để tạo chớp sáng đặc biệt (ví dụ ma rơi)
func trigger_special_lightning(intensity: float = 20.0):
	_trigger_lightning(intensity)
