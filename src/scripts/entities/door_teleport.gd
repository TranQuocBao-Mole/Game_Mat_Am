extends StaticBody3D

@export var prompt_text: String = "Kiểm tra cửa"
@export var is_locked: bool = true
@export var combination_lock_scene: PackedScene

@export_group("Teleport Points")
@export var outside_marker: Marker3D
@export var inside_marker: Marker3D
@export var lock_model: Node3D # Kéo model ổ khóa vào đây

var is_player_inside: bool = false

func _ready():
	if combination_lock_scene == null:
		combination_lock_scene = load("res://src/ui/puzzles/combination_lock_ui.tscn")
	_update_prompt()

func _update_prompt():
	if is_locked:
		prompt_text = "Cửa đang khóa (Cần mã số)"
	elif is_player_inside:
		prompt_text = "Rời khỏi"
	else:
		prompt_text = "Mở cửa đi vào"

func interact():
	if is_locked:
		open_lock_puzzle()
	else:
		toggle_teleport()

func open_lock_puzzle():
	if combination_lock_scene:
		var puzzle_instance = combination_lock_scene.instantiate()
		var cl = CanvasLayer.new()
		cl.layer = 100
		get_tree().root.add_child(cl)
		cl.add_child(puzzle_instance)
		
		if puzzle_instance.has_method("open_puzzle"):
			puzzle_instance.open_puzzle()
		
		puzzle_instance.puzzle_finished.connect(_on_lock_finished)
	else:
		print("[ERROR] Không tìm thấy scene ổ khóa!")

func _on_lock_finished(won: bool):
	if won:
		is_locked = false
		_update_prompt()
		
		# Ẩn mô hình ổ khóa
		if lock_model:
			lock_model.visible = false
			# Hoặc dùng lock_model.queue_free() nếu muốn xóa hẳn
			
		if DialogueManager:
			DialogueManager.show_text("Tiếng 'Cạch' vang lên. Cửa đã có thể mở được.")

func toggle_teleport():
	var target = inside_marker if not is_player_inside else outside_marker
	if target == null:
		print("[ERROR] Chưa gán marker dịch chuyển!")
		return
		
	teleport_player(target)

func teleport_player(target: Marker3D):
	# Hiệu ứng Fade
	var fade_scene = load("res://src/ui/fade_layer.tscn")
	var fade_instance = fade_scene.instantiate()
	get_tree().root.add_child(fade_instance)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_movement_enabled(false)
	
	await fade_instance.fade_to_black(0.6)
	
	if player:
		player.global_position = target.global_position
		player.global_rotation.y = target.global_rotation.y
		# Cập nhật trạng thái trong/ngoài
		is_player_inside = !is_player_inside
		_update_prompt()
		
		# Di chuyển cả điểm tương tác theo người chơi để luôn bấm được? 
		# Cách tốt hơn: Chỉ cần 1 điểm tương tác tĩnh ở cửa, nhưng người chơi ở trong vẫn bấm được (nếu cửa rỗng)
		# Hoặc để điểm tương tác này ở giữa cánh cửa để bấm được từ cả 2 phía.
	
	await get_tree().create_timer(0.2).timeout
	await fade_instance.fade_from_black(0.6)
	
	if player:
		player.set_movement_enabled(true)
	fade_instance.queue_free()
