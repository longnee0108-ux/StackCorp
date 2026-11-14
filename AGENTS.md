# StackCorp
- User chat overrides StackCorp_Spec. No PDF creation without explicit authorization.
- Godot 4.6.1 standard / GDScript / Compatibility renderer; no plugins or external packages.
- Backend owns rules and state; frontend sends commands and renders. Never add gameplay rules to UI.
- Data and English display strings belong in data JSON; gameplay RNG is seeded and saved.
- Start Windows: Play.cmd. Editor: Editor.cmd or open project.godot and F5.
- Headless import: godot --headless --path . --editor --import
- Focused checks: godot --headless --path . --script tools/scenario_test.gd
- src/backend and data: simulation; src/frontend and scenes: presentation.
- scripts: launcher. assets: locally bundled art. docs: implementation and acceptance.
- Keep saves in user://; never reset an existing save without the player's action.
- Keep checks targeted; no bulk bot runs unless needed to investigate or measure balance.
- Finish technical changes with fresh parser/scenario evidence and a short visual check.

