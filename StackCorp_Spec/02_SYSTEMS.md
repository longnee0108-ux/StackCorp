# 02 — SYSTEMS

## 1. Stress & Burnout
- Stress 0–10 (hiện bằng 10 chấm dưới thẻ person).
- +1 mỗi recipe hoàn thành (+2 với `Difficult Client`). Hệ số: Easy ×0.7, Hard ×1.2 (làm tròn xác suất, cộng dồn dạng thập phân).
- Stress ≥7 = **Tired** (speed −25%). Stress 10 = thẻ person biến thành `Burnout` (chiếm slot, 1 Day sau → `Resignation Letter` rồi person rời). Cứu: kéo `Coffee`/`Pantry`/`Team Building Ticket` vào Burnout trong 1 Day → hồi về stress 6.
- Giảm stress: `Coffee` −2 (consume), `Pantry Counter` + person 15s → −3, `Team Building Ticket` −5 cho tối đa 6 person trong stack, `Ergonomic Chair` (gắn cùng person) −25% stress gain, mỗi Payroll Day trả đủ lương −1.
- **Overclock**: `Founder + 3 Coffee` → 1 Day speed ×3, không tăng stress; sau đó `Hospitalized` (Founder bị khóa, Easy 1 Day / Hard 2 Day). Trong lúc khóa Founder, recipe cần Founder tạm dừng, mọi thứ khác vẫn chạy.
- Hazard `Lawsuit` (từ Burnout bị bỏ lâu >2 Day): trừ $20/Pay Cycle cho đến khi giải quyết bằng `Lawyer` hoặc `Insurance` (Insurance hủy hoàn toàn).

## 2. Bug (quái mini)
- Spawn từ pack `Early Leads` hoặc sự kiện. `hp 3`.
- `Dev + Bug` = fight: mỗi 5s trừ hp (Dev 1, Senior Dev 2); Bug không phản đòn trực tiếp nhưng mỗi 45s biến 1 `Product` gần nhất thành `Buggy Product` (giá bán 40%, `Dev + Buggy Product` 20s → sửa).
- Nhân bản: Bug sống >90s sinh 1 Bug mới, **tối đa 4 Bug trên bàn** (Hard 6), cooldown 30s.
- Phase 3: biến thể `AI Hallucination` (hp 6) chỉ xuất hiện khi có AI Agent.

## 3. Thuế & Hóa đơn (Phase 2+)
- Mỗi lần bán sản phẩm sinh 1 `Receipt` (ghi giá trị).
- Cuối Quarter spawn `Tax Notice`. Người chơi **kéo toàn bộ Receipt lên Tax Notice** → tính `tax = 10% tổng giá trị Receipt` (làm tròn lên) → hóa đơn tiền. Không nộp kịp 2 Day → `Late Fine` +25%.
- `Accountant` kề Tax Notice: −30% thuế. `Ledger Folder` (Accountant tạo): gộp 10 Receipt thành 1 thẻ (1 slot).
- Thiếu Receipt (đã hủy) = nghi vấn khi Inspector đến (mục 4).

## 4. Thanh tra (thay Strange Portal)
- Mỗi 2 Quarter (Easy 3) mở `Inspection Portal` (event), spawn `Inspector` (hp 12).
- Giải quyết bằng: `Accountant` attack 2 / 5s, `Lawyer` attack 3 / 5s, hoặc **Settlement**: kéo bill lên Inspector = $6 × hp còn lại.
- Quá 3 Day không giải quyết → `Fine` = 25% tiền mặt; lần thứ 2 liên tiếp → **Sealed** (thua).
- **Quỹ Đen**: `Receipt + Shredder` → Receipt biến mất; `Black Fund` card nhận tiền chưa khai (miễn thuế). Khi Inspector tới: xác suất bị phát hiện = `20% + 5% × (số Receipt đã hủy / 10)` (Easy base 12%, Hard 30%). Nếu bị phát hiện: `Economic Fine` = 3 × thuế đã trốn + Reputation −1.

## 5. Reputation (mới, 0–5)
Giảm khi: Drama, bị phạt, Burnout hàng loạt. Tăng khi: hoàn thành quest, giao hàng đúng hạn, Perks. Ảnh hưởng giá bán (±3% mỗi điểm quanh mốc 2) và giá cổ phiếu P3.

## 6. Labor Strike (Phase 2)
Khi Payroll Day có ≥3 person Stress ≥7 → spawn `Strike` card: mọi person bị khóa. Giải bằng `Bonus` = $5 × số person + `HR` kề thẻ. 2 Strike không giải quyết liên tiếp → thua.

## 7. Bàn thứ 2 (Branch / Factory)
- `Plane Ticket` / `Truck` tạo `Gateway` card ở bàn chính. Thả stack ≤6 thẻ lên Gateway: sau 20s xuất hiện ở bàn 2; Truck vận chuyển ngược.
- Mỗi bàn có **cap riêng** và hóa đơn Rent/Wage riêng (người ở bàn nào nhận lương bàn đó). Tiền có thể chuyển qua Truck hoặc Bank Card (Bank Card sync giữa hai bàn).
- Bàn 2 có Sell Zone riêng với hệ số giá khác (xem 07).

## 8. Stock (Phase 3, sau IPO)
- `Stock Price` card: giá 0–200, khởi điểm 100 khi IPO.
- Chốt mỗi Quarter: `Δ% = clamp((NetProfit − Target) / Target × 20, −20, +20) + (Reputation − 2) × 2`. `Target` tăng 15% mỗi Quarter.
- **Great Recession** (event, Phase 3): ×0.65 giá cổ phiếu, kéo dài 2 Quarter, doanh thu −20%. `Lobbyist` giảm sát thương 40%.
- `Buyback`: $200 bill lên Stock card = +3 giá (tối đa 1 lần/Quarter).
- `Hostile Takeover` (thua): giá ≤10 khi chốt Quarter.
- **Takeover (cơ hội)**: `Weakened Rival` + $ lớn (xem 04) → `Subsidiary` (Passive: +$ mỗi Pay Cycle).

## 9. Quest (Goals Tab)
Giống Stacklands: danh sách mục tiêu, thưởng pack/Idea. Một số quest ẩn đến khi mở. Chi tiết trong 03.

## 10. Sự kiện ngẫu nhiên (weighted, theo phase)
Event deck rút mỗi 1–2 Day, tần suất theo độ khó (07). Gồm: Viral Trend (+giá bán 20%/1 Pay Cycle), Price War (−15%), Poaching (một person bị `Headhunter` hỏi: kéo Perk/tiền giữ lại; nếu để rời, **chỉ mang theo thẻ Draft Idea chưa discovered**, không bao giờ Idea đã sở hữu), Media Drama (−1 Reputation), Power Outage (P3, AI dừng 1 Day), Theft (Safe miễn nhiễm), Friday Beer (−1 stress toàn bàn).
