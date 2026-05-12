extends Control

@onready var continue_btn = $MenuOptions/ContinueBtn
@onready var new_game_btn = $MenuOptions/NewGameBtn
@onready var quit_btn = $MenuOptions/QuitBtn

func _ready():
	# Kiểm tra xem có file save không để hiện nút Continue
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("has_save_file") and sm.has_save_file():
		continue_btn.disabled = false
		continue_btn.modulate = Color.WHITE
	else:
		continue_btn.disabled = true
		continue_btn.modulate = Color(1, 1, 1, 0.3)
	
	# Đảm bảo chuột hiển thị
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed():
	print("[MainMenu] Starting New Game...")
	
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("delete_save"):
		sm.delete_save()
	
	# 2. Reset dữ liệu trong bộ nhớ
	var gs = get_node_or_null("/root/GameState")
	if gs: gs.call("reset_state")
		
	var im = get_node_or_null("/root/InventoryManager")
	if im:
		im.items.clear()
		im.inventory_updated.emit()
		
	var qs = get_node_or_null("/root/QuestSystem")
	if qs:
		qs.call("complete_quest") # Reset quest UI
		qs.current_quest_id = ""
		qs.is_quest_active = false
		
	# 3. Chuyển đến Scene đầu tiên (Scene 1)
	get_tree().change_scene_to_file("res://src/levels/level_1_1/scene1_1.tscn")

func _on_continue_pressed():
	print("[MainMenu] Continuing Game...")
	var sm = get_node_or_null("/root/SaveManager")
	if sm: sm.load_game()

func _on_quit_pressed():
	get_tree().quit()
