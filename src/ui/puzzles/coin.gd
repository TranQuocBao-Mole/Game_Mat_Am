extends TextureRect

var coin_index: int = -1

func _ready():
	# Đảm bảo TextureRect có thể nhận tương tác chuột
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _get_drag_data(_at_position):
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(80, 80)
	preview.modulate.a = 0.7
	
	var lbl = Label.new()
	lbl.text = get_child(0).text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_color_override("font_color", Color(0.7, 0, 0, 1))
	lbl.add_theme_font_size_override("font_size", 24)
	preview.add_child(lbl)
	
	set_drag_preview(preview)
	return self

func _gui_input(event):
	# Xử lý chuột phải để đoán ở ngay trong node xu cho chắc chắn
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var manager = get_tree().root.find_child("CoinPuzzleUI", true, false)
		if not manager:
			# Nếu không tìm thấy bằng tên, thử tìm qua Autoload
			manager = get_node("/root/CoinManager")
			
		if manager and manager.has_method("_guess_coin"):
			manager._guess_coin(self)
