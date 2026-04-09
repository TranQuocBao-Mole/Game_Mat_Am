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

@export_group("Audio")
@export var footstep_sound: AudioStream = preload("res://assets/audio/player/playerwalking.wav") ## Am thanh buoc chan (Da nap san)
@export var footstep_pitch_range: float = 0.1 ## Do bien thien am thanh

# Crouch Settings
@export var CROUCH_SPEED = 80.0               # Speed when crouching
const CROUCH_HEIGHT_OFFSET = -0.5       # How much to lower head (negative)
const STANDING_HEIGHT_OFFSET = 0.0
const CROUCH_TRANSITION_SPEED = 3.0     # Smoothing speed

# Interaction settings
const INTERACT_RANGE = 150.5               # How far the ray reaches
# (Global InteractionManager handles interaction prompt)
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision_shape = $CollisionShape3D   # Assuming the collision shape is a direct child
@onready var raycast = $Head/InteractionRay
var footstep_player: AudioStreamPlayer

var original_collision_height: float
var original_collision_position: Vector3
var target_crouch_offset = 0.0
var can_move := true
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
		# Chỉ quay camera nếu đang chiếm quyền điều khiển chuột (CAPTURED)
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			head.rotate_y(-event.relative.x * SENSITIVITY)
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# 1. Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if not can_move:
		# Still apply gravity? Usually yes, but you might also want to freeze the player completely.
		# Option 1: Skip movement entirely (player stays in place)
		move_and_slide()   # Keep gravity active
		_handle_footsteps() # CHAY TIENG BUOC CHAN KHI EVENT EP DI CHUYEN
		return
	# 3. Crouch input & speed
	var is_crouching = Input.is_action_pressed("crouch")
	var is_running = Input.is_action_pressed("run") and not is_crouching  # can't sprint while crouching
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

	# 6. Crouch transition (head and collision shape)
	target_crouch_offset = CROUCH_HEIGHT_OFFSET if is_crouching else STANDING_HEIGHT_OFFSET
	
	# Smooth head movement
	head.position.y = lerp(head.position.y, target_crouch_offset, delta * CROUCH_TRANSITION_SPEED)
	
	# Adjust collision shape (if it's a capsule)
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		# Height: standing_height + 2 * offset (since offset is negative, this reduces height)
		var target_height = original_collision_height + 2.0 * target_crouch_offset
		collision_shape.shape.height = lerp(collision_shape.shape.height, target_height, delta * CROUCH_TRANSITION_SPEED)
		
		# Position: move down by the offset to keep feet on the ground
		var target_pos_y = original_collision_position.y + target_crouch_offset
		collision_shape.position.y = lerp(collision_shape.position.y, target_pos_y, delta * CROUCH_TRANSITION_SPEED)

	# 7. Realistic Head Bob
	_handle_head_bob(delta, direction)

	move_and_slide()

	# 8. Interaction
	_handle_interaction()
	_handle_footsteps() # CAP NHAT TIENG BUOC CHAN
	
	raycast.global_transform = camera.global_transform
	raycast.target_position = Vector3(0, 0, -INTERACT_RANGE)  # still local

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

func _handle_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		# Only show prompt if the object has an "interact" method
		if collider.has_method("interact"):
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

func _handle_footsteps():
	if is_on_floor() and velocity.length() > 0.1:
		if footstep_player and not footstep_player.playing:
			footstep_player.play()
			# Thay đổi pitch nhẹ để nghe cho thật hơn (Dung thong so tu Editor)
			footstep_player.pitch_scale = randf_range(1.0 - footstep_pitch_range, 1.0 + footstep_pitch_range)
	else:
		if footstep_player and footstep_player.playing:
			footstep_player.stop()
