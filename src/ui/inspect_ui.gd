extends CanvasLayer

signal closed

@onready var control_root = $Control
@onready var content_label = %ContentLabel
@onready var title_label = %TitleLabel
@onready var paper_texture = %PaperTexture

var is_open: bool = false

func _ready() -> void:
	control_root.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
			close()

## Mở giao diện xem chi tiết
## title: Tiêu đề (ví dụ: "Luật chơi")
## content: Nội dung văn bản
func open(title: String, content: String) -> void:
	is_open = true
	title_label.text = title
	content_label.text = content
	
	# Hiện UI và khóa game
	control_root.show()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Hiệu ứng hiện ra nhẹ nhàng
	control_root.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(control_root, "modulate:a", 1.0, 0.3)

func close() -> void:
	is_open = false
	var tween = create_tween()
	tween.tween_property(control_root, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	control_root.hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	closed.emit()
