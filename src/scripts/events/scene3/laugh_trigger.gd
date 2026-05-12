extends Area3D

@export var krasue_node: Node3D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		print("[DEBUG-KRASUE] Player vào vùng LaughTrigger - Bật tiếng cười")
		if krasue_node:
			krasue_node.is_laughing_enabled = true

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		print("[DEBUG-KRASUE] Player rời vùng LaughTrigger - Tắt tiếng cười")
		if krasue_node:
			krasue_node.is_laughing_enabled = false
