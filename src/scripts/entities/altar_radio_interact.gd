extends StaticBody3D

@export var prompt_text: String = "Tương tác với Radio"

func interact():
	if not GameState.is_candle_puzzle_solved:
		DialogueManager.show_text("một chiếc radio cũ. Không biết nó còn sử dụng được không?")
	else:
		print("444")
