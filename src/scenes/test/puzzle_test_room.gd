extends Control

@onready var candle_puzzle = $CanvasLayer/CandlePuzzleUI
@onready var elements_puzzle = $CanvasLayer/ElementsPuzzleUI
@onready var lock_puzzle = $CanvasLayer/CombinationLockUI
@onready var log_label = $LogLabel

func _ready():
	_setup_test_ui()
	log_label.text = "PHÒNG THỬ NGHIỆM CÂU ĐỐ\n[1] Nến | [2] Ngũ Hành | [3] Cân Xu | [4] Vẽ Bùa | [5] Thử Độc"
	
	candle_puzzle.puzzle_finished.connect(_on_puzzle_finished.bind("Xếp Nến"))
	elements_puzzle.puzzle_finished.connect(_on_puzzle_finished.bind("Ngũ Hành"))
	if has_node("/root/CoinManager"):
		get_node("/root/CoinManager").puzzle_finished.connect(_on_puzzle_finished.bind("Cân Xu"))
	if has_node("/root/TalismanManager"):
		get_node("/root/TalismanManager").puzzle_finished.connect(_on_puzzle_finished.bind("Vẽ Bùa"))
	if has_node("/root/PoisonManager"):
		get_node("/root/PoisonManager").puzzle_finished.connect(_on_puzzle_finished.bind("Thử Độc"))
	lock_puzzle.puzzle_finished.connect(_on_puzzle_finished.bind("Ổ Khóa"))

func _setup_test_ui():
	# Làm cho các nút trong phòng test trông xịn hơn và hỗ trợ điều khiển phím
	var test_buttons = [$VBoxContainer/TestCandle, $VBoxContainer/TestElements, $VBoxContainer/TestCoin, $VBoxContainer/TestTalisman]
	if has_node("VBoxContainer/TestPoison"):
		test_buttons.append($VBoxContainer/TestPoison)
	if has_node("VBoxContainer/TestLock"):
		test_buttons.append($VBoxContainer/TestLock)
		
	for btn in test_buttons:
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
	# Kiểm tra thêm các puzzle autoload
	if has_node("/root/CoinManager") and get_node("/root/CoinManager").visible: return
	if has_node("/root/TalismanManager") and get_node("/root/TalismanManager").visible: return
	if has_node("/root/PoisonManager") and get_node("/root/PoisonManager").visible: return
	if lock_puzzle.visible: return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_on_test_candle_pressed()
		elif event.keycode == KEY_2:
			_on_test_elements_pressed()
		elif event.keycode == KEY_3:
			_on_test_coin_pressed()
		elif event.keycode == KEY_4:
			_on_test_talisman_pressed()
		elif event.keycode == KEY_5:
			_on_test_poison_pressed()
		elif event.keycode == KEY_6:
			_on_test_lock_pressed()

func _on_test_candle_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Xếp Nến..."
	candle_puzzle.open_puzzle()

func _on_test_elements_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Ngũ Hành..."
	elements_puzzle.open_puzzle()

func _on_test_coin_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Cân Xu..."
	if has_node("/root/CoinManager"):
		get_node("/root/CoinManager").open_puzzle()

func _on_test_talisman_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Vẽ Bùa..."
	if has_node("/root/TalismanManager"):
		get_node("/root/TalismanManager").open_puzzle()

func _on_test_poison_pressed():
	log_label.text = "Đang kiểm tra: Câu đố Thử Độc..."
	if has_node("/root/PoisonManager"):
		get_node("/root/PoisonManager").open_puzzle()

func _on_test_lock_pressed():
	log_label.text = "Đang kiểm tra: Ổ khóa (Mã: 97529)..."
	lock_puzzle.open_puzzle()

func _on_puzzle_finished(won: bool, puzzle_name: String):
	if won:
		log_label.text = "CHÚC MỪNG! Giải xong [" + puzzle_name + "]\n[1-5] Thử lại các câu đố"
		log_label.modulate = Color.GOLD
	else:
		log_label.text = "PHÒNG THỬ NGHIỆM CÂU ĐỐ\n[1] Nến | [2] Ngũ Hành | [3] Cân Xu | [4] Vẽ Bùa | [5] Thử Độc | [6] Ổ Khóa"
		log_label.modulate = Color.WHITE
