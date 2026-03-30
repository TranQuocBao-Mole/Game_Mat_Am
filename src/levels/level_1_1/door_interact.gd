extends StaticBody3D

var unlocked := false
var prompt_text := "Mở cửa"

func interact():
	if not unlocked:
		print("Door is locked.")
		return
	print("Door opened!")
	# ... door opening logic ...


func _on_radio_interact_first_interaction_occurred() -> void:
	unlocked = true
