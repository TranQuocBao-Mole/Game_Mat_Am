extends CanvasLayer

@onready var list_container = %ItemList
@onready var detail_name = %DetailName
@onready var detail_desc = %DetailDescription
@onready var detail_icon = %DetailIcon
@onready var control_root = $Control

func _ready() -> void:
	# Bắt đầu ở trạng thái đóng
	control_root.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Để hoạt động khi game bị Paused
	
	InventoryManager.inventory_toggled.connect(_on_inventory_toggled)
	InventoryManager.item_added.connect(_on_item_added)
	
	_refresh_list()

func _on_inventory_toggled(is_open: bool) -> void:
	if is_open:
		_refresh_list()
		control_root.show()
	else:
		control_root.hide()

func _on_item_added(_item: ItemData) -> void:
	if control_root.visible:
		_refresh_list()

func _refresh_list() -> void:
	# Xóa các mục cũ
	for child in list_container.get_children():
		child.queue_free()
	
	# Tạo danh sách mới
	for item in InventoryManager.items:
		var btn = Button.new()
		btn.text = item.item_name
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_show_item_details.bind(item))
		list_container.add_child(btn)
	
	# Xóa bảng chi tiết nếu trống
	if InventoryManager.items.size() == 0:
		_clear_details()
	elif list_container.get_child_count() > 0:
		# Tự động chọn mục đầu tiên
		_show_item_details(InventoryManager.items[0])

func _show_item_details(item: ItemData) -> void:
	detail_name.text = item.item_name
	detail_desc.text = item.description
	detail_icon.texture = item.icon

func _clear_details() -> void:
	detail_name.text = "Chọn một vật phẩm"
	detail_desc.text = ""
	detail_icon.texture = null
