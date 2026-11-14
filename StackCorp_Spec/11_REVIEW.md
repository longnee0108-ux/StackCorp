# 11 — REVIEW: lỗ hổng logic đã phát hiện & cách fix (đã áp dụng vào spec)

| # | Lỗ hổng trong bản thiết kế gốc | Hậu quả | Fix trong spec |
|---|---|---|---|
| 1 | **IPO vừa là cột mốc kết thúc P3 vừa là điều kiện để có cổ phiếu (P3)** | Vòng tròn logic: không thể thua vì cổ phiếu trước khi IPO | IPO = chuyển P2→P3; cuối P3 là quest `Rule the Market` (03) |
| 2 | Cap 25 thẻ + mỗi tờ USD là 1 thẻ | Tiền chiếm hết bàn, deadlock ở P1 | 1 cọc ≤10 tờ = 1 slot (01 §7) |
| 3 | Mệnh giá và đổi tiền lẻ không được định nghĩa | Không trả được hóa đơn bằng tiền lớn | 4 mệnh giá + Bank Counter đổi miễn phí |
| 4 | "Nhân viên bỏ việc **hoặc** công ty bị niêm phong" mơ hồ | Điều kiện thua không đo được | Tách Wage (Unpaid → Resignation) và Rent (strike) (01 §9) |
| 5 | Thua P1 = "cạn tiền khi trả lương" | Death spiral không có đường hồi | Floor income + Emergency Client + strike 3/2 (01 §10) |
| 6 | Không có cơ chế **bán hàng** | Sản phẩm không ra tiền | Sell Zone + Receipt (01 §4) |
| 7 | **Overclock "mất 2 chu kỳ"** | Founder là SPOF, phạt quá nặng, có thể dẫn tới chết | Đổi thành Hospitalized 1/2 **Day**, Founder không chết |
| 8 | Nhân viên nhảy việc mang theo thẻ Idea | Idea là recipe vĩnh viễn → mất = soft-lock | Chỉ mang `Draft Idea`; Idea đã sở hữu vĩnh viễn (01 §6, 02 §10) |
| 9 | Bug "tự nhân bản" không giới hạn | Tăng cấp số mũ, tràn bàn | Cap 4/6, cooldown 30s, hp 3 (02 §2) |
| 10 | Thuế −30% (Kế toán) nhưng chưa có cách tính thuế | Không implement được | Receipt vật lý + Tax Notice 10% (02 §3) |
| 11 | Quỹ Đen "giấu khỏi thanh tra" không có xác suất | Không cân bằng được | Công thức detect + Economic Fine (02 §4) |
| 12 | AI Agent: không stress, 24/7 | Chiến lược trội hoàn toàn | Điện + Cloud Server + Power Outage + AI Hallucination |
| 13 | Thua P3 "cổ phiếu về 0" quá cực đoan, thiếu cơ chế giá | Không phát triển được | Stock Price 0–200, Δ theo lợi nhuận, thua ≤10 (02 §8) |
| 14 | Phase ẩn nhưng trigger P1→P2 chưa rõ | Người chơi không biết đang làm gì | Recipe `Series A Pitch` + Idea gợi ý + Goals tab |
| 15 | Bàn thứ 2: hóa đơn/cap/tiền chưa rõ | Double-charge, lạc tiền | Cap riêng, hóa đơn riêng, Bank Card sync (02 §7) |
| 16 | Không có điều kiện thắng | Game không có đích | `Rule the Market` + Endless |
| 17 | Cần Pay Cycle thời gian chưa định nghĩa | Không tính lương/balance được | 1 Day = 60s, Cycle = 7 Day |

# Brainstorm bổ sung (chưa có trong spec lõi, để chọn)
1. **Sản phẩm vòng đời**: MVP → v1 → v2 → Brand; Brand cho passive income nhỏ nhưng cần bảo trì.
2. **Pivot**: bỏ một dòng sản phẩm, đổi hết Idea cùng nhóm thành Idea nhóm khác (cho bạn bình tĩnh khi chọn sai).
3. **Tech Debt** card: mỗi khi bỏ qua recipe sửa lỗi, tích nợ; quá 5 → bug tăng tốc.
4. **Quarter seasons**: Q4 Holiday Rush (+giá, +stress).
5. **Cạnh tranh đối thủ có tên** (AI-controlled) cướp khách theo hướng bạn bỏ bê.
6. **Employee levels**: Intern → Dev → Senior bằng XP, thêm cảm giác nuôi nhân sự.
7. **Office pet** (mèo): giảm stress nhẹ nhưng chiếm slot.
8. **Challenge modes**: No-Debt, Lean (không tuyển quá 5 người), Speedrun.
9. **Achievements/Collection** của mọi thẻ.
10. **Hard-only**: `Loan Shark` card đầu game (ứng trước $100, trả $140 trong 3 cycle).
