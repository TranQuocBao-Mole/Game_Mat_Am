@tool
extends Node3D

@export var tint_color: Color = Color(0.7, 0.6, 0.4, 1):
	set(value):
		tint_color = value
		apply_tint()

func _ready():
	apply_tint()

func apply_tint():
	_tint_recursive(self)

func _tint_recursive(node: Node):
	if node is MeshInstance3D:
		# Tạo bản sao vật liệu để không ảnh hưởng đến các vật thể khác dùng chung
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_surface_override_material(i)
			if mat:
				var new_mat = mat.duplicate()
				if "albedo_color" in new_mat:
					new_mat.albedo_color = tint_color
				node.set_surface_override_material(i, new_mat)
				
		# Nếu chưa có override, lấy material gốc của mesh
		if node.mesh:
			for i in range(node.mesh.get_surface_count()):
				var mat = node.get_surface_override_material(i)
				if not mat:
					mat = node.mesh.surface_get_material(i)
				
				if mat:
					var new_mat = mat.duplicate()
					if "albedo_color" in new_mat:
						new_mat.albedo_color = tint_color
					node.set_surface_override_material(i, new_mat)
					
	for child in node.get_children():
		_tint_recursive(child)
