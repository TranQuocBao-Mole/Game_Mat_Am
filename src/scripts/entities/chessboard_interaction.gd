extends StaticBody3D

@export var prompt_text: String = "Giải cờ tướng"
@export var tint_color: Color = Color(0.7, 0.6, 0.4, 1)
@export var is_active: bool = true : set = _set_active

# Ghi nhớ layer ban đầu từ Editor
@onready var _original_layer = collision_layer
@export var chess_puzzle_scene: PackedScene

func _ready():
	apply_tint()
	_update_state()
	
	# Tự động tìm file UI nếu chưa được gán trong Inspector
	if chess_puzzle_scene == null:
		var path = "res://src/ui/puzzles/chess_puzzle_ui.tscn"
		if ResourceLoader.exists(path):
			chess_puzzle_scene = load(path)
	
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

func interact() -> void:
	if not ChessManager:
		print("[ERROR] ChessManager not found!")
		return
		
	# 1. Nếu đã giải xong, chỉ hiện lời thoại thắc mắc
	if ChessManager.is_game_solved:
		if DialogueManager:
			DialogueManager.show_text("Một bàn cờ tướng")
		return
		
	# 2. Nếu chưa giải, mở UI giải đố cờ
	if chess_puzzle_scene:
		var puzzle_instance = chess_puzzle_scene.instantiate()
		
		# Đảm bảo UI hiện lên trên cùng bằng cách bọc vào CanvasLayer nếu nó chưa phải là CanvasLayer
		if not puzzle_instance is CanvasLayer:
			var cl = CanvasLayer.new()
			cl.layer = 5 # Giảm xuống để Dialogue (thường ở layer cao hơn) có thể hiện đè lên
			get_tree().root.add_child(cl)
			cl.add_child(puzzle_instance)
		else:
			get_tree().root.add_child(puzzle_instance)
			
		# Gọi hàm bắt đầu game đã tìm thấy trong chess_puzzle_ui.gd
		if puzzle_instance.has_method("start_game"):
			puzzle_instance.start_game()
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		print("[ERROR] chess_puzzle_scene not found!")
