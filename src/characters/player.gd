extends CharacterBody3D

# Movement constants
@export var WALK_SPEED = 150.0
const SPRINT_SPEED = 250.0
const SENSITIVITY = 0.002

# Realistic Bob Settings
@export var BOB_FREQ = 0.05
const BOB_AMP = 0.06
const BOB_SWAY = 0.03
const BOB_ROLL = 0.01
var t_bob = 0.0
# Zoom settings
const ZOOM_FOV = 5.0
const DEFAULT_FOV = 75.0
const ZOOM_SPEED = 15.0

@export_group("Audio")
@export var footstep_sound: AudioStream = preload("res://assets/audio/player/playerwalking.wav") ## Am thanh buoc chan (Da nap san)
@export var footstep_pitch_range: float = 0.1 ## Do bien thien am thanh

# Crouch Settings
@export var CROUCH_SPEED = 80.0 # Speed when crouching
const CROUCH_HEIGHT_OFFSET = -0.8 # Hạ thấp camera hơn nữa để cảm giác lén lút rõ rệt
const STANDING_HEIGHT_OFFSET = 0.0
const CROUCH_TRANSITION_SPEED = 3.0 # Smoothing speed

# Interaction settings
const INTERACT_RANGE = 150.5 # How far the ray reaches
# (Global InteractionManager handles interaction prompt)
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision_shape = $CollisionShape3D # Assuming the collision shape is a direct child
@onready var raycast = $Head/InteractionRay
var footstep_player: AudioStreamPlayer
var step_raycast: RayCast3D

# Step climbing settings
const STEP_HEIGHT = 0.4
const STEP_CHECK_DISTANCE = 0.3

var original_collision_height: float
var original_collision_position: Vector3
var target_crouch_offset = 0.0
var can_move := true
var initial_head_y: float
@onready var crouch_label: Label = null

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.near = 0.002
	initial_head_y = head.position.y
	
	# Tao nut Ctrl ảo xịn xò
	var ctrl_panel = Panel.new()
	ctrl_panel.name = "CtrlPanel"
	ctrl_panel.custom_minimum_size = Vector2(160, 40)
	
	crouch_label = Label.new()
	crouch_label.text = "CTRL: KHOM LƯNG"
	crouch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crouch_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crouch_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	ctrl_panel.add_child(crouch_label)
	ctrl_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 30)
	$HUD.add_child(ctrl_panel)
	
	# Nap Hotbar kieu Minecraft
	var hotbar_scene = preload("res://src/ui/hotbar.tscn")
	var hotbar = hotbar_scene.instantiate()
	$HUD.add_child(hotbar)

	# Setup step climbing raycast
	step_raycast = RayCast3D.new()
	add_child(step_raycast)
	step_raycast.enabled = true
	step_raycast.collision_mask = collision_layer

	# SETUP TU DONG TIENG BUOC CHAN (Cho nguoi luoi)
	if not has_node("FootstepPlayer"):
		footstep_player = AudioStreamPlayer.new()
		footstep_player.name = "FootstepPlayer"
		add_child(footstep_player)
	else:
		footstep_player = get_node("FootstepPlayer")
		
	# Nap am thanh tu o Export (Rat de keo tha/chinh sua trong Editor)
	if footstep_sound:
		footstep_player.stream = footstep_sound
		print("DEBUG: Da nạp am thanh buoc chân vao FootstepPlayer.")
	
	# Store original collision shape properties (assuming a CapsuleShape3D)
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		original_collision_height = collision_shape.shape.height
		original_collision_position = collision_shape.position
	
	# Setup interaction ray
	raycast.enabled = true
	
func _input(event):
	if event is InputEventMouseMotion:
		# Chỉ quay camera nếu đang chiếm quyền điều khiển chuột (CAPTURED) VÀ không bị khóa di chuyển
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and can_move:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_use_item()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_try_seed_mouse()
			
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			_use_item()

func _physics_process(delta: float) -> void:
	# 1. Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not can_move:
		move_and_slide()
		_handle_footsteps()
		InteractionManager.hide_prompt()
		return

	# 3. Crouch input & speed
	var is_crouching = Input.is_action_pressed("crouch")
	var is_running = Input.is_action_pressed("run") and not is_crouching
	var current_speed = CROUCH_SPEED if is_crouching else (SPRINT_SPEED if is_running else WALK_SPEED)

	# 4. Movement Input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction: Vector3 = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 5. Momentum / Air Control
	if is_on_floor():
		if direction != Vector3.ZERO:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	else:
		# Keep momentum in air
		if direction != Vector3.ZERO:
			velocity.x = lerp(velocity.x, direction.x * current_speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * current_speed, delta * 3.0)

	# 6. Crouch transition (head, collision, and mesh)
	target_crouch_offset = CROUCH_HEIGHT_OFFSET if is_crouching else STANDING_HEIGHT_OFFSET
	
	# Hien thi UI Khom lung (Hieu ung nhan nut)
	var ctrl_ui = $HUD/CtrlPanel
	if ctrl_ui:
		if is_crouching:
			ctrl_ui.modulate = Color(0.5, 1.0, 0.5)
			ctrl_ui.position.y = get_viewport().size.y - 65
		else:
			ctrl_ui.modulate = Color(1, 1, 1)
			ctrl_ui.position.y = get_viewport().size.y - 70
	
	# Smooth head movement (Camera)
	var target_head_pos = initial_head_y + target_crouch_offset
	head.position.y = lerp(head.position.y, target_head_pos, delta * CROUCH_TRANSITION_SPEED)
	
	# Co ngắn khối nhân vật trắng (Mesh) và vùng va chạm (Collision)
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var target_height = original_collision_height + target_crouch_offset
		collision_shape.shape.height = lerp(collision_shape.shape.height, target_height, delta * CROUCH_TRANSITION_SPEED)
		
		var target_pos_y = original_collision_position.y + (target_crouch_offset / 2.0)
		collision_shape.position.y = lerp(collision_shape.position.y, target_pos_y, delta * CROUCH_TRANSITION_SPEED)
		
		# Dong bo ca khoi Mesh trang cho khoi bi "ngo"
		if $MeshInstance3D:
			$MeshInstance3D.scale.y = collision_shape.shape.height / original_collision_height
			$MeshInstance3D.position.y = collision_shape.position.y

	# 7. Realistic Head Bob
	_handle_head_bob(delta, direction)

	# 7.5. Auto step climbing
	_handle_step_climbing(delta, direction)

	move_and_slide()

	# 8. Interaction
	_handle_interaction()
	_handle_zoom(delta)
	_handle_footsteps() # CAP NHAT TIENG BUOC CHAN
	
	raycast.global_transform = camera.global_transform
	raycast.target_position = Vector3(0, 0, -INTERACT_RANGE) # still local

func _handle_head_bob(delta: float, direction: Vector3) -> void:
	# Only bob if on floor and moving
	if is_on_floor() and direction != Vector3.ZERO:
		# Increase timer based on movement speed
		t_bob += delta * velocity.length()
		
		# Calculate Bobbing Position
		var target_pos = Vector3.ZERO
		target_pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
		target_pos.x = cos(t_bob * BOB_FREQ / 2) * BOB_SWAY
		
		# Apply Bobbing Position
		camera.transform.origin = camera.transform.origin.lerp(target_pos, delta * 10.0)
		
		# Apply Bobbing Tilt
		var target_tilt = sin(t_bob * BOB_FREQ / 2) * BOB_ROLL
		camera.rotation.z = lerp(camera.rotation.z, target_tilt, delta * 10.0)
	else:
		# Reset camera smoothly to zero when stopped or in air
		t_bob = 0.0
		camera.transform.origin = camera.transform.origin.lerp(Vector3.ZERO, delta * 5.0)
		camera.rotation.z = lerp(camera.rotation.z, 0.0, delta * 5.0)

func _handle_step_climbing(delta: float, direction: Vector3) -> void:
	if not is_on_floor() or direction == Vector3.ZERO:
		return

	# Check multiple points in front of player
	var forward = direction.normalized()
	var check_points = [
		forward * STEP_CHECK_DISTANCE,
		forward * STEP_CHECK_DISTANCE * 0.5,
	]

	for offset in check_points:
		step_raycast.global_position = global_position + Vector3(offset.x, 0, offset.z)
		step_raycast.target_position = Vector3(0, -STEP_HEIGHT - 0.1, 0)
		step_raycast.force_raycast_update()

		if step_raycast.is_colliding():
			var hit_pos = step_raycast.get_collision_point()
			var height_diff = global_position.y - hit_pos.y

			# If there's a step within STEP_HEIGHT, push player up
			if height_diff > 0.05 and height_diff < STEP_HEIGHT:
				var target_y = hit_pos.y + 0.1 # Small offset above surface
				global_position.y = lerp(global_position.y, target_y, delta * 10.0)
				break

func _handle_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		# Only show prompt if the object has an "interact" method
		if collider and collider.has_method("interact"):
			var text = "Tương tác"
			if "prompt_text" in collider:
				text = collider.prompt_text
			
			InteractionManager.set_prompt(text)
			
			if Input.is_action_just_pressed("interact"):
				collider.interact()
		else:
			InteractionManager.hide_prompt()
	else:
		InteractionManager.hide_prompt()

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector3.ZERO # Dừng ngay lập tức nếu bị khóa
		InteractionManager.hide_prompt()

func _handle_footsteps():
	if is_on_floor() and velocity.length() > 0.1:
		if footstep_player and not footstep_player.playing:
			footstep_player.play()
			# Thay đổi pitch nhẹ để nghe cho thật hơn (Dung thong so tu Editor)
			footstep_player.pitch_scale = randf_range(1.0 - footstep_pitch_range, 1.0 + footstep_pitch_range)
	else:
		if footstep_player and footstep_player.playing:
			footstep_player.stop()

func _handle_zoom(delta: float):
	var target_fov = ZOOM_FOV if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else DEFAULT_FOV
	camera.fov = lerp(camera.fov, target_fov, delta * ZOOM_SPEED)

# Minecraft-style Inventory Methods
func add_item(item_id: String, _count: int = 1, custom_name: String = ""):
	if item_id == "mouse":
		var mouse_item = ItemData.new()
		mouse_item.item_id = "mouse"
		mouse_item.item_name = custom_name if custom_name != "" else "Chuột"
		
		# Nạp icon thật vừa tạo
		var icon_path = "res://assets/textures/ui/rat_icon.png"
		if ResourceLoader.exists(icon_path):
			mouse_item.icon = load(icon_path)
		else:
			# Fallback nếu chưa nhận diện được file
			mouse_item.icon = PlaceholderTexture2D.new()
			mouse_item.icon.size = Vector2(32, 32)
		
		InventoryManager.add_item(mouse_item)
		print("DEBUG: Đã thêm ", mouse_item.item_name, " vào inventory với icon thật.")
	elif item_id == "poison_vase":
		var vase_item = ItemData.new()
		vase_item.item_id = "poison_vase"
		vase_item.item_name = custom_name if custom_name != "" else "Bình Thuốc Độc"
		
		# Nạp icon bình thuốc độc
		var icon_path = "res://assets/textures/ui/poison_vase_icon.png"
		if ResourceLoader.exists(icon_path):
			vase_item.icon = load(icon_path)
		else:
			vase_item.icon = PlaceholderTexture2D.new()
			vase_item.icon.size = Vector2(32, 32)
			
		InventoryManager.add_item(vase_item)
		print("DEBUG: Đã nhận được Bình Thuốc Độc!")
	else:
		print("Vật phẩm chưa xác định: ", item_id)

func get_item_count(item_id: String) -> int:
	var count = 0
	for item in InventoryManager.items:
		if item.item_id == item_id:
			count += 1
	return count

func _use_item():
	var hotbar = $HUD.get_node_or_null("Hotbar")
	if not hotbar: 
		print("Lỗi: Không tìm thấy Hotbar trên HUD!")
		return
	
	var selected_idx = hotbar.selected_slot
	var items = InventoryManager.items
	
	if selected_idx < items.size():
		var item = items[selected_idx]
		
		# Xử lý riêng cho Chuột theo yêu cầu
		if item.item_id == "mouse":
			if DialogueManager:
				DialogueManager.show_text("Đây là " + item.item_name + ", chắc hẳn có thể dùng làm gì đó.")
			return

		# Xử lý riêng cho tờ giấy cạnh nhà kho theo yêu cầu
		if "nhà kho" in item.item_name.to_lower():
			if DialogueManager:
				DialogueManager.show_text("Đây là tờ giấy cạnh nhà kho.")
				await DialogueManager.dialogue_finished
				DialogueManager.show_text("Trên đó viết số 5.")
			return

		if item.is_readable:
			if InspectManager:
				InspectManager.open(item.title, item.content)
			else:
				if DialogueManager:
					DialogueManager.show_text(item.content)
		else:
			if DialogueManager:
				DialogueManager.show_text("Vật phẩm này không thể đọc: " + item.item_name)
	else:
		if DialogueManager:
			DialogueManager.show_text("Ô đồ này đang trống!")

func _try_seed_mouse():
	var hotbar = $HUD.get_node_or_null("Hotbar")
	if not hotbar: return
	
	var selected_idx = hotbar.selected_slot
	var items = InventoryManager.items
	
	if selected_idx < items.size() and items[selected_idx].item_id == "mouse":
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider.has_method("add_mouse"):
				collider.add_mouse()
				InventoryManager.remove_item_at(selected_idx)
				print("DEBUG: Da nạp chuột vào bình từ ô số ", selected_idx + 1)
