# StackCorp — Spec v1.0 (đọc file này đầu tiên)

Game: 2D card-stacking, real-time with pause, lấy cảm hứng Stacklands. Chủ đề: điều hành công ty từ Garage đến BigCorp.
Ngôn ngữ: **toàn bộ chữ trong game = English**. Tiếng Việt chỉ dùng trong spec, comment giao tiếp, commit message nội bộ. Mọi chuỗi hiển thị phải nằm trong `data/i18n/en.json` (không hard-code) để sau này thêm tiếng Việt không phải sửa code.

## Quy tắc cho agent coding
1. Đọc theo thứ tự file 01 → 10. Không tự thêm cơ chế ngoài spec; gặp điểm mơ hồ thì ghi vào `OPEN_QUESTIONS.md` và hỏi designer.
2. **Data-driven**: mọi con số (giá, lương, thời gian, xác suất, HP) nằm trong `data/*.json`. Cấm hard-code số balance trong code.
3. Engine đề xuất: **Godot 4.x (GDScript)**. Nếu designer đổi engine, giữ nguyên cấu trúc data JSON và logic trong file 01–03.
4. Logic game (simulation) tách khỏi hiển thị: chạy được headless để balance simulator dùng (file 07, 10).
5. Mỗi milestone (file 10) phải chạy được và có test trước khi sang milestone sau.

## Bản đồ spec (6 phần, 11 file)
| Phần | File | Nội dung |
|---|---|---|
| A. Lõi | 01_CORE_RULES.md | Thời gian, thẻ, stack, recipe engine, tiền, capacity, payroll, thắng/thua |
| B. Hệ thống | 02_SYSTEMS.md | Stress, Bug, Thuế/Thanh tra, Quỹ đen, Cổ phiếu, Bàn thứ 2, Quest, Sự kiện |
| C. Tiến trình | 03_PHASES.md | 3 giai đoạn ẩn, trigger chuyển phase, drop table, unlock graph |
| D. Nội dung | 04_CARDS.md, 05_RECIPES.md, 06_PACKS.md | Catalog thẻ, công thức, pack |
| E. Cân bằng | 07_BALANCE.md | Easy/Hard, bảng số khởi điểm, mục tiêu, balance simulator |
| F. Triển khai | 08_UI_ART_AUDIO.md, 09_TECH.md, 10_QA_ROADMAP.md, 11_REVIEW.md | UI, art, cấu trúc folder code (9 module), test, milestone, danh sách lỗ hổng đã fix |

## Thuật ngữ
- **Slot**: đơn vị đếm Card Cap. **Pay Cycle**: 7 ngày game. **Quarter**: 3 Pay Cycle (từ Phase 2).
- **Wad**: cọc tiền (≤10 tờ cùng mệnh giá) = 1 slot.
- **Root card**: thẻ đáy của stack, quyết định recipe.
