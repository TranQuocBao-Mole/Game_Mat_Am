extends CanvasLayer

signal puzzle_finished(won: bool)

@onready var draw_area = $Control/Paper/DrawArea
@onready var current_line = $Control/Paper/DrawArea/CurrentLine
@onready var finished_lines_root = $Control/Paper/DrawArea/FinishedLines
@onready var hint_lines_root = $Control/Paper/DrawArea/HintLines
@onready var nodes_root = $Control/Paper/DrawArea/Nodes
@onready var status_label = find_child("StatusLabel")

var logic = TalismanPuzzleLogic.new()
var is_drawing = false
var last_node_idx: int = -1

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	logic.setup_puzzle()
	logic.puzzle_solved.connect(_on_win)
	logic.puzzle_reset.connect(_clear_lines)
	
	_setup_ui_elements()
	hide()

func _setup_ui_elements():
	# Xóa cũ
	for c in nodes_root.get_children(): c.queue_free()
	for c in hint_lines_root.get_children(): c.queue_free()
	
	_create_ui_nodes()
	_draw_hint_lines()

func _create_ui_nodes():
	var node_tex = load("res://assets/textures/puzzles/talisman/talisman_node.png")
	var area_center = draw_area.size / 2
	
	for i in range(logic.nodes.size()):
		var pos = logic.nodes[i] + area_center
		var sprite = TextureRect.new()
		sprite.texture = node_tex
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.custom_minimum_size = Vector2(80, 80) # Chỉnh lại size cho cân đối 7 nút
		sprite.position = pos - Vector2(40, 40)
		sprite.modulate = Color(0.3, 0, 0, 0.7)
		sprite.name = "Node_" + str(i)
		nodes_root.add_child(sprite)

func _draw_hint_lines():
	var area_center = draw_area.size / 2
	for edge in logic.edges:
		var line = Line2D.new()
		line.width = 4.0
		# Tăng độ đậm lên 0.7 và dùng màu nâu đen sẫm
		line.default_color = Color(0.1, 0.05, 0.02, 0.7)
		line.points = PackedVector2Array([
			logic.nodes[edge.from] + area_center,
			logic.nodes[edge.to] + area_center
		])
		hint_lines_root.add_child(line)
	
	# Thêm hiệu ứng nhấp nháy nhẹ cho toàn bộ sơ đồ khi bắt đầu
	var tween = create_tween().set_loops(3)
	tween.tween_property(hint_lines_root, "modulate:a", 1.0, 0.5)
	tween.tween_property(hint_lines_root, "modulate:a", 0.4, 0.5)

func _input(event):
	if not visible: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drawing()
			else:
				_stop_drawing()
				
	if event is InputEventMouseMotion:
		if is_drawing:
			_update_drawing(event.position)
		else:
			# Hiệu ứng hover khi chưa vẽ
			var local_pos = draw_area.get_local_mouse_position()
			var nearest_idx = _get_nearest_node(local_pos)
			for i in range(logic.nodes.size()):
				_highlight_node(i, i == nearest_idx)

func _start_drawing():
	var mouse_pos = draw_area.get_local_mouse_position()
	var nearest_idx = _get_nearest_node(mouse_pos)
	
	if nearest_idx != -1:
		is_drawing = true
		last_node_idx = nearest_idx
		logic.current_node_idx = nearest_idx
		current_line.clear_points()
		current_line.add_point(logic.nodes[nearest_idx] + draw_area.size / 2)
		_highlight_node(nearest_idx, true)

func _update_drawing(global_mouse_pos):
	var local_pos = draw_area.get_local_mouse_position()
	
	# Luôn cập nhật điểm cuối của nét vẽ theo chuột
	if current_line.points.size() > 1:
		current_line.set_point_position(current_line.points.size() - 1, local_pos)
	else:
		current_line.add_point(local_pos)
		
	# Kiểm tra xem có chạm vào nút mới không
	var nearest_idx = _get_nearest_node(local_pos)
	if nearest_idx != -1 and nearest_idx != last_node_idx:
		if logic.try_move_to(nearest_idx):
			if last_node_idx != -1:
				_add_finished_line(last_node_idx, nearest_idx)
			
			last_node_idx = nearest_idx
			
			# Cập nhật số nét còn lại để người chơi biết
			var remain = logic.total_edges - logic.visited_edges_count
			status_label.text = "Linh khí còn thiếu: " + str(remain) + " nét..."
			status_label.modulate = Color(0.8, 0.2, 0.2, 1)
			
			# Reset nét vẽ tạm thời về điểm nút mới
			current_line.clear_points()
			current_line.add_point(logic.nodes[nearest_idx] + draw_area.size / 2)
			current_line.add_point(local_pos)
			_highlight_node(nearest_idx, true)
		else:
			# Di chuyển sai hoặc nhấc bút giữa chừng? 
			# Trong game này mình cho phép nhấc chuột nếu không nhỡ tay
			pass

func _stop_drawing():
	is_drawing = false
	current_line.clear_points()
	if not logic.is_solved():
		_on_lose()

func _get_nearest_node(local_pos: Vector2) -> int:
	var area_center = draw_area.size / 2
	var nearest_idx = -1
	var min_dist = 80.0 # Tăng độ nhạy bắt điểm lên gấp đôi
	
	for i in range(logic.nodes.size()):
		var node_pos = logic.nodes[i] + area_center
		var dist = local_pos.distance_to(node_pos)
		if dist < min_dist:
			min_dist = dist
			nearest_idx = i
	return nearest_idx

func _highlight_node(idx: int, active: bool):
	var node_node = nodes_root.get_node_or_null("Node_" + str(idx))
	if not node_node: return # Bỏ qua nếu nút chưa tồn tại
	
	if active:
		node_node.modulate = Color(1.5, 0.2, 0.2, 1) # Đỏ rực phát quang
	else:
		node_node.modulate = Color(0.3, 0, 0, 0.7) # Màu mực tàu sẫm

func _add_finished_line(from_idx: int, to_idx: int):
	var area_center = draw_area.size / 2
	var line = Line2D.new()
	line.width = 8.0
	line.default_color = Color(0.8, 0, 0, 1)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = PackedVector2Array([
		logic.nodes[from_idx] + area_center,
		logic.nodes[to_idx] + area_center
	])
	finished_lines_root.add_child(line)

func _clear_lines():
	for child in finished_lines_root.get_children():
		child.queue_free()
	for i in range(logic.nodes.size()):
		_highlight_node(i, false)

func _on_win():
	is_drawing = false
	status_label.text = "PHONG ẤN ĐÃ KÍCH HOẠT!"
	status_label.modulate = Color.GOLD
	GameState.is_talisman_puzzle_solved = true
	await get_tree().create_timer(2.0).timeout

	puzzle_finished.emit(true)
	_close()

func _on_lose():
	if logic.is_solved(): return
	
	# Hiệu ứng trừng phạt: Flash đỏ toàn màn hình
	var overlay = $Control/Overlay
	var paper = $Control/Paper
	
	var flash_tween = create_tween().set_parallel(true)
	overlay.color = Color(0.8, 0, 0, 0.6) # Đỏ rực
	flash_tween.tween_property(overlay, "color", Color(0, 0, 0, 0.7), 0.5)
	
	status_label.text = "!!! LINH KHÍ PHẢN PHỆ !!!"
	status_label.modulate = Color.RED
	
	# Rung mạnh lá bùa
	var shake_tween = create_tween()
	var orig_pos = paper.position
	for i in range(8):
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		shake_tween.tween_property(paper, "position", orig_pos + offset, 0.04)
	shake_tween.tween_property(paper, "position", orig_pos, 0.04)
	
	await get_tree().create_timer(0.6).timeout
	logic.reset_puzzle()
	status_label.text = "Dùng một nét vẽ để kích hoạt bùa..."
	status_label.modulate = Color(0.4, 0, 0, 1)

func open_puzzle():
	show()
	logic.setup_puzzle() # Gọi setup lại để reset toàn bộ logic
	_setup_ui_elements() # Vẽ lại UI cho chắc chắn
	
	status_label.text = "Dùng một nét vẽ để kích hoạt bùa..."
	status_label.modulate = Color(0.4, 0, 0, 1)
	
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
