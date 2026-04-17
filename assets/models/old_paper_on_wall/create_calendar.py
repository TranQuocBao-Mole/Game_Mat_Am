from PIL import Image, ImageDraw, ImageFont, ImageFilter
import random
import math

# Kích thước ngang
width, height = 700, 512
img = Image.new('RGBA', (width, height), (0,0,0,0))
draw = ImageDraw.Draw(img)

# 1. Nền giấy cũ kỹ (Vàng nâu loang lổ)
# Tạo gradient nhẹ
for y in range(height):
    shade = int(180 + 30 * math.sin(y / 50))
    draw.line([(0, y), (width, y)], fill=(shade, shade-40, shade-80, 255))

# Thêm nhiễu hạt (Noise)
for _ in range(5000):
    x, y = random.randint(0, width), random.randint(0, height)
    noise_color = (random.randint(100, 160), random.randint(80, 120), random.randint(50, 90), random.randint(50, 150))
    draw.point((x, y), fill=noise_color)

# 2. Viền và Khung
# Viền ngoài mờ
draw.rectangle([5, 5, width-5, height-5], outline=(100, 70, 40, 200), width=2)
# Khung trang trí kiểu cũ
draw.rectangle([15, 15, width-15, height-15], outline=(139, 90, 43, 255), width=3)

# 3. Header (Phần trên)
# Nền header đỏ sẫm phai màu
draw.rectangle([20, 20, width-20, 130], fill=(160, 50, 50, 220))
# Viền vàng cho header
draw.rectangle([20, 20, width-20, 130], outline=(200, 180, 100, 255), width=2)

# Font chữ
try:
    font_title = ImageFont.truetype('times.ttf', 55) # Font có chân cho cổ điển
    font_date = ImageFont.truetype('times.ttf', 40)
    font_day = ImageFont.truetype('times.ttf', 26)
    font_num = ImageFont.truetype('times.ttf', 28)
except:
    font_title = ImageFont.load_default()
    font_date = ImageFont.load_default()
    font_day = ImageFont.load_default()
    font_num = ImageFont.load_default()

# Tiêu đề
draw.text((width/2, 75), 'LỊCH CŨ', fill=(240, 220, 150, 255), font=font_title, anchor='mm')
# Năm tháng
draw.text((width/2, 115), 'Tháng 7 - Năm 1985', fill=(255, 240, 200, 255), font=font_date, anchor='mm')

# 4. Phần lịch
# Kẻ ô
start_x, start_y = 40, 150
cell_w = (width - 80) / 7
cell_h = (height - 180) / 6

# Vẽ lưới
for r in range(7):
    y = start_y + r * cell_h
    draw.line([(start_x, y), (width-start_x, y)], fill=(100, 70, 40, 150), width=1)
for c in range(8):
    x = start_x + c * cell_w
    draw.line([(x, start_y), (x, height-30)], fill=(100, 70, 40, 150), width=1)

# Thứ
days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7']
for i, d in enumerate(days):
    draw.text((start_x + i*cell_w + cell_w/2, start_y + cell_h/2), d, fill=(80, 40, 40, 255), font=font_day, anchor='mm')

# Số ngày
# Tháng 7/1985 bắt đầu thứ 2 (index 1)
start_day_index = 1 
day_count = 1
for r in range(1, 6):
    for c in range(7):
        if r == 1 and c < start_day_index:
            continue
        if day_count > 31:
            break
        
        cx = start_x + c * cell_w + cell_w/2
        cy = start_y + r * cell_h + cell_h/2
        
        # Màu số ngày (Đỏ cho chủ nhật, đen cho ngày thường)
        color = (180, 40, 40, 255) if c == 0 else (40, 30, 20, 255)
        draw.text((cx, cy), str(day_count), fill=color, font=font_num, anchor='mm')
        day_count += 1

# 5. Hiệu ứng cũ kỹ (Stains & Damage)
# Vết ố vàng
for _ in range(15):
    x, y = random.randint(20, width-20), random.randint(20, height-20)
    r = random.randint(20, 60)
    # Vẽ hình tròn mờ
    for i in range(r):
        alpha = int(50 * (1 - i/r))
        draw.ellipse([x-i, y-i, x+i, y+i], fill=(150, 120, 60, alpha))

# Vết rách góc
draw.polygon([(0,0), (40,0), (0,40)], fill=(200, 180, 120, 255)) # Giả lập góc bị gấp

# Làm mờ nhẹ toàn bộ ảnh cho cảm giác cũ
# img = img.filter(ImageFilter.GaussianBlur(radius=0.5)) # Bỏ comment nếu muốn mờ hơn

img.save('D:/MATAM/assets/models/old_paper_on_wall/old_calendar.png')
print('Created vintage calendar image!')
