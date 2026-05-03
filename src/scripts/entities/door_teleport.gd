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
var stalking_triggered: bool = false # Đánh dấu sự kiện đã xảy ra

func _ready():
	if combination_lock_scene == null:
		combination_lock_scene = load("res://src/ui/puzzles/combination_lock_ui.tscn")
	_update_prompt()

func _update_prompt():
	if is_locked:
		prompt_text = "Cửa đang khóa (Cần mã số)"
	elif is_player_inside:
		prompt_text = "Rời khỏi"
	else:
		prompt_text = "Mở cửa đi vào"

func interact():
	if is_locked:
		# TẠM THỜI: Nhấn E là mở luôn để test nhanh
		_on_lock_finished(true)
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
	else:
		print("[ERROR] Không tìm thấy scene ổ khóa!")

func _on_lock_finished(won: bool):
	if won:
		is_locked = false
		_update_prompt()
		
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
		tween_out.tween_property(env.environment, "exposure_energy", 0.0, 1.0)
	
	await tween_out.finished
	await get_tree().create_timer(0.4).timeout # Khoảng lặng ngắn
	
	# --- 3. DỊCH CHUYỂN & XOAY SẴN TRONG BÓNG TỐI ---
	player.global_position = target_marker.global_position
	player.global_rotation.y = target_marker.global_rotation.y
	
	var is_event = is_player_inside and not stalking_triggered and stalking_entity
	if is_event:
		# CHUẨN BỊ MA NGAY TRONG BÓNG TỐI
		stalking_entity.visible = true
		var ghost_light = stalking_entity.find_child("GhostLight", true, false)
		if ghost_light: ghost_light.visible = true # Bật đèn luôn
		
		var anim = stalking_entity.find_child("AnimationPlayer", true, false)
		if anim:
			var anim_list = anim.get_animation_list()
			if anim_list.size() >= 2: anim.play(anim_list[1])
			elif anim_list.size() > 0: anim.play(anim_list[0])
		
		# --- XOAY CAMERA THEO LOGIC CHUẨN (GIỐNG CHESS EVENT) ---
		var head = player.get_node_or_null("Head")
		var cam = player.find_child("Camera3D", true, false)
		
		if head and cam:
			# Tính hướng từ camera đến con ma
			var dir_c = (stalking_entity.global_position + Vector3.UP * 1.5 - cam.global_position).normalized()
			
			# Xoay ngang (Dùng Head - Trục Y)
			var camera_y_rot = atan2(-dir_c.x, -dir_c.z)
			head.global_rotation.y = camera_y_rot
			
			# Xoay dọc (Dùng Camera - Trục X)
			var x_rot = atan2(dir_c.y, Vector2(dir_c.x, dir_c.z).length())
			cam.rotation.x = x_rot
			cam.rotation.z = 0
			
			# ĐỒNG BỘ CHUỘT
			if mouse_look:
				if "yaw" in mouse_look: mouse_look.yaw = rad_to_deg(head.rotation.y)
				if "pitch" in mouse_look: mouse_look.pitch = rad_to_deg(cam.rotation.x)

	await get_tree().create_timer(0.3).timeout # Tổng cộng 0.7s chờ đen
	
	# --- 4. GIAI ĐOẠN "SÁNG LẠI" (Nhanh hơn - 1.0s) ---
	var tween_in = create_tween().set_parallel(true)
	tween_in.tween_property(fade_overlay, "color:a", 0.0, 1.0)
	if env:
		tween_in.tween_property(env.environment, "ambient_light_energy", 4.0, 1.0)
		tween_in.tween_property(env.environment, "exposure_energy", 1.0, 1.0)
	
	await tween_in.finished
	canvas.queue_free()
	
	# --- 5. KẾT THÚC SỰ KIỆN ---
	if is_event:
		stalking_triggered = true
		await get_tree().create_timer(1.5).timeout # Cho nhìn ma 1.5 giây
		
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
			
			# Tạo thêm vài đường nhiễu ngang ngẫu nhiên
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
			for l in lines: l.queue_free() # Xóa các đường nhiễu ngay sau mỗi nhịp chớp
			
		glitch_canvas.queue_free() # Xóa toàn bộ hiệu ứng
		
		# --- THOẠI SUY NGHĨ CỦA NHÂN VẬT ---
		if DialogueManager:
			DialogueManager.show_text("Cái gì vậy nhỉ?")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Hoa mắt à??")
			await DialogueManager.dialogue_finished
	
	# --- 6. KHÔI PHỤC ĐIỀU KHIỂN ---
	if mouse_look:
		if "yaw" in mouse_look: mouse_look.yaw = player.rotation.y
		var cam = player.find_child("Camera3D", true, false)
		if cam and "pitch" in mouse_look: mouse_look.pitch = cam.rotation.x
		mouse_look.set_process(true)
		mouse_look.set_process_input(true)
	
	if player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
	
	is_player_inside = !is_player_inside
	_update_prompt()
