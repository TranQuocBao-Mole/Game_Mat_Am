extends Control

signal puzzle_finished(won: bool)

@onready var candle_container = find_child("CandleContainer")
@onready var status_label = find_child("StatusLabel")
var is_game_solved: bool = false

var logic = CandlePuzzleLogic.new()

# Cấu hình puzzle
const CANDLE_COUNT = 5
const CANDLE_SHEET_PATH = "res://assets/textures/puzzles/candle/ritual_candle_top_down_sheet_v2_1776367257619.png"
# Sheet 819x430: Frame Trái = Tắt (0,0,409,430) | Frame Phải = Sáng (410,0,409,430)
const FRAME_W = 409
const FRAME_H = 430



func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_puzzle()
	$CloseButton.focus_mode = Control.FOCUS_NONE
	hide()

func _setup_puzzle():
	logic.setup_puzzle(CANDLE_COUNT, []) 
	logic.puzzle_solved.connect(_on_puzzle_solved)
	
	for i in range(candle_container.get_child_count()):
		var candle_node = candle_container.get_child(i)
		# KHÔNG gán position bằng code — kéo thả trong Godot Editor!
		var btn = candle_node.get_node("Button")
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_candle_pressed.bind(i))
	
	_refresh_ui()

func _on_candle_pressed(index: int):
	if logic.is_solved(): return
	
	logic.toggle_candle(index)
	_refresh_ui()

func _refresh_ui():
	for i in range(CANDLE_COUNT):
		var candle_node = candle_container.get_child(i)
		var is_lit = logic.states[i]
		
		# Particles + Sprite kết hợp
		var flames = candle_node.get_node("Flames")
		flames.emitting = is_lit
		
		# Cắt Atlas đúng frame từ sheet 819x430
		var body = candle_node.get_node("Body")
		var tex = load(CANDLE_SHEET_PATH)
		if tex:
			var atlas = AtlasTexture.new()
			atlas.atlas = tex
			if is_lit:
				atlas.region = Rect2(410, 0, FRAME_W, FRAME_H) # Frame phải = Sáng
			else:
				atlas.region = Rect2(0, 0, FRAME_W, FRAME_H)  # Frame trái = Tắt
			body.texture = atlas
			body.modulate = Color(1, 1, 1, 1) # Hiển thị màu gốc của sprite, không tô màu

func _on_puzzle_solved():
	is_game_solved = true
	status_label.text = "PHONG ẤN ĐÃ MỞ! Hào quang quy tụ."
	status_label.modulate = Color(2.5, 2.0, 1.0)
	
	var tween = create_tween().set_parallel(true)
	for i in range(CANDLE_COUNT):
		var candle_node = candle_container.get_child(i)
		var body = candle_node.get_node("Body")
		tween.tween_property(body, "modulate", Color(3.0, 2.5, 1.5, 1.0), 1.5)
	
	await get_tree().create_timer(2.0).timeout
	puzzle_finished.emit(true)
	_on_close_pressed()

func open_puzzle():
	show()
	logic.reset_puzzle()
	_refresh_ui()
	status_label.text = "Thắp sáng Ngũ Chú để tìm đường thoát..."
	
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		p.set_movement_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close_pressed():
	hide()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players: p.set_movement_enabled(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	puzzle_finished.emit(false)
