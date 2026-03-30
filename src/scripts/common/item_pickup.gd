extends StaticBody3D

@export var item_data: ItemData
@export var prompt_text: String = "Nhặt vật phẩm"

func _ready() -> void:
	# Đảm bảo vật thể ở đúng layer để Raycast của Player có thể chạm tới
	collision_layer = 2 # Giả định layer 2 là layer tương tác

func interact() -> void:
	if item_data:
		InventoryManager.add_item(item_data)
		# Tùy chọn: Hiển thị thông báo nhỏ hoặc phát âm thanh ở đây
		queue_free() # Xóa vật thể khỏi thế giới sau khi nhặt
	else:
		print("Lỗi: Vật thể này chưa được gán ItemData!")
