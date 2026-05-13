extends StaticBody3D

@export var prompt_text: String = "Sử dụng tờ bùa"

func _process(_delta):
	var count = 0
	if InventoryManager.has_item("brush"): count += 1
	if InventoryManager.has_item("poison_vase"): count += 1
	if InventoryManager.has_item("coin"): count += 1
	if InventoryManager.has_item("red_paint_bottle"): count += 1
	
	if not GameState.is_diary_read:
		prompt_text = "Có thứ gì đó kỳ lạ về tờ bùa này... (Cần tìm hiểu thêm)"
	elif count < 4:
		prompt_text = "Cần vật phẩm để vẽ bùa (" + str(count) + "/4)"
	else:
		prompt_text = "Bắt đầu vẽ bùa (E)"

func interact():
	if not GameState.is_diary_read:
		if DialogueManager:
			DialogueManager.show_text("Mình có cảm giác tờ bùa này rất quan trọng, nhưng mình chưa hiểu cách kích hoạt nó.")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Có lẽ nên tìm kiếm thêm manh mối xung quanh đây, có thể là những ghi chép cũ...")
		return
		
	if GameState.is_talisman_puzzle_solved:
		if DialogueManager:
			DialogueManager.show_text("Phong ấn đã được mở khóa...")
		return

	# Kiểm tra 4 vật phẩm
	var count = 0
	if InventoryManager.has_item("brush"): count += 1
	if InventoryManager.has_item("poison_vase"): count += 1
	if InventoryManager.has_item("coin"): count += 1
	if InventoryManager.has_item("red_paint_bottle"): count += 1
	
	if count < 4:
		if DialogueManager:
			DialogueManager.show_text("Một tờ giấy bùa cổ xưa...")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("...dường như nó dùng để phong ấn thứ gì đó.")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Trên đó ghi cần một lọ thuốc độc và đồng xu bạc hiến tế...")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("...cần được vẽ bằng mực đỏ.")
			await DialogueManager.dialogue_finished
			DialogueManager.show_text("Tôi chưa có đủ vật phẩm để vẽ bùa.")
		return
	
	# Mở UI giải đố
	var puzzle_ui = load("res://src/ui/puzzles/talisman_puzzle_ui.tscn").instantiate()
	get_tree().root.add_child(puzzle_ui)
	puzzle_ui.open_puzzle()
	puzzle_ui.puzzle_finished.connect(_on_puzzle_finished)

func _on_puzzle_finished(won: bool):
	if won:
		InventoryManager.remove_item("brush")
		InventoryManager.remove_item("poison_vase")
		InventoryManager.remove_item("coin")
		InventoryManager.remove_item("red_paint_bottle")
		
		if DialogueManager:
			DialogueManager.show_text("Phong ấn đã được kích hoạt...")
		prompt_text = "Phong ấn đã hoàn tất."
