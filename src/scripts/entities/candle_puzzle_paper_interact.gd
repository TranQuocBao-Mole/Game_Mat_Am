extends StaticBody3D

@export var prompt_text: String = "Xem tờ giấy"
@export var puzzle_ui_path: String = "res://src/ui/puzzles/candle_puzzle_ui.tscn"

func interact():
	var puzzle_ui = get_tree().root.find_child("CandlePuzzleUI", true, false)
	if not puzzle_ui:
		var scene = load(puzzle_ui_path)
		if scene:
			puzzle_ui = scene.instantiate()
			get_tree().root.add_child(puzzle_ui)
	
	if puzzle_ui:
		puzzle_ui.open_puzzle()
		if not puzzle_ui.is_connected("puzzle_finished", _on_puzzle_finished):
			puzzle_ui.connect("puzzle_finished", _on_puzzle_finished)

func _on_puzzle_finished(won: bool):
	if won:
		GameState.is_candle_puzzle_solved = true
		print("DEBUG: Candle puzzle solved!")
