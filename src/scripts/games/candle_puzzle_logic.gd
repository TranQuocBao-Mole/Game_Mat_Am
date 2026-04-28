extends Node

class_name CandlePuzzleLogic

signal puzzle_solved

var candle_count: int = 5
var states: Array = []

var interaction_matrix = []

func setup_puzzle(count: int, _unused: Array = []):
	candle_count = count
	states.resize(candle_count)
	_generate_solvable_matrix()
	reset_puzzle()

func _generate_solvable_matrix():
	# Sinh ma trận ngẫu nhiên cho đến khi tìm được ma trận khả nghịch trong GF(2)
	# Điều này đảm bảo mọi trạng thái mục tiêu đều có thể đạt được
	while true:
		var matrix = []
		for i in range(candle_count):
			var row = []
			for j in range(candle_count):
				# Mỗi nến ít nhất phải tự tác động lên chính nó (đường chéo chính = 1)
				# Hoặc ngẫu nhiên hoàn toàn
				row.append(randi() % 2)
			# Đảm bảo đường chéo chính là 1 để mỗi nút có tác dụng gì đó
			row[i] = 1
			matrix.append(row)
		
		if _is_matrix_invertible_gf2(matrix):
			interaction_matrix = matrix
			break

func _is_matrix_invertible_gf2(matrix: Array) -> bool:
	# Kiểm tra định thức trong GF(2) bằng khử Gauss
	var m = []
	for row in matrix:
		m.append(row.duplicate())
	
	var n = m.size()
	for i in range(n):
		# Tìm hàng có giá trị 1 ở cột i
		var pivot = i
		while pivot < n and m[pivot][i] == 0:
			pivot += 1
		
		if pivot == n: return false # Cột toàn 0 -> Vô nghiệm
		
		# Đổi hàng
		var temp = m[i]
		m[i] = m[pivot]
		m[pivot] = temp
		
		# Khử các hàng khác
		for j in range(n):
			if i != j and m[j][i] == 1:
				for k in range(i, n):
					m[j][k] = (m[j][k] + m[i][k]) % 2
	return true

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
			states[i] = !states[i]

func reset_puzzle():
	# Sinh ma trận mới mỗi lần reset theo yêu cầu
	_generate_solvable_matrix()
	
	# Sinh trạng thái ngẫu nhiên nhưng đảm bảo không phải là trạng thái thắng ngay lập tức
	while true:
		for i in range(candle_count):
			states[i] = (randi() % 2) == 1
		if not is_solved():
			break

func is_solved() -> bool:
	for s in states:
		if not s: return false # Tất cả nến phải sáng (true)
	return true
