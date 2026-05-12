extends Node3D

@export var detection_radius: float = 150.0 ## Bán kính biến mất (150m)
@export var max_distance: float = 1000.0 ## Khoảng cách tối đa để debug vùng cầu
@export var show_duration: float = 2.0 ## Thời gian ma hiện ra (2 giây)
@export var laugh_sounds: Array[AudioStream] = [
	preload("res://assets/audio/ghost_event/laugh1.mp3"),
	preload("res://assets/audio/ghost_event/laugh2.mp3"),
	preload("res://assets/audio/ghost_event/laugh3.mp3"),
	preload("res://assets/audio/ghost_event/laugh4.mp3")
]
@export var jumpscare_sound: AudioStream = preload("res://assets/audio/ghost_event/laugh1.mp3")
@export var show_debug: bool = false ## Hiện vùng cầu để debug

var _notifier: VisibleOnScreenNotifier3D
var _tween: Tween
var _is_appearing: bool = false
var is_in_trigger: bool = false # Sẽ được set bởi KrasueTrigger
var _ambient_laugh_timer: float = 0.0
var _audio_player: AudioStreamPlayer3D
var is_laughing_enabled: bool = false # Sẽ được set bởi LaughTrigger

func _ready():
	if show_debug:
		_create_debug_spheres()
		
	modulate_alpha(0.0) 
	
	_notifier = VisibleOnScreenNotifier3D.new()
	_notifier.aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	add_child(_notifier)
	
	# Thiết lập âm thanh 3D
	_audio_player = AudioStreamPlayer3D.new()
	_audio_player.stream = jumpscare_sound
	_audio_player.unit_size = 200.0 # Nâng tầm vang vọng
	_audio_player.max_distance = 1500.0 # Nghe thấy từ rất xa
	_audio_player.bus = "SFX"
	add_child(_audio_player)
	
	# Kết nối với tín hiệu sấm sét
	var rain_sys = get_tree().root.find_child("RainSystem", true, false)
	if rain_sys:
		rain_sys.lightning_flashed.connect(_on_lightning_flashed)

func _process(delta):
	# 1. Xử lý cười ngẫu nhiên dồn dập khi ở trong vùng LaughTrigger (Vùng rộng)
	if is_laughing_enabled:
		_ambient_laugh_timer -= delta
		if _ambient_laugh_timer <= 0:
			_play_ambient_laugh() # Tiếng cười 1
			_play_ambient_laugh() # Tiếng cười 2 (chồng lên cái 1 ngay lập tức)
			_ambient_laugh_timer = randf_range(1.0, 3.0) # Nhịp dồn dập 1-3 giây
	
	# 2. Xử lý tan biến khi lại gần
	if not _is_appearing or modulate_alpha_value <= 0.1: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	if dist < detection_radius:
		_fade_out()

func _play_ambient_laugh():
	if laugh_sounds.size() == 0: return
	
	# Tạo một AudioPlayer mới để các tiếng cười có thể chồng lên nhau
	var sfx = AudioStreamPlayer3D.new()
	
	# Chọn ngẫu nhiên 1 trong các tiếng cười có sẵn
	sfx.stream = laugh_sounds[randi() % laugh_sounds.size()]
	
	sfx.unit_size = 200.0
	sfx.max_distance = 1500.0
	sfx.bus = "SFX"
	
	# NGẪU NHIÊN CAO ĐỘ, CƯỜNG ĐỘ VÀ TỐC ĐỘ
	sfx.pitch_scale = randf_range(0.7, 1.4) 
	sfx.volume_db = randf_range(-6.0, 4.0)   
	
	add_child(sfx)
	sfx.play()
	
	# Tự xóa sau khi cười xong
	sfx.finished.connect(func(): sfx.queue_free())

func _on_lightning_flashed(_intensity: float):
	# 1. Kiểm tra xem người chơi có đang ở trong vùng kích hoạt của Krasue không
	if not is_in_trigger:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	var on_screen = _notifier.is_on_screen()
	
	# Chỉ hiện ra khi: Ở trong vùng TRIGGER + Nhìn vào ma + Sét đánh + Ngoài 70m
	if dist > detection_radius and on_screen and not _is_appearing:
		_trigger_appearance()

func _trigger_appearance():
	if _tween: _tween.kill()
	
	_is_appearing = true
	_tween = create_tween()
	_tween.tween_method(modulate_alpha, 0.0, 1.0, 0.5)
	
	_play_jumpscare_effects()
	
	var anim = _find_animation_player(self)
	if anim:
		anim.play(anim.get_animation_list()[0])

func _fade_out():
	if _tween and _tween.is_running(): _tween.kill()
	_tween = create_tween()
	_tween.tween_method(modulate_alpha, modulate_alpha_value, 0.0, 1.5)
	_tween.finished.connect(func(): _is_appearing = false)

# Hàm bổ trợ để chỉnh độ trong suốt của các mesh (Trừ các quả cầu Debug)
func modulate_alpha(alpha: float):
	modulate_alpha_value = alpha
	for child in get_children():
		# Nếu là quả cầu debug thì KHÔNG làm tàng hình
		if child.name.begins_with("DEBUG_SPHERE_"):
			continue
			
		if child is MeshInstance3D:
			child.transparency = 1.0 - alpha
		elif child is Node3D:
			for sub_child in child.find_children("*", "MeshInstance3D"):
				# Tương tự cho các sub-child nếu có
				if not sub_child.name.begins_with("DEBUG_SPHERE_"):
					sub_child.transparency = 1.0 - alpha

func _play_jumpscare_effects():
	if _audio_player:
		_audio_player.play()
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_shake"):
		player.apply_shake(0.2)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found = _find_animation_player(child)
		if found: return found
	return null

var modulate_alpha_value: float = 0.0

func _create_debug_spheres():
	var s = scale.x
	
	var red_sphere = MeshInstance3D.new()
	red_sphere.name = "DEBUG_SPHERE_RED"
	var red_mesh = SphereMesh.new()
	red_mesh.radius = detection_radius / s
	red_mesh.height = (detection_radius * 2) / s
	red_sphere.mesh = red_mesh
	var red_mat = StandardMaterial3D.new()
	red_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	red_mat.albedo_color = Color(1, 0, 0, 0.2)
	red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red_sphere.material_override = red_mat
	red_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(red_sphere)

	var blue_sphere = MeshInstance3D.new()
	blue_sphere.name = "DEBUG_SPHERE_BLUE"
	var blue_mesh = SphereMesh.new()
	blue_mesh.radius = max_distance / s
	blue_mesh.height = (max_distance * 2) / s
	blue_sphere.mesh = blue_mesh
	var blue_mat = StandardMaterial3D.new()
	blue_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blue_mat.albedo_color = Color(0, 0, 1, 0.1)
	blue_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blue_sphere.material_override = blue_mat
	blue_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blue_sphere)
