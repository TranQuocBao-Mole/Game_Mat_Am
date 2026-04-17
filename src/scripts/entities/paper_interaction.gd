@tool
extends StaticBody3D

@export var prompt_text: String = "Đọc luật"
@export var mesh_material: Material = preload("res://assets/models/paper/paper_material.tres"):
	set(value):
		mesh_material = value
		_apply_material_recursive(self)
@export_multiline var rules_content: String = "Luật chơi Cờ Tướng:\n1. Mỗi bên có 16 quân: Tướng, Sĩ, Tượng, Xe, Pháo, Mã, Tốt.\n2. Tướng chỉ đi trong Cung, mỗi lần 1 ô dọc/ngang.\n3. Sĩ đi chéo 1 ô trong Cung.\n4. Tượng đi chéo 2 ô (hình điền), không qua sông.\n5. Xe đi ngang/dọc vô hạn nếu không bị cản.\n6. Pháo đi như Xe, nhưng muốn ăn quân phải nhảy qua 1 quân khác.\n7. Mã đi hình chữ L, có thể bị cản (cản chân Mã).\n8. Tốt đi thẳng, qua sông mới được đi ngang.\n9. Mục tiêu: Chiếu bí Tướng đối phương."

func _ready():
	_apply_material_recursive(self)

func _apply_material_recursive(node: Node):
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			node.set_surface_override_material(i, mesh_material)
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				node.set_surface_override_material(i, mesh_material)
	for child in node.get_children():
		_apply_material_recursive(child)

func interact():
	if InspectManager:
		InspectManager.open("Luật chơi Cờ Tướng", rules_content)
	else:
		print("InspectManager not found!")
