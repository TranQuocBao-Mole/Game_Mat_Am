extends CanvasLayer

@onready var prompt_label = $Control/CenterContainer/HBoxContainer/PromptLabel
@onready var key_label = $Control/CenterContainer/HBoxContainer/KeyLabel

func _ready():
	hide_prompt()

func set_prompt(text: String, key: String = "E"):
	if key_label: key_label.text = "[%s]" % key
	if prompt_label: prompt_label.text = text
	show()

func hide_prompt():
	hide()
