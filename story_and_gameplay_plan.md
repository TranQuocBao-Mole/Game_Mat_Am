# MẮT ÂM - KẾ HOẠCH SỰ KIỆN CUỐI (END EVENT)

## 1. Cốt truyện & Bước ngoặt (The Twist)
Sau khi xem bản tin về kẻ sát nhân hàng loạt **Trần Quốc Minh** trên TV, nhân vật chính đột ngột nhận ra một sự thật kinh hoàng: **Chính mình là kẻ sát nhân đó.** Những mảnh ký ức vụn vỡ từ nhật ký và các linh hồn vây quanh bắt đầu khớp lại với nhau.

## 2. Kịch bản Sự kiện (Event Script)
1.  **Kích hoạt**: Người chơi xem hết Video Kênh 3 trên TV.
2.  **Hội thoại**: Dòng chữ xuất hiện: *"Trần Quốc Minh... không phải là tên mình sao?"*
3.  **Hành động**: 
    - Người chơi bị cưỡng ép quay lưng lại phía sau (hoặc màn hình chớp tắt).
    - Node `EndEvent` được bật `visible = true`.
    - Toàn bộ các thực thể xuất hiện bao vây.

## 3. Danh sách Thực thể trong `EndEvent`
Mọi thực thể sẽ được gom vào một Node3D cha để dễ dàng quản lý (Bật/Tắt đồng loạt).

| Thực thể | Vị trí đặt sẵn | Trạng thái ban đầu |
| :--- | :--- | :--- |
| **Ma rình (Stalker)** | Ngoài cửa nhà kho | Invisible (Tàng hình) |
| **Krasue** | Khu vực sân chính | Invisible (Tàng hình) |
| **Người que (Stickman)** | Chặn cổng làng | Invisible (Tàng hình) |
| **Ma nữ (Lady Ghost)** | Cạnh Máy hát (Phonograph) | Invisible (Tàng hình) |
| **Black Entity** | Góc tối phía sau người chơi | Invisible (Tàng hình) |

## 4. Triển khai kỹ thuật
- **Trigger**: Sử dụng tín hiệu `finished` của `VideoStreamPlayer` trong `tv_interaction.gd`.
- **Visibility**: Điều khiển thuộc tính `visible` của node `EndEvent`.
- **Dialogue**: Gọi `DialogueManager.show_text()` ngay sau khi video kết thúc.

---
*Kế hoạch này thay thế các nội dung cũ và tập trung vào trải nghiệm kinh dị cao trào cuối Scene 3.*
