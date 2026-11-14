# 10 — QA & ROADMAP

## Milestone
| M | Nội dung | Điều kiện hoàn thành |
|---|---|---|
| M1 | Bàn, kéo thả, stack, recipe engine, 8 thẻ + Whiteboard | Tạo Prototype, bán được |
| M2 | Cash (USD vật lý), Sell/Buy Zone, pack 1–3, Payroll/Rent, cap | Chơi trọn P1 đến Series A |
| M3 | Stress, Bug, Ideas/Goals, events P1 | Easy P1 balance theo sim |
| M4 | P2: Thuế/Receipt, Inspector, Strike, pack 4–7, bàn thứ 2 | Trọn P2 → IPO |
| M5 | P3: Stock, Recession, AI, M&A, win/endless | Thắng được |
| M6 | Balance sim + Hard mode + save/load + polish | Pass bảng mục tiêu 07 |

## Test case tiêu biểu
1. Stack 11 bill $20 → cọc mới tách ra, không mất tờ nào.
2. Recipe output khi bàn đầy → Pending, không mất thẻ.
3. Payroll thiếu tiền 1 cycle → Unpaid; 2 cycle → Resignation.
4. Overclock → Hospitalized đúng 1/2 Day; Founder vẫn không thể chết.
5. Bug cap 4/6 không vượt.
6. Receipt hủy → xác suất phát hiện đúng công thức (test 10k lần).
7. Poaching không bao giờ xóa Idea đã discovered.
8. Save/load giữa chừng recipe: tiến độ giữ nguyên.
9. Hai bàn: Rent/Wage tính riêng, không double-charge.
10. Soft-lock: ép tiền $0, 0 lead → Emergency Client xuất hiện.
