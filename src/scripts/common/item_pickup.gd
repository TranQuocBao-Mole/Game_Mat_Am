extends "res://src/scripts/common/interactable_node.gd"

@export var item_data: ItemData

func _ready() -> void:
	super._ready()
	if not item_data:
		print("WARNING: [ItemPickup] item_data is NULL on ", name)

func interact() -> void:
	if !is_active: return
	
	if item_data:
		InventoryManager.add_item(item_data)
		queue_free()
	else:
		print("Lỗi: Vật thể này chưa được gán ItemData! Node: ", name)
