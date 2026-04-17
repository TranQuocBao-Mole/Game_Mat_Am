extends Node

class_name ElementsPuzzleLogic

signal puzzle_solved
signal conflict_occurred(pos1, pos2)
signal out_of_sanity

enum Element { NONE, METAL, WATER, WOOD, FIRE, EARTH }

var element_names = {
    Element.NONE: "?",
    Element.METAL: "Kim",
    Element.WATER: "Thủy",
    Element.WOOD: "Mộc",
    Element.FIRE: "Hỏa",
    Element.EARTH: "Thổ"
}

var slots: Array = [] # Lưu các Element hiện tại ở 5 vị trí
var max_sanity: int = 5
var current_sanity: int = 5
var moves_left: int = 15

# Cặp tương sinh: [Kim, Thủy], [Thủy, Mộc], [Mộc, Hỏa], [Hỏa, Thổ], [Thổ, Kim]
var generation_pairs = [[1, 2], [2, 3], [3, 4], [4, 5], [5, 1]]

# Cặp tương khắc: [Hỏa, Kim], [Kim, Mộc], [Mộc, Thổ], [Thổ, Thủy], [Thủy, Hỏa]
var conflict_pairs = [[4, 1], [1, 3], [3, 5], [5, 2], [2, 4]]

func setup_puzzle():
    randomize()
    slots = [Element.METAL, Element.WATER, Element.WOOD, Element.FIRE, Element.EARTH]
    
    # Xáo trộn cho đến khi không phải trạng thái thắng
    while is_solved():
        slots.shuffle()
        
    current_sanity = max_sanity
    moves_left = 15

func swap_elements(idx_a: int, idx_b: int):
    if moves_left <= 0: return
    
    var temp = slots[idx_a]
    slots[idx_a] = slots[idx_b]
    slots[idx_b] = temp
    
    moves_left -= 1
    _check_for_conflicts()
    
    if is_solved():
        puzzle_solved.emit()
    elif current_sanity <= 0:
        out_of_sanity.emit()

func _check_for_conflicts():
    # Kiểm tra các cặp kề nhau trong vòng tròn
    for i in range(5):
        var e1 = slots[i]
        var e2 = slots[(i + 1) % 5]
        
        if is_conflict_pair(e1, e2):
            current_sanity -= 1
            conflict_occurred.emit(i, (i + 1) % 5)

func is_link_valid(e1: Element, e2: Element) -> bool:
    if e1 == Element.NONE or e2 == Element.NONE: return false
    # Chỉ chấp nhận tương sinh theo chiều Thuận (Kim -> Thủy)
    for p in generation_pairs:
        if e1 == p[0] and e2 == p[1]:
            return true
    return false

func is_conflict_pair(e1: Element, e2: Element) -> bool:
    for p in conflict_pairs:
        if (e1 == p[0] and e2 == p[1]) or (e1 == p[1] and e2 == p[0]):
            return true
    return false

func is_solved() -> bool:
    # Tất cả các mắt xích phải là tương sinh chuẩn theo chiều kim đồng hồ
    for i in range(5):
        if not is_link_valid(slots[i], slots[(i+1)%5]):
            return false
    return true
