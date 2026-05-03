extends StaticBody3D

@export var prompt_text: String = "Xem tờ giấy"
@export var puzzle_ui_path: String = "res://src/ui/puzzles/candle_puzzle_ui.tscn"

func interact():
	if CandleManager:
		CandleManager.open_puzzle()
	else:
		printerr("CandleManager (Autoload) not found!")
