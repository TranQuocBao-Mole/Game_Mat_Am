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
	hide() # Ẩn đi khi vừa khởi tạo (do là Autoload)
	logic.reset_puzzle()
	_setup_ui()
	_update_status("Hãy cho các con chuột uống rượu để tìm ra bình độc...")

func _setup_ui():
	# Xóa placeholder nếu có
	for child in bottle_container.get_children(): child.queue_free()
	for child in rat_container.get_children(): child.queue_free()
	
	# Tạo 8 bình
	for i in range(8):
		var bottle_node = Control.new()
		bottle_node.custom_minimum_size = Vector2(100, 120)
		
		var tex = TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.texture = load("res://assets/textures/puzzles/poison/bottle.png")
		bottle_node.add_child(tex)
		
		var lbl = Label.new()
		lbl.text = str(i + 1)
		lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bottle_node.add_child(lbl)
		
		bottle_node.gui_input.connect(_on_bottle_gui_input.bind(i))
		bottle_container.add_child(bottle_node)
		
	# Tạo 3 con chuột
	for i in range(3):
		var rat_node = Control.new()
		rat_node.custom_minimum_size = Vector2(220, 220)
		
		var tex = TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.texture = load("res://assets/textures/puzzles/poison/rat.png")
		rat_node.add_child(tex)
		
		# Thêm hệ thống hạt độc (ẩn mặc định)
		var particles = CPUParticles2D.new()
		particles.name = "PoisonParticles"
		particles.emitting = false
		particles.amount = 30
		particles.lifetime = 1.0
		particles.spread = 180.0
		particles.gravity = Vector2(0, -50)
		particles.initial_velocity_min = 30.0
		particles.initial_velocity_max = 60.0
		particles.scale_amount_min = 3.0
		particles.scale_amount_max = 6.0
		particles.color = Color(0, 0.8, 0, 1) # Xanh lục
		particles.position = Vector2(110, 110) # Tâm của chuột 220x220
		rat_node.add_child(particles)
		
		var list_label = Label.new()
		list_label.name = "ListLabel"
		list_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		list_label.offset_top = -30
		list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_label.add_theme_font_size_override("font_size", 16)
		rat_node.add_child(list_label)
		
		rat_node.gui_input.connect(_on_rat_gui_input.bind(i))
		rat_container.add_child(rat_node)

func _on_bottle_gui_input(event: InputEvent, idx: int):
	if is_animating: return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Chuột trái: Chọn để thử nghiệm
			if game_phase == "TESTING":
				selected_bottle_idx = idx
				_update_status("Bình " + str(idx + 1) + " đã chọn. Hãy click vào chuột để cho uống.")
			elif game_phase == "ANSWERING":
				_check_final_answer(idx)
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Chuột phải: Chốt kết quả ngay lập tức (Đoán mò)
			_update_status("Bạn đã quyết định chốt Bình " + str(idx + 1) + " là bình độc...")
			await get_tree().create_timer(1.0).timeout
			# Nếu chưa thử độc thì coi như đã thử nhưng kết quả rỗng
			if not logic.test_performed:
				logic.test_performed = true
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
		rat_node.modulate = Color(0.3, 1, 0.3, 1) # Ám xanh
		# Kích hoạt hạt độc
		var p = rat_node.get_node("PoisonParticles")
		p.emitting = true
		
		# Thêm hiệu ứng rung cho chuột chết
		var shake = create_tween().set_loops(5)
		shake.tween_property(rat_node, "position", rat_node.position + Vector2(5, 0), 0.05)
		shake.tween_property(rat_node, "position", rat_node.position - Vector2(5, 0), 0.05)
	
	await get_tree().create_timer(1.0).timeout
	
	var fade_back = create_tween()
	fade_back.tween_property(flash, "color", Color(0, 0, 0, 0), 0.5)
	await fade_back.finished
	flash.queue_free()
	
	var possible = logic.get_possible_bottles()
	# Giữ lại print trong console cho Dev, nhưng không hiện lên UI
	print("[DEV ONLY] Các bình có thể là độc: ", possible.map(func(i): return i + 1))
	
	game_phase = "ANSWERING"
	is_animating = false
	_update_status("") # Xóa thông báo, để không gian tĩnh lặng đáng sợ

func _check_final_answer(idx: int):
	if logic.check_answer(idx):
		_on_win()
	else:
		_on_lose()

var shake_intensity = 0.0
var original_panel_pos = Vector2.ZERO

func _process(delta):
	if shake_intensity > 0.1:
		$Control/MainPanel.position = original_panel_pos + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
		shake_intensity = lerp(shake_intensity, 0.0, delta * 10.0)
	elif original_panel_pos != Vector2.ZERO:
		$Control/MainPanel.position = original_panel_pos

func _on_win():
	_update_status("CHÍNH XÁC! Bạn đã tìm ra bình độc.")
	await get_tree().create_timer(2.0).timeout
	puzzle_finished.emit(true)
	_close()

func _on_lose():
	_update_status("SAI RỒI! Hãy thử lại từ đầu...")
	
	# Hiệu ứng kịch tính: Rung màn hình
	shake_intensity = 30.0
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 0, 0, 0.4) # Đỏ cảnh báo
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color(1, 0, 0, 0), 1.0)
	await tween.finished
	flash.queue_free()
	
	await get_tree().create_timer(1.0).timeout
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
	# Cập nhật vị trí chuẩn ngay khi mở để làm mốc cho hiệu ứng rung
	await get_tree().process_frame
	original_panel_pos = $Control/MainPanel.position
	
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
