extends "res://src/scripts/common/interactable_node.gd"

@export var interaction_range: float = 3.0

func interact():
	if !is_active: return
	
	if GameState.is_coin_puzzle_solved:
		if DialogueManager:
			DialogueManager.show_text("Một cái cân và vài đồng xu.")
		return
		
	print("[DEBUG] Tương tác cân.")
	print(" - lock_opened: ", GameState.lock_opened)
	print(" - chess: ", GameState.is_chess_puzzle_solved)
	print(" - candle: ", GameState.is_candle_puzzle_solved)
	print(" - elements: ", GameState.is_elements_puzzle_solved)
	
	var door = get_tree().root.find_child("House3_DoorInteract", true, false)
	var is_door_unlocked = door and not door.get("is_locked")
	print(" - door_unlocked (physical): ", is_door_unlocked)
	
	if GameState.lock_opened or is_door_unlocked:
		if CoinManager:
			CoinManager.open_puzzle()
		else:
			var cm = get_node_or_null("/root/CoinManager")
			if cm:
				cm.open_puzzle()
			else:
				DialogueManager.show_text("Lỗi: Không tìm thấy CoinManager!")
	else:
		DialogueManager.show_text("Một cái cân và 7 đồng xu.")
