# StackCorp — tiêu chí bàn giao

Các ô dưới là tiêu chí, không phải kết quả kiểm đã đạt. Kết quả thực chạy được ghi trong `STATE.md` và báo cáo bàn giao.

## Đối soát hiện tại — 14–15/11/2026

- Kiểm tham chiếu JSON chạy thành công: 82 loại thẻ, 30 công thức, 10 pack; không thiếu ID thẻ hoặc chuỗi tên/mô tả thẻ, tên recipe và tên pack.
- Đã đọc và xác nhận có nguồn dữ liệu cho specialist bắt buộc, Investor, Branch, Ledger, Stock và Subsidiary. Công thức nối được Series A → Term Sheet → Branch + ba Ledger → IPO → M&A về mặt nội dung; điều kiện doanh thu/thời gian vẫn cần scenario thực chạy.
- Đọc mã đã xác nhận các sửa: recipe giảm/không tăng slot vẫn chạy khi overcap; tự động hóa chỉ lấy Concept rời; phí M&A không trừ lợi nhuận vận hành; thuế đã trả không trừ lợi nhuận lần hai; Receipt/Ledger giữ phần giá trị chưa khai; nghỉ không hủy trạng thái nằm viện; vận chuyển giữ chỗ ở bàn đích.
- Frontend đã dùng z-order giới hạn, event name khớp backend, thanh payroll theo cả chu kỳ và nhãn vai trò dễ đọc. Tutorial thực hành riêng có chín cờ hành động do backend ghi nhận và không ghi đè save chính.
- Root phụ trách bằng chứng runtime mới: import, focused scenarios, UI và clean source copy. Không đánh dấu toàn bộ checklist là đạt chỉ từ việc đọc mã.
- Đọc lại bản sửa mới đã đóng các phát hiện quan trọng: load kiểm board/stack/member references và UID trước commit; xóa Safe trả nội dung ra bàn; Safe còn tiền bị chặn vận chuyển với lý do rõ; helper theft chỉ lấy tiền ngoài Safe. Cần đối chiếu focused scenario mới trước tuyên bố runtime đạt.
- Đã đối soát `tools/scenario_test.gd`: sáu nhóm bao phủ tiền/save continuation và save lỗi, cap/Pending, hai bàn/payroll, Safe/thuế/AI, chuỗi chuyển phase tới Victory/Endless, tutorial/data/độ khó. Nhóm progression dùng seed 123 và fixture cấp nguyên liệu/doanh thu, thực hiện các bước qua lệnh game; nó chứng minh đường chuyển trạng thái khi đủ điều kiện, không chứng minh thời lượng hay tỷ lệ thắng khi chơi bình thường.
- Hai lỗi cuối đã sửa và có kiểm trong nhóm hazard: Pantry cứu Burnout sau 15 giây rồi trả stress về 6; spawn Inspector/Strike phát đúng event để frontend kích hoạt cảnh báo và Auto-pause. Load chuẩn hóa UID thành số nguyên để tiếp tục stack sau JSON round-trip.
- Backend báo 284 kiểm tra/6 nhóm, 0 lỗi sau các sửa trên. Root cần ghi kết quả chạy mới của bản tích hợp cuối vào `STATE.md`; con số kiểm này không phải số lượt mô phỏng cân bằng.
- Bằng chứng hình ảnh do root thực hiện nằm ở `.qa/menu.png`, `.qa/table.png`, `.qa/working.png` và log tương ứng; root đang hoàn thiện lượt kiểm sau polish và clean-source launch. Thư mục `.qa` là bằng chứng cục bộ, không phải nội dung phát hành.

## Chạy ngay và đóng gói

- [ ] Clean copy của source mở/import được bằng Godot phiên bản chỉ định; F5 vào game, không cấu hình ngoài project.
- [ ] Windows `Play.cmd` tự chuẩn bị runtime trên máy chưa cài Godot, kiểm checksum, chờ import lần đầu rồi vào game; lần sau dùng cache. Runtime cũ trên PATH không chặn bootstrap runtime tương thích.
- [ ] Asset/JSON/font/audio cần thiết đã nằm trong repo; không có đường dẫn tuyệt đối tới máy tác giả hoặc dependency mạng runtime.
- [ ] README có đúng đường chạy source, điều khiển, save location và giới hạn đã biết.
- [ ] Main scene được cấu hình; lỗi load dữ liệu hiện rõ thay vì màn hình trống.

## Vòng chơi và hiển thị

- [ ] Main menu có New Game, Continue khi có save, ba độ khó, tutorial và settings.
- [ ] Bàn tự do có pan/zoom; thẻ kéo thả/stack/tách được; overlay không nuốt input sai hoặc click xuyên.
- [ ] Ngoại cảnh được vẽ ngoài bàn; card/pack/cash/hazard đọc rõ và phân biệt bằng hình/nhãn ngoài màu.
- [ ] Pause vẫn sắp xếp được; 1x/2x/3x chỉ đổi tốc độ mô phỏng.
- [ ] Prototype tạo và bán được; tiền vật lý đúng giá; payroll cảnh báo số tiền chính xác.
- [ ] Chuỗi Series A → Branch/thuế/Inspector → IPO → M&A → Victory thực hiện được qua luật bình thường.
- [ ] Tutorial hoàn tất nhờ hành động thực, có skip/replay; gợi ý theo ngữ cảnh mở lại được.
- [ ] Màn thắng có Endless, màn thua nêu nguyên nhân và đường tạo run mới.

## Kiểm tập trung

- [ ] Validator xác nhận JSON/schema/ID/tham chiếu; nguồn các thẻ và Idea bắt buộc reachable.
- [ ] Tiền: đổi cọc, trả thiếu/thừa, mua/bán, bank và hai bàn không nhân đôi hoặc làm mất giá trị.
- [ ] Recipe: thay stack reset đúng; output đầy cap Pending; giải phóng chỗ chỉ nhận output một lần.
- [ ] Payroll/hazard: thiếu lương/rent, cứu Founder, Bug cap và Inspector có kết quả đúng theo deadline.
- [ ] Save/load giữa job, deadline và transit tiếp tục đúng; dữ liệu save sai không phá run hiện tại.
- [ ] Progression tới Victory, soft-lock cứu trợ và Idea vĩnh viễn được kiểm bằng scenario ngắn có seed.

## Kịch bản Tester tối đa năm bước

1. Trên Windows bấm `Play.cmd` và chờ chuẩn bị lần đầu; hoặc mở `project.godot`, chờ import và bấm F5. Chọn Tutorial hoặc New Game.
2. Kéo thẻ tạo Prototype, bán sản phẩm và mở một pack; kiểm tiền/cap thay đổi.
3. Pause rồi sắp bàn, pan/zoom; tiếp tục 2x và xem tiến độ/payroll.
4. Save, về menu và Continue; kiểm thẻ, tiền và tiến độ được giữ.
5. Chơi tiếp hoặc phản hồi về thao tác/hình ảnh/luật gây khó hiểu, kèm ảnh và bước tái hiện nếu có.

## Giới hạn tuyên bố

Mục tiêu win rate 80%/50%/30% chưa được xác nhận bằng dữ liệu người chơi. Parse/build pass không thay thế kiểm trải nghiệm. Không công bố FPS, tỷ lệ thắng hoặc clean-clone play là đã đạt khi chưa quan sát tương ứng.
