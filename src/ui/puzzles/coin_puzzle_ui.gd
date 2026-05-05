extends CanvasLayer

signal puzzle_finished(won: bool)

@onready var coin_pool = $Control/MainPanel/CoinPool/List
@onready var left_pan_container = $Control/MainPanel/Scale/Arm/LeftAnchor/LeftPan
@onready var right_pan_container = $Control/MainPanel/Scale/Arm/RightAnchor/RightPan
@onready var left_pan = $Control/MainPanel/Scale/Arm/LeftAnchor/LeftPan/List
@onready var right_pan = $Control/MainPanel/Scale/Arm/RightAnchor/RightPan/List
@onready var balance_arm = $Control/MainPanel/Scale/Arm
@onready var result_label = find_child("ResultLabel")
@onready var weigh_count_label = $Control/MainPanel/WeighCountLabel

# Bảng chọn Nặng/Nhẹ
@onready var choice_panel = $Control/MainPanel/ChoicePanel
@onready var heavy_btn = $Control/MainPanel/ChoicePanel/VBox/HeavyBtn
@onready var light_btn = $Control/MainPanel/ChoicePanel/VBox/LightBtn

var logic = CoinPuzzleLogic.new()
var is_animating = false
var selected_coin_node: TextureRect = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	logic.setup_puzzle()
	
	_setup_drop_zone($Control/MainPanel/CoinPool)
	_setup_drop_zone($Control/MainPanel/Scale/Arm/LeftAnchor/LeftPan)
	_setup_drop_zone($Control/MainPanel/Scale/Arm/RightAnchor/RightPan)
	
	# Connect Choice Buttons
	heavy_btn.pressed.connect(_on_choice_made.bind(true))
	light_btn.pressed.connect(_on_choice_made.bind(false))
	
	_setup_coins()
	hide()

func _process(_delta):
	if visible:
		# 1. Giữ đĩa cân luôn nằm ngang
		left_pan_container.rotation = -balance_arm.rotation
		right_pan_container.rotation = -balance_arm.rotation
		
		# 2. Tự động trả về thăng bằng nếu cả 2 bên đều trống
		if not is_animating and balance_arm.rotation_degrees != 0:
			var left_count = left_pan.get_children().filter(func(c): return c.has_meta("index")).size()
			var right_count = right_pan.get_children().filter(func(c): return c.has_meta("index")).size()
			if left_count == 0 and right_count == 0:
				var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(balance_arm, "rotation_degrees", 0.0, 0.5)

func _setup_drop_zone(node: Control):
	node.set_script(load("res://src/ui/puzzles/drop_zone.gd"))
	node.mouse_filter = Control.MOUSE_FILTER_PASS

func _setup_coins():
	for c in coin_pool.get_children():
		if c.has_meta("index"): c.queue_free()
	for c in left_pan.get_children():
		if c.has_meta("index"): c.queue_free()
	for c in right_pan.get_children():
		if c.has_meta("index"): c.queue_free()
	
	var coin_script = load("res://src/ui/puzzles/coin.gd")
	var coin_texture = load("res://assets/textures/puzzles/coin/coin_sprite.png")
	
	for i in range(7):
		var coin = TextureRect.new()
		coin.set_script(coin_script)
		coin.coin_index = i
		coin.custom_minimum_size = Vector2(80, 80)
		coin.texture = coin_texture
		coin.set_meta("index", i)
		
		var lbl = Label.new()
		lbl.text = str(i + 1)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		lbl.add_theme_color_override("font_color", Color(0.7, 0, 0, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0.2, 0, 0, 1))
		lbl.add_theme_constant_override("outline_size", 8)
		lbl.add_theme_font_size_override("font_size", 28)
		coin.add_child(lbl)
		
		coin_pool.add_child(coin)

func _on_weigh_pressed():
	if is_animating or logic.is_out_of_moves(): return
	
	var left_indices = []
	for c in left_pan.get_children():
		if c.has_meta("index"): left_indices.append(c.get_meta("index"))
	
	var right_indices = []
	for c in right_pan.get_children():
		if c.has_meta("index"): right_indices.append(c.get_meta("index"))
	
	if left_indices.size() != right_indices.size():
		result_label.text = "Số lượng xu hai bên phải bằng nhau!"
		return
	
	if left_indices.is_empty():
		return

	is_animating = true
	result_label.text = "Đang cân..."
	
	var res = logic.weigh(left_indices, right_indices)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var angle = 0.0
	if res == -1: angle = -15.0
	elif res == 1: angle = 15.0
	
	tween.tween_property(balance_arm, "rotation_degrees", angle, 1.2)
	
	await tween.finished
	is_animating = false
	weigh_count_label.text = "Số lần cân: " + str(logic.get_weigh_count()) + "/3"
	
	if res == 0: result_label.text = "Hai bên cân bằng."
	else: result_label.text = "Cân bị nghiêng."

func _guess_coin(coin_node):
	selected_coin_node = coin_node
	choice_panel.show()

func _on_choice_made(is_heavier_guess: bool):
	choice_panel.hide()
	var idx = selected_coin_node.get_meta("index")
	var current_weighs = logic.get_weigh_count()
	
	if current_weighs < 3:
		result_label.text = "Bạn chưa đủ bằng chứng! Hãy cân đủ 3 lần."
		_on_lose()
	else:
		if logic.check_guess(idx, is_heavier_guess):
			_on_win()
		else:
			_on_lose()

func _on_win():
	result_label.text = "CHÍNH XÁC! Bạn đã tìm ra đồng tiền linh hồn."
	result_label.modulate = Color.GOLD
	
	# Thưởng đồng xu cho người chơi
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].add_item("coin")
	
	await get_tree().create_timer(2.0).timeout
	puzzle_finished.emit(true)
	_close()

func _on_lose():
	result_label.text = "SAI RỒI! Linh hồn đang nổi giận..."
	result_label.modulate = Color.RED
	
	var main_panel = $Control/MainPanel
	var original_pos = main_panel.position
	var shake_tween = create_tween()
	for i in range(10):
		var shake_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		shake_tween.tween_property(main_panel, "position", original_pos + shake_offset, 0.05)
	shake_tween.tween_property(main_panel, "position", original_pos, 0.05)
	
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.8, 0, 0, 0.4)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.6)
	flash_tween.tween_callback(flash.queue_free)
	
	await get_tree().create_timer(1.2).timeout
	result_label.modulate = Color.WHITE
	open_puzzle()

func open_puzzle():
	show()
	logic.reset_puzzle()
	_setup_coins()
	choice_panel.hide()
	balance_arm.rotation_degrees = 0
	result_label.text = "Kéo xu lên cân (Chuột phải để chọn)"
	result_label.modulate = Color.WHITE
	weigh_count_label.text = "Số lần cân: 0/3"
	
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
