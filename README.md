# StackCorp

Game thẻ xếp chồng về xây dựng công ty: Garage → Series A → IPO → Rule the Market.
Godot 4.6.1 standard, GDScript, Compatibility renderer. Giao diện trong game bằng English.

## Chơi trên Windows

1. Tải source bằng GitHub **Code → Download ZIP** hoặc clone repository.
2. Giải nén toàn bộ thư mục, rồi bấm đúp **`Play.cmd`**.
3. Chọn độ khó và **Start company**, hoặc mở **Tutorial** để làm quen.

Lần đầu launcher có thể tải bản Godot portable chính thức vào `.tools/godot`, kiểm SHA-512 và import tài nguyên. Các lần sau dùng runtime đã lưu. Sau bước chuẩn bị đầu tiên, game chơi offline; không cần tài khoản, .NET, npm, plugin hoặc API key.

Khi source không đổi, launcher bỏ qua import lại để mở game nhanh hơn. Music và Sound effects có thể bật/tắt riêng trong Settings.

Nếu đã có Godot, mở **`project.godot`** và bấm **F5**. **`Editor.cmd`** cũng mở dự án trong editor. Không cần export templates để chơi từ source. Godot phiên bản cũ trên PATH được bỏ qua; launcher sẽ chuẩn bị phiên bản phù hợp.

macOS/Linux: dùng Godot standard 4.6.1 trở lên trong dòng 4.x, import `project.godot` rồi F5. `Play.sh` dùng Godot có sẵn trên PATH; bootstrap tải runtime tự động hiện dành cho Windows.

## Điều khiển

| Thao tác | Điều khiển |
|---|---|
| Di chuyển thẻ / stack | Kéo chuột trái |
| Ghép stack | Thả lên thẻ phù hợp |
| Tách thẻ | Shift + kéo |
| Xem thẻ và hành động | Click hoặc chuột phải trên thẻ |
| Di chuyển góc nhìn | Giữ chuột giữa và kéo |
| Phóng to / thu nhỏ | Con lăn |
| Trở lại giữa bàn | Home |
| Pause / tiếp tục | Space |
| Tốc độ | 1 / 2 / 3 |
| Ideas / Goals | I / G |
| Lưu | F5 trong cửa sổ game |
| Menu | Esc |

Khi Pause, bạn vẫn sắp thẻ và giao dịch được; thời gian sản xuất và deadline dừng.
Mua pack từ dải phía trên; bán bằng cách thả vào **Sell**. Click thẻ để xem các hành động như nghỉ, thuê, thanh toán, ngân hàng hoặc dùng Coffee.

## Lưu game

Save và tùy chọn dùng thư mục dữ liệu người dùng của Godot, tách khỏi source. Game có autosave và Continue. Bấm New company khi đang có run sẽ yêu cầu xác nhận trong game. Source GitHub không chứa save của người phát triển.

## Phát triển và kiểm tra

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tools/scenario_test.gd
```

Backend: `src/backend`. Frontend: `src/frontend` và `scenes`. Nội dung/balance/English strings: `data`. Tài nguyên được đóng gói trong `assets`.

Mục tiêu tỷ lệ thắng Easy/Medium/Hard là **80/50/30%**; các con số balance ban đầu chưa được xác nhận bằng mẫu người chơi. Kiểm tra tình huống tập trung thay cho chạy hàng nghìn bot mặc định.

Tài liệu: `docs/IMPLEMENTATION_PLAN.md`, `docs/ACCEPTANCE.md`, `docs/ART_SOURCES.md`, `DECISIONS.md`. Spec gốc giữ nguyên trong `StackCorp_Spec`; yêu cầu trong chat của người dùng được ưu tiên.

## Checklist Tester

1. Chạy `Play.cmd`, mở Tutorial hoặc bắt đầu công ty Easy.
2. Ghép Founder + Old Laptop + Freelance Contract; xem tiến độ và tiền nhận.
3. Tạo sản phẩm, bán, mở pack và sắp lại thẻ; thử pan/zoom và Pause.
4. Trả hóa đơn; kiểm stress, nghỉ và mục tiêu Series A trong Ideas/Goals.
5. Lưu, thoát và Continue; gửi ảnh cùng thao tác gây vấn đề khi feedback.
