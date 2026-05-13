extends CanvasLayer

signal closed

@onready var control_root = $Control
@onready var content_label = %ContentLabel
@onready var title_label = %TitleLabel
@onready var paper_texture = %PaperTexture

var is_open: bool = false
var pages: Array = []
var current_page_index: int = 0

func _ready() -> void:
	control_root.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed("ui_cancel"):
			close()
		elif event.is_action_pressed("interact"):
			# Nếu còn trang tiếp theo, lật trang. Nếu hết trang, đóng.
			if current_page_index < pages.size() - 1:
				next_page()
			else:
				close()
		elif event.is_action_pressed("ui_right"):
			next_page()
		elif event.is_action_pressed("ui_left"):
			prev_page()

## Mở giao diện xem chi tiết (Hỗ trợ 1 trang hoặc nhiều trang)
func open(title: String, content_or_pages: Variant) -> void:
	is_open = true
	title_label.text = title
	
	if content_or_pages is Array:
		pages = content_or_pages
	else:
		pages = [content_or_pages]
	
	current_page_index = 0
	_update_page_display()
	
	# Hiện UI và khóa game
	control_root.show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Hiệu ứng hiện ra nhẹ nhàng
	control_root.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(control_root, "modulate:a", 1.0, 0.3)

func _update_page_display():
	if pages.size() > 0:
		content_label.text = pages[current_page_index]
		
		# Cập nhật Footer để hiển thị số trang nếu có nhiều hơn 1 trang
		var footer = control_root.get_node_or_null("CenterContainer/PaperTexture/MarginContainer/VBoxContainer/Footer")
		if footer:
			if pages.size() > 1:
				footer.text = "[Trang " + str(current_page_index + 1) + "/" + str(pages.size()) + "] - [Nhấn E để lật, Esc để đóng]"
			else:
				footer.text = "[Nhấn E hoặc Esc để đóng]"

func next_page():
	if current_page_index < pages.size() - 1:
		current_page_index += 1
		_play_flip_effect()
		_update_page_display()

func prev_page():
	if current_page_index > 0:
		current_page_index -= 1
		_play_flip_effect()
		_update_page_display()

func _play_flip_effect():
	# Hiệu ứng nháy nhẹ khi lật trang
	var tween = create_tween()
	content_label.modulate.a = 0.5
	tween.tween_property(content_label, "modulate:a", 1.0, 0.1)

func close() -> void:
	is_open = false
	var tween = create_tween()
	tween.tween_property(control_root, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	control_root.hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	closed.emit()

