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
@export_file("*.tscn") var next_scene: String ## Scene tiep theo sau khi xong event

@export_group("Spooky Effects")
@export var laugh_sounds: Array[AudioStream] = [
	preload("res://assets/audio/ghost_event/laugh1.mp3"),
	preload("res://assets/audio/ghost_event/laugh2.mp3"),
	preload("res://assets/audio/ghost_event/laugh3.mp3"),
	preload("res://assets/audio/ghost_event/laugh4.mp3")
]
@export var laugh_min_interval: float = 0.5
@export var laugh_max_interval: float = 1.5
@export var frantic_intensity: float = 0.3 ## Độ loạng choạng khi chạy (0.0 - 1.0)
@export var breath_sound: AudioStream = preload("res://assets/audio/player/heavybreath.mp3") ## Am thanh tho doc
@export var scare_sound: AudioStream = preload("res://assets/audio/ghost_event/scare.mp3") ## Am thanh hù doạ khi ma lao toi
@export var start_sound: AudioStream = preload("res://assets/audio/ghost_event/suprise_hit.mp3") ## Am thanh khi vua cham vao A
@export var crawl_sound: AudioStream = preload("res://assets/audio/ghost_event/GhostCrawl.wav") ## Am thanh khi ma bo truon
@export var walk_sound: AudioStream = preload("res://assets/audio/ghost_event/monsterwalking.wav") ## Am thanh khi ma di bo B -> C

var _player: CharacterBody3D = null
var _is_active: bool = false
var _event_triggered: bool = false # Biến để kiểm tra xem đã chạy sự kiện chưa
var _target_look_pos: Vector3
var _current_anim_player: AnimationPlayer = null
var _is_escaping: bool = false # Biến trạng thái tháo chạy
var _shake_timer: float = 0.0 # Biến đếm nhịp lắc cam
var _laugh_players: Array[AudioStreamPlayer] = []
var _breath_player: AudioStreamPlayer = null
var _scare_player: AudioStreamPlayer = null
var _start_player: AudioStreamPlayer = null
var _walk_player: AudioStreamPlayer = null
var _crawl_player: AudioStreamPlayer = null
var _laugh_timer: float = 0.0
var _next_laugh_time: float = 1.0
var _laughing_enabled: bool = false

func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	
	# Khoi tao pool loa phat tieng cuoi (4 loa de chong lap am thanh)
	for i in range(4):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_laugh_players.append(p)
	
	# Khoi tao loa phat tieng tho doc
	if breath_sound:
		_breath_player = AudioStreamPlayer.new()
		_breath_player.stream = breath_sound
		add_child(_breath_player)
		if _breath_player.stream is AudioStreamMP3:
			_breath_player.stream.loop = true
	
	# Khoi tao loa hù doa/giat minh
	_scare_player = AudioStreamPlayer.new()
	_scare_player.bus = "SFX"
	add_child(_scare_player)
	
	_start_player = AudioStreamPlayer.new()
	_start_player.bus = "SFX"
	add_child(_start_player)
	
	_walk_player = AudioStreamPlayer.new()
	_walk_player.stream = walk_sound
	_walk_player.bus = "SFX"
	add_child(_walk_player)
	
	# Khoi tao loa cho ma bo
	_crawl_player = AudioStreamPlayer.new()
	_crawl_player.stream = crawl_sound
	_crawl_player.bus = "SFX"
	_crawl_player.volume_db = -40.0 # Khởi đầu im lặng
	add_child(_crawl_player)

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
	
	_target_look_pos = look_at_target.global_position
	
	# 2. PHÁT ÂM THANH GIẬT MÌNH TRƯỚC
	if _start_player and start_sound:
		_start_player.stream = start_sound
		_start_player.play()
		# Đợi một chút để âm thanh vang lên xong mới hỏi
		await get_tree().create_timer(0.5).timeout
	
	# 3. DIALOGUE 1: "Ai vậy?" (Trươc khi ma di chuyen)
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		dm.show_text("[Bạn]: Ai vậy?")
		if dm.has_signal("dialogue_finished"):
			await dm.dialogue_finished
	
	# 3. CHUẨN BỊ MA
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
	
	# 4. DI CHUYỂN MA TỚI C VÀ LÀM BƯỚC CHÂN NHỎ DẦN
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ghost, "global_position", end_point.global_position, duration)
	
	# Phat tieng bc và lam nó nho dân (Fade out)
	if _walk_player and walk_sound:
		_walk_player.volume_db = 0.0
		_walk_player.play()
		tween.tween_property(_walk_player, "volume_db", -30.0, duration)
	
	tween.chain().finished.connect(_on_sequence_finished)
	tween.chain().tween_callback(func(): if _walk_player: _walk_player.stop())

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
				cam.position.y = 0
			
			# DUNG TOAN BO TIENG CUOI KHI TOI DICH
			_laughing_enabled = false # Ngung he thong cuoi
			for p in _laugh_players:
				if p.playing: p.stop()
				
			return

		# Ap dung van toc (Giam toc mot chut khi sat dich)
		var current_speed = base_speed
		if dist < 2.0: current_speed = base_speed * 0.5
		
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
			
			# Nghieng cam trai phai (Roll) - Tao cam giac buoc chân khi chay
			var target_roll_z = sin(_shake_timer) * camera_sway_intensity
			cam.rotation.z = lerp(cam.rotation.z, target_roll_z, delta * 15.0)
			
			# Rung giat (Shake)
			cam.h_offset = lerp(cam.h_offset, randf_range(-camera_shake_intensity, camera_shake_intensity), 0.5)
			var bob_offset = sin(_shake_timer * 2.0) * (camera_sway_intensity * 0.3)
			cam.v_offset = lerp(cam.v_offset, randf_range(-camera_shake_intensity, camera_shake_intensity) + bob_offset, 0.5)
		
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
	
	# 1. HIỆN THOẠI NGHI VẤN (Ma đã tới C, người chơi tự hỏi)
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		dm.show_text("[Bạn]: Ai vậy nhỉ?")
		dm.show_text("[Bạn]: Sao trông giống...")
		if dm.has_signal("dialogue_finished"):
			await dm.dialogue_finished
	
	print("DEBUG: [GhostEvent] Suspense ended. Transitioning to Jumpscare...")
	
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
		
		# Phat am thanh bo (To dan khi lai gan bang Tween cho chac chan nghe thay)
		if _crawl_player:
			_crawl_player.pitch_scale = 1.0 # Reset ve toc do thuong
			_crawl_player.volume_db = -25.0 
			_crawl_player.play()
			var v_tween = create_tween()
			v_tween.tween_property(_crawl_player, "volume_db", 2.0, duration_1 + duration_2)
		
		# Chay 2 giai doan di chuyen ma
		var jumpscare_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		
		# Giai doan 1: Toc do thuong
		jumpscare_tween.tween_property(crawling_ghost, "global_position", midpoint, duration_1)
		
		# Giai doan 2: Tang toc và BAT TIENG HU / CUOI / TANG TOC AM THANH
		jumpscare_tween.tween_callback(func():
			if craw_anim: craw_anim.speed_scale = jumpscare_multiplier
			_laughing_enabled = true
			
			# TANG TOC TIENG BO (Pitch)
			if _crawl_player: _crawl_player.pitch_scale = 1.6 # Gắt hơn, nhanh hơn
			
			# Phat tieng hù doa neu co
			if _scare_player and scare_sound:
				_scare_player.stream = scare_sound
				_scare_player.volume_db = 2.0 # Tang am luong them ~15%
				_scare_player.play()
				
			print("DEBUG: [GhostEvent] Ghost and Sound accelerated!")
		)
		jumpscare_tween.tween_property(crawling_ghost, "global_position", target_ground_pos, duration_2)
		
		await jumpscare_tween.finished
		
		if _crawl_player: _crawl_player.stop()
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
			
			# CHI BAT DAU THO KHI DA TOI DIEM E
			if _breath_player:
				_breath_player.volume_db = -15.0 # Cho bé tí lại
				_breath_player.play()
			
			print("DEBUG: [GhostEvent] Player reached Point E. Breathing for 5 more seconds...")
			
			# DOI 5 GIAY SAU KHI TOI DIEM E (Tho doc tiep)
			await get_tree().create_timer(5.0).timeout
			
			# Ngung tho va bat dau hoi thoai
			if _breath_player: _breath_player.stop()
			
			# THOẠI CỦA DÂN LÀNG KHI PLAYER DEN E
			if get_tree().root.has_node("DialogueManager"):
				var dm = get_tree().root.get_node("DialogueManager")
				print("DEBUG: [GhostEvent] Triggering villager dialogue...")
				
				dm.show_text("[Ông lão]: Ơ kìa! Có chuyện gì vậy cu tí?")
				dm.show_text("[Ông lão]: Có chuyện gì mà cậu thở hồng hộc thế này?")
				dm.show_text("[Bạn]: Ma... Có ma! Tôi vừa thấy nó ở đằng kia!")
				dm.show_text("[Ông lão]: Ma cỏ gì đâu, chắc cậu hoa mắt vì sương rừng rồi.")
				dm.show_text("[Ông lão]: Vùng này sương dày hay làm người ta tưởng tượng lắm.")
				dm.show_text("[Ông lão]: Trông cậu có vẻ mệt mỏi quá.")
				dm.show_text("[Ông lão]: Thôi, vào làng nghỉ ngơi một lát cho định thần.")
				
				# Kiểm tra tín hiệu để tránh bị kẹt
				if dm.has_signal("dialogue_finished"):
					await dm.dialogue_finished
				else:
					await get_tree().create_timer(6.0).timeout
			
			# 4. HIỆU ỨNG CHUYỂN CẢNH (FADE TO BLACK)
			print("DEBUG: [GhostEvent] Dialogue finished. Starting transition...")
			
			var canvas = CanvasLayer.new()
			canvas.layer = 100
			add_child(canvas)
			
			var fade_rect = ColorRect.new()
			fade_rect.color = Color.BLACK
			fade_rect.modulate.a = 0.0
			fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Không chặn chuột
			
			# Ép kích thước phủ toàn màn hình
			fade_rect.anchor_right = 1.0
			fade_rect.anchor_bottom = 1.0
			canvas.add_child(fade_rect)
			
			# Tween làm tối màn hình
			var fade_tween = create_tween()
			fade_tween.tween_property(fade_rect, "modulate:a", 1.0, 2.0)
			await fade_tween.finished
			
			print("DEBUG: [GhostEvent] Screen is now BLACK.")
			
			# CHUYỂN SCENE NẾU CÓ
			if next_scene != "":
				print("DEBUG: [GhostEvent] Changing scene to: ", next_scene)
				get_tree().change_scene_to_file(next_scene)
				return
	
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
