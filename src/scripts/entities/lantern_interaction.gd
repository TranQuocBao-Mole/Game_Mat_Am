extends "res://src/scripts/common/interactable_node.gd"

func _ready() -> void:
	# Gọi lại hàm cha để đảm bảo logic ẩn/hiện hoạt động
	super._ready()

func interact() -> void:
	if !is_active: return
	
	if DialogueManager:
		DialogueManager.show_text("Một chiếc đèn lồng đỏ treo giữa đường...")
		DialogueManager.show_text("Ai lại treo đèn lồng ở đây nhỉ?")
