extends StaticBody3D

@export var prompt_text: String = "Sử dụng tờ bùa"

func _process(_delta):
	var count = 0
	if InventoryManager.has_item("brush"): count += 1
	if InventoryManager.has_item("poison_vase"): count += 1
	if InventoryManager.has_item("coin"): count += 1
	if InventoryManager.has_item("red_paint_bottle"): count += 1
	
	if count < 4:
		prompt_text = "Cần vật phẩm để vẽ bùa (" + str(count) + "/4)"
	else:
		prompt_text = "Bắt đầu vẽ bùa (E)"

func interact():
	if DialogueManager:
		DialogueManager.show_text("Một tờ giấy bùa cổ xưa...")
		await DialogueManager.dialogue_finished
		DialogueManager.show_text("...dường như nó dùng để phong ấn thứ gì đó.")
		await DialogueManager.dialogue_finished
		DialogueManager.show_text("Trên đó ghi cần một lọ thuốc độc và đồng xu bạc hiến tế...")
		await DialogueManager.dialogue_finished
		DialogueManager.show_text("...cần được vẽ bằng mực đỏ.")
		await DialogueManager.dialogue_finished
	
	var missing_items = []
	
	if not InventoryManager.has_item("brush"):
		missing_items.append("Cây bút")
	if not InventoryManager.has_item("poison_vase"):
		missing_items.append("Bình thuốc độc")
	if not InventoryManager.has_item("coin"):
		missing_items.append("Đồng tiền")
	if not InventoryManager.has_item("red_paint_bottle"):
		missing_items.append("Lọ mực đỏ")
	
	if missing_items.size() > 0:
		if DialogueManager:
			var missing_str = ""
			for i in range(missing_items.size()):
				missing_str += missing_items[i]
				if i < missing_items.size() - 1:
					missing_str += ", "
			
			DialogueManager.show_text("Hiện tại mình vẫn còn thiếu: " + missing_str)
		return

	# Nếu đã đủ đồ, mở puzzle
	if DialogueManager:
		DialogueManager.show_text("Mọi thứ đã sẵn sàng. Linh hồn đang gào thét... đã đến lúc kết thúc chuyện này.")
		await DialogueManager.dialogue_finished
		
	if TalismanManager:
		TalismanManager.open_puzzle()
	else:
		print("TalismanManager (Autoload) not found")
