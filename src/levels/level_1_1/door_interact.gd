extends StaticBody3D

@export var prompt_text = "Mở cửa"
var is_open = false
var initial_rotation_y: float

func _ready():
	initial_rotation_y = rotation.y

func interact():
	var tween = create_tween()
	if not is_open:
		# Mở cửa xoay 90 độ
		tween.tween_property(self, "rotation:y", initial_rotation_y + deg_to_rad(90), 0.5).set_trans(Tween.TRANS_SINE)
		prompt_text = "Đóng cửa"
	else:
		# Đóng cửa về vị trí cũ
		tween.tween_property(self, "rotation:y", initial_rotation_y, 0.5).set_trans(Tween.TRANS_SINE)
		prompt_text = "Mở cửa"
	
	is_open = !is_open
