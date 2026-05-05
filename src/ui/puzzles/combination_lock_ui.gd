extends CanvasLayer

signal puzzle_finished(won: bool)

@onready var digit_labels = [
	$Control/MainPanel/Digits/Digit1/Label,
	$Control/MainPanel/Digits/Digit2/Label,
	$Control/MainPanel/Digits/Digit3/Label,
	$Control/MainPanel/Digits/Digit4/Label,
	$Control/MainPanel/Digits/Digit5/Label
]

@onready var result_label = $Control/MainPanel/ResultLabel
@onready var main_panel = $Control/MainPanel

var current_values = [0, 0, 0, 0, 0]
var target_code = [9, 7, 5, 2, 9]
var is_locked = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_display()
	result_label.text = "Nhập mã số từ các manh mối (Lịch, Cờ, Nến, Ngũ Hành)"
	hide()

func open_puzzle():
	show()
	is_locked = false
	result_label.text = "Nhập mã số từ các manh mối..."
	result_label.modulate = Color.WHITE
	
	var players = get_tree().get_nodes_in_group("player")
	for p in players: p.set_movement_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _update_display():
	for i in range(5):
		digit_labels[i].text = str(current_values[i])

func _change_digit(index: int, delta: int):
	if is_locked: return
	
	current_values[index] = (current_values[index] + delta + 10) % 10
	_update_display()
	
	# Subtle scale effect on click
	var label = digit_labels[index]
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.05)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_digit_up(index: int):
	_change_digit(index, 1)

func _on_digit_down(index: int):
	_change_digit(index, -1)

func _on_unlock_pressed():
	if is_locked: return
	
	var is_correct = true
	for i in range(5):
		if current_values[i] != target_code[i]:
			is_correct = false
			break
	
	if is_correct:
		# KIỂM TRA MANH MỐI
		var clues_ok = true
		var missing_clues = []
		
		var chess_ok = GameState.is_chess_puzzle_solved
		var candle_ok = GameState.is_candle_puzzle_solved
		var elements_ok = GameState.is_elements_puzzle_solved
		
		print("[DEBUG] Trạng thái các trò chơi (từ GameState):")
		print(" - Cờ tướng: ", chess_ok)
		print(" - Xếp nến: ", candle_ok)
		print(" - Ngũ hành: ", elements_ok)
		
		if not chess_ok:
			clues_ok = false
			missing_clues.append("Cờ tướng")
		if not candle_ok:
			clues_ok = false
			missing_clues.append("Xếp nến")
		if not elements_ok:
			clues_ok = false
			missing_clues.append("Ngũ hành")
		
		if clues_ok:
			_on_win()
		else:
			_on_lose("BẠN CHƯA CÓ ĐỦ MANH MỐI...")
	else:
		_on_lose()

func _on_win():
	is_locked = true
	result_label.text = "Ổ KHÓA ĐÃ MỞ!"
	result_label.modulate = Color.GOLD
	GameState.lock_opened = true
	print("[DEBUG] Ổ KHÓA ĐÃ MỞ! Đã set GameState.lock_opened = true")
	
	# Gold glow effect
	var tween = create_tween().set_parallel(true)
	for label in digit_labels:
		tween.tween_property(label, "modulate", Color.GOLD, 0.5)
	
	await get_tree().create_timer(1.5).timeout
	puzzle_finished.emit(true)
	_close()

func _on_lose(custom_msg: String = ""):
	if custom_msg != "":
		result_label.text = custom_msg
	else:
		result_label.text = "MÃ SỐ SAI RỒI..."
		
	result_label.modulate = Color.RED
	
	# Shake effect
	var original_pos = main_panel.position
	var shake_tween = create_tween()
	for i in range(10):
		var shake_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		shake_tween.tween_property(main_panel, "position", original_pos + shake_offset, 0.04)
	shake_tween.tween_property(main_panel, "position", original_pos, 0.04)
	
	# Flash red
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.8, 0, 0, 0.3)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	flash_tween.tween_callback(flash.queue_free)

func _on_close_pressed():
	puzzle_finished.emit(false)
	_close()

func _close():
	hide()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players: p.set_movement_enabled(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
