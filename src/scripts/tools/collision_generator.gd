@tool
extends Node3D

## If true, collisions will be generated for all MeshInstance3D children at runtime or in editor if possible.
@export var auto_generate_collisions: bool = true

func _ready() -> void:
	if auto_generate_collisions:
		_process_node(self)

func _process_node(node: Node) -> void:
	if node is MeshInstance3D:
		_create_collision_for_mesh(node)
	
	for child in node.get_children():
		_process_node(child)

func _create_collision_for_mesh(mesh_instance: MeshInstance3D) -> void:
	# Check if collision already exists
	for child in mesh_instance.get_children():
		if child is StaticBody3D:
			return
			
	if mesh_instance.mesh:
		var static_body = StaticBody3D.new()
		mesh_instance.add_child(static_body)
		
		var collision_shape = CollisionShape3D.new()
		# For indoor scenes/houses, trimesh (concave) is usually best as it handles interiors correctly.
		collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
		static_body.add_child(collision_shape)
		
		# print("Generated collision for: ", mesh_instance.name)
