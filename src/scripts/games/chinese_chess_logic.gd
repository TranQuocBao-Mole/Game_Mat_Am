extends Node

class_name ChineseChessLogic

# Trạng thái bàn cờ: 10 hàng x 9 cột
# Giá trị: null (trống) hoặc Dictionary { "type": "Tướng", "color": "red"/"black" }
var board = []

func _init():
	_reset_board()

func _reset_board():
	board = []
	for r in range(10):
		var row = []
		for c in range(9):
			row.append(null)
		board.append(row)

## Thiết lập một thế cờ cụ thể (Cờ tàn)
func setup_puzzle():
	_reset_board()
	# Quân Đỏ (Ma) - Phòng thủ chắc chắn
	# Quân Đỏ (Ma - AI) - Thế trận Thiên Địa Pháo
	set_piece(0, 4, {"type": "General", "color": "red"})
	set_piece(0, 3, {"type": "Advisor", "color": "red"})
	set_piece(0, 5, {"type": "Advisor", "color": "red"})
	set_piece(2, 4, {"type": "Cannon",  "color": "red"})  # Pháo đầu
	set_piece(0, 1, {"type": "Chariot", "color": "red"})
	set_piece(0, 7, {"type": "Chariot", "color": "red"})
	set_piece(2, 0, {"type": "Elephant", "color": "red"})
	set_piece(2, 8, {"type": "Elephant", "color": "red"})
	set_piece(3, 1, {"type": "Soldier", "color": "red"})
	set_piece(3, 7, {"type": "Soldier", "color": "red"})

	# Quân Đen (Người chơi) - Thế trận phản công
	set_piece(9, 4, {"type": "General", "color": "black"})
	set_piece(9, 3, {"type": "Advisor", "color": "black"})
	set_piece(9, 5, {"type": "Advisor", "color": "black"})
	set_piece(7, 4, {"type": "Cannon",  "color": "black"})  # Pháo đối đầu
	set_piece(9, 1, {"type": "Horse",   "color": "black"})
	set_piece(9, 7, {"type": "Horse",   "color": "black"})
	set_piece(6, 4, {"type": "Soldier", "color": "black"})
	set_piece(9, 0, {"type": "Chariot", "color": "black"})
	set_piece(9, 8, {"type": "Chariot", "color": "black"})


func set_piece(r, c, piece):
	board[r][c] = piece

func get_piece(r, c):
	if r < 0 or r >= 10 or c < 0 or c >= 9: return null
	return board[r][c]

## Kiểm tra nước đi hợp lệ (Rút gọn cho mục đích giải đố)
func is_valid_move(from_r, from_c, to_r, to_c) -> bool:
	var piece = get_piece(from_r, from_c)
	if not piece: return false
	
	# Không thể ăn quân cùng màu
	var target = get_piece(to_r, to_c)
	if target and target.color == piece.color: return false
	
	var dr = to_r - from_r
	var dc = to_c - from_c
	
	match piece.type:
		"General":
			# Chỉ đi trong cung (r 0-2 hoặc 7-9, c 3-5)
			if to_c < 3 or to_c > 5: return false
			if piece.color == "red" and to_r > 2: return false
			if piece.color == "black" and to_r < 7: return false
			return abs(dr) + abs(dc) == 1
			
		"Chariot":
			# Đi thẳng/ngang, không bị chặn
			if dr != 0 and dc != 0: return false
			return _is_path_clear(from_r, from_c, to_r, to_c)
			
		"Cannon":
			# Đi như Xe, nhưng ăn quân phải nhảy qua 1 quân
			if dr != 0 and dc != 0: return false
			var count = _count_pieces_on_path(from_r, from_c, to_r, to_c)
			if target: # Ăn quân
				return count == 1
			else: # Di chuyển trống
				return count == 0
				
		"Horse":
			if (abs(dr) == 2 and abs(dc) == 1):
				if get_piece(from_r + int(dr/2), from_c) == null: return true
			if (abs(dr) == 1 and abs(dc) == 2):
				if get_piece(from_r, from_c + int(dc/2)) == null: return true
			return false
		"Advisor":
			if abs(dr) != 1 or abs(dc) != 1: return false
			if to_c < 3 or to_c > 5: return false
			if piece.color == "red" and to_r > 2: return false
			if piece.color == "black" and to_r < 7: return false
			return true
		"Elephant":
			if abs(dr) != 2 or abs(dc) != 2: return false
			if get_piece(from_r + int(dr/2), from_c + int(dc/2)) != null: return false
			if piece.color == "red" and to_r > 4: return false
			if piece.color == "black" and to_r < 5: return false
			return true
		"Soldier":
			var forward = -1 if piece.color == "black" else 1
			if dr == forward and dc == 0: return true
			var crossed_river = (piece.color == "black" and from_r <= 4) or (piece.color == "red" and from_r >= 5)
			if crossed_river and dr == 0 and abs(dc) == 1: return true
			return false
			
	return false # Phải đúng luật mới được đi

func _is_path_clear(r1, c1, r2, c2) -> bool:
	return _count_pieces_on_path(r1, c1, r2, c2) == 0

func _count_pieces_on_path(r1, c1, r2, c2) -> int:
	var count = 0
	var dr = sign(r2 - r1)
	var dc = sign(c2 - c1)
	
	var curr_r = r1 + dr
	var curr_c = c1 + dc
	
	while curr_r != r2 or curr_c != c2:
		if get_piece(curr_r, curr_c):
			count += 1
		curr_r += dr
		curr_c += dc
		if curr_r < 0 or curr_r >= 10 or curr_c < 0 or curr_c >= 9: break
		
	return count

func move_piece(from_r, from_c, to_r, to_c) -> bool:
	var piece = get_piece(from_r, from_c)
	if not piece: return false
	board[to_r][to_c] = piece
	board[from_r][from_c] = null
	return true
