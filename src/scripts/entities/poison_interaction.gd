extends StaticBody3D

@export var puzzle_ui_scene: PackedScene = preload("res://src/ui/puzzles/poison_puzzle_ui.tscn")
@export var mice_required: int = 3

var seeded_mice: int = 0

func _ready():
	if PoisonManager:
		PoisonManager.puzzle_finished.connect(_on_puzzle_finished)

func _on_puzzle_finished(won: bool):
	if won:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_item"):
			player.add_item("poison_vase", 1, "Bình Thuốc Độc")
			if DialogueManager:
				DialogueManager.show_text("Mình đã tìm ra bình chứa thuốc độc thực sự. Đây rồi!")

var prompt_text: String = ""

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	# Kiểm tra xem cửa đã mở chưa
	var door = get_tree().root.find_child("House3_DoorInteract", true, false)
	var is_door_locked = door and door.get("is_locked")
	
	if is_door_locked:
		prompt_text = "Tương tác"
		return
	
	# Kiểm tra xem người chơi có đang cầm chuột trên tay không
	var is_holding_mouse = false
	var hotbar = player.get_node_or_null("HUD/Hotbar")
	if hotbar:
		var selected_idx = hotbar.selected_slot
		if selected_idx < InventoryManager.items.size():
			if InventoryManager.items[selected_idx].item_id == "mouse":
				is_holding_mouse = true
	
	# Cập nhật dòng chữ hướng dẫn linh hoạt
	if seeded_mice < mice_required:
		if is_holding_mouse:
			prompt_text = "Chuột trái: Bỏ chuột vào bình (" + str(seeded_mice) + "/" + str(mice_required) + ")"
		else:
			prompt_text = "Cần 3 con chuột (" + str(seeded_mice) + "/" + str(mice_required) + ")"
	else:
		prompt_text = "Bắt đầu giải đố (E)"

func add_mouse():
	seeded_mice += 1
	print("DEBUG: Da nạp chuột ", seeded_mice, "/", mice_required)

func open_puzzle():
	if PoisonManager:
		print("DEBUG: Goi PoisonManager.open_puzzle()")
		PoisonManager.open_puzzle()
	else:
		print("ERROR: Khong tim thay PoisonManager!")

func interact():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	# Nếu đã đủ chuột, mở Puzzle luôn
	if seeded_mice >= mice_required:
		var q_manager = get_node_or_null("/root/QuestSystem")
		if q_manager:
			q_manager.complete_quest()
		open_puzzle()
		return

	# 1. Kiểm tra cửa đã mở chưa
	var door = get_tree().root.find_child("House3_DoorInteract", true, false)
	if door and door.get("is_locked"):
		if DialogueManager:
			DialogueManager.show_text("Ở đây có 8 cái bình.")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Hình như ở trong có chứa thứ nước gì đó...")
			await DialogueManager.dialogue_finished
		return

	# 2. Kiểm tra số lượng chuột
	var mice_count = 0
	if player.has_method("get_item_count"):
		mice_count = player.get_item_count("mouse")
	else:
		mice_count = player.get("mice_count") if "mice_count" in player else 0

	if mice_count < mice_required:
		if DialogueManager:
			DialogueManager.show_text("Cần tìm thứ gì đó để thử độc.")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Lúc nãy mình có thấy vài con chuột...")
			GameState.is_rat_hunt_unlocked = true
			var q_manager = get_node_or_null("/root/QuestSystem")
			if q_manager:
				q_manager.start_quest("find_rats", "TÌM 3 CON CHUỘT", 3)
	else:
		# 3. Mở trò chơi giải độc
		if puzzle_ui_scene:
			var puzzle = puzzle_ui_scene.instantiate()
			get_tree().root.add_child(puzzle)
			if player.has_method("set_movement_enabled"):
				player.set_movement_enabled(false)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
