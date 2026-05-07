extends "res://src/scripts/common/interactable_node.gd"

@export var video_path: String = "res://assets/videos/tv_video1.ogv"
@export var video_player: VideoStreamPlayer
@export var screen_mesh: MeshInstance3D
@export var sub_viewport: SubViewport
@export var krasue: Node3D
@export var channels: Array[String] = [
	"res://assets/videos/tv_video1.ogv",
	"res://assets/videos/tv_video2.ogv",
	"res://assets/videos/7609746668175.ogv",
	"res://assets/videos/tv_video1.ogv",
	"res://assets/videos/tv_video2.ogv"
]

var current_channel: int = 0
var _first_time: bool = true
var _is_transitioning: bool = false
var _is_on: bool = false
var _scare_triggered: bool = false
var _tv_ui: CanvasLayer = null
var _channel_number_label: Label = null
var _channel_fraction_label: Label = null
var _channel_boxes: Array[Label] = []

func _ready() -> void:
	super._ready()
	
	if screen_mesh and sub_viewport:
		var tex = sub_viewport.get_texture()
		var mat = screen_mesh.get_active_material(0)
		if mat:
			var new_mat = mat.duplicate()
			new_mat.albedo_texture = tex
			new_mat.emission_enabled = true
			new_mat.emission_texture = tex
			new_mat.emission_energy_multiplier = 1.0
			screen_mesh.set_surface_override_material(0, new_mat)
	
	if video_player and video_path != "":
		var stream = load(video_path)
		if !stream:
			stream = load("res://assets/videos/7609746668175.ogv")
		if stream:
			video_player.stream = stream
	
	if krasue:
		krasue.visible = false
	
	_create_tv_ui()

func _create_tv_ui():
	_tv_ui = CanvasLayer.new()
	_tv_ui.layer = 105
	add_child(_tv_ui)
	
	# Neo ở góc dưới bên trái (Bottom Left)
	var margin_box = MarginContainer.new()
	margin_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	margin_box.add_theme_constant_override("margin_bottom", 50)
	margin_box.add_theme_constant_override("margin_left", 50)
	_tv_ui.add_child(margin_box)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.9) # Đen nhám
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.4, 0.5)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 20
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)
	margin_box.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	# --- Top Row ---
	var top_hbox = HBoxContainer.new()
	vbox.add_child(top_hbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "📺 CHUYỂN KÊNH"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0)) # Xanh lơ
	top_hbox.add_child(title_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)
	
	_channel_fraction_label = Label.new()
	_channel_fraction_label.text = "1 / " + str(channels.size())
	_channel_fraction_label.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(_channel_fraction_label)
	
	# --- Separator 1 ---
	var sep1 = ColorRect.new()
	sep1.custom_minimum_size = Vector2(0, 1)
	sep1.color = Color(1, 1, 1, 0.2)
	vbox.add_child(sep1)
	
	# --- Second Row (Điều hướng) ---
	var mid_hbox = HBoxContainer.new()
	vbox.add_child(mid_hbox)
	
	var left_btn = Label.new()
	left_btn.text = "◀ [A]"
	left_btn.add_theme_font_size_override("font_size", 16)
	mid_hbox.add_child(left_btn)
	
	_channel_number_label = Label.new()
	_channel_number_label.text = "KÊNH: 1"
	_channel_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_channel_number_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_channel_number_label.add_theme_font_size_override("font_size", 20)
	mid_hbox.add_child(_channel_number_label)
	
	var right_btn = Label.new()
	right_btn.text = "[D] ▶"
	right_btn.add_theme_font_size_override("font_size", 16)
	mid_hbox.add_child(right_btn)
	
	# --- Third Row (Danh sách ô vuông Kênh) ---
	var boxes_hbox = HBoxContainer.new()
	boxes_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	boxes_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(boxes_hbox)
	
	_channel_boxes.clear()
	for i in range(channels.size()):
		var box = Label.new()
		box.text = str(i + 1)
		box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.custom_minimum_size = Vector2(40, 40)
		box.add_theme_font_size_override("font_size", 18)
		
		var box_style = StyleBoxFlat.new()
		box_style.corner_radius_top_left = 6
		box_style.corner_radius_top_right = 6
		box_style.corner_radius_bottom_left = 6
		box_style.corner_radius_bottom_right = 6
		box.add_theme_stylebox_override("normal", box_style)
		
		boxes_hbox.add_child(box)
		_channel_boxes.append(box)
		
	# --- Separator 2 ---
	var sep2 = ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.color = Color(1, 1, 1, 0.2)
	vbox.add_child(sep2)
	
	# --- Bottom Row ---
	var exit_lbl = Label.new()
	exit_lbl.text = "Nhấn [ E ] để Tắt TV"
	exit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_lbl.add_theme_font_size_override("font_size", 16)
	exit_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(exit_lbl)
	
	_tv_ui.visible = false
	_update_ui_state()

func _update_ui_state():
	if _channel_fraction_label:
		_channel_fraction_label.text = str(current_channel + 1) + " / " + str(channels.size())
	if _channel_number_label:
		_channel_number_label.text = "KÊNH:  " + str(current_channel + 1)
		
	for i in range(_channel_boxes.size()):
		var box = _channel_boxes[i]
		var style = box.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			if i == current_channel:
				style.bg_color = Color(0.4, 0.8, 1.0) # Màu xanh lơ cho kênh hiện tại
				box.add_theme_color_override("font_color", Color.BLACK)
			else:
				style.bg_color = Color(0.25, 0.25, 0.25) # Xám mờ cho kênh chưa chọn
				box.add_theme_color_override("font_color", Color.WHITE)

func _input(event: InputEvent) -> void:
	if !_is_on or _is_transitioning: return
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo():
		if event.keycode == KEY_D or event.keycode == KEY_RIGHT:
			_switch_channel(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_A or event.keycode == KEY_LEFT:
			_switch_channel(-1)
			get_viewport().set_input_as_handled()

func _switch_channel(direction: int):
	current_channel = (current_channel + direction) % channels.size()
	if current_channel < 0: current_channel = channels.size() - 1
	
	_update_ui_state()
	
	# Hiệu ứng chớp trắng khi chuyển kênh
	_play_channel_flash()
	
	_play_video_only()

func _play_channel_flash():
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.6) # Trắng mờ
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tv_ui.add_child(flash)
	
	var t = create_tween()
	t.tween_property(flash, "color:a", 0.0, 0.1)
	t.finished.connect(flash.queue_free)

func _play_video_only():
	if video_player:
		var stream = load(channels[current_channel])
		if stream:
			video_player.stream = stream
			video_player.paused = false
			video_player.play()
	if screen_mesh:
		screen_mesh.visible = true
	if _tv_ui:
		_tv_ui.visible = true

func _process(_delta: float) -> void:
	if _is_on and video_player:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dist = global_position.distance_to(player.global_position)
			var max_dist = 400.0
			
			if dist > max_dist:
				video_player.volume_db = -80
			else:
				var vol = lerp(0.0, -40.0, dist / max_dist)
				video_player.volume_db = vol

func interact():
	if !is_active or _is_transitioning: return
	
	var player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
	
	if video_player:
		if _is_on:
			_is_on = false
			video_player.stop()
			if _tv_ui: _tv_ui.visible = false
			DialogueManager.show_text("Bạn đã tắt TV.")
			if screen_mesh:
				screen_mesh.visible = false
			
			if !_scare_triggered:
				_trigger_krasue_scare(player)
			else:
				if player and player.has_method("set_movement_enabled"):
					player.set_movement_enabled(true)
				_cooldown_interaction()
		else:
			_is_on = true
			_handle_tv_view(player)
			_cooldown_interaction()

func _trigger_krasue_scare(player):
	_scare_triggered = true
	_is_transitioning = true
	
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(false)
	
	# 1. Giật đỏ màn hình
	_play_scare_effect()
	
	# 2. Krasue xuất hiện tĩnh
	if krasue:
		krasue.visible = true
	
	await get_tree().create_timer(0.6).timeout
	
	# 3. Đẩy lùi người chơi 70m
	if player:
		var head = player.get_node_or_null("Head")
		var back_dir = head.global_transform.basis.z if head else player.global_transform.basis.z
		back_dir.y = 0
		back_dir = back_dir.normalized()
		
		var target_pos = player.global_position + back_dir * 70.0
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", target_pos, 1.0)
		
		if krasue:
			var anim = krasue.get_node_or_null("AnimationPlayer")
			if anim:
				if anim.has_animation("0"): anim.play("0")
				else: 
					var list = anim.get_animation_list()
					if list.size() > 0: anim.play(list[0])
	
	await get_tree().create_timer(2.0).timeout
	
	# 4. Krasue lao nhanh tới điểm dừng chuẩn xác
	if krasue:
		var target_rush_pos = Vector3(-768.1047, 32.43712, 778.4689)
		krasue.rotation_degrees = Vector3(0, -60.7, 0) # Xoay hướng chuẩn
		
		var rush_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		rush_tween.tween_property(krasue, "global_position", target_rush_pos, 0.5)
		await rush_tween.finished
		
		# TẮT HOÀN TOÀN ANIMATION NGAY KHI TỚI ĐÍCH
		var anim = krasue.get_node_or_null("AnimationPlayer")
		if anim:
			anim.stop() # Dừng animation hiện tại
			anim.active = false # Vô hiệu hóa máy phát animation hoàn toàn
			
	# Đợi 1 giây để người chơi nhìn rõ khuôn mặt ma sát camera
	await get_tree().create_timer(1.0).timeout
	
	# 5. Kết thúc sự kiện
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	var black = ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black)
	
	if krasue:
		krasue.visible = false # Ma biến mất
	
	await get_tree().create_timer(1.5).timeout
	
	var fade_out = get_tree().create_tween()
	fade_out.tween_property(black, "color:a", 0.0, 1.0)
	await fade_out.finished
	canvas.queue_free()
	
	# Mở khóa người chơi để tiếp tục game
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(true)
		
	_is_transitioning = false

func _play_scare_effect():
	var flash_canvas = CanvasLayer.new()
	flash_canvas.layer = 102
	get_tree().root.add_child(flash_canvas)
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(0.8, 0.0, 0.0, 0.5) 
	flash_canvas.add_child(flash_rect)
	var tween = get_tree().create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.3)
	tween.finished.connect(func(): flash_canvas.queue_free())

func _cooldown_interaction():
	_is_transitioning = true
	await get_tree().create_timer(0.3).timeout
	_is_transitioning = false

func _handle_tv_view(player):
	_is_transitioning = true
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	var black = ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black)
	
	var tween_in = get_tree().create_tween()
	tween_in.tween_property(black, "color:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	await tween_in.finished
	
	if player:
		player.global_position = Vector3(-712.6735, 90.5281, 744.7459)
		player.rotation_degrees = Vector3(0, 0, 0)
		var head = player.get_node_or_null("Head")
		if head:
			head.rotation_degrees = Vector3(0, -58.9, 0)
			var mouse_look = player.get_node_or_null("Head/MouseLook")
			if mouse_look and "yaw" in mouse_look:
				mouse_look.yaw = -58.9
		
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(false)
	
	await get_tree().create_timer(0.3).timeout
	_play_video_only()
	
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(black, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	await tween_out.finished
	
	canvas.queue_free()
	_first_time = false
	_is_transitioning = false
	DialogueManager.show_text("TV đang phát một đoạn phim cũ...")
