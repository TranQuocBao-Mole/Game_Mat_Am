extends SceneTree

func _init():
	var main_root = root
	var black = main_root.find_child("black", true, false)
	if black:
		print("FOUND BLACK: ", black.get_path(), " at ", black.global_position if black is Node3D else "N/A")
	else:
		print("BLACK NOT FOUND")
	
	var runningman = root.find_child("runningman", true, false)
	if runningman:
		print("FOUND RUNNINGMAN: ", runningman.get_path(), " at ", runningman.global_position)
	
	quit()
