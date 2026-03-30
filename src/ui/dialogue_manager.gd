extends CanvasLayer

signal dialogue_finished

@onready var label: RichTextLabel = $Control/NinePatchRect/RichTextLabel
@onready var panel: NinePatchRect = $Control/NinePatchRect
@onready var timer: Timer = $Timer
@onready var next_indicator: Label = $Control/NinePatchRect/NextIndicator

var typing_speed: float = 0.05
var message_queue: Array = []
var is_active: bool = false
var current_tween: Tween = null

func _ready() -> void:
	panel.hide()
	next_indicator.hide()
	label.visible_ratio = 0.0

func _input(event: InputEvent) -> void:
	# Bỏ qua hoặc chuyển tiếp câu hội thoại khi nhấn E, CLICK chuột hoặc SPACE
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if is_active:
			if label.visible_ratio < 1.0:
				# Nếu chữ chưa chạy xong, bấm để hiện toàn bộ chữ ngay lập tức
				if current_tween: current_tween.kill()
				label.visible_ratio = 1.0
				next_indicator.show()
			else:
				# Nếu chữ đã hiện xong, bấm lần nữa để xem câu tiếp theo
				_display_next_message()

## Thêm lời thoại vào hàng đợi để hiển thị (Mặc định hiện lâu hơn để đọc: 6.0 giây)
func show_text(content: String, duration: float = 6.0) -> void:
	message_queue.append({"content": content, "duration": duration})
	
	if not is_active:
		_display_next_message()

func _display_next_message() -> void:
	if message_queue.is_empty():
		_hide_dialogue()
		return
	
	var data = message_queue.pop_front()
	is_active = true
	panel.modulate.a = 1.0
	panel.show()
	next_indicator.hide() # Giấu nút trong khi đang gõ
	label.text = "[center]" + data["content"] + "[/center]"
	label.visible_ratio = 0.0
	
	# Hủy Timer cũ
	timer.stop()
	
	# Chạy hiệu ứng gõ chữ
	current_tween = create_tween()
	var duration_calc = data["content"].length() * typing_speed
	current_tween.tween_property(label, "visible_ratio", 1.0, duration_calc)
	
	# Sau khi gõ xong thì hiện cái hướng dẫn [Space]
	await current_tween.finished
	if is_active: 
		next_indicator.show()
	
	# Sau khi gõ xong thì mới bắt đầu đếm ngược thời gian tự ẩn (Dài hơn cho người dùng dễ đọc)
	timer.wait_time = data["duration"]
	timer.one_shot = true
	timer.start()

func _hide_dialogue() -> void:
	is_active = false
	next_indicator.hide()
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	await tween.finished
	panel.hide()
	panel.modulate.a = 1.0
	message_queue.clear()
	dialogue_finished.emit()

func _on_timer_timeout() -> void:
	# Nếu không ai bấm gì thì tự ẩn hoặc chuyển tiếp
	if is_active:
		_display_next_message()
