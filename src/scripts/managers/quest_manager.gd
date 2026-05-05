extends Node

signal quest_updated(text: String)
signal quest_completed()

var current_quest_id: String = ""
var current_quest_title: String = ""
var current_progress: int = 0
var goal_count: int = 0
var is_quest_active: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_quest(id: String, title: String, goal: int = 0):
	current_quest_id = id
	current_quest_title = title
	current_progress = 0
	goal_count = goal
	is_quest_active = true
	_refresh_ui()
	print("QUEST STARTED: ", id, " - ", title)

func update_progress(amount: int):
	if not is_quest_active: return
	current_progress = amount
	_refresh_ui()

func _refresh_ui():
	quest_updated.emit(get_display_text())

func get_display_text() -> String:
	var display_text = current_quest_title
	if goal_count > 0:
		display_text += " (" + str(current_progress) + "/" + str(goal_count) + ")"
	return display_text

func complete_quest():
	if not is_quest_active: return
	is_quest_active = false
	quest_completed.emit()
	print("QUEST COMPLETED: ", current_quest_id)
