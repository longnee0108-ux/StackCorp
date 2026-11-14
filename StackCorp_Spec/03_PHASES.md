# 03 — PHASES (ẩn, không hiện UI)

State `phase` lưu trong save, **chỉ tăng**, không bao giờ giảm. Người chơi nhận biết qua pack mới, drop mới, nút thắt mới, nhạc nền đổi.

| | P1 StartUp | P2 SMEs | P3 BigCorp |
|---|---|---|---|
| Cap | 25→45 | 45→80 | 150 |
| Nút thắt | USD lẻ, bàn chật | Stress, Thuế/Thanh tra, 2 bàn | Quy mô thẻ, Khủng hoảng, Cổ phiếu |
| Thua | Eviction ×3 (Easy)/×2 (Hard) | Sealed / Strike | Hostile Takeover |
| Pack | 1–3 (+Pitch Night) | 4–7 | 8–9 |
| Mục tiêu | Series A | IPO | Rule the Market |

## Trigger
- **P1→P2: Series A.** Recipe `Series A Pitch`: `Founder + Pitch Deck + Investor + Polished Prototype` (60s) → 5×$100 + `Term Sheet`. Hiệu ứng: Coworking (cap 45), unlock pack 4–6, bật Receipt/Thuế từ Quarter kế.
- **P2→P3: IPO.** Điều kiện: quý gần nhất doanh thu ≥ $1,500 (Easy $1,200), `Branch` đang hoạt động, 0 Strike chưa giải quyết. Recipe `IPO Prospectus`: `Founder + Lawyer + Accountant + Term Sheet + 3 Ledger Folder` → `Stock Price` card + HQ Tower (cap 150) + unlock pack 8–9.
- **Win: Rule the Market** (quest cuối): sở hữu 3 `Subsidiary` + `Stock Price` ≥150 trong 2 Quarter liên tiếp. Hoàn thành → màn Victory, nút Endless Mode.

## Drop table theo phase (trọng số, ví dụ)
- Founding Team: P1 {Intern 35, Dev 25, Sales 20, Designer 20}; P2 thêm {Senior Dev 10, Marketing 10}.
- Garage Gear: {Old Laptop 25, Desk 15, Coffee Machine 20, Whiteboard 15, Marker 25}.
- Early Leads: {Freelance Contract 40, Difficult Client 15, Bug 25, Coffee 20}.
- Market & Crisis (P2): {Million Contract 10, Viral Trend 20, Media Drama 20, Price War 20, Poaching 20, Bad Hire 10} — rủi ro cân bằng cơ hội.
Toàn bộ nằm trong `data/packs.json`.

## Unlock graph (tóm tắt)
P1: Starter recipes → Whiteboard Ideas → MVP chain → Pitch Night → Series A.
P2: Operations pack → Perks pack → Market & Crisis → Logistics (Branch) → IPO.
P3: Automation/AI → Wall Street/M&A → 3 Subsidiary → Rule the Market.
