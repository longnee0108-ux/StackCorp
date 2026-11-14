extends Node2D

const Backend = preload("res://src/backend/game_sim.gd")
const CardView = preload("res://src/frontend/card_view.gd")
const Backdrop = preload("res://src/frontend/board_backdrop.gd")
const AmbientAudio = preload("res://src/frontend/ambient_audio.gd")
const INK = Color("344436")
const PAPER = Color("fff2d6")
const MUTED = Color("72806a")
var sim = Backend.new()
var camera: Camera2D
var backdrop: Node2D
var card_layer: Node2D
var views: Dictionary = {}
var ui_root: Control
var hud: HBoxContainer
var money_label: Label
var clock_label: Label
var cap_label: Label
var office_label: Label
var payroll_bar: ProgressBar
var pause_button: Button
var speed_buttons: Array = []
var shop: HFlowContainer
var sell_zone: PanelContainer
var toast_label: Label
var detail_panel: PanelContainer
var detail_text: RichTextLabel
var detail_actions: VBoxContainer
var popup: PanelContainer
var menu_layer: ColorRect
var menu_panel: PanelContainer
var tutorial_panel: PanelContainer
var tutorial_text: Label
var tutorial_title: Label
var tutorial_index = 0
var show_tutorial = true
var tutorial_seen: Dictionary = {}
var selected_uid = -1
var hovered_uid = -1
var dragged_uid = -1
var drag_offset = Vector2.ZERO
var drag_started = Vector2.ZERO
var drag_origin = Vector2.ZERO
var drag_moved = false
var drag_members: Dictionary = {}
var panning = false
var pan_origin = Vector2.ZERO
var world_origin = Vector2.ZERO
var game_running = false
var ui_timer = 0.0
var toast_time = 0.0
var toast_message = ""
var current_difficulty = "easy"
var open_panel = ""
var shop_stamp = ""
var last_status = ""
var reduced_motion = false
var auto_pause = true
var strings: Dictionary = {}
var menu_page = "home"
var screen_size = Vector2(1600, 900)
var board_buttons: HBoxContainer
var ui_theme: Theme
var sfx_player: AudioStreamPlayer
var click_sound: AudioStreamWAV
var selected_sound: AudioStreamWAV
var muted = false
var music_enabled = true
var ambient_audio: Node
var practice_mode = false
var tutorial_next: Button
var detail_action_stamp = ""

func _ready() -> void:
	_load_ui_preferences()
	_load_strings()
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_min_size(Vector2i(1000, 650))
	backdrop = Backdrop.new()
	add_child(backdrop)
	card_layer = Node2D.new()
	add_child(card_layer)
	camera = Camera2D.new()
	camera.position = Vector2(0, 0)
	camera.zoom = Vector2(0.82, 0.82)
	add_child(camera)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -17
	add_child(sfx_player)
	click_sound = _make_sound(350.0, 0.055)
	selected_sound = _make_sound(520.0, 0.065)
	ambient_audio = AmbientAudio.new()
	add_child(ambient_audio)
	ambient_audio.set_enabled(music_enabled)
	sim.new_run("easy", 0)
	_build_ui()
	_sync_cards()
	_refresh_hud()
	_open_menu("home")
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func _load_strings() -> void:
	var file = FileAccess.open("res://data/i18n/en.json", FileAccess.READ)
	if file:
		var value: Variant = JSON.parse_string(file.get_as_text())
		if value is Dictionary: strings = value

func ui(key: String, fallback: String) -> String:
	return str(strings.get("ui." + key, strings.get(key, fallback)))

func _style(color: Color = PAPER, radius: int = 9, border: int = 2) -> StyleBoxFlat:
	var value = StyleBoxFlat.new()
	value.bg_color = color
	value.border_color = INK
	value.set_border_width_all(border)
	value.set_corner_radius_all(radius)
	value.content_margin_left = 15
	value.content_margin_right = 15
	value.content_margin_top = 10
	value.content_margin_bottom = 10
	value.shadow_color = Color("21372b30")
	value.shadow_size = 3
	value.shadow_offset = Vector2(3, 5)
	return value

func _label(text_value: String, size_value: int = 18, color: Color = INK) -> Label:
	var value = Label.new()
	value.text = text_value
	value.add_theme_font_size_override("font_size", size_value)
	value.add_theme_color_override("font_color", color)
	return value

func _button(text_value: String, callback: Callable, primary = false) -> Button:
	var value = Button.new()
	value.text = text_value
	value.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	value.add_theme_stylebox_override("normal", _style(INK if primary else PAPER, 7, 2))
	value.add_theme_stylebox_override("hover", _style(Color("4f6450") if primary else Color("f3deb0"), 7, 2))
	value.add_theme_stylebox_override("pressed", _style(Color("ced6b5"), 7, 2))
	value.add_theme_color_override("font_color", PAPER if primary else INK)
	value.add_theme_color_override("font_hover_color", PAPER if primary else INK)
	value.add_theme_color_override("font_pressed_color", INK)
	value.add_theme_color_override("font_disabled_color", Color("89917c"))
	value.pressed.connect(func(): _play_sound(click_sound); callback.call())
	return value

func _panel() -> PanelContainer:
	var value = PanelContainer.new()
	value.add_theme_stylebox_override("panel", _style())
	return value

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_root)
	ui_theme = Theme.new()
	ui_theme.default_font_size = 17
	for control_type in ["CheckButton", "CheckBox"]:
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			ui_theme.set_color(color_name, control_type, INK)
		ui_theme.set_color("font_disabled_color", control_type, MUTED)
	var font_path = "res://assets/fonts/Nunito.ttf"
	if ResourceLoader.exists(font_path): ui_theme.default_font = load(font_path)
	ui_root.theme = ui_theme
	var hud_panel = _panel()
	hud_panel.name = "HUD"
	ui_root.add_child(hud_panel)
	hud_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hud_panel.offset_left = 22
	hud_panel.offset_top = 16
	hud_panel.offset_right = -22
	hud_panel.offset_bottom = 83
	hud = HBoxContainer.new()
	hud.add_theme_constant_override("separation", 22)
	hud_panel.add_child(hud)
	var brand = _label(ui("brand", "StackCorp"), 26)
	brand.add_theme_font_override("font", preload("res://assets/fonts/PatrickHand-Regular.ttf"))
	hud.add_child(brand)
	office_label = _label("", 15, MUTED)
	hud.add_child(office_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)
	money_label = _label("", 22)
	hud.add_child(money_label)
	cap_label = _label("", 17)
	hud.add_child(cap_label)
	var clock_box = VBoxContainer.new()
	clock_box.custom_minimum_size.x = 220
	hud.add_child(clock_box)
	clock_label = _label("", 15)
	clock_box.add_child(clock_label)
	payroll_bar = ProgressBar.new()
	payroll_bar.custom_minimum_size.y = 5
	payroll_bar.show_percentage = false
	payroll_bar.add_theme_stylebox_override("background", _style(Color("d9ddbf"), 2, 0))
	payroll_bar.add_theme_stylebox_override("fill", _style(Color("758d66"), 2, 0))
	clock_box.add_child(payroll_bar)
	pause_button = _button(ui("pause", "Pause"), _toggle_pause)
	hud.add_child(pause_button)
	for speed_value in [1, 2, 3]:
		var button = _button("%d×" % speed_value, func(): _send("set_speed", {"value":speed_value}); _send("set_paused", {"value":false}))
		speed_buttons.append(button)
		hud.add_child(button)
	hud.add_child(_button("☰", func(): _open_menu("pause")))
	shop = HFlowContainer.new()
	shop.name = "Shop"
	shop.add_theme_constant_override("h_separation", 9)
	shop.add_theme_constant_override("v_separation", 8)
	ui_root.add_child(shop)
	shop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	shop.offset_left = 26
	shop.offset_top = 99
	shop.offset_right = -175
	shop.offset_bottom = 180
	board_buttons = HBoxContainer.new()
	board_buttons.add_theme_constant_override("separation", 6)
	ui_root.add_child(board_buttons)
	board_buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	board_buttons.offset_left = 24
	board_buttons.offset_top = -63
	board_buttons.offset_bottom = -15
	var dock = _panel()
	dock.name = "Dock"
	ui_root.add_child(dock)
	dock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dock.offset_left = -300
	dock.offset_right = 300
	dock.offset_top = -70
	dock.offset_bottom = -16
	var dock_row = HBoxContainer.new()
	dock_row.add_theme_constant_override("separation", 7)
	dock.add_child(dock_row)
	for item in [["ideas", "Ideas"], ["goals", "Goals"], ["company", "Company"], ["help", "Help"]]:
		var item_key = str(item[0])
		dock_row.add_child(_button(ui(item_key, item[1]), func(): _toggle_panel(item_key)))
	dock_row.add_child(_button(ui("save", "Save"), _save))
	sell_zone = _panel()
	sell_zone.name = "SellZone"
	ui_root.add_child(sell_zone)
	sell_zone.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	sell_zone.offset_left = -133
	sell_zone.offset_right = -22
	sell_zone.offset_top = -60
	sell_zone.offset_bottom = 65
	var sell_label = _label(ui("sell_zone", "SELL\nDrop a card"), 18)
	sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_zone.add_child(sell_label)
	toast_label = _label("", 17)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_stylebox_override("normal", _style())
	ui_root.add_child(toast_label)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_top = 184
	toast_label.offset_left = -380
	toast_label.offset_right = 380
	toast_label.visible = false
	detail_panel = _panel()
	detail_panel.name = "CardDetails"
	ui_root.add_child(detail_panel)
	detail_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	detail_panel.offset_left = -330
	detail_panel.offset_right = -23
	detail_panel.offset_top = -364
	detail_panel.offset_bottom = -88
	var details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	detail_panel.add_child(details)
	var detail_header = HBoxContainer.new()
	details.add_child(detail_header)
	var title = _label(ui("card_details", "Card details"), 15, MUTED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_header.add_child(title)
	detail_header.add_child(_button("×", func(): selected_uid = -1; detail_panel.hide()))
	detail_text = RichTextLabel.new()
	detail_text.bbcode_enabled = true
	detail_text.add_theme_color_override("default_color", INK)
	detail_text.fit_content = true
	detail_text.custom_minimum_size.y = 80
	detail_text.scroll_active = false
	details.add_child(detail_text)
	detail_actions = VBoxContainer.new()
	detail_actions.add_theme_constant_override("separation", 5)
	details.add_child(detail_actions)
	detail_panel.hide()
	popup = _panel()
	popup.name = "Notebook"
	ui_root.add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	popup.offset_left = 24
	popup.offset_top = 197
	popup.offset_right = 454
	popup.offset_bottom = 699
	popup.hide()
	tutorial_panel = _panel()
	ui_root.add_child(tutorial_panel)
	tutorial_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	tutorial_panel.offset_left = 24
	tutorial_panel.offset_right = 420
	tutorial_panel.offset_top = -250
	tutorial_panel.offset_bottom = -86
	var tutorial_box = VBoxContainer.new()
	tutorial_box.add_theme_constant_override("separation", 6)
	tutorial_panel.add_child(tutorial_box)
	tutorial_title = _label("", 16)
	tutorial_box.add_child(tutorial_title)
	tutorial_text = _label("", 16)
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_text.custom_minimum_size.x = 350
	tutorial_box.add_child(tutorial_text)
	var tutorial_row = HBoxContainer.new()
	tutorial_box.add_child(tutorial_row)
	tutorial_next = _button(ui("next_tip", "Next tip →"), func(): tutorial_index += 1; _refresh_tutorial())
	tutorial_row.add_child(tutorial_next)
	tutorial_row.add_child(_button(ui("hide", "Hide"), func(): show_tutorial = false; tutorial_panel.hide(); _save_ui_preferences()))
	menu_layer = ColorRect.new()
	menu_layer.color = Color("203b335e")
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(menu_layer)
	menu_panel = _panel()
	menu_layer.add_child(menu_panel)
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu_panel.offset_left = -354
	menu_panel.offset_top = -310
	menu_panel.offset_right = 354
	menu_panel.offset_bottom = 310

func _layout_ui() -> void:
	if not ui_root: return
	screen_size = get_viewport_rect().size
	var compact_ui = screen_size.x < 1300
	for node in [office_label]: node.visible = not compact_ui
	hud.add_theme_constant_override("separation", 10 if compact_ui else 22)
	if compact_ui:
		money_label.add_theme_font_size_override("font_size", 18)
		clock_label.get_parent().custom_minimum_size.x = 165
		clock_label.add_theme_font_size_override("font_size", 13)
		for button in speed_buttons: button.add_theme_font_size_override("font_size", 14)
		tutorial_panel.offset_right = 355
		tutorial_text.custom_minimum_size.x = 285
	else:
		money_label.add_theme_font_size_override("font_size", 22)
		clock_label.get_parent().custom_minimum_size.x = 220
		clock_label.add_theme_font_size_override("font_size", 15)
		for button in speed_buttons: button.add_theme_font_size_override("font_size", 17)
		tutorial_panel.offset_right = 420
		tutorial_text.custom_minimum_size.x = 350
	if menu_panel: _fit_menu()

func _fit_menu() -> void:
	if not menu_panel: return
	var menu_size = menu_panel.get_combined_minimum_size().max(Vector2(708, 620))
	menu_panel.size = menu_size
	menu_panel.pivot_offset = menu_size * 0.5
	menu_panel.position = (get_viewport_rect().size - menu_size) * 0.5
	var fit = minf(1.0, minf((get_viewport_rect().size.x - 36) / menu_size.x, (get_viewport_rect().size.y - 36) / menu_size.y))
	menu_panel.scale = Vector2(fit, fit)

func _process(delta: float) -> void:
	if game_running and not menu_layer.visible:
		sim.step(delta)
		ui_timer += delta
		if ui_timer >= 0.1:
			ui_timer = 0
			_sync_cards()
			_refresh_hud()
			_handle_events()
			if selected_uid >= 0: _refresh_details(false)
	if toast_time > 0:
		toast_time -= delta
		toast_label.visible = true
		if toast_time <= 0: toast_label.visible = false
	if game_running and not menu_layer.visible:
		var mouse = get_global_mouse_position()
		var new_hover = _hit_card(mouse, dragged_uid, dragged_uid >= 0)
		if new_hover != hovered_uid:
			if views.has(hovered_uid): views[hovered_uid].hovered = false; views[hovered_uid].queue_redraw()
			hovered_uid = new_hover
			if views.has(hovered_uid): views[hovered_uid].hovered = true; views[hovered_uid].queue_redraw()
		if dragged_uid >= 0 and views.has(dragged_uid):
			var next_position = mouse - drag_offset
			var drag_order = 0
			for uid in drag_members:
				if not views.has(uid): continue
				views[uid].position = next_position + drag_members[uid]
				views[uid].display_position = views[uid].position
				views[uid].z_index = 4000 + mini(94, drag_order)
				drag_order += 1
			if get_viewport().get_mouse_position().distance_to(drag_started) > 7: drag_moved = true

func _sync_cards() -> void:
	var board = int(sim.state.get("board", 0))
	var alive: Dictionary = {}
	var stack_map: Dictionary = {}
	var stack_order: Dictionary = {}
	var live_stack_index = 0
	for stack in sim.state.get("stacks", []):
		stack_order[int(stack.get("uid", 0))] = live_stack_index
		live_stack_index += 1
		var ids: Array = stack.get("cards", [])
		for i in range(ids.size()): stack_map[int(ids[i])] = {"stack":stack,"index":i}
	var index = 0
	for value in sim.state.get("cards", []):
		var uid = int(value.get("uid", -1))
		if int(value.get("board", 0)) != board: continue
		if int(value.get("stored_in", -1)) >= 0: continue
		alive[uid] = true
		if not views.has(uid):
			var view = CardView.new()
			view.setup(value, sim.definition(str(value.get("id", ""))))
			view.position = Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
			card_layer.add_child(view)
			views[uid] = view
		var card_view = views[uid]
		if str(card_view.definition.get("id", "")) != str(value.get("id", "")):
			card_view.setup(value, sim.definition(str(value.get("id", ""))))
		card_view.card = value
		card_view.selected = selected_uid == uid
		card_view.target = dragged_uid >= 0 and hovered_uid == uid
		card_view.reduced_motion = reduced_motion
		card_view.sell_value = int(sim.sell_price(uid)) if card_view.definition.get("sell_price") != null else -1
		card_view.work_progress = -1
		card_view.work_name = ""
		if uid != dragged_uid:
			card_view.display_position = Vector2(float(value.get("x", 0)), float(value.get("y", 0)))
			card_view.z_index = index
		if stack_map.has(uid):
			var item: Dictionary = stack_map[uid]
			var stack: Dictionary = item["stack"]
			var cards: Array = stack.get("cards", [])
			var root_card = sim.card(int(cards[0])) if not cards.is_empty() else {}
			if uid != dragged_uid and not root_card.is_empty():
				card_view.display_position = Vector2(float(root_card.get("x", 0)), float(root_card.get("y", 0))) + Vector2(0, int(item["index"]) * 29)
			card_view.z_index = mini(3900, 100 + int(stack_order.get(int(stack.get("uid", 0)), 0)) * 12 + int(item["index"])) if uid != dragged_uid else 4095
			if int(item["index"]) == cards.size() - 1 and float(stack.get("duration", 0)) > 0:
				card_view.work_progress = float(stack.get("progress", 0)) / float(stack.get("duration", 1))
				card_view.work_name = ui("pending", "Free a slot") if bool(stack.get("pending", false)) else str(stack.get("recipe", "Working")).trim_prefix("r_").replace("_", " ").capitalize()
		card_view.queue_redraw()
		index += 1
	for uid in views.keys():
		if not alive.has(uid): views[uid].queue_free(); views.erase(uid)
	if selected_uid >= 0 and not alive.has(selected_uid):
		selected_uid = -1
		detail_panel.hide()
	if backdrop.board != board:
		backdrop.board = board
		backdrop.queue_redraw()

func _refresh_hud() -> void:
	var s: Dictionary = sim.state
	ambient_audio.set_phase(int(s.get("phase", 1)))
	money_label.text = "$%d" % int(sim.cash_available())
	money_label.tooltip_text = ui("cash_tooltip", "Cash on this board. Open Company for your shared bank balance.")
	var used = int(sim.used_capacity())
	var capacity_value = int(sim.capacity())
	cap_label.text = "%d/%d %s" % [used, capacity_value, ui("cards", "cards")]
	cap_label.add_theme_color_override("font_color", Color("a14f3f") if used >= capacity_value else INK)
	var payroll: Dictionary = sim.payroll_preview()
	var due = float(payroll.get("due_in", 0))
	var day_seconds = float(sim.rules().get("day_seconds", 60))
	clock_label.text = "%s %d · %s %.1fd" % [ui("day", "Day"), int(s.get("day", 1)), ui("payroll_in", "payroll in"), due / day_seconds]
	clock_label.tooltip_text = "%s: $%d  |  %s: $%d" % [ui("rent", "Rent"), int(payroll.get("rent", 0)), ui("wages", "Wages"), int(payroll.get("wages", 0))]
	var difficulty_data: Dictionary = sim.db.get("difficulty", {}).get(str(s.get("difficulty", "easy")), {})
	var cycle_seconds = float(difficulty_data.get("cycle_days", difficulty_data.get("pay_cycle", 7))) * day_seconds
	payroll_bar.value = (1.0 - clampf(due / cycle_seconds, 0.0, 1.0)) * 100
	office_label.text = str(s.get("office", "garage")).replace("_", " ").capitalize()
	pause_button.text = ui("resume", "Resume") if bool(s.get("paused", false)) else ui("pause", "Pause")
	for i in range(speed_buttons.size()):
		speed_buttons[i].modulate = Color.WHITE if int(s.get("speed", 1)) == i + 1 else Color("b7b7a3")
	var stamp = str(s.get("phase", 1)) + str(s.get("office", ""))
	if stamp != shop_stamp:
		shop_stamp = stamp
		_refresh_shop()
	_refresh_boards()
	tutorial_panel.visible = game_running and show_tutorial and not menu_layer.visible and open_panel == ""
	if practice_mode and not menu_layer.visible: _refresh_practice()
	if bool(s.get("ended", false)) or (bool(s.get("victory", false)) and last_status != "victory"):
		last_status = "victory" if bool(s.get("victory", false)) else "ended"
		_open_menu(last_status)

func _refresh_shop() -> void:
	for child in shop.get_children(): child.queue_free()
	for value in sim.available_packs():
		var id = str(value.get("id", "")) if value is Dictionary else str(value)
		var pack: Dictionary = sim.db.get("packs", {}).get(id, {})
		if pack.is_empty(): continue
		var price = sim.pack_price(id)
		var pack_name = str(pack.get("name", id))
		var button = _button("%s\n$%d · %d cards" % [pack_name, price, int(pack.get("count", 3))], func():
			var result = _send("buy_pack", {"id":id,"x":camera.position.x + randf_range(-200, 200),"y":camera.position.y - 220})
			if bool(result.get("ok", false)): _tutorial_action("buy_pack"))
		button.custom_minimum_size = Vector2(123, 67)
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = str(pack.get("description", ui("buy_pack", "Buy this pack. Cards are placed on your table.")))
		shop.add_child(button)

func _refresh_boards() -> void:
	var boards: Array = sim.state.get("boards", [])
	if board_buttons.get_child_count() == boards.size(): return
	for child in board_buttons.get_children(): child.queue_free()
	for value in boards:
		var id = int(value.get("id", 0))
		board_buttons.add_child(_button(str(value.get("name", "Office")), func(): _send("set_board", {"board":id}); camera.position = Vector2.ZERO; _sync_cards()))

func _send(kind: String, payload: Dictionary = {}) -> Dictionary:
	var result: Dictionary = sim.command(kind, payload)
	if not bool(result.get("ok", false)):
		_toast(str(result.get("message", ui("not_possible", "That action is not available yet."))))
	elif str(result.get("message", "")) != "":
		_toast(str(result.get("message", "")))
	_sync_cards()
	_refresh_hud()
	if selected_uid >= 0: _refresh_details(true)
	return result

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if menu_layer.visible and game_running: _close_menu()
			elif popup.visible: _toggle_panel(open_panel)
			elif detail_panel.visible: selected_uid = -1; detail_panel.hide()
			else: _open_menu("pause" if game_running else "home")
			get_viewport().set_input_as_handled()
			return
		if not game_running or menu_layer.visible: return
		if event.keycode == KEY_SPACE: _toggle_pause()
		elif event.keycode == KEY_F5: _save()
		elif event.keycode == KEY_HOME: camera.position = Vector2.ZERO; camera.zoom = Vector2(0.82, 0.82)
		elif event.keycode == KEY_I: _toggle_panel("ideas")
		elif event.keycode == KEY_G: _toggle_panel("goals")
		elif event.keycode == KEY_1: _send("set_speed", {"value":1})
		elif event.keycode == KEY_2: _send("set_speed", {"value":2})
		elif event.keycode == KEY_3: _send("set_speed", {"value":3})
	if not game_running or menu_layer.visible: return
	if event is InputEventMouseButton:
		var mouse = get_global_mouse_position()
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var pointer_offset = get_viewport().get_mouse_position() - get_viewport_rect().size * 0.5
			var old_zoom = camera.zoom.x
			var zoom_value = clampf(camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.9), 0.45, 1.7)
			camera.position += pointer_offset * (1.0 / old_zoom - 1.0 / zoom_value)
			camera.zoom = Vector2(zoom_value, zoom_value)
			camera.force_update_scroll()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			pan_origin = get_viewport().get_mouse_position()
			world_origin = camera.position
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var hit = _hit_card(mouse)
				if hit >= 0: _select(hit)
				else: panning = true; pan_origin = get_viewport().get_mouse_position(); world_origin = camera.position
			else: panning = false
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var hit = _hit_card(mouse)
				if hit >= 0:
					var start_position: Vector2 = views[hit].position
					if event.shift_pressed: _send("unstack", {"uid":hit,"x":start_position.x,"y":start_position.y})
					dragged_uid = hit
					drag_offset = mouse - views[hit].position
					drag_started = get_viewport().get_mouse_position()
					drag_origin = views[hit].position
					drag_moved = false
					drag_members.clear()
					var moving_stack = int(sim.card(hit).get("stack_id", -1))
					for uid in views:
						if int(uid) == hit or (moving_stack >= 0 and int(sim.card(int(uid)).get("stack_id", -1)) == moving_stack):
							drag_members[uid] = views[uid].position - drag_origin
				else:
					selected_uid = -1
					detail_panel.hide()
			else: _finish_drag()
	elif event is InputEventMouseMotion and panning:
		camera.position = world_origin - (get_viewport().get_mouse_position() - pan_origin) / camera.zoom

func _input(event: InputEvent) -> void:
	# Release must arrive even if a dragged card ends above an interface panel.
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and dragged_uid >= 0: _finish_drag()
		elif event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]: panning = false

func _finish_drag() -> void:
	if dragged_uid < 0: return
	var uid = dragged_uid
	dragged_uid = -1
	if not views.has(uid): drag_members.clear(); return
	drag_moved = drag_moved or get_viewport().get_mouse_position().distance_to(drag_started) > 7
	if not drag_moved:
		views[uid].display_position = drag_origin
		_select(uid)
		drag_members.clear()
		return
	var mouse = get_global_mouse_position()
	if sell_zone.get_global_rect().has_point(get_viewport().get_mouse_position()):
		var sold_result = _send("sell", {"uid":uid})
		if bool(sold_result.get("ok", false)): _tutorial_action("sell")
	else:
		var hit = _hit_card(mouse, uid, true)
		if hit >= 0:
			var result = _send("stack", {"uid":uid,"target":hit})
			if bool(result.get("ok", false)): _tutorial_action("stack")
			else: _send("move", {"uid":uid,"x":mouse.x - drag_offset.x,"y":mouse.y - drag_offset.y})
		else:
			_send("move", {"uid":uid,"x":mouse.x - drag_offset.x,"y":mouse.y - drag_offset.y})
	_play_sound(selected_sound)
	drag_members.clear()
	_sync_cards()

func _hit_card(mouse: Vector2, exclude: int = -1, exclude_moving_stack: bool = false) -> int:
	var best = -1
	var best_z = -100000
	for uid in views:
		if int(uid) == exclude: continue
		if exclude_moving_stack and drag_members.has(uid): continue
		var value = views[uid]
		if Rect2(value.position, CardView.SIZE).has_point(mouse) and value.z_index >= best_z:
			best = int(uid)
			best_z = value.z_index
	return best

func _select(uid: int) -> void:
	selected_uid = uid
	_play_sound(selected_sound)
	_refresh_details(true)
	_sync_cards()

func _refresh_details(rebuild: bool = true) -> void:
	var card: Dictionary = sim.card(selected_uid)
	if card.is_empty(): detail_panel.hide(); return
	var definition: Dictionary = sim.definition(str(card.get("id", "")))
	var copy = "[b]%s[/b]\n%s" % [definition.get("name", "Card"), definition.get("description", "")]
	if definition.get("type") == "person": copy += "\n%s %.1f/10 · %s $%d/cycle" % [ui("stress", "Stress"), float(card.get("stress", 0)), ui("wage", "Wage"), int(sim.wage_for(selected_uid))]
	if int(card.get("amount", 0)) > 0: copy += "\n%s: %s" % [ui("amount", "Amount"), card.get("amount", 0)]
	var hint = str(sim.recipe_hint(selected_uid))
	if hint != "": copy += "\n[color=#61744f]%s[/color]" % hint
	detail_text.text = copy
	detail_panel.show()
	var available_actions: Array = sim.actions_for(selected_uid)
	var action_stamp = str(selected_uid) + JSON.stringify(available_actions)
	if not rebuild and action_stamp == detail_action_stamp: return
	detail_action_stamp = action_stamp
	for child in detail_actions.get_children(): child.queue_free()
	for action in available_actions:
		var id = str(action.get("id", ""))
		var label = str(action.get("label", id.capitalize()))
		if int(action.get("cost", 0)) > 0 and not "$" in label: label += " · $%d" % int(action.cost)
		var button = _button(label, func(): _run_card_action(id))
		button.add_theme_font_size_override("font_size", 14)
		button.disabled = not bool(action.get("enabled", true))
		detail_actions.add_child(button)
	var bottom = HBoxContainer.new()
	detail_actions.add_child(bottom)
	if int(card.get("stack_id", -1)) >= 0:
		bottom.add_child(_button(ui("separate", "Separate"), func(): _send("unstack", {"uid":selected_uid,"x":float(card.get("x", 0)) + 185,"y":float(card.get("y", 0))})))
	if definition.get("sell_price") != null:
		bottom.add_child(_button(ui("sell", "Sell"), func():
			var result = _send("sell", {"uid":selected_uid})
			if bool(result.get("ok", false)): _tutorial_action("sell")))

func _run_card_action(id: String) -> void:
	var known_commands = ["rest", "discover", "consume", "dismiss", "pay_invoice", "deposit", "unstack"]
	var result: Dictionary
	if id in known_commands:
		result = _send(id, {"uid":selected_uid})
	else:
		result = _send("action", {"id":id,"uid":selected_uid})
	if bool(result.get("ok", false)): _tutorial_action(id)

func _toggle_pause() -> void:
	_send("set_paused", {"value":not bool(sim.state.get("paused", false))})
	_tutorial_action("pause")

func _toggle_panel(kind: String) -> void:
	if open_panel == kind and popup.visible:
		popup.hide(); open_panel = ""; _refresh_hud(); return
	open_panel = kind
	for child in popup.get_children(): child.queue_free()
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	popup.add_child(box)
	var header = HBoxContainer.new()
	box.add_child(header)
	var heading = _label(ui(kind, kind.capitalize()), 25)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(_button("×", func(): popup.hide(); open_panel = ""; _refresh_hud()))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(385, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	if kind == "ideas": _ideas_content(content)
	elif kind == "goals": _goals_content(content)
	elif kind == "company": _company_content(content)
	else: _help_content(content)
	popup.show()
	tutorial_panel.hide()

func _wrapped(text_value: String, size_value: int = 16) -> Label:
	var label = _label(text_value, size_value)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 340
	return label

func _ingredient_name(id: String) -> String:
	var roles = {"#worker":ui("role_worker", "Any worker"),"#builder":ui("role_builder", "Developer or Founder"),"#designer":ui("role_designer", "Designer or Founder"),"#sales":ui("role_sales", "Sales Rep or Founder"),"#person":ui("role_person", "Any person")}
	return str(roles.get(id, sim.definition(id).get("name", id.replace("#", "").replace("_", " ").capitalize())))

func _ideas_content(box: VBoxContainer) -> void:
	box.add_child(_wrapped(ui("ideas_intro", "Stack ingredients on the root card. Workers and equipment remain; ingredients are consumed. Discovered Ideas are permanent.")))
	for recipe in sim.db.get("recipes", []):
		var idea = str(recipe.get("idea", ""))
		if int(recipe.get("phase", 1)) > int(sim.state.get("phase", 1)): continue
		var unlocked = idea == "" or idea == "starter" or idea in sim.state.get("ideas", [])
		var text_value = str(recipe.get("name", recipe.get("id", "Recipe")))
		if not unlocked:
			box.add_child(_wrapped("◇ " + text_value + " · " + ui("undiscovered", "Find its Idea"), 15))
			continue
		var names: Array = [_ingredient_name(str(recipe.get("root", "")))]
		for id in recipe.get("inputs", []): names.append(_ingredient_name(str(id)))
		box.add_child(_wrapped("✓ " + text_value + "\n" + " + ".join(names) + "\n%ss" % str(recipe.get("time", 0)), 15))

func _goals_content(box: VBoxContainer) -> void:
	box.add_child(_wrapped(ui("goals_intro", "A small company, one good decision at a time. Complete milestones to discover new packs and equipment.")))
	for goal in sim.goals():
		if goal is Dictionary:
			var done = bool(goal.get("completed", goal.get("done", goal.get("complete", false))))
			box.add_child(_wrapped(("✓ " if done else "○ ") + str(goal.get("name", goal.get("title", goal.get("id", "Goal"))))))
			if goal.get("description", "") != "": box.add_child(_wrapped(str(goal.get("description")), 14))
		else: box.add_child(_wrapped(str(goal)))
	box.add_child(_button(ui("company_actions", "Open company actions"), func(): _toggle_panel("company")))

func _company_content(box: VBoxContainer) -> void:
	var payroll: Dictionary = sim.payroll_preview()
	box.add_child(_wrapped("%s: $%d\n%s: $%d\n%s: $%d\n%s: %s/5" % [ui("next_payroll", "Next payroll"), int(payroll.get("total", 0)), ui("cash", "Cash"), int(sim.cash_available()), ui("bank", "Bank"), int(sim.state.get("bank", 0)), ui("reputation", "Reputation"), str(sim.state.get("reputation", 2))]))
	for item in sim.actions_for():
		var id = str(item.get("id", ""))
		var label = str(item.get("label", id))
		if int(item.get("cost", 0)) > 0: label += " · $%d" % int(item.cost)
		box.add_child(_button(label, func(): _send("action", {"id":id}); _toggle_panel("company"); _toggle_panel("company")))
	var bank_row = HBoxContainer.new()
	box.add_child(bank_row)
	bank_row.add_child(_button(ui("withdraw_20", "Withdraw $20"), func(): _send("withdraw", {"amount":20})))
	bank_row.add_child(_button(ui("withdraw_100", "Withdraw $100"), func(): _send("withdraw", {"amount":100})))
	if int(sim.state.get("phase", 1)) >= 3: box.add_child(_wrapped("%s: %s" % [ui("stock_price", "Share price"), str(sim.state.get("stock", 100))]))

func _help_content(box: VBoxContainer) -> void:
	box.add_child(_wrapped(ui("controls", "Drag cards together to work. Drag a root to move its stack. Shift-drag or Separate to remove one card. Right-click a card for actions.\n\nMouse wheel: zoom\nMiddle mouse / right-drag empty table: pan\nSpace: pause / resume\n1 / 2 / 3: speed\nHome: return to table\nI: Ideas · G: Goals\nEsc: menu")))
	box.add_child(_wrapped(ui("survival_help", "Reserve cash for rent and wages before expanding. Let stressed workers take a break. Keep your receipts and prepare for inspections. Your Founder always has a way back.")))
	box.add_child(_button(ui("replay_tutorial", "Replay tutorial"), func(): tutorial_index = 0; show_tutorial = true; popup.hide(); open_panel = ""; _refresh_tutorial(); _refresh_hud()))
	box.add_child(_button(ui("settings", "Settings"), func(): _open_menu("settings")))

func _open_menu(page: String) -> void:
	menu_page = page
	menu_layer.show()
	tutorial_panel.hide()
	for child in menu_panel.get_children(): child.queue_free()
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	menu_panel.add_child(box)
	var title = _label(ui("brand", "StackCorp"), 62)
	title.add_theme_font_override("font", preload("res://assets/fonts/PatrickHand-Regular.ttf"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle = _label(ui("tagline", "Small cards. Big ambitions."), 20, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(HSeparator.new())
	if page == "settings":
		box.add_child(_label(ui("settings", "Settings"), 24))
		var motion = CheckButton.new()
		motion.text = ui("reduced_motion", "Reduce card motion")
		motion.button_pressed = reduced_motion
		motion.toggled.connect(func(value): reduced_motion = value; _save_ui_preferences())
		box.add_child(motion)
		var alerts = CheckButton.new()
		alerts.text = ui("auto_pause", "Pause on important alerts")
		alerts.button_pressed = auto_pause
		alerts.toggled.connect(func(value): auto_pause = value; _save_ui_preferences())
		box.add_child(alerts)
		var sound = CheckButton.new()
		sound.text = ui("sound", "Sound effects")
		sound.button_pressed = not muted
		sound.toggled.connect(func(value): muted = not value; _save_ui_preferences())
		box.add_child(sound)
		var music = CheckButton.new()
		music.text = ui("music", "Music")
		music.button_pressed = music_enabled
		music.toggled.connect(func(value): music_enabled = value; ambient_audio.set_enabled(value); _save_ui_preferences())
		box.add_child(music)
		box.add_child(_button(ui("back", "Back"), func(): _open_menu("pause" if game_running else "home"), true))
	elif page in ["victory", "ended"]:
		box.add_child(_wrapped(ui("victory", "You rule the market!") if page == "victory" else ui("game_over", "Every company has a story."), 29))
		box.add_child(_wrapped(str(sim.state.get("notice", ui("run_finished", "Your run has finished."))), 18))
		if page == "victory": box.add_child(_button(ui("endless", "Continue in Endless Mode"), func(): sim.command("continue_endless", {}); last_status = "endless"; _close_menu(), true))
		box.add_child(_button(ui("new_company", "Start a new company"), func(): game_running = false; _open_menu("home")))
	elif page == "practice_done":
		box.add_child(_wrapped(ui("practice_done", "You're ready to build your own company."), 27))
		box.add_child(_wrapped(ui("practice_done_desc", "You have learned how to stack, produce, trade, pay bills and look after your team. Your saved company is unchanged."), 18))
		box.add_child(_button(ui("play", "Play — start your company"), func(): practice_mode = false; game_running = false; _open_menu("home"), true))
		if FileAccess.file_exists("user://save.json"): box.add_child(_button(ui("continue_company", "Continue company"), _load_game))
	elif page == "pause" and game_running:
		box.add_child(_button(ui("resume_game", "Return to your table"), _close_menu, true))
		box.add_child(_button(ui("save_game", "Save company"), _save))
		box.add_child(_button(ui("settings", "Settings"), func(): _open_menu("settings")))
		box.add_child(_button(ui("new_company", "Start a new company"), func(): _confirm_new_game()))
		box.add_child(_button(ui("quit", "Save & quit"), _quit))
	elif page == "confirm_new":
		box.add_child(_wrapped(ui("new_warning", "Your current company is saved. Starting a new company will replace the autosave when it is saved."), 18))
		box.add_child(_button(ui("continue", "Continue"), func(): game_running = false; _open_menu("home")))
		box.add_child(_button(ui("back", "Back"), func(): _open_menu("pause")))
	else:
		var difficulty_row = HBoxContainer.new()
		difficulty_row.alignment = BoxContainer.ALIGNMENT_CENTER
		difficulty_row.add_theme_constant_override("separation", 10)
		box.add_child(difficulty_row)
		for difficulty in ["easy", "medium", "hard"]:
			var button = _button(ui(difficulty, difficulty.capitalize()), func(): current_difficulty = difficulty; _open_menu("home"), current_difficulty == difficulty)
			button.custom_minimum_size.x = 170
			difficulty_row.add_child(button)
		var descriptions = {"easy":ui("easy_desc", "Room to learn, recover and grow. Recommended for your first company."),"medium":ui("medium_desc", "A tighter budget. Balance growth with the next payroll."),"hard":ui("hard_desc", "Little room for waste. Keep a reserve and respond early.")}
		box.add_child(_wrapped(descriptions[current_difficulty], 17))
		var guide = CheckButton.new()
		guide.text = ui("guided_start", "Show helpful tips as I play")
		guide.button_pressed = show_tutorial
		guide.toggled.connect(func(value): show_tutorial = value; _save_ui_preferences())
		box.add_child(guide)
		box.add_child(_button(ui("play", "Play — start your company"), _new_game, true))
		box.add_child(_button(ui("practice", "Tutorial — learn by playing"), _start_practice))
		var continue_button = _button(ui("continue_company", "Continue company"), _load_game)
		continue_button.disabled = not FileAccess.file_exists("user://save.json")
		box.add_child(continue_button)
		var bottom_row = HBoxContainer.new()
		bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
		bottom_row.add_theme_constant_override("separation", 12)
		box.add_child(bottom_row)
		bottom_row.add_child(_button(ui("settings", "Settings"), func(): _open_menu("settings")))
		bottom_row.add_child(_button(ui("quit", "Quit"), _quit))
	box.add_spacer(false)
	var footer = _label(ui("menu_footer", "Build a business at your own pace. Pause any time."), 14, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)
	call_deferred("_fit_menu")

func _close_menu() -> void:
	menu_layer.hide()
	_refresh_tutorial()
	_refresh_hud()

func _confirm_new_game() -> void:
	_save()
	_open_menu("confirm_new")

func _new_game() -> void:
	# Retain the previous run as a recovery copy before replacing the active save.
	if FileAccess.file_exists("user://save.json"):
		DirAccess.copy_absolute("user://save.json", "user://previous_company.json")
	sim.new_run(current_difficulty, 0)
	practice_mode = false
	game_running = true
	selected_uid = -1
	tutorial_index = 0
	tutorial_seen.clear()
	last_status = ""
	shop_stamp = ""
	open_panel = ""
	popup.hide()
	detail_panel.hide()
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(0.82, 0.82)
	_close_menu()
	_sync_cards()
	_refresh_shop()
	_save(false)

func _load_game() -> void:
	if sim.load_game():
		practice_mode = false
		game_running = true
		last_status = ""
		shop_stamp = ""
		current_difficulty = str(sim.state.get("difficulty", "easy"))
		_close_menu()
		_sync_cards()
		_toast(ui("loaded", "Company restored. Welcome back."))
	else: _toast(ui("load_failed", "This save could not be opened. Your file has been kept."))

func _save(show_notice = true) -> void:
	if not game_running: return
	if practice_mode:
		if show_notice: _toast(ui("practice_no_save", "Practice stays separate. Your saved company is unchanged."))
		return
	if sim.save_game():
		if show_notice: _toast(ui("saved", "Company saved."))
	else: _toast(ui("save_failed", "Could not save. Please check available disk space."))

func _quit() -> void:
	_save(false)
	_save_ui_preferences()
	if is_instance_valid(ambient_audio): ambient_audio.shutdown()
	if is_instance_valid(sfx_player):
		sfx_player.stop()
		sfx_player.stream = null
	get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(sfx_player):
		sfx_player.stop()
		sfx_player.stream = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and game_running:
		_save(false)

func _toast(text_value: String) -> void:
	toast_message = text_value
	toast_label.text = text_value
	toast_time = 5.0
	toast_label.show()

func _handle_events() -> void:
	for event in sim.drain_events():
		var kind = str(event.get("type", ""))
		var message = str(event.get("message", ""))
		if message != "": _toast(message)
		if auto_pause and kind in ["inspection", "strike", "burnout", "eviction", "phase_changed"]:
			sim.command("set_paused", {"value":true})
		if kind in ["cycle_closed", "phase_changed", "victory"]: _save(false)
		if kind in ["recipe_completed", "sold"]: _play_sound(selected_sound)
		if kind == "phase_changed": shop_stamp = ""; _refresh_shop()
		if practice_mode and kind == "recipe_completed": _tutorial_action(str(event.get("recipe", "")))
		if practice_mode and kind == "sold": _tutorial_action("sell")
		if practice_mode and kind == "pack_opened": _tutorial_action("buy_pack")

func _tutorial_action(kind: String) -> void:
	tutorial_seen[kind] = true
	var triggers = ["pause", "r_gig", "r_concept", "r_proto", "sell", "buy_pack", "pay_invoice", "rest", "discover"] if practice_mode else ["pause", "stack", "sell", "buy_pack", "pay_invoice", "rest", "discover"]
	if tutorial_index < triggers.size() and kind == triggers[tutorial_index]:
		tutorial_index += 1
		_refresh_tutorial()

func _refresh_tutorial() -> void:
	if practice_mode:
		_refresh_practice()
		return
	tutorial_next.visible = true
	var tips = [
		[ui("tip1_title", "A moment to think"),ui("tip1", "Press Space to pause. You can still move cards and plan your next move.")],
		[ui("tip2_title", "Your first client"),ui("tip2", "Drag Founder onto Old Laptop, then add Freelance Contract. The stack starts working when the recipe matches.")],
		[ui("tip3_title", "Make something worth selling"),ui("tip3", "Look in Ideas for recipes. Drag a finished product to the Sell stamp at the right edge.")],
		[ui("tip4_title", "Open new possibilities"),ui("tip4", "Choose a pack above the table. Each pack focuses on a different part of your company. Keep money for payroll.")],
		[ui("tip5_title", "Payday is coming"),ui("tip5", "The top bar shows your deadline. Select an invoice to pay it, or use Company → Pay outstanding invoices.")],
		[ui("tip6_title", "People need a break"),ui("tip6", "Select a person and choose Rest. Coffee helps too. High Stress slows work and may cause Burnout.")],
		[ui("tip7_title", "Ideas turn into a company"),ui("tip7", "Discover Idea cards to keep recipes permanently. Follow Goals toward Series A, then expand at your own pace.")],
		[ui("tip8_title", "The whole table is yours"),ui("tip8", "Zoom with the mouse wheel. Pan with middle mouse or right-drag. Shift-drag separates a card. Press Home to return.")]
	]
	if tutorial_index >= tips.size():
		show_tutorial = false
		tutorial_panel.hide()
		_save_ui_preferences()
		return
	tutorial_title.text = "%s · %d/%d" % [tips[tutorial_index][0], tutorial_index + 1, tips.size()]
	tutorial_text.text = tips[tutorial_index][1]
	tutorial_panel.visible = show_tutorial and game_running and not menu_layer.visible

func _start_practice() -> void:
	if game_running and not practice_mode: _save(false)
	sim.new_run("easy", 0)
	var result: Dictionary = sim.command("action", {"id":"start_tutorial"})
	if not bool(result.get("ok", false)):
		_toast(ui("practice_unavailable", "Practice could not be started."))
		return
	practice_mode = true
	game_running = true
	show_tutorial = true
	tutorial_index = 0
	tutorial_seen.clear()
	shop_stamp = ""
	selected_uid = -1
	detail_panel.hide()
	popup.hide()
	open_panel = ""
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(0.82, 0.82)
	_close_menu()
	_sync_cards()
	_refresh_shop()

func _refresh_practice() -> void:
	var flags: Dictionary = sim.state.get("tutorial_flags", {})
	var flag_order = ["paused", "gig", "concept", "prototype", "sold", "pack", "paid", "relief", "idea"]
	while tutorial_index < flag_order.size() and bool(flags.get(flag_order[tutorial_index], false)):
		tutorial_index += 1
	var steps = [
		[ui("practice1_title", "1. Pause and plan"),ui("practice1", "Press Space or Pause. Practice is separate from your saved company. When you're ready, resume at 1× or 2×.")],
		[ui("practice2_title", "2. Finish your first gig"),ui("practice2", "Stack Founder + Freelance Contract on Old Laptop. Resume time and wait for the payment. Shift-drag separates a card.")],
		[ui("practice3_title", "3. Sketch a Concept"),ui("practice3", "Separate Founder from the laptop, then stack Founder + Marker on Whiteboard. Wait for your Concept.")],
		[ui("practice4_title", "4. Build a Prototype"),ui("practice4", "Place Developer + Concept on Old Laptop. Wait for the Prototype. You can select the laptop to see recipe actions.")],
		[ui("practice5_title", "5. Make a sale"),ui("practice5", "Drag the finished Prototype to the Sell stamp on the right. The payment appears as real cash cards.")],
		[ui("practice6_title", "6. Open a pack"),ui("practice6", "Choose Early Leads above the table. Packs add new cards, so watch the card limit and keep cash for bills.")],
		[ui("practice7_title", "7. Pay your bills"),ui("practice7", "Select the practice invoice and choose Pay invoice. Company → Pay outstanding invoices can settle several bills.")],
		[ui("practice8_title", "8. Look after your team"),ui("practice8", "Select Developer and choose Rest. A short break lowers Stress. Coffee can also help a tired person.")],
		[ui("practice9_title", "9. Keep an Idea"),ui("practice9", "Select the golden Idea card and choose Discover. Its recipe stays in Ideas and the card leaves the table.")]
	]
	tutorial_next.visible = false
	if tutorial_index >= steps.size():
		_open_menu("practice_done")
		return
	tutorial_title.text = str(steps[tutorial_index][0])
	tutorial_text.text = str(steps[tutorial_index][1])
	tutorial_panel.visible = game_running and not menu_layer.visible

func _load_ui_preferences() -> void:
	var config = ConfigFile.new()
	if config.load("user://preferences.cfg") == OK:
		reduced_motion = bool(config.get_value("ui", "reduced_motion", false))
		auto_pause = bool(config.get_value("ui", "auto_pause", true))
		show_tutorial = bool(config.get_value("ui", "tutorial", true))
		muted = bool(config.get_value("ui", "muted", false))
		music_enabled = bool(config.get_value("ui", "music", true))

func _save_ui_preferences() -> void:
	var config = ConfigFile.new()
	config.set_value("ui", "reduced_motion", reduced_motion)
	config.set_value("ui", "auto_pause", auto_pause)
	config.set_value("ui", "tutorial", show_tutorial)
	config.set_value("ui", "muted", muted)
	config.set_value("ui", "music", music_enabled)
	config.save("user://preferences.cfg")

func _make_sound(frequency: float, duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples = int(22050 * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var envelope = pow(1.0 - float(i) / samples, 2)
		var sample = int(sin(float(i) * TAU * frequency / 22050.0) * envelope * 14000)
		bytes.encode_s16(i * 2, sample)
	stream.data = bytes
	return stream

func _play_sound(sound: AudioStreamWAV) -> void:
	if muted or DisplayServer.get_name() == "headless": return
	sfx_player.stream = sound
	sfx_player.play()
