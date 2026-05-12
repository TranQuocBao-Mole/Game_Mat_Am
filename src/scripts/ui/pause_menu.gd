extends CanvasLayer

@onready var resume_btn = $Panel/VBoxContainer/ResumeBtn
@onready var save_btn = $Panel/VBoxContainer/SaveBtn
@onready var main_menu_btn = $Panel/VBoxContainer/MainMenuBtn
@onready var quit_btn = $Panel/VBoxContainer/QuitBtn

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	resume_btn.pressed.connect(_on_resume_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Thường là phím ESC
		if visible:
			_on_resume_pressed()
		else:
			# Chỉ mở Pause Menu nếu không có UI quan trọng khác đang mở (ví dụ Inventory)
			var inv = get_node_or_null("/root/InventoryManager")
			if inv and inv.is_open:
				return # Để Inventory tự xử lý việc đóng bằng ESC
				
			open()

func open():
	show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_pressed():
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_save_pressed():
	var sm = get_node_or_null("/root/SaveManager")
	if sm: sm.auto_save()
	# Có thể thêm thông báo "Đã lưu" ở đây

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")

func _on_quit_pressed():
	var sm = get_node_or_null("/root/SaveManager")
	if sm: sm.auto_save() # Tự động lưu khi thoát
	get_tree().quit()
