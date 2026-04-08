@tool
extends MeshInstance3D

@export_group("Settings")
@export var dress_color: Color = Color.WHITE:
	set(value):
		dress_color = value
		if is_inside_tree():
			apply_color()

@export var auto_apply: bool = true

func _ready() -> void:
	apply_color()

## Hàm này sẽ nhuộm màu cho TOÀN BỘ các surface của cái váy này
func apply_color() -> void:
	# Lấy số lượng surface
	var surface_count = get_surface_override_material_count()
	if surface_count == 0 and mesh:
		surface_count = mesh.get_surface_count()
	
	for i in range(surface_count):
		# Lấy material hiện tại
		var mat = get_surface_override_material(i)
		if not mat and mesh:
			mat = mesh.surface_get_material(i)
		
		if mat:
			# Nhuộm màu bất chấp (Standard hoặc ORM)
			var new_mat = mat.duplicate()
			if "albedo_color" in new_mat:
				new_mat.albedo_color = dress_color
			elif "albedo" in new_mat:
				new_mat.albedo = dress_color
				
			set_surface_override_material(i, new_mat)
			print("DEBUG: Da nhuom mau vay cho: ", name, " sang màu ", dress_color)
		else:
			# Trường hợp chưa có vât liệu thì tạo mới
			var new_mat = StandardMaterial3D.new()
			new_mat.albedo_color = dress_color
			set_surface_override_material(i, new_mat)
			print("DEBUG: Tao vat lieu moi màu ", dress_color, " cho ", name)
