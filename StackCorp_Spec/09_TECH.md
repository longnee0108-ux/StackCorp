# 09 — TECH & FOLDER STRUCTURE (9 module code)

Engine đề xuất: Godot 4.x. Mọi con số ở `data/`. Simulation tách UI.

```
stackcorp/
  project.godot
  data/                 # Module 1: dữ liệu (JSON)
    cards.json  recipes.json  packs.json  events.json  quests.json
    difficulty.json  phases.json  i18n/en.json
  src/
    core/               # Module 2: clock, RNG(seed), game state, phase manager, save
    cards/              # Module 3: Card model, factory, stack/capacity rules
    recipes/            # Module 4: recipe matcher + executor, idea discovery
    economy/            # Module 5: cash, wads, bank, payroll, rent, tax, stock
    systems/            # Module 6: stress, bug, inspector, strike, events, boards/gateway
    ui/                 # Module 7: table, drag-drop, zones, tooltips, HUD, tabs
    audio/              # Module 8: music, sfx (event-driven)
    tools/              # Module 9: balance_sim (headless), data validator, debug console
  assets/ (sprites, fonts, sfx, music)
  tests/ (unit + scenario)
  docs/ (spec này)
```

## Data schema mẫu
```json
{"id":"dev","name":"Developer","type":"person","stack_max":1,
 "stats":{"wage":12,"speed":1.0,"stress_max":10},"tags":["worker","tech"]}
```
Recipe: `{"id":"r_proto","root":"laptop_old","stack":["dev","concept"],"worker":"dev","time":40,"outputs":["prototype"],"consumes":["concept"],"stress":1,"idea":null}`.

## Save
Autosave mỗi Pay Cycle + khi thoát; lưu: seed, difficulty, phase, tick, card list (id, pos, state, stack_id), ideas, quests, counters. Phiên bản save có `schema_version`.

## Quy tắc kỹ thuật
- Fixed tick 10 Hz cho sim; render độc lập.
- Mọi RNG qua `GameRng` (seeded). Không dùng `randi()` trực tiếp.
- Data validator chạy khi build: id trùng, recipe tham chiếu id không tồn tại, vòng lặp vô tận trong recipe.
- Debug console: `spawn <id>`, `set_phase n`, `skip_days n`, `cash n` — chỉ bật ở debug build.
