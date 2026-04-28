extends Control

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func _can_drop_data(_at_position, data):
	return data is Control and data.has_meta("index")

func _drop_data(_at_position, data):
	if data.get_parent():
		# Nếu chúng ta là vùng chứa cha (CoinPool) có chứa một List bên trong
		if has_node("List"):
			data.reparent(get_node("List"))
		else:
			data.reparent(self)
		
		print("[DEBUG] Dropped coin ", data.get_meta("index"), " into ", name)
