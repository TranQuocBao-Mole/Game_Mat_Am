extends StaticBody3D

@export var prompt_text: String = "Nhìn tờ lịch"

func interact():
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		dm.show_text("[Bạn]: Ai lại để tấm lịch ở đây nhỉ?")
		dm.show_text("[Bạn]: Tháng 7 năm 1985... Lâu quá rồi.")
