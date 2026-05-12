extends Node3D

func _ready():
	# Đợi một chút để màn hình load xong
	await get_tree().create_timer(1.0).timeout
	
	if DialogueManager:
		DialogueManager.show_text("Đây là đâu?")
		DialogueManager.show_text("Mình mới đi ra khỏi phòng mà?")
