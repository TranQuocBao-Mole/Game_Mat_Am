class_name CoinPuzzleLogic
extends Object

const COIN_COUNT = 7
var weigh_count: int = 0
var max_weighs: int = 3

# Danh sách các khả năng còn lại: mỗi khả năng là {index: int, is_heavier: bool}
var possible_solutions = []

func setup_puzzle():
	weigh_count = 0
	possible_solutions.clear()
	# Ban đầu có 14 khả năng (7 xu, mỗi xu có thể nặng hơn hoặc nhẹ hơn)
	for i in range(COIN_COUNT):
		possible_solutions.append({"index": i, "is_heavier": true})
		possible_solutions.append({"index": i, "is_heavier": false})
	
	# Chỉ dùng để hiển thị giao diện, xu giả thực sự sẽ bị "dồn" dần qua các lần cân
	special_coin_index = -1 
	print("DEBUG: Adversarial Puzzle Started. Possible: ", possible_solutions.size())

var special_coin_index: int = -1 # Sẽ chốt khi cần thiết

func reset_puzzle():
	setup_puzzle()

func weigh(left_indices: Array, right_indices: Array) -> int:
	weigh_count += 1
	
	# Tính toán 3 tập hợp kết quả có thể xảy ra
	var if_equal = []
	var if_left_heavier = []
	var if_right_heavier = []
	
	for sol in possible_solutions:
		var idx = sol["index"]
		var heavier = sol["is_heavier"]
		
		if left_indices.has(idx):
			if heavier: if_left_heavier.append(sol)
			else: if_right_heavier.append(sol)
		elif right_indices.has(idx):
			if heavier: if_right_heavier.append(sol)
			else: if_left_heavier.append(sol)
		else:
			if_equal.append(sol)
	
	# Tạo danh sách các kết quả có thể xảy ra
	var counts = [
		{"res": 0, "list": if_equal},
		{"res": -1, "list": if_left_heavier},
		{"res": 1, "list": if_right_heavier}
	]
	
	# Sắp xếp để tìm tập hợp giữ lại nhiều ĐỒNG XU nghi vấn nhất
	counts.sort_custom(func(a, b):
		var a_suspects = []
		for s in a["list"]: if not a_suspects.has(s["index"]): a_suspects.append(s["index"])
		var b_suspects = []
		for s in b["list"]: if not b_suspects.has(s["index"]): b_suspects.append(s["index"])
		
		# Ưu tiên kết quả giữ lại nhiều ĐỒNG XU hơn
		return a_suspects.size() > b_suspects.size()
	)
	
	# Nếu là lượt cân 1 hoặc 2, và kết quả dẫn đến chỉ còn 1 xu nghi vấn
	# hãy cố gắng chọn kết quả khác nếu có thể để kéo dài trò chơi
	var choice = counts[0]
	if weigh_count < 3:
		for c in counts:
			var c_suspects = []
			for s in c["list"]: if not c_suspects.has(s["index"]): c_suspects.append(s["index"])
			if c_suspects.size() > 1:
				choice = c
				break
	
	possible_solutions = choice["list"]
	
	# Log danh sách nghi phạm còn lại
	var suspects = []
	for s in possible_solutions: 
		if not suspects.has(s["index"] + 1): suspects.append(s["index"] + 1)
	
	# Chọn một xu giả "tạm thời" để người dùng test
	if possible_solutions.size() > 0:
		special_coin_index = possible_solutions[randi() % possible_solutions.size()]["index"]
	
	print("DEBUG: Sau lượt cân ", weigh_count, ", còn lại các xu nghi vấn: ", suspects)
	if weigh_count == 3:
		if suspects.size() > 1:
			print("DEBUG: TEST: Linh hồn đang tạm trú ở xu số: ", special_coin_index + 1)
			print("DEBUG: CẢNH BÁO: Vì còn ", suspects.size(), " nghi phạm, nếu bạn chọn xu ", special_coin_index + 1, " vẫn sẽ bị SAI.")
		else:
			print("DEBUG: CHÚC MỪNG: Bạn đã dồn được linh hồn về duy nhất xu số: ", suspects[0])

	return choice["res"]

func check_guess(index: int, is_heavier_guess: bool) -> bool:
	print("DEBUG: Người chơi chọn xu số: ", index + 1, " | Dự đoán: ", "Nặng" if is_heavier_guess else "Nhẹ")
	
	# Quy tắc sắt đá: Chỉ cho thắng nếu đã dồn được linh hồn vào 1 KHẢ NĂNG duy nhất (cả xu và tính chất nặng/nhẹ)
	if possible_solutions.size() > 1:
		print("DEBUG: THẤT BẠI: Logic chưa hoàn hảo, còn ", possible_solutions.size(), " khả năng (tính cả nặng/nhẹ).")
		return false
	
	# Nếu chỉ còn đúng 1 khả năng duy nhất
	if possible_solutions.size() == 1:
		var sol = possible_solutions[0]
		return sol["index"] == index and sol["is_heavier"] == is_heavier_guess
	
	return false

func get_weigh_count() -> int:
	return weigh_count

func is_out_of_moves() -> bool:
	return weigh_count >= max_weighs
