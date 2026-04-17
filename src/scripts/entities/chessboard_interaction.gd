extends StaticBody3D

@export var prompt_text: String = "Giải cờ tướng"
@export var tint_color: Color = Color(0.7, 0.6, 0.4, 1)
@export var is_active: bool = true : set = _set_active

# Ghi nhớ layer ban đầu từ Editor
@onready var _original_layer = collision_layer

func _ready():
	apply_tint()
	_update_state()
	if ChessManager:
		if ChessManager.is_game_solved:
			prompt_text = "Xem bàn cờ"
		ChessManager.game_finished.connect(func(won): if won: prompt_text = "Xem bàn cờ")

func _set_active(value: bool) -> void:
	is_active = value
	if is_node_ready():
		_update_state()

func _update_state() -> void:
	visible = is_active
	# Tắt va chạm ở lớp vật lý (Layer) để RayCast đi xuyên qua
	collision_layer = _original_layer if is_active else 0

	# Tìm và tắt vùng va chạm (CollisionShape)
	var shapes = find_children("*", "CollisionShape3D", true, false)
	for shape in shapes:
		shape.set_deferred("disabled", !is_active)

func apply_tint():
	_tint_recursive(self)

func _tint_recursive(node: Node):
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_surface_override_material(i)
			if mat:
				var new_mat = mat.duplicate()
				if "albedo_color" in new_mat:
					new_mat.albedo_color = tint_color
				node.set_surface_override_material(i, new_mat)
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.get_surface_override_material(i)
				if not mat: mat = node.mesh.surface_get_material(i)
				if mat:
					var new_mat = mat.duplicate()
					if "albedo_color" in new_mat: new_mat.albedo_color = tint_color
					node.set_surface_override_material(i, new_mat)
	for child in node.get_children():
		_tint_recursive(child)

func interact():
	if ChessManager:
		# Nếu đã giải xong, chỉ hiện lời thoại thắc mắc
		if ChessManager.is_game_solved:
			prompt_text = "Xem bàn cờ"
			if DialogueManager:
				DialogueManager.show_text("Một bàn cờ tướng")
			return
			
		# Khóa di chuyển của người chơi
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			players[0].set_movement_enabled(false)
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		ChessManager.start_game()
	else:
		print("ChessManager not found!")
