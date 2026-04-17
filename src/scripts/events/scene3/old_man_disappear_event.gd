extends Node3D

## Scene 3 Event: Old man disappearance dialogue
## Triggered 2 seconds after entering the scene

@export_group("Configuration")
@export var dialogue_delay: float = 2.0 ## Thời gian chờ trước khi hiện thoại (giây)
@export var auto_unlock_after_dialogue: bool = true ## Tự mở khóa di chuyển sau khi thoại xong

var _player: CharacterBody3D = null
var _event_triggered: bool = false

func _ready() -> void:
	print("DEBUG: [Scene3Event] Script loaded, waiting...")
	
	# Tự động ẩn đèn house3_light3 và tờ giấy khi bắt đầu scene
	var target_light = get_tree().root.find_child("house3_light3", true, false)
	if target_light:
		target_light.visible = false
		print("DEBUG: [Scene3Event] house3_light3 has been hidden.")

	var paper_chess = get_tree().root.find_child("PaperEventChess", true, false)
	if paper_chess:
		paper_chess.visible = false
		print("DEBUG: [Scene3Event] PaperEventChess has been hidden.")
	
	# Tìm player trong scene
	await get_tree().create_timer(0.5).timeout
	_player = _find_player()
	
	print("DEBUG: [Scene3Event] Player found: ", _player != null)

	if _player:
		print("DEBUG: [Scene3Event] Waiting ", dialogue_delay, " seconds before dialogue...")
		# Chờ 2 giây rồi bắt đầu event
		await get_tree().create_timer(dialogue_delay).timeout
		print("DEBUG: [Scene3Event] Delay finished, triggering event...")
		_trigger_event()
	else:
		print("LOI: Không tìm thấy Player trong Scene 3!")

func _find_player() -> CharacterBody3D:
	# Cách 1: Tìm node có group "player"
	for node in get_tree().get_nodes_in_group("player"):
		if node is CharacterBody3D:
			return node as CharacterBody3D
	
	# Cách 2: Tìm node tên "Player"
	var player_node = get_tree().root.find_child("Player", true, false)
	if player_node is CharacterBody3D:
		return player_node as CharacterBody3D
	
	return null

func _trigger_event() -> void:
	if _event_triggered:
		return
	
	_event_triggered = true
	
	# 1. Khóa người chơi
	if _player and _player.has_method("set_movement_enabled"):
		_player.set_movement_enabled(false)
	
	# 2. Hiện thoại
	if get_tree().root.has_node("DialogueManager"):
		var dm = get_tree().root.get_node("DialogueManager")
		
		dm.show_text("[Bạn]: Ông lão lúc nãy dẫn mình vào làng...")
		dm.show_text("[Bạn]: ...bây giờ đi đâu rồi không biết?")
		dm.show_text("[Bạn]: Lạ thật, vừa mới đứng đây mà...")
		
		# Đợi thoại xong
		if dm.has_signal("dialogue_finished"):
			await dm.dialogue_finished
		else:
			await get_tree().create_timer(8.0).timeout
	
	# 3. Mở khóa di chuyển
	if auto_unlock_after_dialogue and _player and _player.has_method("set_movement_enabled"):
		_player.set_movement_enabled(true)
	
	print("DEBUG: [Scene3Event] Dialogue finished. Player unlocked.")
