extends Area3D

@export var phonograph_node: Node3D
@export var scary_head: Node3D
@export var scary_girl: Node3D
@export var scary_girl_7: Node3D
@export var scary_girl_8: Node3D
@export var scary_girl_9: Node3D
@export var scary_girl_10: Node3D
@export var candle_light_1: OmniLight3D
@export var candle_light_2: OmniLight3D

var event_triggered: bool = false
var _flickering: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	if scary_head: scary_head.visible = false
	if scary_girl: scary_girl.visible = false
	if scary_girl_7: scary_girl_7.visible = false
	if scary_girl_8: scary_girl_8.visible = false
	if scary_girl_9: scary_girl_9.visible = false
	if scary_girl_10: scary_girl_10.visible = false

func _process(_delta):
	if _flickering:
		if candle_light_1: candle_light_1.light_energy = randf_range(0.1, 2.5)
		if candle_light_2: candle_light_2.light_energy = randf_range(0.1, 2.5)

func _on_body_entered(body: Node3D):
	print("[DEBUG] Area3D entered by: ", body.name)
	if event_triggered: return
	if not body.is_in_group("player"): 
		print("[DEBUG] Body not in group 'player'")
		return
	
	# Kiểm tra nếu máy hát đã được phát nhạc ít nhất 1 lần
	if phonograph_node:
		if "music_played" in phonograph_node:
			if phonograph_node.music_played:
				# Khóa di chuyển người chơi
				if body.has_method("set_movement_enabled"):
					body.set_movement_enabled(false)
				trigger_event()
			else:
				print("[DEBUG] Nhạc chưa được phát lần nào.")
		else:
			print("[DEBUG] phonograph_node không có biến music_played.")
	else:
		print("[DEBUG] phonograph_node bị NULL.")

func trigger_event():
	event_triggered = true
	_flickering = true
	
	# 1. Chớp đen lần 1 (0.1s)
	var flash1 = _create_flash_rect()
	await get_tree().create_timer(0.05).timeout # Chờ giữa lúc đang đen
	if scary_head: scary_head.visible = true
	await get_tree().create_timer(0.05).timeout
	flash1.queue_free() # Hết đen
	_play_scare_effect()
	
	# 2. Chờ 1.5 giây
	await get_tree().create_timer(1.5).timeout
	
	# 3. Chớp đen lần 2 (0.1s)
	var flash2 = _create_flash_rect()
	await get_tree().create_timer(0.05).timeout # Chờ giữa lúc đang đen
	if scary_girl: scary_girl.visible = true
	await get_tree().create_timer(0.05).timeout
	flash2.queue_free() # Hết đen
	_play_scare_effect()
	
	# Chờ một chút trước khi lùi (thay vì hiện thoại)
	await get_tree().create_timer(0.5).timeout
	
	# 4. Hiệu ứng bị đẩy lùi trong 1 giây
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("[DEBUG] Bắt đầu đẩy lùi 70m.")
		var head = player.get_node_or_null("Head")
		var back_dir: Vector3
		
		if head:
			back_dir = head.global_transform.basis.z
		else:
			back_dir = player.global_transform.basis.z
			
		back_dir.y = 0 
		back_dir = back_dir.normalized()
		
		var push_distance = 70.0 # Chỉnh lại thành 70m
		var target_pos = player.global_position + back_dir * push_distance
		
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", target_pos, 1.0)
		await tween.finished
		print("[DEBUG] Kết thúc đẩy lùi.")
		
		# Hiện thoại SAU KHI bị lùi
		if DialogueManager:
			DialogueManager.show_text("Gì vậy ???")
		
		# 5. Đợi lâu (Cảm giác an toàn giả tạo - False Security)
		await get_tree().create_timer(3.0).timeout

		
		# 6. BÙM! Tất cả 7, 8, 9, 10 xuất hiện cùng lúc
		var final_flash = _create_flash_rect()
		await get_tree().create_timer(0.05).timeout
		
		if scary_girl_7: scary_girl_7.visible = true
		if scary_girl_8: scary_girl_8.visible = true
		if scary_girl_9: scary_girl_9.visible = true
		if scary_girl_10: scary_girl_10.visible = true
		
		await get_tree().create_timer(0.05).timeout
		final_flash.queue_free()
		_play_scare_effect() # Chớp đỏ và rung cực mạnh
		
		# 7. Trợn mắt nhìn trong 0.6 giây rồi ngất xỉu
		await get_tree().create_timer(0.6).timeout
		_start_faint_sequence(player)

func _start_faint_sequence(player):
	# Tắt nến
	_flickering = false
	if candle_light_1: candle_light_1.visible = false
	if candle_light_2: candle_light_2.visible = false

	# 1. Tạo màn hình đen
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.color.a = 0
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_overlay)

	# 2. Fade màn hình tối dần
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 1.5)
	await tween.finished

	# 3. Chờ 2 giây (đang ngất)
	await get_tree().create_timer(2.0).timeout

	# 4. Ẩn toàn bộ ma
	if scary_head: scary_head.visible = false
	if scary_girl: scary_girl.visible = false
	if scary_girl_7: scary_girl_7.visible = false
	if scary_girl_8: scary_girl_8.visible = false
	if scary_girl_9: scary_girl_9.visible = false
	if scary_girl_10: scary_girl_10.visible = false
	
	# Bật nến lại bình thường
	if candle_light_1: 
		candle_light_1.visible = true
		candle_light_1.light_energy = 1.0
	if candle_light_2: 
		candle_light_2.visible = true
		candle_light_2.light_energy = 1.0
	
	# 5. Fade màn hình sáng lại (Tỉnh dậy)
	var tween2 = create_tween()
	tween2.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	await tween2.finished
	canvas.queue_free()
	
	# 6. Thoại sau khi tỉnh
	if DialogueManager:
		DialogueManager.show_text("Đau đầu quá...")
		await DialogueManager.dialogue_finished
		DialogueManager.show_text("Chuyện gì xảy ra vậy?")
		await DialogueManager.dialogue_finished
	
	# 7. Khôi phục điều khiển
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)

func _create_flash_rect() -> CanvasLayer:
	var flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 101
	get_tree().root.add_child(flash_canvas)
	
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color.BLACK
	flash_canvas.add_child(flash_rect)
	return flash_canvas

func _play_scare_effect():
	_shake_camera(0.3, 0.2)
	
	var flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 102
	get_tree().root.add_child(flash_canvas)
	
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(0.8, 0.0, 0.0, 0.2) # Chớp đỏ mờ kinh dị
	flash_canvas.add_child(flash_rect)
	
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.2)
	await tween.finished
	if is_instance_valid(flash_canvas):
		flash_canvas.queue_free()


func _shake_camera(intensity: float, duration: float):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var camera = player.get_node_or_null("Head/Camera3D")
		if camera:
			var shake_tween = create_tween()
			var steps = int(duration / 0.05)
			for i in range(steps):
				shake_tween.tween_property(camera, "h_offset", randf_range(-intensity, intensity), 0.05)
				shake_tween.parallel().tween_property(camera, "v_offset", randf_range(-intensity, intensity), 0.05)
			shake_tween.tween_property(camera, "h_offset", 0.0, 0.05)
			shake_tween.parallel().tween_property(camera, "v_offset", 0.0, 0.05)

