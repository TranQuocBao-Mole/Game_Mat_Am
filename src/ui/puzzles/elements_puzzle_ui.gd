extends CanvasLayer

signal puzzle_finished(won: bool)

@onready var slots_container = find_child("Slots")
@onready var lines_container = find_child("Lines")
@onready var status_label = find_child("StatusLabel")
@onready var moves_label = find_child("MovesLabel")
@onready var sanity_bar = find_child("SanityBar")
@onready var main_panel = find_child("MainPanel")

var logic = ElementsPuzzleLogic.new()
var selected_slot: int = -1
var shake_intensity = 0.0
var original_panel_pos: Vector2 = Vector2.ZERO

# Asset Ngũ Ngọc
const ORBS_SHEET_PATH = "res://assets/textures/puzzles/elements/element_orbs_sheet_1776362934567.png"

# Màu sắc nguyên tố (Tự nhiên, không bị cháy sáng)
var element_colors = {
	ElementsPuzzleLogic.Element.METAL: Color(1.0, 1.0, 1.05),
	ElementsPuzzleLogic.Element.WATER: Color(0.8, 0.9, 1.1),
	ElementsPuzzleLogic.Element.WOOD: Color(0.9, 1.1, 0.9),
	ElementsPuzzleLogic.Element.FIRE: Color(1.1, 0.8, 0.8),
	ElementsPuzzleLogic.Element.EARTH: Color(1.1, 1.0, 0.8)
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	logic.setup_puzzle()
	
	logic.puzzle_solved.connect(_on_puzzle_solved)
	logic.conflict_occurred.connect(_on_conflict_occurred)
	logic.out_of_sanity.connect(_on_game_over)
	
	_setup_ui()
	hide()

func _process(_delta):
	if visible:
		# Đợi cho đến khi panel có kích thước và vị trí ổn định từ container
		if original_panel_pos == Vector2.ZERO and main_panel.position != Vector2.ZERO:
			original_panel_pos = main_panel.position
			
		# Hiệu ứng rung màn hình
		if shake_intensity > 0 and original_panel_pos != Vector2.ZERO:
			main_panel.position = original_panel_pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
			shake_intensity = lerp(shake_intensity, 0.0, 0.1)
		elif original_panel_pos != Vector2.ZERO:
			# Đảm bảo reset lại đúng vị trí trung tâm của container nếu không rung
			main_panel.position = original_panel_pos

func _setup_ui():
	# Sắp xếp các Slot theo vòng tròn
	var radius = 180.0 # Giảm bán kính một chút cho cân đối
	var center = Vector2(300, 300) 
	
	for i in range(5):
		var slot = slots_container.get_child(i)
		var angle = deg_to_rad(i * 72 - 90)
		slot.position = center + Vector2(cos(angle), sin(angle)) * radius - Vector2(50, 50)
		
		if not slot.pressed.is_connected(_on_slot_pressed):
			slot.pressed.connect(_on_slot_pressed.bind(i))
		slot.focus_mode = Control.FOCUS_NONE
		slot.pivot_offset = Vector2(50, 50)
	
	_refresh_ui()

func _on_slot_pressed(index: int):
	if selected_slot == -1:
		selected_slot = index
		_animate_selection(index, true)
	elif selected_slot == index:
		_animate_selection(index, false)
		selected_slot = -1
	else:
		var old_idx = selected_slot
		selected_slot = -1
		_animate_selection(old_idx, false)
		logic.swap_elements(old_idx, index)
		_animate_swap(old_idx, index)
		_refresh_ui()

func _refresh_ui():
	moves_label.text = "NGUYÊN KHÍ: " + str(logic.moves_left)
	sanity_bar.value = (float(logic.current_sanity) / logic.max_sanity) * 100.0
	
	for i in range(5):
		var slot = slots_container.get_child(i)
		var element = logic.slots[i]
		_style_slot(slot, element)
	
	_update_lines()

func _style_slot(slot: Button, element: int):
	if element == ElementsPuzzleLogic.Element.NONE:
		slot.icon = null
		return
		
	var tex = load(ORBS_SHEET_PATH)
	if tex:
		# Map vị trí trong ảnh (0: Kim, 1: Mộc, 2: Hỏa, 3: Thổ, 4: Thủy)
		var orb_order_map = {
			ElementsPuzzleLogic.Element.METAL: 0,
			ElementsPuzzleLogic.Element.WOOD: 1,
			ElementsPuzzleLogic.Element.FIRE: 2,
			ElementsPuzzleLogic.Element.EARTH: 3,
			ElementsPuzzleLogic.Element.WATER: 4
		}
		
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		var slice_h = tex.get_height() / 5.0
		var slice_w = tex.get_width()
		var vertical_idx = orb_order_map[element]
		atlas.region = Rect2(0, vertical_idx * slice_h, slice_w, slice_h)
		slot.icon = atlas
	
	slot.expand_icon = true
	slot.modulate = element_colors[element]
	slot.modulate.a = 0.9
	
	var sb = StyleBoxEmpty.new()
	slot.add_theme_stylebox_override("normal", sb)
	slot.add_theme_stylebox_override("hover", sb)
	slot.add_theme_stylebox_override("pressed", sb)

func _update_lines():
	for i in range(5):
		var line = lines_container.get_child(i)
		var e1 = logic.slots[i]
		var e2 = logic.slots[(i + 1) % 5]
		
		# Tẩy cấu trúc Line2D cũ để dùng Texture mới
		line.texture = load("res://assets/textures/puzzles/elements/asset_spiritual_cord.png")
		line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		
		var start_pos = slots_container.get_child(i).position + Vector2(50, 50)
		var end_pos = slots_container.get_child((i + 1) % 5).position + Vector2(50, 50)
		line.points = PackedVector2Array([start_pos, end_pos])
		
		var tween = create_tween()
		if logic.is_link_valid(e1, e2):
			line.width = 45 
			# Hiển thị đúng màu gốc của dây, không dùng hiệu ứng ánh sáng nhân tạo
			tween.tween_property(line, "default_color", Color(1, 1, 1, 1.0), 0.3)
		else:
			line.width = 15
			# Dây chưa kích hoạt sẽ mờ đi
			tween.tween_property(line, "default_color", Color(1, 1, 1, 0.15), 0.3)

func _animate_selection(index: int, is_selected: bool):
	var slot = slots_container.get_child(index)
	var tween = create_tween()
	if is_selected:
		tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.1)
		slot.modulate.a = 1.0
	else:
		tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1)
		slot.modulate.a = 0.9

func _animate_swap(_idx_a: int, _idx_b: int):
	var tween = create_tween()
	main_panel.modulate = Color(1.3, 1.3, 1.8)
	tween.tween_property(main_panel, "modulate", Color(1, 1, 1), 0.2)

func _on_conflict_occurred(_p1: int, _p2: int):
	shake_intensity = 20.0
	status_label.text = "!!! NĂNG LƯỢNG NGHỊCH LOẠN !!!"
	status_label.modulate = Color(2.5, 0.3, 0.3)
	
	var flash = create_tween()
	main_panel.self_modulate = Color(3.0, 0.5, 0.5)
	flash.tween_property(main_panel, "self_modulate", Color(1, 1, 1), 0.5)

func _on_puzzle_solved():
	status_label.text = "VẠN VẬT QUY NHẤT! PHONG ẤN ĐÃ MỞ."
	status_label.modulate = Color(2.0, 1.8, 0.5)
	
	var tween = create_tween().set_parallel(true)
	for i in range(5):
		var line = lines_container.get_child(i)
		tween.tween_property(line, "width", 30.0, 1.5)
		tween.tween_property(line, "default_color", Color(0.5, 3.0, 2.0, 1.0), 1.5)
	
	await get_tree().create_timer(2.0).timeout
	puzzle_finished.emit(true)
	_on_close_pressed()

func _on_game_over():
	status_label.text = "NGUYÊN THẦN TÁN LẠC!"
	status_label.modulate = Color.DARK_RED
	shake_intensity = 30.0
	await get_tree().create_timer(2.0).timeout
	open_puzzle()

func open_puzzle():
	show()
	original_panel_pos = Vector2.ZERO # Reset để lấy lại tọa độ chuẩn
	logic.setup_puzzle()
	_refresh_ui()
	status_label.text = "Hãy cân bằng Ngũ Hành..."
	status_label.modulate = Color(0.9, 0.8, 0.7)
	
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
