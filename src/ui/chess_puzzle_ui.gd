extends Control

signal game_finished(won: bool)

@onready var board_container = $BoardContainer
@onready var piece_container = $BoardContainer/PieceContainer
@onready var grid_overlay = $BoardContainer/GridOverlay

var logic = ChineseChessLogic.new()
var selected_pos = null # { "r": int, "c": int }
var is_player_turn = false
var is_active = false
var is_game_solved = false # Flag đã giải xong ván cờ
var board_history = [] # Lưu trữ các hash của bàn cờ để chống lặp lại


const TILE_SIZE = 62
const OFFSET_X = 22
const OFFSET_Y = 40

func _ready():
	# ĐÂY LÀ SỬA TRIỆT ĐỂ: Node này luôn chạy kể cả khi scene bị pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ui()
	hide()
	grid_overlay.draw.connect(_on_grid_draw)


func _on_grid_draw():
	var draw_node = grid_overlay
	var color = Color(0.9, 0.8, 0.6, 0.5) # Màu vàng nhạt cho vạch kẻ
	var line_width = 2.0
	
	# Vẽ đường ngang (10 đường)
	for r in range(10):
		var y = r * TILE_SIZE + OFFSET_Y + (TILE_SIZE / 2)
		var start = Vector2(OFFSET_X + TILE_SIZE / 2, y)
		var end = Vector2(OFFSET_X + TILE_SIZE / 2 + TILE_SIZE * 8, y)
		draw_node.draw_line(start, end, color, line_width)
		
	# Vẽ đường dọc (9 đường)
	for c in range(9):
		var x = c * TILE_SIZE + OFFSET_X + (TILE_SIZE / 2)
		var start_y = OFFSET_Y + (TILE_SIZE / 2)
		var end_y = OFFSET_Y + (TILE_SIZE / 2) + TILE_SIZE * 9
		
		if c == 0 or c == 8:
			# Hai biên dọc vẽ suốt
			draw_node.draw_line(Vector2(x, start_y), Vector2(x, end_y), color, line_width)
		else:
			# Các đường dọc ở giữa bị ngắt bởi Sông (hàng 4-5)
			draw_node.draw_line(Vector2(x, start_y), Vector2(x, start_y + TILE_SIZE * 4), color, line_width)
			draw_node.draw_line(Vector2(x, start_y + TILE_SIZE * 5), Vector2(x, end_y), color, line_width)
			
	# Vẽ Cung Tướng (Đường chéo)
	var palace_offsets = [0, 7] # Hàng bắt đầu của cung đỏ và đen
	for r_start in palace_offsets:
		var x1 = 3 * TILE_SIZE + OFFSET_X + TILE_SIZE / 2
		var y1 = r_start * TILE_SIZE + OFFSET_Y + TILE_SIZE / 2
		var x2 = 5 * TILE_SIZE + OFFSET_X + TILE_SIZE / 2
		var y2 = (r_start + 2) * TILE_SIZE + OFFSET_Y + TILE_SIZE / 2
		draw_node.draw_line(Vector2(x1, y1), Vector2(x2, y2), color, line_width)
		draw_node.draw_line(Vector2(x2, y1), Vector2(x1, y2), color, line_width)

func start_game():
	is_active = true
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		p.set_movement_enabled(false)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()
	logic.setup_puzzle()
	_refresh_board()
	_ghost_move_sequence() # Gọi trực tiếp, không cần call_deferred


func _ghost_move_sequence():
	is_player_turn = false
	
	# Tạo Timer node thực để đảm bảo chạy xuyên suốt
	var t = Timer.new()
	t.process_mode = Node.PROCESS_MODE_ALWAYS
	t.one_shot = true
	add_child(t)
	
	# 1. Chờ 1 giây
	t.start(1.0)
	await t.timeout
	
	# 2. Cho AI tự tìm nước đi khai cuộc thông minh nhất để hù dọa
	var start_time = Time.get_ticks_msec()
	var best_move = _find_best_move_minimax(3, start_time, 1000)
	
	if best_move:
		var piece = logic.get_piece(best_move.fr, best_move.fc)
		var from_pos = Vector2(best_move.fc * TILE_SIZE + OFFSET_X, best_move.fr * TILE_SIZE + OFFSET_Y)
		var to_pos = Vector2(best_move.tc * TILE_SIZE + OFFSET_X, best_move.tr * TILE_SIZE + OFFSET_Y)
		
		if logic.move_piece(best_move.fr, best_move.fc, best_move.tr, best_move.tc):
			_refresh_board()
			var anim_piece = _create_tile_ui(best_move.tr, best_move.tc, piece)
			anim_piece.position = from_pos
			var tween = create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(anim_piece, "position", to_pos, 0.5).set_trans(Tween.TRANS_SINE)
			await tween.finished
			_refresh_board()
	
	# 3. Hiện lời thoại thắc mắc
	if DialogueManager:
		DialogueManager.show_text("Tôi: Cái gì thế này? Quân cờ... tại sao nó lại tự di chuyển được?")
		await DialogueManager.dialogue_finished
	
	t.queue_free()
	is_player_turn = true

func _setup_ui():
	# Xóa các quân cờ cũ
	for child in piece_container.get_children():
		child.queue_free()

func _refresh_board():
	for child in piece_container.get_children():
		child.queue_free()
		
	for r in range(10):
		for c in range(9):
			var piece = logic.get_piece(r, c)
			_create_tile_ui(r, c, piece)

func _create_tile_ui(r, c, piece_data):
	var btn = Button.new()
	btn.focus_mode = FocusMode.FOCUS_NONE
	btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	btn.position = Vector2(c * TILE_SIZE + OFFSET_X, r * TILE_SIZE + OFFSET_Y)
	
	var empty_sb = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)

	if piece_data:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.1, 0.1) if piece_data.color == "black" else Color(0.5, 0.1, 0.1)
		sb.set_corner_radius_all(31)
		sb.set_border_width_all(2)
		
		# HIỆN GỢI Ý: Quân Đen đang chọn hoặc có thể ăn quân Đỏ
		if selected_pos:
			var is_selected = (selected_pos.r == r and selected_pos.c == c)
			var can_capture = (piece_data.color == "red" and logic.is_valid_move(selected_pos.r, selected_pos.c, r, c))
			
			if is_selected or can_capture:
				sb.border_color = Color.CYAN
				sb.set_border_width_all(6 if can_capture else 4)
			else:
				sb.border_color = Color.GOLD if piece_data.color == "black" else Color.WHITE
		else:
			sb.border_color = Color.GOLD if piece_data.color == "black" else Color.WHITE
			
		# Áp dụng cho mọi trạng thái nút
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)
		
		var han_name = _get_han_name(piece_data.type, piece_data.color)
		btn.text = han_name
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_font_size_override("font_size", 24)
	else:
		# Ô TRỐNG: Không hiện dấu chấm gợi ý nữa theo yêu cầu
		pass
	
	btn.pressed.connect(_on_piece_pressed.bind(r, c))
	piece_container.add_child(btn)
	return btn # QUAN TRỌNG: Trả về button để dùng cho animation

func _get_han_name(type, color):
	match type:
		"General": return "帥" if color == "red" else "將"
		"Chariot": return "俥" if color == "red" else "車"
		"Cannon": return "炮" if color == "red" else "砲"
		"Horse": return "傌" if color == "red" else "馬"
		"Elephant": return "相" if color == "red" else "象"
		"Advisor": return "仕" if color == "red" else "士"
		"Soldier": return "兵" if color == "red" else "卒"
	return "?"

func _on_piece_pressed(r, c):
	if not is_active or not is_player_turn: return
	
	var piece = logic.get_piece(r, c)
	if piece and piece.color == "black":
		selected_pos = {"r": r, "c": c}
		print("Selected piece at: ", r, c)
		_refresh_board() # <--- QUAN TRỌNG: Cần refresh để hiện viền xanh
	elif selected_pos:
		# Kiểm tra tính hợp lệ và an toàn (không bị chiếu tướng sau khi đi)
		var can_move_here = logic.is_valid_move(selected_pos.r, selected_pos.c, r, c)
		var is_safe = true
		
		if can_move_here:
			var captured = _simulate_move(selected_pos.r, selected_pos.c, r, c)
			is_safe = not _is_checking_general("black")
			_undo_move(selected_pos.r, selected_pos.c, r, c, captured)
			
		if can_move_here and is_safe:
			_execute_move(selected_pos.r, selected_pos.c, r, c)
			selected_pos = null
			_refresh_board()
			
			if not _check_win_condition():
				# Sau khi người chơi đi, đến lượt Ma phản công
				_make_ghost_move()
		else:
			selected_pos = null
			_refresh_board()
			print("Invalid move")

func _make_ghost_move():
	is_player_turn = false
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var best_move = null
	var start_time = Time.get_ticks_msec()
	var time_limit = 1200 # Cho AI 1.2 giây để tính toán sâu hơn
	
	# Iterative Deepening lên tới độ sâu 4
	for depth in range(1, 5):
		var current_move = _find_best_move_minimax(depth, start_time, time_limit)
		if current_move:
			best_move = current_move
		# Nếu đã dùng hơn 60% thời gian, đừng cố leo lên độ sâu tiếp theo
		if Time.get_ticks_msec() - start_time > time_limit * 0.6:
			break

	if best_move:
		logic.move_piece(best_move.fr, best_move.fc, best_move.tr, best_move.tc)
		_record_board_state()
		_refresh_board()
		if not _check_win_condition():
			is_player_turn = true
	else:
		_check_win_condition()

func _find_best_move_minimax(depth: int, start_time: int, time_limit: int):
	var best_score = -5000000
	var best_move = null
	var moves = _get_all_valid_moves("red")

	# Sắp xếp nước đi: Ưu tiên ăn quân to
	moves.sort_custom(func(a, b):
		var target_a = logic.get_piece(a.tr, a.tc)
		var target_b = logic.get_piece(b.tr, b.tc)
		return _get_piece_value(target_a) > _get_piece_value(target_b)
	)

	for m in moves:
		if Time.get_ticks_msec() - start_time > time_limit: break

		var captured = _simulate_move(m.fr, m.fc, m.tr, m.tc)
		var score = _minimax(depth - 1, -5000000, 5000000, false, start_time, time_limit)
		_undo_move(m.fr, m.fc, m.tr, m.tc, captured)

		if score > best_score:
			best_score = score
			best_move = m

	return best_move

func _minimax(depth: int, alpha: float, beta: float, is_ghost: bool, start_time: int, time_limit: int) -> float:
	if _is_game_over_sim(): return _evaluate_board()
	if Time.get_ticks_msec() - start_time > time_limit: return _evaluate_board()
	
	if depth == 0:
		# Thay vì dừng hẳn, ta dùng Quiescence Search để tìm các nước ăn quân nốt
		return _quiescence_search(alpha, beta, is_ghost, start_time, time_limit)
	
	if is_ghost:
		var max_eval = -5000000
		var moves = _get_all_valid_moves("red")
		moves.sort_custom(func(a, b): return _get_piece_value(logic.get_piece(a.tr, a.tc)) > _get_piece_value(logic.get_piece(b.tr, b.tc)))
		
		for m in moves:
			var captured = _simulate_move(m.fr, m.fc, m.tr, m.tc)
			var eval = _minimax(depth - 1, alpha, beta, false, start_time, time_limit)
			_undo_move(m.fr, m.fc, m.tr, m.tc, captured)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha: break
		return max_eval
	else:
		var min_eval = 5000000
		var moves = _get_all_valid_moves("black")
		moves.sort_custom(func(a, b): return _get_piece_value(logic.get_piece(a.tr, a.tc)) > _get_piece_value(logic.get_piece(b.tr, b.tc)))
		
		for m in moves:
			var captured = _simulate_move(m.fr, m.fc, m.tr, m.tc)
			var eval = _minimax(depth - 1, alpha, beta, true, start_time, time_limit)
			_undo_move(m.fr, m.fc, m.tr, m.tc, captured)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha: break
		return min_eval

# Tìm kiếm tĩnh (Quiescence Search): Chỉ tìm các nước ăn quân để tránh sai số ở độ sâu cuối
func _quiescence_search(alpha: float, beta: float, is_ghost: bool, start_time: int, time_limit: int) -> float:
	var stand_pat = _evaluate_board()
	if Time.get_ticks_msec() - start_time > time_limit: return stand_pat
	
	if is_ghost:
		if stand_pat >= beta: return beta
		alpha = max(alpha, stand_pat)
		
		var moves = _get_all_valid_moves("red")
		for m in moves:
			# Chỉ xét nước đi ăn quân
			if not logic.get_piece(m.tr, m.tc): continue
			
			var captured = _simulate_move(m.fr, m.fc, m.tr, m.tc)
			var score = _quiescence_search(alpha, beta, false, start_time, time_limit)
			_undo_move(m.fr, m.fc, m.tr, m.tc, captured)
			
			if score >= beta: return beta
			alpha = max(alpha, score)
		return alpha
	else:
		if stand_pat <= alpha: return alpha
		beta = min(beta, stand_pat)
		
		var moves = _get_all_valid_moves("black")
		for m in moves:
			if not logic.get_piece(m.tr, m.tc): continue
			
			var captured = _simulate_move(m.fr, m.fc, m.tr, m.tc)
			var score = _quiescence_search(alpha, beta, true, start_time, time_limit)
			_undo_move(m.fr, m.fc, m.tr, m.tc, captured)
			
			if score <= alpha: return alpha
			beta = min(beta, score)
		return beta


func _get_piece_value(piece) -> int:
	if not piece:
		return 0
	match piece.type:
		"General": return 10000
		"Chariot": return 900
		"Cannon": return 450
		"Horse": return 400
		"Advisor": return 200
		"Elephant": return 200
		"Soldier": return 100
	return 0

func _evaluate_board() -> float:
	var total = 0.0
	var current_hash = _get_board_hash()

	# CHỐNG LẶP LẠI: Phạt nặng nếu thế cờ này đã từng xuất hiện
	for h in board_history:
		if h == current_hash:
			total -= 500 # Trừ điểm nặng để Ma tránh lặp lại

	# Bảng giá trị vị trí cho từng loại quân (lấy từ góc nhìn quân Đỏ)
	var piece_position_bonus = {
		"Soldier": [
			[0, 0, 0, 0, 0, 0, 0, 0, 0], # Hàng 0 (xa nhất)
			[0, 0, 0, 0, 0, 0, 0, 0, 0], # Hàng 1
			[0, 0, 0, 0, 0, 0, 0, 0, 0], # Hàng 2
			[0, 0, 0, 0, 0, 0, 0, 0, 0], # Hàng 3
			[0, 0, 0, 0, 0, 0, 0, 0, 0], # Hàng 4 (chưa qua sông)
			[10, 10, 10, 15, 20, 15, 10, 10, 10], # Hàng 5 (qua sông)
			[15, 20, 25, 30, 35, 30, 25, 20, 15], # Hàng 6
			[20, 25, 30, 35, 40, 35, 30, 25, 20], # Hàng 7
			[25, 30, 35, 40, 45, 40, 35, 30, 25], # Hàng 8
			[30, 35, 40, 45, 50, 45, 40, 35, 30], # Hàng 9 (gần tướng nhất)
		],
		"Horse": [
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[5, 10, 15, 15, 15, 15, 15, 10, 5],
			[10, 15, 20, 25, 25, 25, 20, 15, 10],
			[15, 20, 25, 30, 30, 30, 25, 20, 15],
			[10, 15, 20, 25, 25, 25, 20, 15, 10],
			[5, 10, 15, 15, 15, 15, 15, 10, 5],
		],
		"Cannon": [
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[5, 5, 5, 5, 5, 5, 5, 5, 5],
			[5, 5, 5, 5, 5, 5, 5, 5, 5],
			[10, 10, 10, 15, 15, 15, 10, 10, 10],
			[10, 10, 10, 15, 15, 15, 10, 10, 10],
			[5, 5, 5, 5, 5, 5, 5, 5, 5],
			[5, 5, 5, 5, 5, 5, 5, 5, 5],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
		],
		"Chariot": [
			[0, 0, 0, 0, 0, 0, 0, 0, 0],
			[5, 5, 5, 5, 5, 5, 5, 5, 5],
			[5, 5, 5, 5, 5, 5, 5, 5, 5],
			[10, 10, 10, 15, 15, 15, 10, 10, 10],
			[10, 10, 10, 15, 15, 15, 10, 10, 10],
			[10, 10, 10, 15, 15, 15, 10, 10, 10],
			[15, 15, 15, 20, 20, 20, 15, 15, 15],
			[15, 15, 15, 20, 20, 20, 15, 15, 15],
			[20, 20, 20, 25, 25, 25, 20, 20, 20],
			[20, 20, 20, 25, 25, 25, 20, 20, 20],
		],
	}

	for r in range(10):
		for c in range(9):
			var p = logic.get_piece(r, c)
			if not p: continue

			var score = 0
			match p.type:
				"General": score = 10000
				"Chariot":
					score = 900
					if piece_position_bonus.has("Chariot"):
						var bonus_r = r if p.color == "red" else 9 - r
						score += piece_position_bonus["Chariot"][bonus_r][c]
				"Cannon":
					score = 450
					if piece_position_bonus.has("Cannon"):
						var bonus_r = r if p.color == "red" else 9 - r
						score += piece_position_bonus["Cannon"][bonus_r][c]
				"Horse":
					score = 400
					if piece_position_bonus.has("Horse"):
						var bonus_r = r if p.color == "red" else 9 - r
						score += piece_position_bonus["Horse"][bonus_r][c]
				"Advisor": score = 200
				"Elephant": score = 200
				"Soldier":
					score = 100
					if piece_position_bonus.has("Soldier"):
						var bonus_r = r if p.color == "red" else 9 - r
						score += piece_position_bonus["Soldier"][bonus_r][c]

			if p.color == "red": total += score
			else: total -= score

	# Bonus nếu đang chiếu tướng đối phương (Tăng mạnh để AI hung hãn hơn)
	if _is_checking_general("black"):
		total += 500
	if _is_checking_general("red"):
		total -= 500

	# Tính linh động: Mỗi nước đi hợp lệ cộng thêm 2 điểm
	var red_mobility = _get_all_valid_moves("red").size()
	var black_mobility = _get_all_valid_moves("black").size()
	total += (red_mobility - black_mobility) * 2

	return total

func _get_board_hash() -> String:
	var s = ""
	for r in range(10):
		for c in range(9):
			var p = logic.get_piece(r, c)
			if p: s += p.type[0] + p.color[0]
			else: s += "--"
	return s

func _record_board_state():
	board_history.append(_get_board_hash())
	if board_history.size() > 12: # Chỉ giữ 12 trạng thái gần nhất
		board_history.remove_at(0)

func _get_all_valid_moves(color: String, check_safety: bool = true) -> Array:
	var moves = []
	for fr in range(10):
		for fc in range(9):
			var p = logic.get_piece(fr, fc)
			if p and p.color == color:
				var possible_targets = _get_possible_targets(fr, fc, p)
				for target in possible_targets:
					var tr = target[0]
					var tc = target[1]
					
					if logic.is_valid_move(fr, fc, tr, tc):
						if check_safety:
							# Kiểm tra xem đi xong có bị chiếu tướng không (Luật cờ tướng)
							var captured = _simulate_move(fr, fc, tr, tc)
							var is_safe = not _is_checking_general(color)
							_undo_move(fr, fc, tr, tc, captured)
							
							if is_safe:
								moves.append({"fr": fr, "fc": fc, "tr": tr, "tc": tc})
						else:
							moves.append({"fr": fr, "fc": fc, "tr": tr, "tc": tc})
	return moves

# Trả về danh sách ô đích có thể đi đến cho một quân cờ
func _get_possible_targets(from_r: int, from_c: int, piece: Dictionary) -> Array:
	var targets = []
	match piece.type:
		"General":
			# Chỉ đi 1 ô trong cung
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if abs(dr) + abs(dc) == 1:
						var nr = from_r + dr
						var nc = from_c + dc
						if nr >= 0 and nr < 10 and nc >= 0 and nc < 9:
							if nc >= 3 and nc <= 5:
								if (piece.color == "red" and nr <= 2) or (piece.color == "black" and nr >= 7):
									targets.append([nr, nc])
		"Chariot":
			# Xe đi thẳng: duyệt 4 hướng đến khi gặp cản
			for dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]:
				var nr = from_r + dir[0]
				var nc = from_c + dir[1]
				while nr >= 0 and nr < 10 and nc >= 0 and nc < 9:
					targets.append([nr, nc])
					if logic.get_piece(nr, nc): break
					nr += dir[0]
					nc += dir[1]
		"Cannon":
			# Pháo đi như Xe
			for dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]:
				var nr = from_r + dir[0]
				var nc = from_c + dir[1]
				while nr >= 0 and nr < 10 and nc >= 0 and nc < 9:
					targets.append([nr, nc])
					if logic.get_piece(nr, nc): break
					nr += dir[0]
					nc += dir[1]
		"Horse":
			# Mã đi chữ L
			var horse_moves = [
				[-2, -1], [-2, 1], [-1, -2], [-1, 2],
				[1, -2], [1, 2], [2, -1], [2, 1]
			]
			for m in horse_moves:
				var nr = from_r + m[0]
				var nc = from_c + m[1]
				if nr >= 0 and nr < 10 and nc >= 0 and nc < 9:
					targets.append([nr, nc])
		"Advisor":
			# Sĩ đi chéo 1 ô trong cung
			for dr in [-1, 1]:
				for dc in [-1, 1]:
					var nr = from_r + dr
					var nc = from_c + dc
					if nr >= 0 and nr < 10 and nc >= 0 and nc < 9:
						if nc >= 3 and nc <= 5:
							if (piece.color == "red" and nr <= 2) or (piece.color == "black" and nr >= 7):
								targets.append([nr, nc])
		"Elephant":
			# Tượng đi chéo 2 ô, không qua sông
			for dr in [-2, 2]:
				for dc in [-2, 2]:
					var nr = from_r + dr
					var nc = from_c + dc
					if nr >= 0 and nr < 10 and nc >= 0 and nc < 9:
						if (piece.color == "red" and nr <= 4) or (piece.color == "black" and nr >= 5):
							targets.append([nr, nc])
		"Soldier":
			# Tốt tiến 1 ô, qua sông rồi đi ngang được
			var forward = -1 if piece.color == "black" else 1
			var nr_forward = from_r + forward
			if nr_forward >= 0 and nr_forward < 10:
				targets.append([nr_forward, from_c])
			var crossed = (piece.color == "black" and from_r <= 4) or (piece.color == "red" and from_r >= 5)
			if crossed:
				if from_c - 1 >= 0: targets.append([from_r, from_c - 1])
				if from_c + 1 < 9: targets.append([from_r, from_c + 1])
	return targets

func _simulate_move(fr, fc, tr, tc):
	var captured = logic.board[tr][tc]
	logic.board[tr][tc] = logic.board[fr][fc]
	logic.board[fr][fc] = null
	return captured

func _undo_move(fr, fc, tr, tc, captured):
	logic.board[fr][fc] = logic.board[tr][tc]
	logic.board[tr][tc] = captured

func _is_game_over_sim() -> bool:
	var red = false
	var black = false
	for r in range(10):
		for c in range(9):
			var p = logic.get_piece(r, c)
			if p and p.type == "General":
				if p.color == "red": red = true
				else: black = true
	return not (red and black)

# Kiểm tra xem màu 'target_color' có đang bị chiếu tướng không
func _is_checking_general(target_color: String) -> bool:
	var gen_pos = null
	var enemy_gen_pos = null
	for r in range(10):
		for c in range(9):
			var p = logic.get_piece(r, c)
			if p and p.type == "General":
				if p.color == target_color:
					gen_pos = {"r": r, "c": c}
				else:
					enemy_gen_pos = {"r": r, "c": c}
	
	if not gen_pos or not enemy_gen_pos: return false
	
	# 1. LUẬT LỘ MẶT TƯỚNG: Hai tướng không được nhìn nhau trực diện trên cùng cột
	if gen_pos.c == enemy_gen_pos.c:
		var r_min = min(gen_pos.r, enemy_gen_pos.r)
		var r_max = max(gen_pos.r, enemy_gen_pos.r)
		var has_blocker = false
		for r_mid in range(r_min + 1, r_max):
			if logic.get_piece(r_mid, gen_pos.c):
				has_blocker = true
				break
		if not has_blocker:
			return true # Tướng đang bị "chiếu" bởi tướng đối phương
	
	# 2. KIỂM TRA CÁC QUÂN CỜ KHÁC
	var attacker_color = "red" if target_color == "black" else "black"
	for r in range(10):
		for c in range(9):
			var p = logic.get_piece(r, c)
			if p and p.color == attacker_color:
				if logic.is_valid_move(r, c, gen_pos.r, gen_pos.c):
					return true
	return false

func _execute_move(fr, fc, tr, tc):
	logic.move_piece(fr, fc, tr, tc)
	# Có thể thêm hiệu ứng âm thanh gỗ va chạm ở đây

func _check_win_condition() -> bool:
	# Kiểm tra xem AI (Red) còn nước đi không
	var red_moves = _get_all_valid_moves("red")
	if red_moves.is_empty():
		_on_win()
		return true
		
	# Kiểm tra xem Người chơi (Black) còn nước đi không
	var black_moves = _get_all_valid_moves("black")
	if black_moves.is_empty():
		if _is_checking_general("black"):
			if DialogueManager: DialogueManager.show_text("Chiếu bí!")
		else:
			if DialogueManager: DialogueManager.show_text("Hết nước đi!")
		_on_lose()
		return true
		
	return false

func _on_win():
	print("DEBUG: [ChessPuzzle] Thắng cuộc! Khởi động sự kiện đèn bí ẩn...")
	is_active = false
	is_player_turn = false
	
	# Đợi một chút cho ván cờ biến mất
	await get_tree().create_timer(0.5).timeout
	hide()
	game_finished.emit(true)
	
	# 1. Tìm đèn house3_light3 (Tìm xuyên suốt scene hiện tại)
	var target_light = get_tree().current_scene.find_child("house3_light3", true, false)
	if target_light:
		target_light.visible = true
		print("DEBUG: [ChessPuzzle] Đã bật đèn house3_light3.")
		
		# Bật tương tác cho đèn lồng
		var lantern_interact = target_light.find_child("LanternInteract", true, false)
		if lantern_interact and lantern_interact.has_method("interact"):
			lantern_interact.is_active = true
			print("DEBUG: [ChessPuzzle] Đã bật LanternInteract.")
	else:
		print("LOI: Không tìm thấy node 'house3_light3' trong scene hiện tại!")

	# 1.5. Hiện tờ giấy gợi ý cờ tướng
	var paper_chess = get_tree().current_scene.find_child("PaperEventChess", true, false)
	if paper_chess:
		paper_chess.visible = true
		# Bật tương tác cho tờ giấy
		if paper_chess.has_method("interact"):
			paper_chess.is_active = true
		print("DEBUG: [ChessPuzzle] Đã hiện PaperEventChess.")
	
	# 2. Tìm người chơi
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Nếu group fail, tìm theo tên
		player = get_tree().current_scene.find_child("Player", true, false)
		
	if player:
		print("DEBUG: [ChessPuzzle] Đã tìm thấy người chơi. Bắt đầu xoay camera...")
		player.set_movement_enabled(false) # Khóa cả di chuyển và chuột (nhờ sửa player.gd trước đó)
		
		if target_light:
			var head = player.get_node_or_null("Head")
			var camera = player.get_node_or_null("Head/Camera3D")
			
			if head and camera:
				# Vị trí đèn
				var light_pos = target_light.global_position
				
				# Xoay Body/Head sang ngang (Y)
				var head_transform = head.global_transform.looking_at(light_pos, Vector3.UP)
				var target_head_quat = head_transform.basis.get_rotation_quaternion()
				
				# Xoay Camera lên xuống (X)
				var cam_transform = camera.global_transform.looking_at(light_pos, Vector3.UP)
				var target_cam_quat = cam_transform.basis.get_rotation_quaternion()
				
				# Tạo Tween xoay mượt 1.5 giây
				var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				
				# Lưu ý: Tween trực tiếp rotation bằng góc để tránh vấn đề Quat nhảy
				var target_rot = head_transform.basis.get_euler()
				var target_cam_rot = cam_transform.basis.get_euler()
				
				tween.tween_property(head, "global_rotation:y", target_rot.y, 1.5)
				tween.tween_property(camera, "global_rotation:x", clamp(target_cam_rot.x, -0.7, 1.0), 1.5)
				
				await tween.finished
		
		# 3. Hiện lời thoại thắc mắc
		if DialogueManager:
			print("DEBUG: [ChessPuzzle] Đang hiện lời thoại...")
			DialogueManager.show_text("Này, mình đâu có thấy đèn ở đó sáng đâu nhỉ?")
			DialogueManager.show_text("Chắc là ai mới treo để lại thử xem")
			# Đợi thoại xong (nếu manager có signal)
			if DialogueManager.has_signal("dialogue_finished"):
				await DialogueManager.dialogue_finished
			else:
				await get_tree().create_timer(4.0).timeout
		
		player.set_movement_enabled(true) # Mở khóa lại
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Trả lại quyền điều khiển hướng nhìn
		is_game_solved = true # Đánh dấu đã giải xong
		print("DEBUG: [ChessPuzzle] Kết thúc sự kiện, mở khóa người chơi và trả lại chuột.")

	else:
		print("LOI: Không tìm thấy Player để xoay hướng nhìn!")

func _on_lose():
	is_active = false
	is_player_turn = false
	if DialogueManager:
		DialogueManager.show_text("Bạn đã thua")
	
	await get_tree().create_timer(2.0).timeout
	start_game()

func _on_close_pressed():
	is_active = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		p.set_movement_enabled(true)
