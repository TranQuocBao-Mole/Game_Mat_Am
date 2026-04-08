@tool
extends EditorScenePostImport

func _post_import(scene):
	# Danh sách các vật liệu đã tạo sẵn
	var mat_body = load("res://assets/models/lady_of_the_asylum/materials/mat_body.tres")
	var mat_dress = load("res://assets/models/lady_of_the_asylum/materials/mat_dress.tres")
	var mat_hair = load("res://assets/models/lady_of_the_asylum/materials/mat_hair.tres")
	var mat_eyes = load("res://assets/models/lady_of_the_asylum/materials/mat_eyes.tres")
	
	apply_materials(scene, mat_body, mat_dress, mat_hair, mat_eyes)
	return scene

func apply_materials(node: Node, body, dress, hair, eyes):
	if node is MeshInstance3D:
		# Lấy số lượng surface (mặt) của Mesh
		var surface_count = node.get_surface_override_material_count()
		if surface_count == 0 and node.mesh:
			surface_count = node.mesh.get_surface_count()
			
		for i in range(surface_count):
			var n = node.name.to_lower()
			# Thử lấy tên vật liệu của surface để gán chính xác hơn
			var mat_name = ""
			if node.mesh:
				var original_mat = node.mesh.surface_get_material(i)
				if original_mat:
					mat_name = original_mat.resource_name.to_lower()
			
			# Logic gán vật liệu thông minh
			if "eyes" in n or "eye" in n or "pupil" in n or "cornea" in n or "eyes" in mat_name or "eye" in mat_name:
				# Đảm bảo không gán nhầm cho tóc (đôi khi tóc có tên "eyebrow")
				if not "hair" in n and not "hair" in mat_name:
					node.set_surface_override_material(i, eyes)
			elif "dress" in n or "dress" in mat_name:
				node.set_surface_override_material(i, dress)
			elif "hair" in n or "hair" in mat_name or "plane" in n:
				node.set_surface_override_material(i, hair)
			elif "body" in n or "mesh" in n or "scary" in n or "body" in mat_name or "face" in mat_name:
				# Nếu nó là thân hoặc mặt
				node.set_surface_override_material(i, body)
				
	for child in node.get_children():
		apply_materials(child, body, dress, hair, eyes)
