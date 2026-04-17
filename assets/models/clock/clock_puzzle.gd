extends StaticBody3D

## Clock Puzzle Script
## Xử lý tương tác với đồng hồ trong puzzle

@export_group("Clock Settings")
@export var clock_id: int = 1
@export var default_hour: int = 3
@export var default_minute: int = 15

var current_hour: int = 3
var current_minute: int = 15

func _ready():
	current_hour = default_hour
	current_minute = default_minute

func interact():
	_show_clock_dialogue()

func _show_clock_dialogue():
	var time_text = ""
	match clock_id:
		1:
			time_text = "2:00"
		2:
			time_text = "7:00"
		3:
			time_text = "10:00"
	
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		dm.show_text(time_text)
		
		# Clock 3 có thêm dialogue đặc biệt
		if clock_id == 3:
			dm.show_text("Quái, lại sao ai lại treo đồng hồ ngoài trời thế nhỉ?")
