extends Area3D

@export var black2_node: Node3D
@export var jumpscare_sound: AudioStream = preload("res://assets/audio/ghost_event/suprise_hit.mp3")

@export var chase_speed: float = 175.0

var _event_finished: bool = false # Cờ đánh dấu sự kiện ma đã xong hoàn toàn
var _is_triggered: bool = false
var _player: Node3D
var _audio_player: AudioStreamPlayer

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Khởi tạo trình phát âm thanh
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = jumpscare_sound
	_audio_player.bus = "SFX"
	add_child(_audio_player)
	
	if black2_node:
		black2_node.hide()

func _on_body_entered(body: Node3D):
	print("[DEBUG-BLACK] Có vật thể chạm vào: ", body.name, " | Group 'player': ", body.is_in_group("player"))
	
	if body.is_in_group("player"):
		print("[DEBUG-BLACK] ĐÃ XÁC NHẬN PLAYER. _event_finished = ", _event_finished)
		# 1. Luôn cập nhật trạng thái "trong nhà" cho Krasue
		if "is_player_inside" in GameState:
			GameState.is_player_inside = true
		
		# 2. CHỈ KÍCH HOẠT SỰ KIỆN KINH DỊ 1 LẦN DUY NHẤT
		if not _event_finished:
			print("[DEBUG-BLACK] Khởi động _start_event()...")
			_player = body
			_is_triggered = true
			_start_event()
		else:
			print("[DEBUG-BLACK] Sự kiện đã hoàn thành trước đó, không chạy lại.")

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		if "is_player_inside" in GameState:
			GameState.is_player_inside = false

func _start_event():
	print("[DEBUG-BLACK] Kích hoạt sự kiện Black2: TẬN DỤNG LOGIC PHONOGRAPH")
	
	# 1. Khóa di chuyển & camera (Dùng hàm chuẩn của bạn)
	if _player:
		if _player.has_method("set_movement_enabled"):
			_player.set_movement_enabled(false)
		if _player.has_method("set_camera_lock"):
			_player.set_camera_lock(true)

	# 2. Phát âm thanh hù dọa
	if _audio_player:
		_audio_player.play()

	# 3. Hiệu ứng hù dọa: Rung màn hình + Chớp đỏ (Tái sử dụng logic cũ)
	_play_scare_effect()
	
	# 3. Hiện black2
	if black2_node:
		black2_node.visible = true
		black2_node.process_mode = Node.PROCESS_MODE_INHERIT
		black2_node.show()
	
	# 4. Kích hoạt sét chớp liên hồi
	var rain_sys = get_tree().root.find_child("RainSystem", true, false)
	if rain_sys and rain_sys.has_method("set_storm_mode"):
		rain_sys.set_storm_mode(true)

	_run_timer_event()

func _play_scare_effect():
	# Rung màn hình
	_shake_camera(0.3, 0.2)
	
	# Chớp đỏ mờ kinh dị
	var flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 102
	get_tree().root.add_child(flash_canvas)
	
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(0.8, 0.0, 0.0, 0.2) 
	flash_canvas.add_child(flash_rect)
	
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.2)
	await tween.finished
	if is_instance_valid(flash_canvas):
		flash_canvas.queue_free()

func _shake_camera(intensity: float, duration: float):
	if not _player: return
	var camera = _player.get_node_or_null("Head/Camera3D")
	if camera:
		var shake_tween = create_tween()
		var steps = int(duration / 0.05)
		for i in range(steps):
			shake_tween.tween_property(camera, "h_offset", randf_range(-intensity, intensity), 0.05)
			shake_tween.parallel().tween_property(camera, "v_offset", randf_range(-intensity, intensity), 0.05)
		shake_tween.tween_property(camera, "h_offset", 0.0, 0.05)
		shake_tween.parallel().tween_property(camera, "v_offset", 0.0, 0.05)

func _run_timer_event():
	# Đứng rình trong 3 giây
	await get_tree().create_timer(3.0).timeout
	
	var rain_sys = get_tree().root.find_child("RainSystem", true, false)
	if rain_sys and rain_sys.has_method("trigger_special_lightning"):
		rain_sys.trigger_special_lightning(35.0) 
	
	# Tan biến mượt mà
	_fade_out_black2()
	
	if rain_sys and rain_sys.has_method("set_storm_mode"):
		rain_sys.set_storm_mode(false)
	
	# GIẢI PHÓNG PLAYER
	_release_player()
	
	_event_finished = true # KẾT THÚC VĨNH VIỄN KHÔNG LẶP LẠI
	_is_triggered = false

func _fade_out_black2():
	if not black2_node: return
	var tween = create_tween()
	tween.tween_method(_set_black2_alpha, 1.0, 0.0, 2.0)
	tween.finished.connect(func(): if black2_node: black2_node.hide())

func _set_black2_alpha(alpha: float):
	if not black2_node: return
	for mesh in black2_node.find_children("*", "MeshInstance3D"):
		mesh.transparency = 1.0 - alpha

func _release_player():
	if _player:
		if _player.has_method("set_movement_enabled"):
			_player.set_movement_enabled(true)
		if _player.has_method("set_camera_lock"):
			_player.set_camera_lock(false)
