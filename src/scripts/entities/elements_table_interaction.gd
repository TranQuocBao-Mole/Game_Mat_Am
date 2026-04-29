extends StaticBody3D

@export var prompt_text: String = "Sắp xếp Ngũ Hành"

var _connected := false
var _puzzle_solved := false

func interact():
	if _puzzle_solved:
		_show_reveal_dialogue()
		return
		
	if ElementsManager:
		if not _connected:
			ElementsManager.puzzle_finished.connect(_on_puzzle_done)
			_connected = true
		ElementsManager.open_puzzle()
	else:
		printerr("ElementsManager not found!")

func _on_puzzle_done(won: bool):
	if won:
		_puzzle_solved = true
		prompt_text = "Bàn Ngũ Hành (Đã hóa giải)"
		_show_reveal_dialogue()
		# Tự ngắt kết nối
		if _connected:
			ElementsManager.puzzle_finished.disconnect(_on_puzzle_done)
			_connected = false

func _show_reveal_dialogue():
	if DialogueManager:
		DialogueManager.show_text("Trận đồ đã được hóa giải. Một dải sáng mờ hiện lên trên mặt bàn...")
		DialogueManager.show_text("Có một con số 9 được khắc rất sâu ngay tại tâm của trận đồ.")
		DialogueManager.show_text("Tại sao lại là số 9 nhỉ? Có lẽ nó liên quan đến chiếc radio chăng?")
