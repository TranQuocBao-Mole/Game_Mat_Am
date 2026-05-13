extends StaticBody3D

@export var prompt_text: String = "Kiểm tra cửa"
@export var is_locked: bool = true
@export var combination_lock_scene: PackedScene

@export_group("Teleport Points")
@export var outside_marker: Marker3D
@export var inside_marker: Marker3D
@export var lock_model: Node3D # Kéo model ổ khóa vào đây
@export var stalking_entity: Node3D # Kéo con ma stalking vào đây

var is_player_inside: bool = false
var stalking_triggered: bool = false # Sự kiện lúc đi ra
var entry_scare_triggered: bool = false # Sự kiện lúc đi vào
@export var surprise_sound: AudioStream = preload("res://assets/audio/ghost_event/suprise_hit.mp3")
var _audio_player: AudioStreamPlayer

func _ready():
	if combination_lock_scene == null:
		combination_lock_scene = load("res://src/ui/puzzles/combination_lock_ui.tscn")
	_update_prompt()
	
	# Ẩn ma ngay khi bắt đầu để chờ sự kiện
	if stalking_entity:
		stalking_entity.hide()
	
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = surprise_sound
	_audio_player.bus = "SFX"
	add_child(_audio_player)

func _update_prompt():
	if is_locked:
		prompt_text = "Cửa đang khóa (Cần mã số)"
	elif is_player_inside:
		prompt_text = "Rời khỏi"
	else:
		prompt_text = "Mở cửa đi vào"

func interact():
	if is_locked:
		open_lock_puzzle()
	else:
		toggle_teleport()

func open_lock_puzzle():
	if combination_lock_scene:
		var puzzle_instance = combination_lock_scene.instantiate()
		var cl = CanvasLayer.new()
		cl.layer = 100
		get_tree().root.add_child(cl)
		cl.add_child(puzzle_instance)
		
		if puzzle_instance.has_method("open_puzzle"):
			puzzle_instance.open_puzzle()
		
		puzzle_instance.puzzle_finished.connect(_on_lock_finished)
		# Tự động dọn dẹp CanvasLayer khi UI khoá đóng lại
		puzzle_instance.puzzle_finished.connect(func(_won): cl.queue_free())
	else:
		print("[ERROR] Không tìm thấy scene ổ khóa!")

func _on_lock_finished(won: bool):
	if won:
		# Nhập đúng mật khẩu nhưng chưa giải đủ 3 trò chơi
		if not GameState.is_chess_puzzle_solved or not GameState.is_candle_puzzle_solved or not GameState.is_elements_puzzle_solved:
			if DialogueManager:
				DialogueManager.show_text("Chưa đủ manh mối.")
			return
			
		is_locked = false
		_update_prompt()
		
		# Xóa tờ giấy số 5 khỏi kho đồ vì đã mở xong
		if InventoryManager:
			InventoryManager.remove_item("paper_warehouse")
		
		# Ẩn mô hình ổ khóa
		if lock_model:
			lock_model.visible = false
			
		if DialogueManager:
			DialogueManager.show_text("Tiếng 'Cạch' vang lên. Cửa đã có thể mở được.")

func toggle_teleport():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Khóa người chơi và chuột
	var mouse_look = player.get_node_or_null("Head/MouseLook")
	if mouse_look:
		mouse_look.set_process(false)
		mouse_look.set_process_input(false)
	if player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	
	# Xác định điểm đích
	var target_marker = outside_marker if is_player_inside else inside_marker
	if not target_marker: return
	
	# --- 1. TẠO MÀN HÌNH ĐEN THỦ CÔNG ---
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().root.add_child(canvas)
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.color.a = 0
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_overlay)
	
	var env = get_tree().root.find_child("WorldEnvironment", true, false)
	
	# --- 2. GIAI ĐOẠN "TỐI SẦM" (Nhanh hơn - 1.0s) ---
	var tween_out = create_tween().set_parallel(true)
	tween_out.tween_property(fade_overlay, "color:a", 1.0, 1.0)
	if env:
		tween_out.tween_property(env.environment, "ambient_light_energy", 0.0, 1.0)
		tween_out.tween_property(env.environment, "tonemap_exposure", 0.0, 1.0)
	
	await tween_out.finished
	await get_tree().create_timer(0.4).timeout # Khoảng lặng ngắn
	
	# --- 3. DỊCH CHUYỂN & XOAY SẴN TRONG BÓNG TỐI ---
	var is_entry_event = not is_player_inside and not entry_scare_triggered
	
	if is_entry_event:
		player.global_position = Vector3(-821.7226, 90.52896, 988.3943)
		player.global_rotation.y = 0
		var head = player.get_node_or_null("Head")
		if head:
			head.rotation.y = deg_to_rad(-32.65)
			if mouse_look: mouse_look.yaw = -32.65
		
		# Phát âm thanh giật mình khi gặp bộ xương
		if _audio_player: _audio_player.play()
	else:
		player.global_position = target_marker.global_position
		player.global_rotation.y = target_marker.global_rotation.y
	
	# DEBUG LOG
	print("[Door] Teleporting... Inside: ", is_player_inside, " | Entry Event: ", is_entry_event)
	
	var is_stalking_event = is_player_inside and not stalking_triggered and stalking_entity
	if is_stalking_event:
		print("[Door] KÍCH HOẠT SỰ KIỆN STALKING (OUT)!")
		
		# Phát âm thanh giật mình khi gặp con ma ở cửa
		if _audio_player: _audio_player.play()
		# ... logic con ma cũ giữ nguyên ...
		stalking_entity.visible = true
		var ghost_light = stalking_entity.find_child("GhostLight", true, false)
		if ghost_light: ghost_light.visible = true
		
		var anim = stalking_entity.find_child("AnimationPlayer", true, false)
		if anim:
			var anim_list = anim.get_animation_list()
			if anim_list.size() >= 2: anim.play(anim_list[1])
			elif anim_list.size() > 0: anim.play(anim_list[0])
		
		var head = player.get_node_or_null("Head")
		var cam = player.find_child("Camera3D", true, false)
		if head and cam:
			var dir_c = (stalking_entity.global_position + Vector3.UP * 1.5 - cam.global_position).normalized()
			head.global_rotation.y = atan2(-dir_c.x, -dir_c.z)
			cam.rotation.x = atan2(dir_c.y, Vector2(dir_c.x, dir_c.z).length())
			if mouse_look:
				mouse_look.yaw = rad_to_deg(head.rotation.y)
				mouse_look.pitch = rad_to_deg(cam.rotation.x)

	await get_tree().create_timer(0.2).timeout # Đợi rất ngắn cho chớp nhoáng
	
	# --- 4. GIAI ĐOẠN "SÁNG LẠI" ---
	if is_entry_event:
		fade_overlay.color.a = 0.0
		if env:
			env.environment.ambient_light_energy = 4.0
			env.environment.tonemap_exposure = 1.0
		canvas.queue_free()
	else:
		var tween_in = create_tween().set_parallel(true)
		tween_in.tween_property(fade_overlay, "color:a", 0.0, 1.0)
		if env:
			tween_in.tween_property(env.environment, "ambient_light_energy", 4.0, 1.0)
			tween_in.tween_property(env.environment, "tonemap_exposure", 1.0, 1.0)
		await tween_in.finished
		canvas.queue_free()
	
	# --- 5. KẾT THÚC SỰ KIỆN ---
	if is_entry_event:
		entry_scare_triggered = true
		_play_scare_effect() # Kích hoạt rung và chớp đỏ y hệt Phonograph
		await get_tree().create_timer(1.0).timeout # Đợi 1 giây theo yêu cầu
		if DialogueManager:
			DialogueManager.show_text("Giật cả mình!")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Ai lại để cái mô hình bộ xương đây vậy?")
			await DialogueManager.dialogue_finished
			
	elif is_stalking_event:
		stalking_triggered = true
		await get_tree().create_timer(1.5).timeout
		
		# HIỆU ỨNG NHIỄU SÓNG TV (GLITCH/STATIC)
		var glitch_canvas = CanvasLayer.new()
		glitch_canvas.layer = 101
		get_tree().root.add_child(glitch_canvas)
		var glitch_rect = ColorRect.new()
		glitch_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glitch_canvas.add_child(glitch_rect)
		
		# Chớp giật và nhiễu ngang trong 0.6 giây
		for i in range(12):
			glitch_rect.color = Color(1, 1, 1, randf_range(0.05, 0.2)) if i % 2 == 0 else Color(0, 0, 0, 0)
			
			var lines = []
			if i % 2 == 0:
				for j in range(3):
					var line = ColorRect.new()
					line.color = Color(1, 1, 1, randf_range(0.2, 0.5))
					line.set_begin(Vector2(0, randf_range(0, 720)))
					line.set_custom_minimum_size(Vector2(1280, randf_range(2, 10)))
					glitch_canvas.add_child(line)
					lines.append(line)
			
			if i == 6: # Giữa chừng thì ẩn ma
				stalking_entity.visible = false
				var ghost_light = stalking_entity.find_child("GhostLight", true, false)
				if ghost_light: ghost_light.visible = false
				
			await get_tree().create_timer(0.05).timeout
			for l in lines: l.queue_free()
			
		glitch_canvas.queue_free()
		
		if DialogueManager:
			DialogueManager.show_text("Cái gì vậy nhỉ?")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Hoa mắt à??")
			await DialogueManager.dialogue_finished
	
	# --- 6. KHÔI PHỤC ĐIỀU KHIỂN ---
	if mouse_look:
		# Đồng bộ lại hướng quay hiện tại của nhân vật vào MouseLook
		if "yaw" in mouse_look: mouse_look.yaw = rad_to_deg(player.rotation.y)
		var cam = player.find_child("Camera3D", true, false)
		if cam and "pitch" in mouse_look: mouse_look.pitch = rad_to_deg(cam.rotation.x)
		mouse_look.set_process(true)
		mouse_look.set_process_input(true)
	
	if player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
	
	is_player_inside = !is_player_inside
	GameState.is_player_inside = is_player_inside
	_update_prompt()

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
