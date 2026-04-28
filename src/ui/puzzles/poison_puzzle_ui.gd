extends CanvasLayer

signal puzzle_finished(won: bool)

@onready var bottle_container = $Control/MainPanel/BottleContainer
@onready var rat_container = $Control/MainPanel/RatContainer
@onready var status_label = find_child("StatusLabel")
@onready var test_button = $Control/MainPanel/TestButton

var logic = PoisonPuzzleLogic.new()
var selected_bottle_idx: int = -1
var is_animating: bool = false
var game_phase: String = "TESTING" # TESTING, ANSWERING

func _ready():
	logic.reset_puzzle()
	_setup_ui()
	_update_status("Hãy cho các con chuột uống rượu để tìm ra bình độc...")

func _setup_ui():
	# Xóa placeholder nếu có
	for child in bottle_container.get_children(): child.queue_free()
	for child in rat_container.get_children(): child.queue_free()
	
	# Tạo 8 bình
	for i in range(8):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 120)
		btn.text = "Bình " + str(i + 1)
		btn.flat = true
		# Thêm TextureRect cho hình ảnh bình (sau này)
		var tex = TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.texture = load("res://assets/textures/puzzles/poison/ancient_poison_bottle_1777413655446.png")
		btn.add_child(tex)
		
		btn.pressed.connect(_on_bottle_pressed.bind(i))
		bottle_container.add_child(btn)
		
	# Tạo 3 con chuột
	for i in range(3):
		var rat_node = Control.new()
		rat_node.custom_minimum_size = Vector2(150, 150)
		
		var tex = TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.texture = load("res://assets/textures/puzzles/poison/creepy_rat_asset_1777413672563.png")
		rat_node.add_child(tex)
		
		var list_label = Label.new()
		list_label.name = "ListLabel"
		list_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		list_label.offset_top = -30
		list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_label.add_theme_font_size_override("font_size", 16)
		rat_node.add_child(list_label)
		
		rat_node.gui_input.connect(_on_rat_gui_input.bind(i))
		rat_container.add_child(rat_node)

func _on_bottle_pressed(idx: int):
	if is_animating: return
	if game_phase == "TESTING":
		selected_bottle_idx = idx
		_update_status("Bình " + str(idx + 1) + " đã chọn. Hãy click vào chuột để cho uống.")
	elif game_phase == "ANSWERING":
		_check_final_answer(idx)

func _on_rat_gui_input(event: InputEvent, rat_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game_phase == "TESTING" and selected_bottle_idx != -1:
			logic.add_drink(rat_idx, selected_bottle_idx)
			_update_rat_ui(rat_idx)
			selected_bottle_idx = -1
			_update_status("Đã cho chuột " + str(rat_idx + 1) + " uống. Tiếp tục với bình khác?")

func _update_rat_ui(rat_idx: int):
	var rat_node = rat_container.get_child(rat_idx)
	var label = rat_node.get_node("ListLabel")
	var drinks = logic.rats_drinking[rat_idx]
	var text = ""
	for d in drinks:
		text += str(d + 1) + " "
	label.text = text

func _on_test_pressed():
	if is_animating or game_phase != "TESTING": return
	is_animating = true
	test_button.disabled = true
	_update_status("Đang kiểm tra độc tính...")
	
	# Hiệu ứng kịch tính
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0, 0, 0, 0)
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(0, 0, 0, 0.8), 0.5)
	await tween.finished
	
	var dead_rats = logic.perform_test()
	for i in dead_rats:
		var rat_node = rat_container.get_child(i)
		rat_node.modulate = Color.RED
		# Thêm hiệu ứng rung cho chuột chết
		var shake = create_tween().set_loops(5)
		shake.tween_property(rat_node, "position", rat_node.position + Vector2(5, 0), 0.05)
		shake.tween_property(rat_node, "position", rat_node.position - Vector2(5, 0), 0.05)
	
	await get_tree().create_timer(1.0).timeout
	
	var fade_back = create_tween()
	fade_back.tween_property(flash, "color", Color(0, 0, 0, 0), 0.5)
	await fade_back.finished
	flash.queue_free()
	
	game_phase = "ANSWERING"
	is_animating = false
	_update_status("Một số con đã chết! Dựa vào đó, hãy chọn đúng bình chứa độc.")

func _check_final_answer(idx: int):
	if logic.check_answer(idx):
		_on_win()
	else:
		_on_lose()

func _on_win():
	_update_status("CHÍNH XÁC! Bạn đã tìm ra bình độc và sống sót.")
	await get_tree().create_timer(2.0).timeout
	puzzle_finished.emit(true)
	_close()

func _on_lose():
	_update_status("SAI RỒI! Bạn đã uống nhầm độc và tử vong...")
	# Hiệu ứng thua
	Input.vibrate_handheld(500)
	await get_tree().create_timer(2.0).timeout
	logic.reset_puzzle()
	game_phase = "TESTING"
	test_button.disabled = false
	_setup_ui()
	_update_status("Hãy thử lại từ đầu...")

func _update_status(msg: String):
	if status_label:
		status_label.text = msg

func open_puzzle():
	show()
	logic.reset_puzzle()
	game_phase = "TESTING"
	test_button.disabled = false
	_setup_ui()
	_update_status("Hãy cho các con chuột uống rượu để tìm ra bình độc...")
	
	var players = get_tree().get_nodes_in_group("player")
	for p in players: p.set_movement_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close_pressed():
	_close()
	puzzle_finished.emit(false)

func _close():
	hide()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		for p in players: p.set_movement_enabled(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
