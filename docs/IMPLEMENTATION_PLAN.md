# StackCorp — kế hoạch triển khai đã giao

## Ưu tiên và phạm vi

Chat hiện tại của người dùng ưu tiên hơn `StackCorp_Spec/`. Giữ Godot 4/GDScript, ba giai đoạn, tiền vật lý, backend/frontend riêng. Ba độ khó có mục tiêu thắng Easy 80%, Medium 50%, Hard 30%; đây là mục tiêu chưa đo. Có tutorial thực hành và gợi ý theo ngữ cảnh. Chỉ kiểm tra dữ liệu, bất biến quan trọng và vòng chơi chính; không mặc định chạy hàng nghìn lượt.

Người dùng đóng vai Tester. Nhóm triển khai tự giải quyết các quyết định thường lệ trong phạm vi đã duyệt. Không mở thêm cổng duyệt. Không tạo PDF.

## Trải nghiệm chạy

- Repository chứa `project.godot`, main scene, code, JSON và toàn bộ asset cần chạy.
- Windows có `Play.cmd` gọi `scripts/Launch.ps1`: tìm runtime tương thích hoặc tải Godot portable 4.6.1 chính thức một lần, đối chiếu SHA-512 rồi import asset và mở game. Các lần sau dùng cache; runtime/bootstrap cần được kiểm trên clean copy trước khi tuyên bố đạt.
- Với Godot phiên bản được README chỉ định: import/open project, chờ import lần đầu, bấm F5/Play là chơi được; không npm, pip, khóa API, database hoặc tải asset khi chơi.
- F6 chỉ được hứa với scene chính đã chọn; F5 là đường khởi động tiêu chuẩn cho cả project.
- Tài liệu phân biệt Windows bootstrap, source mở bằng Godot và bản executable. Bootstrap Windows chuẩn bị runtime thay người chơi; lần đầu cần mạng nếu máy chưa có runtime tương thích. Source ở hệ điều hành khác dùng Godot phù hợp hoặc bản export riêng.

## Ranh giới module

| Phía | Sở hữu |
|---|---|
| `data/` | Nội dung thẻ, công thức, pack, events, quests, difficulty, strings English |
| `src/backend/` | State chuẩn, fixed tick 10 Hz, RNG gameplay, cards/stacks/cap, recipes, tiền, hazards, phases, save payload |
| `src/frontend/` | Draw, camera/pan/zoom, drag ghost, hit-test input, HUD, panels, tooltip, tutorial presentation, audio |
| `src/app/` | Khởi tạo, nối lệnh/sự kiện, đọc/ghi file, vòng đời ứng dụng |
| `tools/` | Validator và các scenario tối thiểu, không phụ thuộc renderer |

API cốt lõi: `StackCorpSim extends RefCounted`, có `new_run(difficulty, seed_value)`, `step(delta)`, `command(kind, payload)`, `snapshot()`, `save_game(path)`, `load_game(path)`, `drain_events()`. Backend phụ trách schema cuối và thông báo cho frontend. Command luôn dùng UID ổn định, không dùng chỉ số mảng. Snapshot không được để frontend thay đổi state thật.

Frontend gửi lệnh → backend kiểm tra tại thời điểm commit → backend cập nhật state → events/result → frontend vẽ. Animation không sinh thưởng. Camera và hover không vào state gameplay; vị trí có ảnh hưởng adjacency do backend giữ.

## Trình tự và bất biến

Tick xử lý lệnh hợp lệ theo thứ tự, cập nhật timer/recipe, commit output một lần, cập nhật nghĩa vụ/hazard, progression, thắng/thua rồi phát events. Cùng thời điểm cần tie-break ổn định. Khi pause, thời gian ngừng nhưng lệnh sắp xếp/giao dịch tức thời vẫn hợp lệ theo luật.

- Tiền không âm; chuyển cọc/đổi tiền/gửi rút không tự sinh tiền. Bank Card hai bàn truy cập một tài khoản.
- Mỗi card có UID duy nhất và chỉ ở một bàn/stack/transit tại một thời điểm; nhân sự chỉ tham gia một job.
- Job Pending giữ kết quả đã xác định, không roll lại RNG hoặc thưởng lại. Cap tính phần thay đổi ròng sau tiêu hao.
- Invoice, Receipt bắt buộc và Emergency Client được phép overcap có chủ đích; pack/output tùy chọn chờ đủ chỗ.
- Discovered Idea vĩnh viễn; Founder không chết hoặc biến mất; thẻ khởi đầu thiết yếu có đường phục hồi.
- Receipt là hồ sơ doanh thu, không phải tiền lần hai. Hủy Receipt không xóa lịch sử doanh thu/thuế mà thanh tra cần.
- Phase chỉ tăng. Vận chuyển và payroll dùng board ID, không tính lương hai lần.
- Save versioned lưu seed + RNG state, tick, deadlines, card/stack state, progress/Pending, ideas/quests, invoices, tax, stock, transit. Load lỗi giữ nguyên run hiện tại.

## Đóng các thiếu sót nội dung trước hoàn thành

1. Có nguồn hữu hạn-bảo-đảm cho Whiteboard, Developer/Designer/Sales, Investor, Lawyer, Accountant, Senior Dev và Ideas bắt buộc.
2. Mọi recipe ghi worker, inputs, consumes, outputs, thời gian và điều kiện; worker/equipment không vô tình bị consume.
3. Chuỗi P1 tạo Pitch Deck + Polished Prototype → Series A + Term Sheet + Coworking.
4. P2 bán sản phẩm → Receipt/Ledger; có Branch, quý đủ doanh thu và specialist → IPO + Stock + HQ.
5. P3 tạo được doanh thu đủ cho M&A; mua ba Subsidiary, stock ≥150 hai quý liên tiếp → Victory, tiếp tục Endless.
6. Mọi hazard có nguyên nhân, cảnh báo, hạn và cách giải quyết bằng hành động nhìn thấy được. Không thêm brainstorm ngoài scope lõi.

## Chất lượng trình bày

Bàn chơi là không gian tự do có pan/zoom và nhiều khoảng thở; không chia cứng thành ô sản xuất. HUD/Buy/Sell là lớp nổi cạnh màn hình, không bó hẹp mặt bàn thành dashboard. Ngoại cảnh văn phòng, cây xanh, đường đi và đồ vật nền tạo thế giới liên tục ngoài khu thẻ. Card có silhouette riêng, minh họa rõ loại, stack header đọc được, shadow nhẹ, nhãn/biểu tượng ngoài màu. Dùng asset gốc của dự án, không sao chép asset Sokpop.

## Mốc tích hợp

M1: tạo và bán Prototype. M2: tiền/pack/payroll/tutorial/save và P1 tới Series A. M3: stress/Bug/events/ba độ khó. M4: thuế/thanh tra/Strike/hai bàn và IPO. M5: stock/AI/M&A/win/endless. M6: clean import, trải nghiệm Play, polish. Các mốc là thứ tự phụ thuộc, không cắt scope đã giao.
