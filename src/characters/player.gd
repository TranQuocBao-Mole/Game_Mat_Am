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
var rat_mute_hint: Label = null


func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.near = 0.002
	initial_head_y = head.position.y
	
	# --- Controls HUD Setup ---
	var controls_container = VBoxContainer.new()
	controls_container.name = "ControlsHUD"
	controls_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Căn lề góc phải, thụt vào 20px
	controls_container.offset_left = -220
	controls_container.offset_top = -220
	controls_container.offset_right = -20
	controls_container.offset_bottom = -20
	controls_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_container.alignment = BoxContainer.ALIGNMENT_END
	$HUD.add_child(controls_container)
	
	# Helper function để tạo dòng phím tắt
	var create_hint = func(key_str: String, action_str: String):
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_END
		hbox.add_theme_constant_override("separation", 15) # Tăng khoảng cách
		
		# Khung phím bấm
		var key_panel = PanelContainer.new()
		var key_style = StyleBoxFlat.new()
		key_style.bg_color = Color(0, 0, 0, 0.7)
		key_style.set_border_width_all(1)
		key_style.border_color = Color(1, 1, 1, 0.9)
		key_style.set_corner_radius_all(4)
		key_panel.add_theme_stylebox_override("panel", key_style)
		
		var key_lbl = Label.new()
		key_lbl.text = " " + key_str + " "
		key_lbl.add_theme_font_size_override("font_size", 14) # To hơn tí
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_panel.add_child(key_lbl)
		
		# Nhãn hành động
		var action_lbl = Label.new()
		action_lbl.text = action_str
		action_lbl.add_theme_font_size_override("font_size", 15) # To hơn tí
		action_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		action_lbl.add_theme_constant_override("outline_size", 5)
		
		hbox.add_child(action_lbl)
		hbox.add_child(key_panel)
		return hbox
	
	# Thêm các phím vào danh sách (Cập nhật phím theo ý bạn)
	controls_container.add_child(create_hint.call("W A S D", "DI CHUYỂN"))
	controls_container.add_child(create_hint.call("SHIFT", "CHẠY"))
	
	# Lưu lại nút Ctrl để hiệu ứng đổi màu còn hoạt động
	var ctrl_hint = create_hint.call("CTRL", "KHOM LƯNG")
	controls_container.add_child(ctrl_hint)
	crouch_label = ctrl_hint.get_child(1).get_child(0)
	
	controls_container.add_child(create_hint.call("E", "TƯƠNG TÁC"))
	controls_container.add_child(create_hint.call("F", "XEM CHI TIẾT")) # Đổi Chuột Phải thành F
	
	# Nap Hotbar kieu Minecraft
	var hotbar_scene = preload("res://src/ui/hotbar.tscn")
	var hotbar = hotbar_scene.instantiate()
	$HUD.add_child(hotbar)
	
	# Thêm gợi ý tắt nhạc chuột (K)
	rat_mute_hint = Label.new()
	rat_mute_hint.text = "Nhấn K để tắt nhạc"
	rat_mute_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rat_mute_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rat_mute_hint.offset_left = -250
	rat_mute_hint.offset_top = 20
	rat_mute_hint.add_theme_font_size_override("font_size", 16)
	rat_mute_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	rat_mute_hint.add_theme_constant_override("shadow_outline_size", 5)
	rat_mute_hint.visible = false
	$HUD.add_child(rat_mute_hint)


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
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_seed_mouse()
			
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			_use_item()
		elif event.keycode == KEY_ALT:
			print("--- PLAYER DEBUG INFO ---")
			print("Position: Vector3", global_position)
			print("Rotation: Vector3", rotation_degrees)
			print("Head Rotation: Vector3", head.rotation_degrees)
			print("-------------------------")
		elif event.keycode == KEY_K:
			GameState.rat_singing_enabled = !GameState.rat_singing_enabled



var _interaction_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _interaction_timer > 0:
		_interaction_timer -= delta

	# 1. Gravity & Movement logic...
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# 2. Interaction (Luôn cho phép tương tác kể cả khi bị khóa di chuyển)
	_handle_interaction()
	
	if not can_move:
		move_and_slide()
		_handle_footsteps()
		return
		
	# 3. Zoom (Chỉ khi có quyền di chuyển mới cho zoom thủ công)
	_handle_zoom(delta)

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
	if crouch_label:
		var key_panel = crouch_label.get_parent()
		if is_crouching:
			key_panel.modulate = Color(0.5, 1.0, 0.5)
		else:
			key_panel.modulate = Color(1, 1, 1)
	
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

	# Các hàm này đã được chuyển lên trên để ưu tiên
	_handle_footsteps() # CAP NHAT TIENG BUOC CHAN
	
	raycast.global_transform = camera.global_transform
	raycast.target_position = Vector3(0, 0, -INTERACT_RANGE) # still local
	
	# Cập nhật hiển thị gợi ý tắt nhạc chuột
	if rat_mute_hint:
		rat_mute_hint.visible = GameState.singing_rats_count > 0 and GameState.rat_singing_enabled


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
	# Không hiển thị nút tương tác và không cho tương tác khi đang mở UI (chuột hiện)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		InteractionManager.hide_prompt()
		return
		
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		# Only show prompt if the object has an "interact" method
		if collider and collider.has_method("interact"):
			var text = "Tương tác"
			if "prompt_text" in collider:
				text = collider.prompt_text
			
			InteractionManager.set_prompt(text)
			
			if Input.is_action_just_pressed("interact") and _interaction_timer <= 0:
				collider.interact()
				_interaction_timer = 0.2
		else:
			InteractionManager.hide_prompt()
	else:
		InteractionManager.hide_prompt()

func set_movement_enabled(enabled: bool) -> void:
	can_move = enabled
	if not enabled:
		velocity = Vector3.ZERO # Dừng ngay lập tức nếu bị khóa
		InteractionManager.hide_prompt()

var _can_play_step: bool = true

func _handle_footsteps():
	if is_on_floor() and velocity.length() > 0.1:
		var bob_step = sin(t_bob * BOB_FREQ)
		
		# Phát âm thanh khi đạt đến đỉnh (>0.85) hoặc đáy (<-0.85)
		if abs(bob_step) > 0.85:
			if _can_play_step:
				footstep_player.pitch_scale = randf_range(1.0 - footstep_pitch_range, 1.0 + footstep_pitch_range)
				if Input.is_action_pressed("run"):
					footstep_player.pitch_scale += 0.1
				
				footstep_player.play()
				_can_play_step = false 
		else:
			_can_play_step = true 
	else:
		_can_play_step = true
		if footstep_player.playing:
			footstep_player.stop() # Dừng ngay lập tức khi đứng yên

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
	elif item_id == "coin":
		var coin_item = ItemData.new()
		coin_item.item_id = "coin"
		coin_item.item_name = custom_name if custom_name != "" else "Đồng Tiền Linh Hồn"
		
		var icon_path = "res://assets/textures/ui/coin.png"
		if ResourceLoader.exists(icon_path):
			coin_item.icon = load(icon_path)
		else:
			coin_item.icon = PlaceholderTexture2D.new()
			coin_item.icon.size = Vector2(32, 32)
			
		InventoryManager.add_item(coin_item)
		print("DEBUG: Đã nhận được Đồng Tiền Linh Hồn!")
	elif item_id == "red_paint_bottle":
		var paint_item = ItemData.new()
		paint_item.item_id = "red_paint_bottle"
		paint_item.item_name = custom_name if custom_name != "" else "Bình Sơn Đỏ"
		
		# Nạp icon bình sơn đỏ
		var icon_path = "res://assets/textures/ui/red_paint_bottle.png"
		if ResourceLoader.exists(icon_path):
			paint_item.icon = load(icon_path)
		else:
			paint_item.icon = PlaceholderTexture2D.new()
			paint_item.icon.size = Vector2(32, 32)
			
		InventoryManager.add_item(paint_item)
		print("DEBUG: Đã nhận được Bình Sơn Đỏ!")
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
