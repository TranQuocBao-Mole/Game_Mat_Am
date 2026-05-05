@tool
extends CharacterBody3D

enum State { WANDER, ALERT, FLEE, RETURN, CAUGHT }

@export_group("Debug")
@export var show_debug: bool = true:
	set(value):
		show_debug = value
		if is_inside_tree(): update_debug_circles()

@export_group("Identity")
@export var rat_name: String = "Chuột Lạ":
	set(value):
		rat_name = value
		if name_label: name_label.text = rat_name
@export var speed_walk: float = 40.0
@export var speed_run: float = 80.0
@export var wander_radius: float = 200.0:
	set(value):
		wander_radius = value
		if is_inside_tree(): update_debug_circles()
@export var wait_time: float = 2.0

@export_group("Detection")
@export var detection_range_normal: float = 80.0:
	set(value):
		detection_range_normal = value
		if is_inside_tree(): update_debug_circles()
@export var detection_range_crouch: float = 30.0:
	set(value):
		detection_range_crouch = value
		if is_inside_tree(): update_debug_circles()
@export var catch_range: float = 15.0:
	set(value):
		catch_range = value
		if is_inside_tree(): update_debug_circles()

@export var prompt_text: String = "Bắt (E)"
@export var is_active: bool = true

var current_state = State.WANDER
var target_position: Vector3
var wander_timer: float = 0.0
var initial_position: Vector3
var current_anim: String = ""
var anim_finish_callback: Callable
var time_since_player_seen: float = 0.0

@onready var anim: AnimationPlayer = null
@onready var player = null
var name_label: Label3D

func _ready():
	add_to_group("interactable")
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	initial_position = global_position
	update_debug_circles()
	
	if not Engine.is_editor_hint():
		anim = find_child("AnimationPlayer", true, false)
		if anim:
			anim.animation_finished.connect(_on_animation_finished)
		
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_tree().current_scene.find_child("player", true, false)
			
		pick_random_target()
	
	# Tao Label hien thi ten tren dau (Cho ca Editor va Game)
	name_label = Label3D.new()
	name_label.text = rat_name
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.double_sided = false
	name_label.no_depth_test = true # Nhìn xuyên tường giống Roblox
	name_label.pixel_size = 0.05 # Phong to chu (Vi map x20 rat rong)
	name_label.font_size = 64
	name_label.outline_size = 20
	name_label.outline_modulate = Color.BLACK
	name_label.modulate = Color.YELLOW # Chu mau vang cho noi bat
	name_label.top_level = true
	add_child(name_label)

func _on_animation_finished(anim_name: String):
	if anim_finish_callback.is_valid():
		anim_finish_callback.call()
		anim_finish_callback = Callable()

func update_debug_circles():
	if not is_inside_tree(): return
	# Don dep triet de moi vong tron cu (ke ca nhung vong bi loi)
	for child in get_children():
		if child is MeshInstance3D and ("DEBUG_CIRCLE" in child.name):
			child.free()
	
	if not show_debug: return
	
	var circles = [
		[wander_radius, Color(0, 0.5, 1, 0.4), "DEBUG_CIRCLE_WANDER"],
		[detection_range_normal, Color(1, 0.5, 0, 0.6), "DEBUG_CIRCLE_DETECT"],
		[detection_range_crouch, Color(1, 1, 0, 0.5), "DEBUG_CIRCLE_CROUCH"],
		[catch_range, Color(0, 1, 0, 0.6), "DEBUG_CIRCLE_CATCH"]
	]
	
	for data in circles:
		var circle = create_circle_mesh(data[0], data[1], data[2])
		add_child(circle)
		circle.global_position = global_position + Vector3(0, 5.0, 0)

func create_circle_mesh(radius: float, color: Color, node_name: String) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.top_level = true # Khong bi anh huong boi scale x20 cua chuot
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	mesh_instance.mesh = immediate_mesh
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	mesh_instance.material_override = material
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var steps = 64
	for i in range(steps + 1):
		var angle = i * TAU / steps
		var next_angle = (i + 1) * TAU / steps
		immediate_mesh.surface_add_vertex(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
		immediate_mesh.surface_add_vertex(Vector3(cos(next_angle) * radius, 0, sin(next_angle) * radius))
	immediate_mesh.surface_end()
	return mesh_instance

var is_transitioning: bool = false

func _process(_delta):
	# Luon cap nhat vi tri vong debug theo con chuot
	if show_debug:
		for child in get_children():
			if child is MeshInstance3D and ("DEBUG_CIRCLE" in child.name):
				child.global_position = global_position + Vector3(0, 5.0, 0)
				child.rotation = Vector3.ZERO
				child.scale = Vector3.ONE
	
	# Cap nhat vi tri Ten tren dau
	if name_label:
		name_label.global_position = global_position + Vector3(0, 10.0, 0)
		name_label.text = rat_name
		# Chỉ hiện tên khi đã mở khóa
		name_label.visible = GameState.is_rat_hunt_unlocked

func _physics_process(delta):
	if Engine.is_editor_hint() or current_state == State.CAUGHT or not player: return

	var dist_to_player = global_position.distance_to(player.global_position)
	
	# Cap nhat thoi gian tu lan cuoi thay nguoi choi
	if dist_to_player < detection_range_normal:
		time_since_player_seen = 0.0
	else:
		time_since_player_seen += delta
	
	# Neu qua 10s khong thay ai, quay ve nha
	if time_since_player_seen > 10.0 and current_state != State.RETURN and current_state != State.WANDER:
		change_state(State.RETURN)
	
	# Cập nhật chữ hiển thị tương tác dựa trên khoảng cách
	if not GameState.is_rat_hunt_unlocked:
		prompt_text = "???"
	elif dist_to_player <= catch_range:
		prompt_text = "Bắt " + rat_name + " (E)"
	else:
		prompt_text = "Quá xa để bắt " + rat_name
	var is_player_crouching = Input.is_action_pressed("crouch")
	var is_player_running = Input.is_action_pressed("run")
	
	var current_detection_range = detection_range_crouch if is_player_crouching else detection_range_normal
	if is_player_running: current_detection_range *= 1.5
	
	match current_state:
		State.WANDER:
			if dist_to_player < current_detection_range:
				if is_player_running or dist_to_player < current_detection_range * 0.7:
					change_state(State.FLEE)
				else:
					change_state(State.ALERT)
				return

			var dist_to_target = global_position.distance_to(target_position)
			if dist_to_target < 5.0:
				play_anim("Mammals|idle_A1")
				wander_timer += delta
				if wander_timer > wait_time:
					pick_random_target()
					wander_timer = 0.0
			else:
				play_anim("Mammals|walk_A1", 1.2) # Di tuan thong tha
				move_direct(target_position, speed_walk, delta)
				
		State.ALERT:
			play_anim("Mammals|idle_A3")
			look_at_node(player.global_position, delta)
			# Chỉ chạy khi thực sự gần (0.8) hoặc người chơi chạy nhanh
			if dist_to_player < (current_detection_range * 0.8) or is_player_running:
				change_state(State.FLEE)
			elif dist_to_player > current_detection_range * 1.5: # Vùng đệm rộng hơn để tránh giật
				change_state(State.WANDER)
				
		State.FLEE:
			var dynamic_anim_speed = (speed_run / speed_walk) * 0.3
			play_anim("Mammals|run_A1", dynamic_anim_speed) 
			
			# Tính toán hướng chạy trốn ổn định hơn
			var flee_dir = (global_position - player.global_position).normalized()
			# Giới hạn tốc độ thay đổi hướng để tránh giật (Sử dụng lerp cho hướng)
			var flee_target = global_position + flee_dir * 50.0
			
			# Gioi han khong cho chay qua xa nha (300m)
			if global_position.distance_to(initial_position) > 300.0:
				flee_target = initial_position
				
			move_direct(flee_target, speed_run, delta)
			
			# Chỉ ngừng chạy khi đã thực sự an toàn (Rất xa)
			if dist_to_player > (detection_range_normal * 2.0):
				change_state(State.WANDER)
				
		State.RETURN:
			play_anim("Mammals|run_A1", 1.5)
			move_direct(initial_position, speed_walk * 1.5, delta)
			if global_position.distance_to(initial_position) < 5.0:
				change_state(State.WANDER)
			
			# Nếu đang đi về mà lại thấy người chơi thì bỏ chạy tiếp
			if dist_to_player < current_detection_range:
				change_state(State.ALERT)

func play_anim(anim_name, custom_speed = 1.0):
	if current_anim == anim_name and not is_transitioning: 
		if anim: anim.speed_scale = custom_speed
		return
		
	if anim and anim.has_animation(anim_name):
		anim.play(anim_name)
		anim.speed_scale = custom_speed
		current_anim = anim_name

func change_state(new_state):
	if current_state == new_state: return
	
	# Chuyển đổi Animation mượt mà không chặn di chuyển
	if new_state == State.FLEE:
		play_anim("Mammals|run_start_A", 2.0)
	elif current_state == State.FLEE and new_state == State.WANDER:
		play_anim("Mammals|run_end_A", 1.5)
		
	current_state = new_state
	wander_timer = 0.0

func move_direct(target_pos, speed, delta):
	var dir = (target_pos - global_position).normalized()
	dir.y = 0
	global_position += dir * speed * delta
	
	if dir.length() > 0.01:
		var target_angle = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 10.0)

func pick_random_target():
	var random_offset = Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	target_position = initial_position + random_offset
	target_position.y = global_position.y

func look_at_node(target_pos, delta):
	var dir = (target_pos - global_position).normalized()
	dir.y = 0
	if dir.length() > 0.01:
		var target_angle = Vector2(dir.z, dir.x).angle()
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 4.0)

func _input(event):
	if Engine.is_editor_hint() or current_state == State.CAUGHT: return
	if not GameState.is_rat_hunt_unlocked: return # Chống "bắt trộm" khi chưa mở khóa
	
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if player and global_position.distance_to(player.global_position) <= catch_range:
			catch_rat()

func interact():
	if current_state == State.CAUGHT or not player: return
	if not GameState.is_rat_hunt_unlocked: 
		if get_tree().root.has_node("DialogueManager"):
			get_tree().root.get_node("DialogueManager").show_text("Bạn chưa biết cách bắt sinh vật này...")
		return
	
	if global_position.distance_to(player.global_position) <= catch_range:
		catch_rat()

func catch_rat():
	current_state = State.CAUGHT
	
	if get_tree().root.has_node("DialogueManager"):
		get_tree().root.get_node("DialogueManager").show_text("Bạn đã bắt được " + rat_name + "!")
	
	if player and player.has_method("add_item"):
		player.add_item("mouse", 1, rat_name)
	elif player and "mice_count" in player:
		player.mice_count += 1
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	await tween.finished
	queue_free()
