class_name TalismanPuzzleLogic
extends Object

signal puzzle_solved
signal puzzle_reset

# Cấu trúc đồ thị: 5 nodes, 10 edges
var nodes = [] # Array of Vector2 (positions)
var edges = [] # Array of Dictionary {from: int, to: int, visited: bool}

var current_node_idx: int = -1
var visited_edges_count: int = 0
var total_edges: int = 10

func setup_puzzle():
	nodes.clear()
	edges.clear()
	visited_edges_count = 0
	current_node_idx = -1
	
	# 1. Định nghĩa 5 Nodes (Xếp hình ngũ giác đều, thu nhỏ để vừa giấy)
	var area_center = Vector2(0, 0)
	var radius = 230
	for i in range(5):
		var angle = deg_to_rad(i * 72 - 90)
		nodes.append(area_center + Vector2(cos(angle), sin(angle)) * radius)
	
	# 2. Định nghĩa 10 Edges (Vòng ngoài + Ngôi sao bên trong)
	# Vòng ngoài (Pentagon)
	_add_edge(0, 1)
	_add_edge(1, 2)
	_add_edge(2, 3)
	_add_edge(3, 4)
	_add_edge(4, 0)
	
	# Ngôi sao (Pentagram)
	_add_edge(0, 2)
	_add_edge(2, 4)
	_add_edge(4, 1)
	_add_edge(1, 3)
	_add_edge(3, 0)

func _add_edge(a, b):
	edges.append({"from": a, "to": b, "visited": false})

func reset_puzzle():
	for edge in edges:
		edge.visited = false
	visited_edges_count = 0
	current_node_idx = -1
	puzzle_reset.emit()

func can_start_at(node_idx: int) -> bool:
	return visited_edges_count == 0

func try_move_to(next_node_idx: int) -> bool:
	if current_node_idx == -1:
		current_node_idx = next_node_idx
		return true
	
	if current_node_idx == next_node_idx:
		return false
		
	# Tìm cạnh nối giữa current và next mà chưa được visit
	for edge in edges:
		if not edge.visited:
			if (edge.from == current_node_idx and edge.to == next_node_idx) or \
			   (edge.from == next_node_idx and edge.to == current_node_idx):
				edge.visited = true
				visited_edges_count += 1
				current_node_idx = next_node_idx
				
				if visited_edges_count == total_edges:
					puzzle_solved.emit()
				return true
				
	return false # Không có đường nối hoặc đường đã đi qua rồi

func get_edge_status(a: int, b: int) -> bool:
	for edge in edges:
		if (edge.from == a and edge.to == b) or (edge.from == b and edge.to == a):
			return edge.visited
	return false

func is_solved() -> bool:
	return visited_edges_count == total_edges
