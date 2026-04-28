extends Control

@onready var candle_puzzle = $CanvasLayer/CandlePuzzleUI
@onready var elements_puzzle = $CanvasLayer/ElementsPuzzleUI
@onready var log_label = $LogLabel

func _ready():
	_setup_test_ui()
	log_label.text = "PHÒNG THỬ NGHIỆM CÂU ĐỐ\n[1] Nến | [2] Ngũ Hành | [3] Cân Xu | [4] Vẽ Bùa"
	
	candle_puzzle.puzzle_finished.connect(_on_puzzle_finished.bind("Xếp Nến"))
	elements_puzzle.puzzle_finished.connect(_on_puzzle_finished.bind("Ngũ Hành"))
	if has_node("/root/CoinManager"):
		get_node("/root/CoinManager").puzzle_finished.connect(_on_puzzle_finished.bind("Cân Xu"))
	if has_node("/root/TalismanManager"):
		get_node("/root/TalismanManager").puzzle_finished.connect(_on_puzzle_finished.bind("Vẽ Bùa"))

func _setup_test_ui():
	# Làm cho các nút trong phòng test trông xịn hơn và hỗ trợ điều khiển phím
	for btn in [$VBoxContainer/TestCandle, $VBoxContainer/TestElements, $VBoxContainer/TestCoin, $VBoxContainer/TestTalisman]:
		btn.focus_mode = Control.FOCUS_ALL
		var sb_focus = StyleBoxFlat.new()
		sb_focus.draw_center = false
		sb_focus.set_border_width_all(2)
		sb_focus.border_color = Color(1, 0.8, 0.2) # Viền vàng sang trọng khi chọn bằng phím
		btn.add_theme_stylebox_override("focus", sb_focus)

func _input(event):
	# Nếu đang chơi puzzle thì không nhận phím chọn game
	if candle_puzzle.visible or elements_puzzle.visible:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_on_test_candle_pressed()
		elif event.keycode == KEY_2:
			_on_test_elements_pressed()
		elif event.keycode == KEY_3:
			_on_test_coin_pressed()
		elif event.keycode == KEY_4:
			_on_test_talisman_pressed()

func _on_test_candle_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Xếp Nến..."
	candle_puzzle.open_puzzle()

func _on_test_elements_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Ngũ Hành..."
	elements_puzzle.open_puzzle()

func _on_test_coin_pressed():
	print("[DEBUG] TestRoom: Coin button pressed")
	log_label.text = "Đang kiểm tra: Câu đố Cân Xu..."
	if has_node("/root/CoinManager"):
		print("[DEBUG] TestRoom: Found /root/CoinManager")
		get_node("/root/CoinManager").open_puzzle()
	else:
		print("[ERR] TestRoom: /root/CoinManager NOT FOUND!")

func _on_test_talisman_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Vẽ Bùa..."
	if has_node("/root/TalismanManager"):
		get_node("/root/TalismanManager").open_puzzle()

func _on_puzzle_finished(won: bool, puzzle_name: String):
	if won:
		log_label.text = "CHÚC MỪNG! Giải xong [" + puzzle_name + "]\n[1] Thử lại nến | [2] Thử lại Ngũ hành"
		log_label.modulate = Color.GOLD
	else:
		log_label.text = "PHÒNG THỬ NGHIỆM\n[1] Nến | [2] Ngũ Hành | [3] Cân Xu | [4] Vẽ Bùa"
		log_label.modulate = Color.WHITE
