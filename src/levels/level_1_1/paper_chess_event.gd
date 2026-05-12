extends "res://src/scripts/common/item_pickup.gd"

@export_group("Event Settings")
@export var start_node: Node3D ## ĐIỂM A: Nơi ma bắt đầu xuất hiện
@export var end_node: Node3D ## ĐIỂM B: Nơi ma bò tới
@export var point_c: Node3D ## ĐIỂM C: Điểm camera nhìn theo
@export var point_e: Node3D ## ĐIỂM E: Nơi con ma rơi xuống hù dọa
@export var ghost_node: Node3D ## Con Ma BÒ (kéo GhostCrawl vào đây)
@export var scare_ghost_node: Node3D ## Con ma cũ (sẽ bị ẩn đi)
@export var jumpscare_ghost_scene: PackedScene ## KÉO FILE female_dynamic_pose.tscn VÀO ĐÂY
@export var look_speed: float = 1.0
@export var crawl_speed: float = 50.0 ## Tốc độ bò (units/giây)
@export var end_dialogues: Array[String] = [
	"Quái lạ... vừa nãy là cái gì vậy?",
	"Hình như mình có cảm giác đã quên đi một chuyện gì đó...",
	"Cái đèn lúc nãy cũng biến mất rồi?",
	"Chắc là mình tưởng tượng thôi...",
	"Nhưng sao tờ giấy này lại ở đây nhỉ?",
	"Trên đó viết số 5...",
	"Thôi, cất đi đã."
] ## Lời thoại sau khi tỉnh dậy
@export var scare_speed: float = 150.0 ## Tốc độ ma lao đến hù dọa (nhanh hơn bò)
@export var rotation_offset: Vector3 = Vector3(0, 180, 0) ## Điều chỉnh hướng mặt con ma BÒ (degrees)
@export var lantern_parent: Node3D ## Node lồng đèn sẽ biến mất (house3_light3)
@export var scare_animation: String = "" ## Tên animation khi hù dọa (Dừ trống = ngừng animation, đặt tên = chạy animation đó)

@export_group("Jumpscare Manual Tuning")
@export var jumpscare_offset: Vector3 = Vector3(0, -1.4, 0) ## Chỉnh tọa độ thủ công (X: ngang, Y: cao thấp, Z: xa gần)
@export var jumpscare_distance: float = 1.2 ## Khoảng cách từ mặt
@export var jumpscare_scale: float = 30.0 ## Độ lớn của con ma
@export var jumpscare_rotation_offset: Vector3 = Vector3(0, 0, 0) ## Xoay thêm (degrees)
@export var jumpscare_shake_intensity: float = 0.7 ## Lực rung màn hình
@export var fall_height: float = 10.0 ## Độ cao ma rơi xuống
@export var surprise_sound: AudioStream = preload("res://assets/audio/ghost_event/suprise_hit.mp3")

var _audio_player: AudioStreamPlayer

func interact() -> void:
	print("[DEBUG] Đã nhấn tương tác vào tờ giấy!")
	if !is_active:
		print("[DEBUG] Tờ giấy chưa Active, bỏ qua.")
		return
	
	# 1. Nhặt đồ vào túi
	if item_data:
		InventoryManager.add_item(item_data)
		print("[DEBUG] Đã thêm vật phẩm vào túi.")
	
	# 2. Kích hoạt sự kiện
	_start_horror_event()

func _start_horror_event():
	print("[DEBUG] Bắt đầu sự kiện kinh dị...")
	is_active = false

	var player = get_tree().get_first_node_in_group("player")
	if not player: player = get_tree().current_scene.find_child("Player", true, false)

	# Debug: In ra thông tin các node
	print("[DEBUG] player = ", player)
	print("[DEBUG] ghost_node = ", ghost_node)
	print("[DEBUG] start_node = ", start_node)
	print("[DEBUG] end_node = ", end_node)
	print("[DEBUG] point_c = ", point_c)

	if not player or not ghost_node:
		print("[ERR] Thiếu Player hoặc Node Con Ma!")
		if player: player.set_movement_enabled(true)
		return
	
	# Khóa di chuyển người chơi
	player.set_movement_enabled(false)
	
	# Tắt mouse look để camera không bị override
	var mouse_look = player.get_node_or_null("Head/MouseLook")
	if mouse_look:
		mouse_look.set_process(false)
		mouse_look.set_process_input(false)
		mouse_look.set_physics_process(false)
		print("[DEBUG] Đã tắt MouseLook")
	
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = surprise_sound
	_audio_player.bus = "SFX"
	add_child(_audio_player)

	# --- BƯỚC 1: HIỆN MA VÀ CHO NÓ BÒ ---
	var pos_a = start_node.global_position if start_node else ghost_node.global_position
	var pos_b = end_node.global_position if end_node else pos_a
	
	print("[DEBUG] pos_a (vị trí ma xuất hiện) = ", pos_a)
	print("[DEBUG] pos_b (vị trí ma bò tới) = ", pos_b)
	print("[DEBUG] player pos = ", player.global_position)

	ghost_node.global_position = pos_a
	
	# Xoay con ma nhìn về điểm B rồi áp dụng offset tuỳ chỉnh
	ghost_node.look_at(pos_b)
	ghost_node.rotate_z(PI)
	# Gán offset trực tiếp (không cộng dồn, không lệch vị trí)
	ghost_node.rotation_degrees += rotation_offset
	
	ghost_node.visible = true # HIỆN CON MA LÊN
	if _audio_player: _audio_player.play()
	print("[DEBUG] Đã hiện con ma tại: ", ghost_node.global_position)

	# --- CHẠY ANIMATION ---
	var anim_player = ghost_node.find_child("AnimationPlayer", true)
	if anim_player and anim_player.get_animation_list().size() > 0:
		anim_player.speed_scale = crawl_speed / 15.0 # Chỉnh tốc độ animation tỉ lệ thuận với crawl_speed (lấy 15 làm mốc 1x ban đầu)
		anim_player.play(anim_player.get_animation_list()[0])
		print("[DEBUG] Đang chạy animation: ", anim_player.current_animation, " với tốc độ ", anim_player.speed_scale)

	# --- BƯỚC 2: XOAY CAMERA NHÌN ĐIỂM C ---
	var head = player.get_node("Head")
	var camera = head.get_node("Camera3D")

	# Tính hướng từ camera đến điểm C
	var pos_c = point_c.global_position if point_c else pos_b
	print("[DEBUG] Điểm C: ", pos_c)
	print("[DEBUG] Camera pos: ", camera.global_position)

	# Tính direction và góc xoay thủ công (tránh bị roll trục Z)
	var dir_c = (pos_c - camera.global_position).normalized()

	# Góc Y: xoay ngang (dùng Head)
	var camera_y_rot = atan2(-dir_c.x, -dir_c.z)
	head.global_rotation.y = camera_y_rot
	
	# Góc X: xoay dọc (dùng Camera) - chỉ cần tính từ Y component
	var x_rot = atan2(dir_c.y, Vector2(dir_c.x, dir_c.z).length())
	camera.rotation.x = x_rot
	# Đảm bảo trục Z = 0 (không bị roll)
	camera.rotation.z = 0

	print("[DEBUG] Camera đã xoay về điểm C")
	print("[DEBUG] Head Y: ", rad_to_deg(camera_y_rot), " độ")
	print("[DEBUG] Camera X: ", rad_to_deg(x_rot), " độ")
	
	# Tween con ma bò từ A đến B (crawl_speed = số giây để đi hết)
	var distance = pos_a.distance_to(pos_b)
	var crawl_duration = distance / crawl_speed
	print("[DEBUG] Khoảng cách A-B: ", distance, " units | Tốc độ: ", crawl_speed, " u/s | Thời gian: ", crawl_duration, "s")
	
	var crawl_tween = create_tween()
	crawl_tween.tween_property(ghost_node, "global_position", pos_b, crawl_duration)

	# Debug: sau 2s in khoảng cách còn lại của ma tới B
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(ghost_node):
			var dist_to_b = ghost_node.global_position.distance_to(pos_b)
			print("[DEBUG 2s] Khoảng cách ma tới B: ", dist_to_b, " units | Ma đang ở: ", ghost_node.global_position)
	)

	# Kết thúc sự kiện
	crawl_tween.finished.connect(func():
		print("[DEBUG] Sự kiện kết thúc!")
		ghost_node.visible = false # ẨN CON MA ĐI
		
		# Hiện hội thoại "Thứ gì vậy?" (Ngắt câu riêng biệt)
		DialogueManager.show_text("Thứ gì vậy?")
		
		# Chờ xem xong hội thoại mới bắt đầu cú hù dọa rơi xuống (D->E)
		if DialogueManager.is_connected("dialogue_finished", _on_dialogue_done):
			DialogueManager.dialogue_finished.disconnect(_on_dialogue_done)
		DialogueManager.dialogue_finished.connect(_on_dialogue_done, CONNECT_ONE_SHOT)
	)

func _on_dialogue_done():
	print("[DEBUG] Hội thoại xong, bắt đầu NHÂN BẢN con ma từ Scene...")
	
	if not scare_ghost_node:
		print("[ERROR] Chưa gán scare_ghost_node trong Inspector!")
		_finalize_event()
		return
	
	# 1. Ẩn con ma gốc đi
	scare_ghost_node.visible = false
	
	# 2. Nhân bản con ma từ chính cái bạn đã chỉnh trong Scene
	var new_ghost = scare_ghost_node.duplicate()
	get_tree().root.add_child(new_ghost)
	new_ghost.name = "CON_MA_NHAN_BAN"
	new_ghost.visible = true # Hiện bản sao lên
	if _audio_player: _audio_player.play()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var camera = player.get_node("Head/Camera3D")
		if camera:
			# 3. Đặt vị trí và hướng xoay (Dùng logic Inspector của bạn)
			var target_pos = camera.global_position + (-camera.global_transform.basis.z * jumpscare_distance) + jumpscare_offset
			
			var t = Transform3D()
			t.origin = target_pos
			t.basis = camera.global_transform.basis.scaled(Vector3(jumpscare_scale, jumpscare_scale, jumpscare_scale))
			
			new_ghost.global_transform = t
			new_ghost.rotate_object_local(Vector3.UP, PI)
			
			if jumpscare_rotation_offset != Vector3.ZERO:
				new_ghost.rotation_degrees += jumpscare_rotation_offset
			
			# Hiệu ứng rơi từ trên trời xuống
			var final_pos = new_ghost.global_position
			new_ghost.global_position.y += fall_height
			var fall_tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			fall_tween.tween_property(new_ghost, "global_position:y", final_pos.y, 0.3)
			
			# Chớp sáng đặc biệt khi ma rơi xuống
			var rain_sys = get_tree().root.find_child("RainSystem", true, false)
			if rain_sys and rain_sys.has_method("trigger_special_lightning"):
				rain_sys.trigger_special_lightning(25.0) # Sáng cực mạnh (25.0)
			
			_shake_camera(camera, 0.6, jumpscare_shake_intensity)
	
	# 4. Chạy animation cho con ma mới
	var anim_player = new_ghost.find_child("AnimationPlayer", true)
	if anim_player:
		if scare_animation != "" and anim_player.has_animation(scare_animation):
			anim_player.play(scare_animation)
	
	# KÍCH HOẠT LỆNH NGẤT (Chờ 0.8s để thấy cái xác rồi xỉu luôn)
	await get_tree().create_timer(0.8).timeout
	_start_faint_sequence()

func _start_faint_sequence():
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

	# Ẩn con ma đi trong bóng tối
	if ghost_node: ghost_node.visible = false
	if scare_ghost_node: scare_ghost_node.visible = false

	# 3. Hiện dialog "Bạn đã bị ngất." và chờ tín hiệu
	var dialogue_finished_signal = DialogueManager.dialogue_finished
	
	# Disconnect any existing connection first
	if dialogue_finished_signal.is_connected(_on_faint_dialogue_done_wrapper):
		dialogue_finished_signal.disconnect(_on_faint_dialogue_done_wrapper)
	
	# Store references for the callback
	_fade_overlay_ref = fade_overlay
	_canvas_ref = canvas
	
	dialogue_finished_signal.connect(_on_faint_dialogue_done_wrapper, CONNECT_ONE_SHOT)
	DialogueManager.show_text("Bạn đã bị ngất.")

# Store references to pass to the callback
var _fade_overlay_ref: ColorRect = null
var _canvas_ref: CanvasLayer = null

func _on_faint_dialogue_done_wrapper():
	await get_tree().create_timer(2.0).timeout
	_on_faint_dialogue_done(_fade_overlay_ref, _canvas_ref)

func _on_faint_dialogue_done(fade_overlay, canvas):
	# 4. Xóa lồng đèn và CÁC CON MA (Lúc màn hình vẫn đang đen thui)
	var spawned_ghost = get_tree().root.get_node_or_null("CON_MA_NHAN_BAN")
	if spawned_ghost:
		spawned_ghost.queue_free()
		
	if ghost_node:
		ghost_node.queue_free()
	if scare_ghost_node:
		scare_ghost_node.queue_free()

	if lantern_parent:
		lantern_parent.visible = false
		lantern_parent.queue_free()
		print("[DEBUG] Đã xóa lồng đèn và con ma trong bóng tối.")
	
	# 5. Fade màn hình sáng lại
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 1.5)
	await tween.finished
	canvas.queue_free() # Xóa màn hình đen
	
	# 6. Hiện dialog suy nghĩ cuối (ngắt câu)
	if end_dialogues.size() > 0:
		for line in end_dialogues:
			DialogueManager.show_text(line)
		DialogueManager.dialogue_finished.connect(func():
			GameState.is_raining = true
			_finalize_event()
		, CONNECT_ONE_SHOT)
	else:
		GameState.is_raining = true
		_finalize_event()

func _finalize_event():
	print("[DEBUG] Hoàn tất toàn bộ chuỗi sự kiện. Khôi phục điều khiển.")
	
	# 2. Khôi phục điều khiển cho Player
	var player = get_tree().get_first_node_in_group("player")
	if not player: player = get_tree().current_scene.find_child("Player", true, false)
	
	if player:
		var mouse_look = player.get_node_or_null("Head/MouseLook")
		if mouse_look:
			mouse_look.set_process(true)
			mouse_look.set_process_input(true)
			mouse_look.set_physics_process(true)
		player.set_movement_enabled(true)
	
	queue_free() # Xóa tờ giấy (Script này)

func _shake_node(node: Node3D, duration: float, intensity: float = 0.1, rot_intensity: float = 0.2, target_pos: Vector3 = Vector3.ZERO):
	if not node: return
	var original_pos = node.global_position
	var original_rot = node.global_rotation
	var shake_tween = create_tween()
	
	var steps = int(duration / 0.03)
	for i in range(steps):
		var t = float(i) / steps # Tỉ lệ thời gian trôi qua (0.0 đến 1.0)
		
		# Nếu có target_pos, dịch chuyển vị trí gốc dần về phía đó (tiến tới 70% quãng đường)
		var base_pos = original_pos
		if target_pos != Vector3.ZERO:
			base_pos = original_pos.lerp(target_pos, t * 0.7)
			
		var pos_offset = Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		
		var rot_offset = Vector3(
			randf_range(-rot_intensity, rot_intensity),
			randf_range(-rot_intensity, rot_intensity),
			randf_range(-rot_intensity, rot_intensity)
		)
		
		shake_tween.tween_property(node, "global_position", base_pos + pos_offset, 0.03)
		shake_tween.parallel().tween_property(node, "global_rotation", original_rot + rot_offset, 0.03)
	
	# Kết thúc không trả về vị trí cũ mà giữ nguyên vị trí đã tiến sát (để tạo cảm giác đe dọa)

func _shake_camera(camera: Camera3D, duration: float, intensity: float = 0.1):
	var original_offset = camera.h_offset
	var original_v_offset = camera.v_offset
	var shake_tween = create_tween()
	
	var steps = int(duration / 0.05)
	for i in range(steps):
		var h_off = randf_range(-intensity, intensity)
		var v_off = randf_range(-intensity, intensity)
		shake_tween.tween_property(camera, "h_offset", h_off, 0.05)
		shake_tween.parallel().tween_property(camera, "v_offset", v_off, 0.05)
	
	shake_tween.tween_property(camera, "h_offset", original_offset, 0.05)
	shake_tween.parallel().tween_property(camera, "v_offset", original_v_offset, 0.05)
