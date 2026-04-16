extends CanvasLayer

signal time_set(hour: int, minute: int)

var current_hour: int = 0
var current_minute: int = 0

@onready var hour_label = $Panel/VBoxContainer/HourContainer/HourLabel
@onready var minute_label = $Panel/VBoxContainer/MinuteContainer/MinuteLabel

func _ready():
	hide()

func show_clock_ui(start_hour: int, start_minute: int):
	current_hour = start_hour
	current_minute = start_minute
	update_labels()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_clock_ui():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_labels():
	hour_label.text = "%02d" % current_hour
	minute_label.text = "%02d" % current_minute

func _on_hour_plus_pressed():
	current_hour = (current_hour + 1) % 24
	update_labels()

func _on_hour_minus_pressed():
	current_hour = (current_hour - 1 + 24) % 24
	update_labels()

func _on_minute_plus_pressed():
	current_minute = (current_minute + 5) % 60
	update_labels()

func _on_minute_minus_pressed():
	current_minute = (current_minute - 5 + 60) % 60
	update_labels()

func _on_confirm_pressed():
	time_set.emit(current_hour, current_minute)
	hide_clock_ui()

func _on_cancel_pressed():
	hide_clock_ui()
