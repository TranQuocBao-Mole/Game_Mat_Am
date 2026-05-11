extends StaticBody3D

@export var prompt_text: String = "Tương tác"

func _ready():
	if InkManager:
		InkManager.puzzle_finished.connect(_on_puzzle_finished)

func _on_puzzle_finished(won: bool):
	if won:
		GameState.is_ink_puzzle_solved = true
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_item"):
			player.add_item("red_paint_bottle", 1, "Bình Sơn Đỏ")
			if DialogueManager:
				DialogueManager.show_text("Bạn đã nhận được bình sơn màu đỏ.")
				await DialogueManager.dialogue_finished
				DialogueManager.show_text("Chắc hẳn nó cần để làm gì đó.")
			
			# Trả lại quyền di chuyển và con trỏ chuột cho người chơi
			if player.has_method("set_movement_enabled"):
				player.set_movement_enabled(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func interact():
	if GameState.is_ink_puzzle_solved:
		if DialogueManager:
			DialogueManager.show_text("Ở đây có 6 hộp sơn.")
		return

	if InkManager:
		InkManager.open_puzzle()
		print("[DEBUG] Đang mở Mini-game Pha sơn...")
	else:
		print("[ERROR] Không tìm thấy InkManager!")
