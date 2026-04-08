extends Area3D

@export_group("Target Nodes")
@export var look_at_target: Node3D ## Vật D: Nơi người chơi nhìn vào
@export var ghost: Node3D ## Con ma
@export var crawling_ghost: Node3D ## Con ma bò trườn (cho cú Jumpscare)
@export var start_point: Node3D ## Vật B: Điểm xuất phát của con ma
@export var end_point: Node3D ## Vật C: Điểm kết thúc của con ma
@export var escape_point: Node3D ## Vật E: Điểm người chơi chạy đến sau khi bị hù
@export var villager: Node3D ## Dân làng
@export var villager_point: Node3D ## Vật F: Nơi dân làng xuất hiện
@export var villager_animation_name: String = "" ## Tên animation của dân làng

@export_group("Configuration")
@export var use_fixed_duration: bool = true ## Bật để đi trong số giây cố định
@export var sequence_duration: float = 12.0 ## Thời gian đi từ B tới C (giây)
@export var ghost_speed: float = 2.0 ## Tốc độ (chỉ dùng nếu tắt Fixed Duration)
@export var look_smoothness: float = 5.0 ## Độ mượt của camera
@export var reverse_facing: bool = false ## Tích nếu ma bị đi lùi
@export var ghost_rotation_offset: float = 0.0 ## Xoay ma thêm bao nhiêu độ
@export var custom_animation_name: String = "" ## Tên animation (để trống sẽ tự tìm)
@export var jumpscare_speed: float = 30.0 ## Tốc độ ma lao vào mặt (m/s)
@export var jumpscare_ratio: float = 0.5 ## Tỉ lệ quãng đường bắt đầu tăng tốc (0.1 - 0.9)
@export var jumpscare_multiplier: float = 3.0 ## Hệ số tăng tốc giai đoạn sau
@export var camera_shake_intensity: float = 0.2 ## Độ rung giật (Shake)
@export var camera_sway_intensity: float = 0.12 ## Độ nghiêng trái phải (Sway)
@export var camera_sway_speed: float = 12.0 ## Tốc độ nhịp lắc
@export var hide_ghost_on_end: bool = true
@export var auto_unlock_after: float = 0.5 ## Thời gian chờ sau khi tới E để mở khóa

@export_group("Spooky Effects")
@export var laugh_sounds: Array[AudioStream] = [
	preload("res://assets/audio/laugh1.mp3"),
	preload("res://assets/audio/laugh2.mp3"),
	preload("res://assets/audio/laugh3.mp3"),
	preload("res://assets/audio/laugh4.mp3")
]
@export var laugh_min_interval: float = 0.5
@export var laugh_max_interval: float = 1.5
@export var frantic_intensity: float = 0.3 ## Độ loạng choạng khi chạy (0.0 - 1.0)
@export var stumble_distance_ratio: float = 0.5 ## Tỉ lệ quãng đường sẽ bị vấp ngã (0.1 - 0.9)

var _player: CharacterBody3D = null
var _is_active: bool = false
var _event_triggered: bool = false # Biến để kiểm tra xem đã chạy sự kiện chưa
var _target_look_pos: Vector3
var _current_anim_player: AnimationPlayer = null
var _is_escaping: bool = false # Biến trạng thái tháo chạy
var _shake_timer: float = 0.0 # Biến đếm nhịp lắc cam
var _laugh_players: Array[AudioStreamPlayer] = []
var _laugh_timer: float = 0.0
var _next_laugh_time: float = 1.0
var _laughing_enabled: bool = false
var _has_stumbled: bool = false
var _is_stumbling: bool = false
var _stumble_timer: float = 0.0
var _escape_total_dist: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	
	# Khoi tao pool loa phat tieng cuoi (4 loa de chong lap am thanh)
	for i in range(4):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_laugh_players.append(p)

	if ghost: ghost.hide()
	
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
		
		# TINH TOAN TOC DO (Giam xuong 75% vi loạng choạng)
		var base_speed = _player.get("WALK_SPEED") if "WALK_SPEED" in _player else 8.0
		base_speed *= 0.75 # Chạy yếu hơn bình thường
		
		# KIEM TRA VẤP NGÃ (Xay ra o khoang thiet lap tren Editor)
		if not _has_stumbled and dist < (_escape_total_dist * stumble_distance_ratio) and dist > 2.0:
			_is_stumbling = true
			_has_stumbled = true
			_stumble_timer = 1.2 # Ngã lâu hơn để tăng độ thốn
			print("DEBUG: [GhostEvent] Player STUMBLED HARD!")

		# KIEM TRA XEM DA TOI DICH CHUA
		if dist < (base_speed * delta * 1.5) or dist < 0.5:
			_is_escaping = false
			_player.velocity = Vector3.ZERO
			# Reset camera ve binh thuong
			var cam = _player.get_node_or_null("Head/Camera3D")
			if cam:
				cam.h_offset = 0
				cam.v_offset = 0
				cam.rotation.z = 0
				cam.rotation.x = 0
			
			# DUNG TOAN BO TIENG CUOI KHI TOI DICH
			_laughing_enabled = false # Ngung he thong cuoi
			for p in _laugh_players:
				if p.playing: p.stop()
				
			return

		# Ap dung van toc (Giam toc mot chut khi sat dich)
		var current_speed = base_speed
		if dist < 2.0: current_speed = base_speed * 0.5
		
		# Neu dang vap ngã thi giam toc tham te
		if _is_stumbling:
			current_speed *= 0.1
			_stumble_timer -= delta
			if _stumble_timer <= 0:
				_is_stumbling = false
		
		# TINH TOAN HUONG CHAY TÁN LOẠN (Zigzag)
		var side_dir = direction.cross(Vector3.UP).normalized()
		# Ham sin tao nhip đảo trai phai
		var zigzag_offset = side_dir * sin(_shake_timer * 0.5) * frantic_intensity
		var frantic_direction = (direction + zigzag_offset).normalized()
		
		_player.velocity.x = frantic_direction.x * current_speed
		_player.velocity.z = frantic_direction.z * current_speed
		
		# XOAY NGUOI THEO HUONG CHAY (Bao gom ca huong liệng)
		if frantic_direction.length() > 0.01:
			var target_basis = Basis.looking_at(frantic_direction, Vector3.UP)
			_player.global_basis = _player.global_basis.slerp(target_basis, delta * 8.0)
		
		# 3. RUNG LAC & NGHIENG CAMERA (Shake & Sway)
		var cam = _player.get_node_or_null("Head/Camera3D")
		if cam:
			_shake_timer += delta * camera_sway_speed # Nhịp lắc cam (từ Editor)
			
			# HIEU UNG VẤP NGÃ: Cam chúi xuong & Lún xuông
			var target_tilt_x = 0.0
			var target_roll_z = sin(_shake_timer) * camera_sway_intensity # Nghiêng mặc định khi chạy
			var stumble_v_dip = 0.0 # Độ lún camera (dung v_offset cho muot)
			var extra_shake = 0.0
			
			if _is_stumbling:
				target_tilt_x = -deg_to_rad(85.0) # Nhìn vuông góc xuống đất luôn
				target_roll_z = deg_to_rad(35.0) # Vẹo đầu sang một bên cho thảm
				stumble_v_dip = 2.0 # Sát sạt mặt đất
				extra_shake = camera_shake_intensity * 4.0 # Rung cực mạnh
			
			# Thuc hien xoay cam (Duy nhat mot lan de tranh giật)
			cam.rotation.x = lerp(cam.rotation.x, target_tilt_x, delta * 12.0)
			cam.rotation.z = lerp(cam.rotation.z, target_roll_z, delta * 15.0)
			
			# Rung giat (Shake) + Cú lún vấp ngã
			var current_shake = camera_shake_intensity + extra_shake
			cam.h_offset = lerp(cam.h_offset, randf_range(-current_shake, current_shake), 0.5)
			
			# Cong them stumble_v_dip vao v_offset de tao cam giac lun nguoi
			var bob_offset = sin(_shake_timer * 2.0) * (camera_sway_intensity * 0.3)
			cam.v_offset = lerp(cam.v_offset, randf_range(-current_shake, current_shake) + bob_offset + stumble_v_dip, 0.5)
		
		# 4. DAN LANG XOAY THEO THEO DOI PLAYER
		if villager and villager.visible:
			var target_pos = _player.global_position
			villager.look_at(Vector3(target_pos.x, villager.global_position.y, target_pos.z), Vector3.UP)
			villager.rotate_y(PI) # Xoay 180 do bi nguoc model
	
	# 5. TIENG CUOI HON TAP (Laugh System - Co the chay truoc ca luc tháo chay)
	if _laughing_enabled:
		_laugh_timer += delta
		if _laugh_timer >= _next_laugh_time:
			_play_random_laugh()
			_laugh_timer = 0
			_next_laugh_time = randf_range(laugh_min_interval, laugh_max_interval)
		
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
		
		# Giai doan 2: Tang toc va BAT TIENG CUOI
		jumpscare_tween.tween_callback(func():
			if craw_anim: craw_anim.speed_scale = jumpscare_multiplier
			_laughing_enabled = true
			print("DEBUG: [GhostEvent] Ghost accelerated and Laughter started!")
		)
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
			_has_stumbled = false
			_is_stumbling = false
			_escape_total_dist = _player.global_position.distance_to(escape_point.global_position)
			
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

func _play_random_laugh() -> void:
	if laugh_sounds.size() == 0: return
	
	# Tim mot loa dang ranh
	var player_to_use: AudioStreamPlayer = null
	for p in _laugh_players:
		if not p.playing:
			player_to_use = p
			break
	
	# Neu tat ca deu dang ban, cu dung loa dau tien
	if not player_to_use: player_to_use = _laugh_players[0]
	
	# Chon tieng cuoi ngau nhien
	var sound = laugh_sounds[randi() % laugh_sounds.size()]
	player_to_use.stream = sound
	
	# Ngau nhien hoa Pitch de nghe cho kinh di (Tram/Bong)
	player_to_use.pitch_scale = randf_range(0.7, 1.4)
	player_to_use.volume_db = randf_range(-5.0, 5.0) # Am luong to nho khac nhau
	
	player_to_use.play()
