extends Node

const SAVE_PATH = "user://savegame.json"

signal save_completed
signal load_completed

var _last_saved_scene: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Tắt process lúc đầu nếu không cần, nhưng ở đây ta dùng nó để theo dõi scene
	set_process(true)

func _process(_delta: float) -> void:
	var current = get_tree().current_scene
	if current and current.scene_file_path != "" and current.scene_file_path != _last_saved_scene:
		# Đợi thêm 1 frame để đảm bảo scene load xong mọi thứ
		call_deferred("auto_save")

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	if has_save_file():
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(SAVE_PATH.get_file())
			print("[SaveManager] Đã xóa file save cũ.")

func auto_save():
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Không lưu nếu đang ở Main Menu hoặc scene không hợp lệ
	if current_scene_path == "" or "main_menu" in current_scene_path.to_lower():
		return
		
	# Tránh lưu liên tục cùng một scene
	if current_scene_path == _last_saved_scene:
		return
		
	_last_saved_scene = current_scene_path
	
	var save_data = {
		"meta": {
			"save_time": Time.get_datetime_string_from_system(),
			"scene": current_scene_path
		}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		save_completed.emit()
		print("[SaveManager] Auto-saved at scene: ", current_scene_path)
	else:
		printerr("[SaveManager] Failed to auto-save!")

var _is_loading: bool = false

func load_game():
	if _is_loading: return
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(json_string)
		if data != null and data.has("meta") and data.meta.has("scene"):
			_is_loading = true
			var target_scene = data.meta.scene
			if target_scene != "" and target_scene != get_tree().current_scene.scene_file_path:
				get_tree().change_scene_to_file(target_scene)
			
			load_completed.emit()
			_is_loading = false
			print("[SaveManager] Loaded game at scene: ", target_scene)
		else:
			printerr("[SaveManager] Invalid save data structure.")
