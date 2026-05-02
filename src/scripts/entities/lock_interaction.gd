extends StaticBody3D

@export var prompt_text: String = "Mở ổ khóa"
@export var combination_lock_scene: PackedScene
@export var door_node: Node3D # Kéo node DoorInteract vào đây

func _ready():
	# Tự động load scene nếu chưa gán trong Inspector
	if combination_lock_scene == null:
		combination_lock_scene = load("res://src/ui/puzzles/combination_lock_ui.tscn")

func interact():
	if combination_lock_scene:
		var puzzle_instance = combination_lock_scene.instantiate()
		
		# Bọc vào CanvasLayer để hiện trên cùng
		var cl = CanvasLayer.new()
		cl.layer = 100
		get_tree().root.add_child(cl)
		cl.add_child(puzzle_instance)
		
		# Mở puzzle
		if puzzle_instance.has_method("open_puzzle"):
			puzzle_instance.open_puzzle()
		
		# Kết nối tín hiệu khi hoàn thành
		puzzle_instance.puzzle_finished.connect(_on_puzzle_finished)
	else:
		print("[ERROR] combination_lock_scene not found!")

func _on_puzzle_finished(won: bool):
	if won:
		print("[Lock] Mở khóa thành công!")
		if door_node and door_node.has_method("interact"):
			door_node.is_locked = false
		
		# Thông báo cho người chơi
		if DialogueManager:
			DialogueManager.show_text("Tiếng 'Cạch' vang lên. Có vẻ cửa đã mở được rồi.")
			
		queue_free() # Xóa ổ khóa sau khi mở xong
