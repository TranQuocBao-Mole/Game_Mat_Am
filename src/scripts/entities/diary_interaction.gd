extends StaticBody3D

@export var prompt_text: String = "Xem nhật ký"
@export var diary_pages: Array[String] = [
	"30/2/2024.\n\nLại thêm một người nữa. Tôi đã mất dấu số lượng rồi, hay là tôi chỉ đang giả vờ quên?",
	"Họ đều giống nhau khi im lặng. Những gương mặt thanh tú, những mái tóc dài... giờ đây đều trở thành một phần của bộ sưu tập trong tâm trí tôi.",
	"Căn phòng này đầy rẫy những hơi thở đã tắt. Tôi có thể nghe thấy tiếng họ thì thầm khi gió rít qua khe cửa.\n\nTại sao họ lại nhìn tôi như vậy? Những đôi mắt vô hồn đó...",
	"Mỗi lần kết thúc, tôi lại thấy mình trống rỗng hơn. Giống như một cái hố không đáy đang dần nuốt chửng chút ánh sáng cuối cùng còn sót lại.",
	"Thế giới ngoài kia vẫn đang tìm kiếm 'kẻ thủ ác'. Họ gọi tôi là ác quỷ.\n\nNhưng nếu tôi là ác quỷ, thì tại sao tôi lại thấy mình đau đớn đến thế này?\n\nNgười tiếp theo... sẽ là ai?"
]

func interact():
	if InspectManager:
		InspectManager.open("Nhật ký cũ", diary_pages)
		GameState.is_diary_read = true
	else:
		print("InspectManager not found!")

