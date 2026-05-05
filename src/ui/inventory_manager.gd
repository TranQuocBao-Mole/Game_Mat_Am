extends Node

signal item_added(item: ItemData)
signal item_removed(item_id: String)
signal inventory_updated()
signal inventory_toggled(is_open: bool)

var items: Array[ItemData] = []
var is_open: bool = false

func _ready() -> void:
	# Đảm bảo trình quản lý luôn hoạt động ngay cả khi game bị Paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	elif is_open and event.is_action_pressed("ui_cancel"):
		toggle_inventory()

func toggle_inventory() -> void:
	is_open = !is_open
	
	# Pause/Unpause the game
	get_tree().paused = is_open
	
	# Handle mouse cursor
	if is_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	inventory_toggled.emit(is_open)

func add_item(item: ItemData) -> void:
	items.append(item)
	item_added.emit(item)
	inventory_updated.emit()
	print("Đã nhặt vật phẩm: ", item.item_name)

func remove_item(item_id: String) -> void:
	for i in range(items.size()):
		if items[i].item_id == item_id:
			remove_item_at(i)
			break

func remove_item_at(index: int) -> void:
	if index >= 0 and index < items.size():
		var item = items[index]
		items.remove_at(index)
		item_removed.emit(item.item_id)
		inventory_updated.emit()

func has_item(item_id: String) -> bool:
	for item in items:
		if item.item_id == item_id:
			return true
	return false
