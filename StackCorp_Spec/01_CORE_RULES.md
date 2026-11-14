# 01 — CORE RULES

## 1. Trụ cột thiết kế (mọi quyết định phải qua 5 câu hỏi này)
1. Luật đơn giản, tự mày mò (không tutorial dài; chỉ Idea card + Quest gợi ý).
2. Bàn chơi chật = áp lực chính (Card Cap + tiền mặt vật lý chiếm chỗ).
3. Mỗi giai đoạn đổi nút thắt, không chỉ đổi con số.
4. Rủi ro luôn có đường thoát (không bao giờ soft-lock, xem mục 10).
5. Một run Easy ≈ 2 giờ; mỗi phase kết thúc bằng một dự án lớn.

## 2. Thời gian
- Real-time có Pause, tốc độ 1x/2x/3x. **1 Day = 60s** ở 1x (không có đêm, chỉ có thanh ngày).
- **Pay Cycle = 7 Day** (Easy 8, Hard 6). Cuối mỗi Pay Cycle = **Payroll Day**.
- Hiện thanh tiến độ Payroll Day ở đỉnh màn hình (tương đương thanh Moon). Hóa đơn xuất hiện trước 1 Day (cảnh báo) với số tiền chính xác.
- Quarter = 3 Pay Cycle, chỉ bật từ Phase 2.

## 3. Mô hình thẻ
Loại thẻ: `person, resource, cash, product, equipment, lead, hazard, document, container, building, event, idea`.
Trường bắt buộc (JSON): `id, name, type, sell_price (nullable), stack_max, tags[], stats{}`.
- `person` có `stress (0–10)`, `skill{}`, `wage`, `speed`.
- `hazard` (Bug, Burnout, Lawsuit, Inspector...) có `hp`, `behaviors[]`.
- Thẻ spawn luôn xuất hiện cạnh thẻ nguồn, đẩy (push) thẻ khác nhẹ như Stacklands.

## 4. Tương tác
- Kéo thả; thả lên thẻ khác = stack nếu hợp lệ (có recipe hoặc cùng loại stackable), không thì đẩy ra.
- Mở pack: kéo tiền (đủ giá) vào ô Buy Zone hoặc click pack → trừ bill từ Wad kề cận; rút từng thẻ ra bàn.
- **Sell Zone** (cố định cạnh phải bàn): thả thẻ có `sell_price` → trả tiền bằng bill (mệnh giá nhỏ nhất đủ). Từ Phase 2 mỗi sản phẩm bán ra sinh thêm 1 thẻ `receipt`.
- **Buy Zone** (cố định cạnh trái): pack đang mở khóa, hiển thị giá.
- Thẻ person/equipment không thể bán nếu đang trong stack đang chạy recipe.
- Right-click / giữ: xem tooltip (tên, mô tả, stat).

## 5. Recipe engine
- Mỗi tick, với mỗi stack, tìm recipe khớp: root card + tập thẻ trên nó (multiset). Khớp **cụ thể nhất** thắng (nhiều thẻ khớp hơn).
- Recipe có `time` (giây ở 1x), `worker` (person yêu cầu, tùy chọn), `inputs`, `consumes[]`, `outputs[]`, `stress_gain`, `idea_required` (id, tùy chọn).
- Thời gian thực = `time / person.speed` (Tired −25%, Coffee Boost +50%, Overclock ×3).
- Stack bị thay đổi giữa chừng → tiến độ reset (không mất thẻ).
- Recipe chỉ chạy khi Idea tương ứng đã **discovered** (trừ recipe cơ bản đánh dấu `starter`).
- Outputs có thể ngẫu nhiên (`weights`). RNG dùng seed của run (reproducible, phục vụ simulator).

## 6. Ideas
- Idea là thẻ khi lên bàn; khi **Consume** (kéo vào Ideas Tab hoặc double-click) thành mục vĩnh viễn trong Ideas Tab, **không tốn slot**. Hiển thị recipe dạng icon, tên thẻ ẩn `???` đến khi sở hữu đủ nguyên liệu lần đầu.
- Nguồn Idea: Whiteboard (`Founder + Whiteboard`), Idea pack (`Pitch Night`), Quest reward.
- Mất Idea không bao giờ xảy ra (xem fix #10 ở file 11).

## 7. Capacity
| Office | Slots | Mở khóa |
|---|---|---|
| Garage | 25 | Start |
| Coworking | 45 | Series A |
| Office Floor | 80 | Document `Lease: Office Floor` (Phase 2) |
| HQ Tower | 150 | IPO |
- Mỗi thẻ = 1 slot, **trừ** Wad tiền (1 slot/cọc ≤10 tờ) và `receipt` đã gộp trong `Ledger Folder` (1 slot / 10).
- Vượt cap: không mở được pack, không spawn thẻ mới từ recipe (output bị giữ "Pending" tại stack, hiện cảnh báo đỏ). Không bao giờ xóa thẻ tự động.

## 8. Tiền (USD vật lý)
- Mệnh giá: `$1, $5, $20, $100`. Cọc tối đa 10 tờ cùng mệnh giá.
- **Bank Counter** (equipment): thả cọc vào để đổi mệnh giá (ví dụ 5×$1 → $5) miễn phí.
- **Office Safe**: giữ tối đa 3 cọc, tính 1 slot, miễn nhiễm sự kiện trộm cắp.
- **Bank Card**: lưu số dư (Basic ≤$500, Corporate ≤$5,000). Kéo cọc vào = deposit; click `Withdraw` = ra bill. Phí 0. Auto-pay Payroll chỉ khi có `Accountant` hoặc `HR` kề cận Bank Card.
- Trả tiền (pack, hóa đơn): hệ thống tự lấy từ cọc đang kéo; nếu thiếu, người chơi kéo thêm.

## 9. Payroll Day
Hóa đơn gồm: `Rent` (theo office) + `Wages` (tổng lương mọi person đang có).
1. Trước 1 Day: spawn `Payroll Invoice` + `Rent Invoice` kèm số tiền chính xác.
2. Người chơi kéo bill lên hóa đơn đến khi đủ. Hóa đơn có thanh còn lại.
3. Đến hạn mà thiếu:
   - **Wages thiếu**: person không được trả → `Unpaid` (−1 speed tier), nếu thiếu thêm 1 chu kỳ liên tiếp → `Resignation` (rời bàn).
   - **Rent thiếu**: nhận `Eviction Notice` (strike). Strike reset khi trả đủ rent chu kỳ sau. **Thua nếu đủ số strike liên tiếp** (Easy 3, Hard 2).
4. Rent mới = trả hóa đơn mới; hóa đơn cũ biến mất.

## 10. Thắng / Thua / Chống soft-lock
- **Floor income**: `Founder + Laptop + Freelance Contract` luôn có thể kiếm tiền; pack `Early Leads` ($3) luôn có mặt trong Buy Zone; nếu bàn không còn recipe nào sinh tiền và tiền < $3, tặng 1 thẻ `Emergency Client` (1 lần/Pay Cycle).
- **Thua**: (P1) 2/3 Eviction liên tiếp; (P2) Sealed by Inspector hoặc Labor Strike không giải quyết; (P3) Hostile Takeover (cổ phiếu ≤10 khi chốt quý). Founder không chết (chỉ Hospitalized).
- **Thắng**: hoàn thành quest `Rule the Market` (file 03). Sau thắng: Endless Mode (tiếp tục, thêm event leo thang).
