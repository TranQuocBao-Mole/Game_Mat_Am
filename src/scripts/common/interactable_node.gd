extends StaticBody3D

@export var prompt_text: String = "Tương tác"
@export var is_active: bool = true : set = _set_active

# Ghi nhớ layer ban đầu từ Editor
@onready var _original_layer = collision_layer

func _ready() -> void:
	_update_state()

func _set_active(value: bool) -> void:
	is_active = value
	if is_node_ready():
		_update_state()

func _update_state() -> void:
	visible = is_active
	# Tắt va chạm ở lớp vật lý (Layer) để RayCast đi xuyên qua
	collision_layer = _original_layer if is_active else 0
	
	# Tìm và tắt vùng va chạm (CollisionShape)
	var shapes = find_children("*", "CollisionShape3D", true, false)
	for shape in shapes:
		shape.set_deferred("disabled", !is_active)
