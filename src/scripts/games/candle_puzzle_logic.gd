extends Node

class_name CandlePuzzleLogic

signal puzzle_solved

var candle_count: int = 5
var states: Array = []

var interaction_matrix = [
    [1, 0, 1, 1, 0], # Nhấn nến 0
    [0, 1, 0, 1, 1], # Nhấn nến 1
    [1, 1, 1, 0, 0], # Nhấn nến 2
    [0, 0, 1, 0, 1], # Nhấn nến 3
    [1, 0, 0, 1, 1] # Nhấn nến 4
]

func setup_puzzle(count: int, _unused: Array = []):
    candle_count = count
    states.resize(candle_count)
    reset_puzzle()

func toggle_candle(index: int) -> bool:
    if index < 0 or index >= candle_count:
        return false
        
    _apply_toggle_logic(index)
    
    if is_solved():
        puzzle_solved.emit()
    return true

func _apply_toggle_logic(index: int):
    var toggles = interaction_matrix[index]
    for i in range(candle_count):
        if toggles[i] == 1:
            _toggle_single_candle(i)

func _toggle_single_candle(i: int):
    if i >= 0 and i < candle_count:
        states[i] = !states[i]

func reset_puzzle():
    states = [true, false, false, false, true]
    
    if is_solved():
        states = [false, false, false, false, false]

func is_solved() -> bool:
    for s in states:
        if not s: return false
    return true
