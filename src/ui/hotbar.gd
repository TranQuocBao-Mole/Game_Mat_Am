extends Control

@onready var grid = $HBoxContainer
@onready var selector = $Selector # Một cái Frame để highlight ô đang chọn

var selected_slot: int = 0
var slot_count: int = 9

func _ready():
	# Kết nối trực tiếp với Singleton cho ổn định
	InventoryManager.item_added.connect(_on_item_updated)
	InventoryManager.inventory_updated.connect(update_hotbar)
	print("DEBUG: Hotbar đã kết nối với InventoryManager")
	
	update_hotbar()
	update_selector()

func _input(event):
	# Chọn ô bằng phím số 1-9
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			selected_slot = event.keycode - KEY_1
			update_selector()
	
	# Chọn ô bằng con lăn chuột
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			selected_slot = (selected_slot - 1 + slot_count) % slot_count
			update_selector()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			selected_slot = (selected_slot + 1) % slot_count
			update_selector()

func update_selector():
	# Di chuyển khung chọn đến vị trí ô tương ứng
	var target_slot = grid.get_child(selected_slot)
	if target_slot:
		selector.global_position = target_slot.global_position

func update_hotbar():
	# Xóa các ô cũ (nếu có) và tạo mới hoặc cập nhật
	# Trong thực tế, chúng ta sẽ lặp qua 9 ô và gán dữ liệu từ InventoryManager
	var inventory_items = InventoryManager.items
	
	for i in range(slot_count):
		var slot = grid.get_child(i)
		var icon_rect = slot.get_node("Icon")
		var count_label = slot.get_node("Count")
		
		if i < inventory_items.size():
			var item = inventory_items[i]
			icon_rect.texture = item.icon
			icon_rect.show()
			# Hiển thị số thứ tự (1, 2, 3...) thay vì số lượng
			count_label.text = str(i + 1)
			count_label.show()
		else:
			icon_rect.hide()
			count_label.hide()

func _on_item_updated(_item):
	update_hotbar()
