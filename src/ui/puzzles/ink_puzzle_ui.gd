extends CanvasLayer

signal puzzle_finished(won: bool)

@onready var main_ui = $Control/AspectRatioContainer/MainUI
@onready var bottle_container = $Control/AspectRatioContainer/MainUI/InteractionLayer/Bottles
@onready var bowl_rect = $Control/AspectRatioContainer/MainUI/BowlArea/Bowl
@onready var status_label = $Control/AspectRatioContainer/MainUI/StatusLabel
@onready var mix_button = $Control/AspectRatioContainer/MainUI/InteractionLayer/Buttons/MixButton
@onready var guess_button = $Control/AspectRatioContainer/MainUI/InteractionLayer/Buttons/GuessButton
@onready var blood_drops = $Control/AspectRatioContainer/MainUI/BloodDrops
@onready var overlay = $Control/Overlay

var logic = InkPuzzleLogic.new()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	logic.puzzle_updated.connect(_update_ui)
	logic.puzzle_solved.connect(_on_puzzle_solved)
	visible = false
	hide()

func reset_game():
	logic.setup_puzzle()
	bowl_rect.modulate = Color(1, 1, 1, 0)
	status_label.text = ""
	status_label.modulate = Color(0.2, 0.2, 0.2, 1)
	status_label.scale = Vector2(1, 1)
	overlay.hide()
	_update_ui()

func _update_ui():
	# Cập nhật số giọt máu (HP)
	var drops = blood_drops.get_children()
	for i in range(drops.size()):
		drops[i].visible = (i < logic.attempts_left)
	
	# Update bottles visual (Hiệu ứng trồi lên)
	var wrappers = bottle_container.get_children()
	for i in range(wrappers.size()):
		var btn = wrappers[i].get_child(0) # Lấy TextureButton bên trong Control wrapper
		var is_selected = logic.selected_bottles.has(i)
		
		var tween = get_tree().create_tween()
		if is_selected:
			tween.tween_property(btn, "position:y", -30.0, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			btn.self_modulate = Color(1.2, 1.2, 1.2, 1) # Sáng lên một chút
		else:
			tween.tween_property(btn, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			btn.self_modulate = Color.WHITE

	mix_button.disabled = logic.selected_bottles.size() != 2 or logic.attempts_left <= 0
	guess_button.disabled = logic.selected_bottles.size() != 1

func _on_bottle_pressed(index: int):
	# Hiệu ứng bấm nút (nhún nhẹ)
	var btn = bottle_container.get_child(index).get_child(0)
	var tween = get_tree().create_tween()
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.05)
	
	logic.select_bottle(index)

func _on_mix_pressed():
	# Nhún nhẹ nút pha
	var tween_btn = get_tree().create_tween()
	tween_btn.tween_property(mix_button, "scale", Vector2(0.95, 0.95), 0.05)
	tween_btn.tween_property(mix_button, "scale", Vector2(1.0, 1.0), 0.05)

	var result = logic.mix_ink()
	
	# Hiệu ứng hiện vũng mực mượt mà
	var tween = get_tree().create_tween()
	bowl_rect.modulate = result
	bowl_rect.modulate.a = 0
	tween.tween_property(bowl_rect, "modulate:a", 1.0, 0.5)
	
	if logic.attempts_left == 0:
		status_label.text = "Hết lượt pha! Hãy chọn lọ bạn tin là ĐỎ."

func _on_guess_pressed():
	if logic.selected_bottles.size() == 1:
		logic.check_guess(logic.selected_bottles[0])

func _on_puzzle_solved(won: bool):
	if won:
		status_label.text = "CHÍNH XÁC! ĐÂY LÀ MÀU ĐỎ THẬT!"
		status_label.modulate = Color.RED
		var tween = get_tree().create_tween()
		tween.tween_property(status_label, "scale", Vector2(1.5, 1.5), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		# Cho lọ đúng trồi lên thật cao
		var correct_idx = -1
		for i in range(logic.bottle_data.size()):
			if logic.bottle_data[i].true_color == 0: # 0 là InkColor.RED
				correct_idx = i
				break
		if correct_idx != -1:
			var btn = bottle_container.get_child(correct_idx).get_child(0)
			var t2 = get_tree().create_tween()
			t2.tween_property(btn, "position:y", -60.0, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		_play_fail_effects()
		status_label.text = "SAI RỒI! LINH HỒN GIẬN DỮ..."
		status_label.modulate = Color.DARK_RED
	
	await get_tree().create_timer(3.0).timeout
	puzzle_finished.emit(won)
	_close()

func _close():
	hide()
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("set_movement_enabled"):
			p.set_movement_enabled(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _play_fail_effects():
	# Hiệu ứng rung màn hình
	var original_pos = main_ui.position
	var tween = get_tree().create_tween()
	for i in range(10):
		var shake_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		tween.tween_property(main_ui, "position", original_pos + shake_offset, 0.03)
	tween.tween_property(main_ui, "position", original_pos, 0.03)
	
	# Hiệu ứng chớp đỏ
	overlay.color = Color(0.8, 0, 0, 0.5)
	overlay.show()
	overlay.modulate.a = 1.0
	var t2 = get_tree().create_tween()
	t2.tween_property(overlay, "modulate:a", 0.0, 0.5)
	await t2.finished
	overlay.hide()

func open_puzzle():
	show()
	reset_game()
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("set_movement_enabled"):
			p.set_movement_enabled(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_close_pressed():
	_close()
	puzzle_finished.emit(false)
