class_name InkPuzzleLogic
extends Object

signal puzzle_solved(won: bool)
signal puzzle_updated

# Định nghĩa các loại mực
enum InkColor { RED, YELLOW, BLUE, POISON_GREEN, BLACK, OLD_BLOOD }

var bottle_data = [] # Array of Dictionary {id: int, true_color: InkColor}
var target_color: InkColor = InkColor.RED
var attempts_left: int = 3
var selected_bottles = [] # Chỉ số các lọ đang được chọn (tối đa 2)

func setup_puzzle():
	bottle_data.clear()
	selected_bottles.clear()
	attempts_left = 3
	
	# Danh sách 6 màu mực thật sự
	var true_colors = [
		InkColor.RED, 
		InkColor.YELLOW, 
		InkColor.BLUE, 
		InkColor.POISON_GREEN, 
		InkColor.BLACK, 
		InkColor.OLD_BLOOD
	]
	true_colors.shuffle() # Xáo trộn vị trí các màu thật
	
	for i in range(6):
		bottle_data.append({
			"id": i,
			"true_color": true_colors[i]
		})
	
	target_color = InkColor.RED # Luôn luôn tìm màu ĐỎ THẬT
	puzzle_updated.emit()

func select_bottle(index: int):
	if selected_bottles.has(index):
		selected_bottles.erase(index)
	elif selected_bottles.size() < 2:
		selected_bottles.append(index)
	puzzle_updated.emit()

func mix_ink() -> Color:
	if selected_bottles.size() != 2:
		return Color.TRANSPARENT
	
	if attempts_left <= 0:
		return Color.TRANSPARENT
		
	attempts_left -= 1
	var c1 = bottle_data[selected_bottles[0]].true_color
	var c2 = bottle_data[selected_bottles[1]].true_color
	
	var result = get_mixed_color_value(c1, c2)
	
	selected_bottles.clear()
	puzzle_updated.emit()
	
	return result

func get_mixed_color_value(c1: InkColor, c2: InkColor) -> Color:
	var color_map = {
		InkColor.RED: Color.RED,
		InkColor.YELLOW: Color.YELLOW,
		InkColor.BLUE: Color.BLUE,
		InkColor.POISON_GREEN: Color.GREEN,
		InkColor.BLACK: Color.BLACK,
		InkColor.OLD_BLOOD: Color(0.4, 0, 0) # Màu máu khô (Đỏ thẫm)
	}
	
	var v1 = color_map[c1]
	var v2 = color_map[c2]
	
	# Logic pha màu: Trung bình cộng và làm đậm màu một chút
	var mixed = v1.lerp(v2, 0.5)
	
	# Nếu một trong hai là Đen, màu kết quả sẽ bị kéo về phía tối rất mạnh
	if c1 == InkColor.BLACK or c2 == InkColor.BLACK:
		mixed = mixed.lerp(Color.BLACK, 0.6)
	
	mixed.a = 1.0
	return mixed

func check_guess(index: int) -> bool:
	var is_correct = bottle_data[index].true_color == target_color
	puzzle_solved.emit(is_correct)
	return is_correct
