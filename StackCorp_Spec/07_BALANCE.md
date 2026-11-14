# 07 — BALANCE (Easy / Hard)

## Mục tiêu (đo bằng simulator, xem mục 4)
| Chỉ số | Easy | Hard |
|---|---|---|
| Thời lượng 1 run | ~2h (P1 20–25p, P2 45–60p, P3 45p) | ~2h, ít thời gian rảnh hơn |
| Tỉ lệ thắng bot "casual" | 80% | 20% |
| Tỉ lệ thắng bot "expert" | 97% | 55% |
| Thua trước hết ở | P1 (rent) hiếm; P2 Strike | P1 Eviction + P2 Sealed |
| Biên lợi nhuận gộp | P1 45–55%, P2 35–45%, P3 25–35% | thấp hơn 5–8 điểm |

Nguyên tắc: người chơi mới không chết ở 2 Pay Cycle đầu; thua đầu tiên nên đến từ **chọn sai ưu tiên**, không phải RNG.

## Tham số theo độ khó (data/difficulty.json)
| Tham số | Easy | Hard |
|---|---|---|
| Start cash | $60 (3×$20) | $30 (1×$20 + 2×$5) |
| Pay Cycle | 8 Day | 6 Day |
| Rent ×  | 0.8 | 1.2 |
| Wage × | 0.9 | 1.1 |
| Pack price × | 0.85 | 1.15 |
| Sell price × | 1.10 | 0.95 |
| Stress gain × | 0.7 | 1.2 |
| Card cap bonus | +5 | 0 |
| Eviction strikes | 3 | 2 |
| Founder Hospitalized | 1 Day | 2 Day |
| Max Bug | 4 | 6 |
| Inspector base detect | 12% | 30% |
| Inspection interval | 3 Quarter | 2 Quarter |
| Event interval | 1.5–2 Day | 1–1.5 Day |
| Event bad-weight × | 0.8 | 1.3 |
| Recession dmg | ×0.75 | ×0.60 |
| Hint/Quest nudge | bật | tắt |

## Rent & Wage mốc
Rent/cycle: Garage 10, Coworking 40, Office Floor 120, HQ 400, Branch 150, Factory 250.
Wage: xem 04. Chi phí cố định kỳ vọng: cuối P1 ≈ $60–90, cuối P2 ≈ $450–600, P3 ≈ $1,500+.

## Doanh thu kỳ vọng / Pay Cycle (người chơi trung bình, Easy)
P1 đầu ≈ $30 → cuối ≈ $120 · P2 ≈ $300 → $900 · P3 ≈ $2,000 → $6,000.
Mục tiêu: thu ≥ 1.3× chi ở giữa mỗi phase, ~1.0× lúc mới chuyển phase (nút thắt mới).

## Điểm kiểm soát lạm phát
- Mỗi thẻ person thêm chi phí + stress; không có recipe nào "tự động có lãi" nếu không quản lý stress.
- Chiếm bàn: tiền mặt > $200 trên bàn là sai lầm (phạt slot) → thúc đẩy Bank/Safe.
- Pack 6, 9 là EV gần 0 nhưng có tail lớn.

## Balance Simulator (bắt buộc, module tools/balance_sim)
- Chạy headless N=1000 run/seed, 3 bot: `random_legal`, `casual` (heuristic ưu tiên lương trước, mở pack khi dư), `expert` (tối ưu hóa chuỗi).
- Output CSV: win rate, tuổi thọ run, nguyên nhân thua, doanh thu/phase, số lần chạm cap.
- Pass điều kiện: các mục tiêu bảng đầu trong ±5 điểm. Thay số chỉ sửa data JSON.
