extends Area3D

@export var ghost_node: Node3D
@export var escape_point: Node3D
@export var ghost_speed: float = 240.0 # Tốc độ ma ban đầu (siêu nhanh)
@export var speed_multiplier: float = 3.0 # Hệ số tăng tốc (240 * 3 = 720)
@export var brush_node: Node3D # Node cây bút sẽ hiện ra
@export var camera_shake_intensity: float = 0.2
@export var camera_sway_intensity: float = 0.12
@export var camera_sway_speed: float = 12.0

var _is_triggered: bool = false
var _player: CharacterBody3D = null
var _state: String = "idle"
var _initial_chase_dist: float = 0.0
var _current_chase_dist: float = 0.0
var _anim_player: AnimationPlayer = null
var _shake_timer: float = 0.0
var _initial_ghost_pos: Vector3
var _initial_ghost_rot: Vector3
var _first_completion: bool = true
var _original_fov: float = 75.0
var _is_zoomed: bool = false
var _player_start_pos: Vector3

func _ready():
	body_entered.connect(_on_body_entered)
	if brush_node:
		if brush_node.has_method("set_active"):
			brush_node.is_active = false
		else:
			brush_node.hide()
	
	if ghost_node: 
		_initial_ghost_pos = ghost_node.global_position
		_initial_ghost_rot = ghost_node.global_rotation
		ghost_node.hide()
		_anim_player = _find_animation_player(ghost_node)
		
		# Vô hiệu hóa vật lý để không làm kẹt người chơi
		_disable_ghost_collision(ghost_node)
	
	# Lấy FOV gốc từ camera của người chơi
	call_deferred("_cache_original_fov")

func _cache_original_fov():
	if _player:
		var cam = _player.get_node_or_null("Head/Camera3D")
		if cam: _original_fov = cam.fov

func _find_animation_player(root: Node) -> AnimationPlayer:
	var anim = root.get_node_or_null("AnimationPlayer")
	if anim: return anim
	for child in root.get_children():
		var found = _find_animation_player(child)
		if found: return found
	return null

func _on_body_entered(body: Node3D):
	if _is_triggered: return
	if body.is_in_group("player"):
		_is_triggered = true
		_player = body as CharacterBody3D
		_player_start_pos = _player.global_position # Chốt vị trí ban đầu
		_start_event()

func _start_event():
	# Khóa người chơi và chuột
	if _player.has_method("set_movement_enabled"):
		_player.set_movement_enabled(false)
		
	var mouse_look = _player.get_node_or_null("Head/MouseLook")
	if mouse_look:
		mouse_look.set_process(false)
		mouse_look.set_process_input(false)
	
	# 1. Chớp đen
	var flash = _create_flash_rect()
	await get_tree().create_timer(0.05).timeout
	if ghost_node: ghost_node.show()
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(flash):
		flash.queue_free()

	# Zoom camera vào ma (FOV nhỏ lại cực đại) và hướng nhìn thẳng vào ma
	var cam = _player.get_node_or_null("Head/Camera3D")
	var head = _player.get_node_or_null("Head")
	if cam:
		var tween = create_tween()
		tween.tween_property(cam, "fov", 12.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		if head and ghost_node:
			var look_target = ghost_node.global_position
			look_target.y += 2.0 # Nhìn vào phần trên của ma để nó ở trung tâm
			head.look_at(look_target, Vector3.UP)
			# Reset rotation X của camera để tránh bị nghiêng lên/xuống quá mức
			cam.rotation.x = clamp(cam.rotation.x, -0.5, 0.5)
		
		_is_zoomed = true

	if not _anim_player: 
		print("[ERROR] Không tìm thấy AnimationPlayer trong ghost_node.")
		return
		
	var anim_list = _anim_player.get_animation_list()
	print("[GhostEvent] Bắt đầu chuỗi event. Tổng số Anim: ", anim_list.size())
	
	# 2. Anim 17 (index 16)
	_play_anim(anim_list, 16, true)
	await get_tree().create_timer(2.0).timeout
	
	# 4. Anim 6 (index 5)
	var len5 = _play_anim(anim_list, 5, false)
	await get_tree().create_timer(len5).timeout
	
	# 5. Anim 13 (index 12)
	_play_anim(anim_list, 12, true)
	
	# 6. Đợi 2s
	await get_tree().create_timer(2.0).timeout
	
	# 7. Anim 14 (index 13)
	var len13 = _play_anim(anim_list, 13, false)
	await get_tree().create_timer(len13).timeout
	
	# 8. Anim 16 (index 15) - Ma bắt đầu chạy
	_play_anim(anim_list, 15, true)
	
	print("[GhostEvent] Bắt đầu rượt đuổi!")
	# Bắt đầu trạng thái rượt đuổi
	_initial_chase_dist = ghost_node.global_position.distance_to(_player.global_position)
	_current_chase_dist = 0.0
	_state = "chasing"

func _play_anim(list: Array[StringName], index: int, force_loop: bool = false) -> float:
	if index >= 0 and index < list.size():
		var anim_name = list[index]
		_anim_player.play(anim_name)
		var anim = _anim_player.get_animation(anim_name)
		if anim:
			if force_loop:
				anim.loop_mode = Animation.LOOP_LINEAR
			else:
				anim.loop_mode = Animation.LOOP_NONE
			print("[GhostEvent] Đang chạy Anim: ", anim_name, " | Thời lượng: ", anim.length)
			return anim.length
		return 1.0
	else:
		print("[WARNING] Không tồn tại Animation ở vị trí ", index)
		return 1.0

func _create_flash_rect() -> CanvasLayer:
	var flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 101
	get_tree().root.add_child(flash_canvas)
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color.BLACK
	flash_canvas.add_child(flash_rect)
	return flash_canvas

func _physics_process(delta: float):
	# Logic di chuyển của Ma (Chạy trong cả trạng thái chasing và escaping)
	if (_state == "chasing" or _state == "escaping") and ghost_node and _player:
		var ghost_pos = ghost_node.global_position
		
		# Ma lao về vị trí CHỐT của người chơi thay vì đuổi theo tọa độ sống
		var target_aim_pos = _player_start_pos
		
		# Tính toán tốc độ ma (x3 sau 30% quãng đường)
		var current_speed = ghost_speed
		var anim_speed = 1.0
		if _current_chase_dist >= _initial_chase_dist * 0.3:
			current_speed *= speed_multiplier
			anim_speed = speed_multiplier
			
			# Zoom camera lại bình thường muộn hơn (khi ma đạt 70% quãng đường)
			if _is_zoomed and _current_chase_dist >= _initial_chase_dist * 0.7:
				_is_zoomed = false
				var cam = _player.get_node_or_null("Head/Camera3D")
				if cam:
					var tween = create_tween()
					tween.tween_property(cam, "fov", _original_fov, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
		# Đồng bộ tốc độ animation
		if _anim_player:
			_anim_player.speed_scale = anim_speed
			
		# Ma nhìn về phía vị trí mục tiêu
		ghost_node.look_at(Vector3(target_aim_pos.x, ghost_node.global_position.y, target_aim_pos.z), Vector3.UP)
		ghost_node.rotate_y(PI)
		
		# Ma di chuyển tới vị trí chốt
		var direction = (target_aim_pos - ghost_pos).normalized()
		direction.y = 0
		var move_step = direction * current_speed * delta
		ghost_node.global_position += move_step
		_current_chase_dist += move_step.length()
		
		# Tính khoảng cách 2D (bỏ qua trục Y) để tránh lỗi chênh lệch độ cao
		var dist_2d = Vector2(ghost_pos.x, ghost_pos.z).distance_to(Vector2(target_aim_pos.x, target_aim_pos.z))
		
		# Nếu ma đã tới sát vị trí chốt của người chơi (trên mặt phẳng ngang)
		if _state == "chasing" and dist_2d < 2.0:
			_state = "escaping"
			print("[GhostEvent] Ma đã tới điểm chốt, người chơi tháo chạy!")
			
			# Dừng ma lại tại điểm chốt
			if _anim_player:
				_anim_player.speed_scale = 1.0
				_anim_player.stop()

	# Logic người chơi bỏ chạy
	if _state == "escaping" and _player and escape_point:
		var player_pos = _player.global_position
		var target_pos = escape_point.global_position
		
		var dist = Vector2(player_pos.x, player_pos.z).distance_to(Vector2(target_pos.x, target_pos.z))
		
		if dist > 1.0:
			var direction = (target_pos - player_pos).normalized()
			direction.y = 0
			var base_speed = _player.get("WALK_SPEED") if "WALK_SPEED" in _player else 12.0
			base_speed *= 1.3
			
			_player.velocity.x = direction.x * base_speed
			_player.velocity.z = direction.z * base_speed
			
			# Xoay người chơi về hướng chạy
			var target_basis = Basis.looking_at(direction, Vector3.UP)
			_player.global_basis = _player.global_basis.slerp(target_basis, delta * 10.0)
			
			# Hiệu ứng rung lắc camera (Shake & Sway)
			var cam = _player.get_node_or_null("Head/Camera3D")
			if cam:
				_shake_timer += delta * camera_sway_speed
				
				# Nghiêng camera (Roll)
				var target_roll_z = sin(_shake_timer) * camera_sway_intensity
				cam.rotation.z = lerp(cam.rotation.z, target_roll_z, delta * 15.0)
				
				# Rung giật (Shake)
				cam.h_offset = lerp(cam.h_offset, randf_range(-camera_shake_intensity, camera_shake_intensity), 0.5)
				var bob_offset = sin(_shake_timer * 2.0) * (camera_sway_intensity * 0.3)
				cam.v_offset = lerp(cam.v_offset, randf_range(-camera_shake_intensity, camera_shake_intensity) + bob_offset, 0.5)
		else:
			# Dừng lại khi tới nơi
			_state = "idle"
			_player.velocity = Vector3.ZERO
			
			# Reset camera
			var cam = _player.get_node_or_null("Head/Camera3D")
			if cam:
				cam.h_offset = 0
				cam.v_offset = 0
				cam.rotation.z = 0
				
			_finish_event()

func _finish_event():
	if ghost_node: 
		ghost_node.hide()
		ghost_node.global_position = _initial_ghost_pos
		ghost_node.global_rotation = _initial_ghost_rot
	
	if _anim_player:
		_anim_player.speed_scale = 1.0
	
	# Người chơi quay lại nhìn về phía ma vừa đuổi (điểm bắt đầu sự kiện)
	var look_pos = global_position
	var head = _player.get_node_or_null("Head")
	if head:
		head.look_at(Vector3(look_pos.x, head.global_position.y, look_pos.z), Vector3.UP)
		var cam = _player.get_node_or_null("Head/Camera3D")
		if cam: cam.rotation.x = 0
	
	# Thoại
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		dm.show_text("Cái thứ quái quỷ gì vậy?")
		if dm.has_signal("dialogue_finished"):
			await dm.dialogue_finished
			
	# Hiện cây bút ở lần đầu tiên
	if _first_completion:
		if brush_node:
			if brush_node.has_method("set_active") or "is_active" in brush_node:
				brush_node.is_active = true
			else:
				brush_node.show()
			print("[GhostEvent] Đã hiện cây bút Brush.")
		_first_completion = false
	
	# Đồng bộ và mở khóa chuột
	var mouse_look = _player.get_node_or_null("Head/MouseLook")
	if mouse_look:
		if "yaw" in mouse_look: mouse_look.yaw = _player.rotation.y
		var cam = _player.find_child("Camera3D", true, false)
		if cam and "pitch" in mouse_look: mouse_look.pitch = cam.rotation.x
		mouse_look.set_process(true)
		mouse_look.set_process_input(true)
	
	# Mở khóa điều khiển và cho phép kích hoạt lại sự kiện
	if _player.has_method("set_movement_enabled"):
		_player.set_movement_enabled(true)
	
	_is_triggered = false
	_state = "idle"
	_current_chase_dist = 0.0

func _disable_ghost_collision(node: Node):
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	
	if node is CollisionShape3D:
		node.disabled = true
		
	for child in node.get_children():
		_disable_ghost_collision(child)
