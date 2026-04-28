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

# Thực hiện thử độc, trả về danh sách các con chuột bị chết (rat_index)
func perform_test() -> Array:
	test_performed = true
	var dead_rats = []
	for i in range(rat_count):
		if poisoned_bottle in rats_drinking[i]:
			dead_rats.append(i)
	return dead_rats

# Kiểm tra xem bình người chơi chọn có đúng là bình độc không
func check_answer(selected_bottle: int) -> bool:
	if not test_performed: return false
	return selected_bottle == poisoned_bottle
