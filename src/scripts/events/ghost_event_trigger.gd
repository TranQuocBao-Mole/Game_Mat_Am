extends Area3D

@export_group("Target Nodes")
@export var look_at_target: Node3D      ## Vật D: Nơi người chơi nhìn vào
@export var ghost: Node3D              ## Con ma
@export var crawling_ghost: Node3D       ## Con ma bò trườn (cho cú Jumpscare)
@export var start_point: Node3D          ## Vật B: Điểm xuất phát của con ma
@export var end_point: Node3D          ## Vật C: Điểm kết thúc của con ma
@export var escape_point: Node3D       ## Vật E: Điểm người chơi chạy đến sau khi bị hù
@export var villager: Node3D           ## Dân làng
@export var villager_point: Node3D     ## Vật F: Nơi dân làng xuất hiện
@export var villager_animation_name: String = "" ## Tên animation của dân làng

@export_group("Configuration")
@export var use_fixed_duration: bool = true ## Bật để đi trong số giây cố định
@export var sequence_duration: float = 12.0  ## Thời gian đi từ B tới C (giây)
@export var ghost_speed: float = 2.0   ## Tốc độ (chỉ dùng nếu tắt Fixed Duration)
@export var look_smoothness: float = 5.0 ## Độ mượt của camera
@export var reverse_facing: bool = false ## Tích nếu ma bị đi lùi
@export var ghost_rotation_offset: float = 0.0 ## Xoay ma thêm bao nhiêu độ
@export var custom_animation_name: String = "" ## Tên animation (để trống sẽ tự tìm)
@export var jumpscare_speed: float = 30.0 ## Tốc độ ma lao vào mặt (m/s)
@export var jumpscare_ratio: float = 0.5 ## Tỉ lệ quãng đường bắt đầu tăng tốc (0.1 - 0.9)
@export var jumpscare_multiplier: float = 3.0 ## Hệ số tăng tốc giai đoạn sau
@export var camera_shake_intensity: float = 0.2 ## Độ rung giật (Shake)
@export var camera_sway_intensity: float = 0.12 ## Độ nghiêng trái phải (Sway)
@export var camera_sway_speed: float = 12.0    ## Tốc độ nhịp lắc
@export var hide_ghost_on_end: bool = true
@export var auto_unlock_after: float = 0.5 ## Thời gian chờ sau khi tới E để mở khóa

var _player: CharacterBody3D = null
var _is_active: bool = false
var _event_triggered: bool = false # Biến để kiểm tra xem đã chạy sự kiện chưa
var _target_look_pos: Vector3
var _current_anim_player: AnimationPlayer = null
var _is_escaping: bool = false # Biến trạng thái tháo chạy
var _shake_timer: float = 0.0 # Biến đếm nhịp lắc cam

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	
	# Hien ma va cho đứng sẵn o Diem B (Start Point)
	if ghost and start_point and end_point:
		ghost.global_position = start_point.global_position
		ghost.look_at(end_point.global_position, Vector3.UP)
		if reverse_facing: ghost.rotate_y(PI)
		if ghost_rotation_offset != 0: ghost.rotate_y(deg_to_rad(ghost_rotation_offset))
		ghost.show()
		
		# Neu muon ma dung im o tư the Idle luc dau
		var anim = _find_animation_player(ghost)
		if anim:
			var list = anim.get_animation_list()
			if list.size() > 0: anim.play(list[0]) # Thuong la Idle/Walk
			anim.stop() # Dung im tai cho
	
	if crawling_ghost: crawling_ghost.hide()
	if villager: villager.hide()

func _on_body_entered(body: Node3D) -> void:
	if _is_active or _event_triggered: return # Nếu đang chạy hoặc đã chạy rồi thì bỏ qua
	
	if body.is_in_group("player"):
		_event_triggered = true # Đánh dấu là đã kích hoạt
		_player = body as CharacterBody3D
		_trigger_sequence()

func _trigger_sequence() -> void:
	# KIEM TRA AN TOAN: Neu thieu node thi khong khoa nguoi choi
	if not look_at_target:
		print("LOI: Thieu Vat D (Look At Target). Su kien khong chay.")
		return
	if not ghost or not start_point or not end_point:
		print("LOI: Thieu Ma hoac Diem B, C. Su kien khong chay.")
		return

	_is_active = true
	
	# 1. Khóa người chơi
	if _player.has_method("set_movement_enabled"):
		_player.set_movement_enabled(false)
		print("DEBUG: [GhostEvent] Da khoa di chuyen de chay su kien.")
	
	_target_look_pos = look_at_target.global_position
	
	ghost.global_position = start_point.global_position
	ghost.look_at(end_point.global_position, Vector3.UP)
	if reverse_facing: ghost.rotate_y(PI)
	if ghost_rotation_offset != 0: ghost.rotate_y(deg_to_rad(ghost_rotation_offset))
	ghost.show()
	
	_current_anim_player = _find_animation_player(ghost)
	if _current_anim_player:
		var target_anim = _get_target_animation(_current_anim_player)
		if target_anim != "":
			var anim_res = _current_anim_player.get_animation(target_anim)
			if anim_res: anim_res.loop_mode = Animation.LOOP_LINEAR
			_current_anim_player.play(target_anim)
	
	var dist = start_point.global_position.distance_to(end_point.global_position)
	var duration = sequence_duration if use_fixed_duration else (dist / ghost_speed)
	
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "global_position", end_point.global_position, duration)
	tween.finished.connect(_on_sequence_finished)

func _find_animation_player(root: Node) -> AnimationPlayer:
	var anim = root.get_node_or_null("AnimationPlayer")
	if anim: return anim
	for child in root.get_children():
		if child is AnimationPlayer: return child
	return null

func _get_target_animation(ap: AnimationPlayer) -> String:
	var list = ap.get_animation_list()
	if custom_animation_name != "" and ap.has_animation(custom_animation_name):
		return custom_animation_name
	for a in list:
		if "walk" in a.to_lower() or "run" in a.to_lower(): return a
	if list.size() > 0: return list[0]
	return ""

func _physics_process(delta: float) -> void:
	# 1. Tu dong xoay cam nhin ma (Khi dang dien ra su kien)
	if _is_active and look_at_target and _player:
		_handle_player_look(delta)
		# 2. XU LY THAO CHAY (Set velocity va Rung camera)
	if _is_escaping and _player and escape_point:
		var pos_now = _player.global_position
		var pos_target = escape_point.global_position
		
		# Tinh huong di chuyen (Chi lay X va Z)
		var direction_full = (pos_target - pos_now)
		var direction = Vector3(direction_full.x, 0, direction_full.z).normalized()
		var dist = Vector2(pos_now.x, pos_now.z).distance_to(Vector2(pos_target.x, pos_target.z))
		
		# SU DUNG TOC DO MAC DINH CUA PLAYER
		var base_speed = _player.get("WALK_SPEED") if "WALK_SPEED" in _player else 8.0
		
		# KIEM TRA XEM DA TOI DICH CHUA (Dung khoang cach dong de tranh overshoot)
		# Neu khoang cach con lai nho hon quang duong di trong 1 frame -> TOI DICH
		if dist < (base_speed * delta * 1.5) or dist < 0.5:
			_is_escaping = false
			_player.velocity.x = 0
			_player.velocity.z = 0
			# Reset camera ve binh thuong
			var cam = _player.get_node_or_null("Head/Camera3D")
			if cam:
				cam.h_offset = 0
				cam.v_offset = 0
				cam.rotation.z = 0
			return

		# Ap dung van toc (Giam toc mot chut khi sat dich de "tiep dat" cho em)
		var current_speed = base_speed
		if dist < 2.0: current_speed = base_speed * 0.5
		
		_player.velocity.x = direction.x * current_speed
		_player.velocity.z = direction.z * current_speed
		
		# XOAY NGUOI MUOT MA
		if direction.length() > 0.01:
			var target_basis = Basis.looking_at(direction, Vector3.UP)
			_player.global_basis = _player.global_basis.slerp(target_basis, delta * 10.0)
		
		# 3. RUNG LAC & NGHIENG CAMERA (Shake & Sway)
		var cam = _player.get_node_or_null("Head/Camera3D")
		if cam:
			_shake_timer += delta * camera_sway_speed # Nhịp lắc cam (từ Editor)
			
			# Nghieng cam trai phai (Roll) - Tao cam giac buoc chân khi chay
			cam.rotation.z = lerp(cam.rotation.z, sin(_shake_timer) * camera_sway_intensity, delta * 15.0)
			
			# Rung giat (Shake)
			cam.h_offset = lerp(cam.h_offset, randf_range(-camera_shake_intensity, camera_shake_intensity), 0.5)
			cam.v_offset = lerp(cam.v_offset, randf_range(-camera_shake_intensity, camera_shake_intensity) + (sin(_shake_timer * 2.0) * (camera_sway_intensity * 0.3)), 0.5)
		
		# 4. DAN LANG XOAY THEO THEO DOI PLAYER
		if villager and villager.visible:
			var target_pos = _player.global_position
			villager.look_at(Vector3(target_pos.x, villager.global_position.y, target_pos.z), Vector3.UP)
			villager.rotate_y(PI) # Xoay 180 do bi nguoc model
		
		# LUU Y: Khong goi move_and_slide() o day nua 
		# vi trong player.gd da goi move_and_slide() roi.

func _handle_player_look(delta: float) -> void:
	var head = _player.get_node_or_null("Head")
	var camera = _player.get_node_or_null("Head/Camera3D")
	if head and camera:
		var look_at_h = Vector3(_target_look_pos.x, head.global_position.y, _target_look_pos.z)
		head.global_transform = head.global_transform.interpolate_with(head.global_transform.looking_at(look_at_h, Vector3.UP), delta * look_smoothness)
		camera.global_transform = camera.global_transform.interpolate_with(camera.global_transform.looking_at(_target_look_pos, Vector3.UP), delta * look_smoothness)

func _on_sequence_finished() -> void:
	if _current_anim_player: _current_anim_player.stop()
	if hide_ghost_on_end: ghost.hide()
	
	# 1. HIEN THOAI SAU KHI MA DI XONG
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		dm.show_text("Đụ má, con cặc gì đang diễn ra vậy, Ộ")
		dm.show_text("Tao là thái tử nhà họ Phùng, coi chừng tao")
		if dm.has_signal("dialogue_finished"):
			await dm.dialogue_finished
	
	# 2. JUMPSCARE: MA BO TRUON LAO VAO MAT
	if crawling_ghost and _player:
		# Dich chuyen ma bo den Diem D (Noi nguoi choi dang nhin)
		crawling_ghost.global_position = look_at_target.global_position
		
		# Quat ma bo ve phuong nguoi choi
		crawling_ghost.look_at(_player.global_position, Vector3.UP)
		crawling_ghost.rotate_y(PI) # Thuong ma bo se bi nguoc nen xoay 180 do
		
		# Phat animation bo
		var craw_anim = _find_animation_player(crawling_ghost)
		if craw_anim:
			var list = craw_anim.get_animation_list()
			if list.size() > 0: 
				craw_anim.speed_scale = 1.0 # Toc do goc
				craw_anim.play(list[0])
			
		crawling_ghost.show()
		
		# Tinh toan 2 giai doan di chuyen (Dung cac thong so moi)
		var cam_pos = _player.get_node("Head/Camera3D").global_position
		var target_ground_pos = Vector3(cam_pos.x, crawling_ghost.global_position.y, cam_pos.z)
		
		var total_dist = crawling_ghost.global_position.distance_to(target_ground_pos)
		var midpoint = crawling_ghost.global_position.lerp(target_ground_pos, jumpscare_ratio)
		
		var dist_1 = total_dist * jumpscare_ratio
		var dist_2 = total_dist * (1.0 - jumpscare_ratio)
		
		var duration_1 = dist_1 / jumpscare_speed
		var duration_2 = dist_2 / (jumpscare_speed * jumpscare_multiplier)
		
		# Chay 2 giai doan
		var jumpscare_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		
		# Giai doan 1: Toc do thuong
		jumpscare_tween.tween_property(crawling_ghost, "global_position", midpoint, duration_1)
		
		# Giai doan 2: Tang toc ca di chuyen lan animation
		jumpscare_tween.tween_callback(func(): if craw_anim: craw_anim.speed_scale = jumpscare_multiplier)
		jumpscare_tween.tween_property(crawling_ghost, "global_position", target_ground_pos, duration_2)
		
		await jumpscare_tween.finished
		
		crawling_ghost.hide()
		
		# 3. DAN LANG XUAT HIEN NGAY LAP TUC TAI DIEM F
		if villager and villager_point:
			villager.global_position = villager_point.global_position
			# Quay dân làng về phía người chơi
			var look_target = _player.global_position
			villager.look_at(Vector3(look_target.x, villager.global_position.y, look_target.z), Vector3.UP)
			villager.rotate_y(PI) # Xoay 180 nếu bị ngược
			villager.show()
			
			# CHAY ANIMATION CHO DAN LANG
			var v_anim = _find_animation_player(villager)
			if v_anim:
				var anim_to_play = villager_animation_name
				if anim_to_play == "":
					var list = v_anim.get_animation_list()
					if list.size() > 0: anim_to_play = list[0]
				
				if anim_to_play != "" and v_anim.has_animation(anim_to_play):
					v_anim.play(anim_to_play)
					v_anim.get_animation(anim_to_play).loop_mode = Animation.LOOP_LINEAR
			
			print("DEBUG: [GhostEvent] Villager spawned and animated at Point F.")

		# 4. THAO CHAY NGAY LAP TUC: Kich hoat trang thai tháo chay vat ly
		if escape_point and _player:
			print("DEBUG: [GhostEvent] Player begins physics-based escape to Point E IMMEDIATELY...")
			
			# Ngung viec khoa cam nhìn ma
			_is_active = false 
			
			# Bat trang thai tháo chay
			_is_escaping = true
			
			# Đợi cho đén khi tháo chạy xong
			while _is_escaping:
				await get_tree().physics_frame
			
			print("DEBUG: [GhostEvent] Escape finished.")
			
			# THOẠI CỦA DÂN LÀNG KHI PLAYER DEN E
			if get_tree().root.has_node("DialogueManager"):
				var dm = get_tree().root.get_node("DialogueManager")
				dm.show_text("Ớ kìa Thái tử! Làm cái gì mà chạy như ma đuổi thế?")
				dm.show_text("Váy áo gì mà đỏ lòm thế kia, mới đi 'ăn hàng' ở đâu về à?")
				if dm.has_signal("dialogue_finished"):
					await dm.dialogue_finished
	
	# KET THUC TOAN BO
	if auto_unlock_after > 0:
		await get_tree().create_timer(auto_unlock_after).timeout
	
	if _player.has_method("set_movement_enabled"):
		_player.set_movement_enabled(true)
	
	_is_active = false
