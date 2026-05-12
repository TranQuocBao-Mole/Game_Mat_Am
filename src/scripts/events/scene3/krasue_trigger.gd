extends Area3D

@export var krasue_node: Node3D ## Node Krasue (chứa script krasue_flicker.gd)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player"):
		print("[DEBUG-KRASUE] Player vào vùng KrasueTrigger")
		if krasue_node:
			krasue_node.is_in_trigger = true

func _on_body_exited(body: Node3D):
	if body.is_in_group("player"):
		print("[DEBUG-KRASUE] Player rời vùng KrasueTrigger")
		if krasue_node:
			krasue_node.is_in_trigger = false
