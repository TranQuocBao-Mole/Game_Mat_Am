extends CanvasLayer

const SLOT_SCENE = preload("res://src/ui/inventory_slot.tscn")

@onready var list_container = %ItemList
@onready var detail_name = %DetailName
@onready var detail_desc = %DetailDescription
@onready var detail_icon = %DetailIcon
@onready var control_root = $Control

var current_selected_index: int = 0

func _ready() -> void:
	control_root.hide()
	control_root.modulate.a = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	InventoryManager.inventory_toggled.connect(_on_inventory_toggled)
	InventoryManager.item_added.connect(_on_item_added)
	
	_refresh_list()

func _on_inventory_toggled(is_open: bool) -> void:
	var tween = create_tween()
	if is_open:
		_refresh_list()
		control_root.show()
		tween.tween_property(control_root, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(control_root, "scale", Vector2.ONE, 0.3).from(Vector2(0.95, 0.95))
		
		# Focus first item after a short delay
		await get_tree().create_timer(0.1).timeout
		if list_container.get_child_count() > 0:
			list_container.get_child(0).grab_focus()
	else:
		tween.tween_property(control_root, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		control_root.hide()

func _on_item_added(_item: ItemData) -> void:
	if control_root.visible:
		_refresh_list()

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()
	
	for i in range(InventoryManager.items.size()):
		var item = InventoryManager.items[i]
		var slot = SLOT_SCENE.instantiate()
		list_container.add_child(slot)
		
		# Set icon
		var icon_node = slot.get_node("%Icon")
		if icon_node:
			icon_node.texture = item.icon
		
		# Connect signals
		slot.focus_entered.connect(_on_slot_focused.bind(i, item))
		slot.pressed.connect(_on_slot_pressed.bind(item))
	
	if InventoryManager.items.size() == 0:
		_clear_details()
	else:
		_show_item_details(InventoryManager.items[0])

func _on_slot_focused(index: int, item: ItemData) -> void:
	current_selected_index = index
	_show_item_details(item)
	
	# Subtle focus animation
	var slot = list_container.get_child(index)
	var tween = create_tween()
	tween.tween_property(slot, "scale", Vector2(1.1, 1.1), 0.1)
	slot.pivot_offset = slot.size / 2

func _on_slot_pressed(item: ItemData) -> void:
	# Action for when item is selected (e.g. use or inspect)
	print("Vật phẩm được chọn: ", item.item_name)

func _show_item_details(item: ItemData) -> void:
	detail_name.text = item.item_name
	detail_desc.text = item.description
	detail_icon.texture = item.icon
	
	# Animate detail entry
	var tween = create_tween()
	detail_name.modulate.a = 0
	detail_desc.modulate.a = 0
	detail_icon.modulate.a = 0
	detail_icon.scale = Vector2(0.8, 0.8)
	
	tween.tween_property(detail_icon, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(detail_icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(detail_name, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(detail_desc, "modulate:a", 1.0, 0.2)

func _clear_details() -> void:
	detail_name.text = "HÀNH TRANG TRỐNG"
	detail_desc.text = "Bạn chưa tìm thấy vật phẩm nào."
	detail_icon.texture = null
