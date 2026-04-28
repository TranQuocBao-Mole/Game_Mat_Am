extends Node

class_name PoisonPuzzleLogic

signal puzzle_solved
signal puzzle_lost

var poisoned_bottle: int = -1
var rat_count: int = 3
var bottle_count: int = 8

# Dữ liệu theo dõi: mỗi con chuột uống những bình nào
# rats_drinking[rat_index] = [bottle_index1, bottle_index2, ...]
var rats_drinking: Array = [[], [], []]
var test_performed: bool = false

func reset_puzzle():
	poisoned_bottle = randi() % bottle_count
	rats_drinking = [[], [], []]
	for i in range(rat_count):
		rats_drinking[i] = []
	test_performed = false

# Thêm bình vào danh sách uống của chuột
func add_drink(rat_index: int, bottle_index: int):
	if test_performed: return
	if not bottle_index in rats_drinking[rat_index]:
		rats_drinking[rat_index].append(bottle_index)

# Xóa bình khỏi danh sách uống của chuột
func remove_drink(rat_index: int, bottle_index: int):
	if test_performed: return
	rats_drinking[rat_index].erase(bottle_index)

# Thực hiện thử độc
func perform_test() -> Array:
	test_performed = true
	
	# KIỂM TRA TÍNH TOÀN VẸN (Bắt buộc 8 bình phải có 8 tổ hợp duy nhất)
	var all_patterns = {}
	var is_strategy_perfect = true
	for i in range(bottle_count):
		var p = _get_pattern_for_bottle(i)
		var p_str = str(p)
		if all_patterns.has(p_str):
			is_strategy_perfect = false
			break
		all_patterns[p_str] = i
		
	if not is_strategy_perfect:
		# Nếu chiến thuật không hoàn hảo, linh hồn sẽ "tráo" bình độc 
		# hoặc làm kết quả trở nên vô nghĩa để người chơi không thể thắng
		print("[DEBUG] Logic: Chiến thuật quá sơ sài. Hệ thống kích hoạt chế độ Trừng Phạt.")
		return [] # Không con nào chết hoặc kết quả không giúp ích gì
		
	# Chỉ khi chiến thuật hoàn hảo mới cho ra kết quả đúng
	var dead_rats = []
	for i in range(rat_count):
		if poisoned_bottle in rats_drinking[i]:
			dead_rats.append(i)
	return dead_rats

# Kiểm tra xem bình người chơi chọn có đúng là bình độc không
func check_answer(selected_bottle: int) -> bool:
	if not test_performed: return false
	
	# Kiểm tra lại tính hoàn hảo của chiến thuật một lần nữa
	var all_patterns = {}
	for i in range(bottle_count):
		var p = _get_pattern_for_bottle(i)
		var p_str = str(p)
		if all_patterns.has(p_str):
			return false # Luôn thua nếu chiến thuật không duy nhất cho cả 8 bình
		all_patterns[p_str] = i
		
	return selected_bottle == poisoned_bottle

# Lấy danh sách tất cả các bình có thể là bình độc dựa trên kết quả chuột chết hiện tại
func get_possible_bottles() -> Array:
	if not test_performed: return []
	
	var possible = []
	var current_dead_pattern = _get_pattern_for_bottle(poisoned_bottle)
	
	for i in range(bottle_count):
		var pattern = _get_pattern_for_bottle(i)
		if pattern == current_dead_pattern:
			possible.append(i)
	return possible

# Hàm hỗ trợ lấy tổ hợp chuột chết nếu bình 'bottle_idx' là độc
func _get_pattern_for_bottle(bottle_idx: int) -> Array:
	var pattern = []
	for rat_idx in range(rat_count):
		if bottle_idx in rats_drinking[rat_idx]:
			pattern.append(rat_idx)
	return pattern
