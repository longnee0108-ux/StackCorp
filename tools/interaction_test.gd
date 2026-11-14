extends SceneTree

var game: Node

func _initialize() -> void:
	call_deferred("_run")

func send(kind: String, payload: Dictionary = {}) -> void:
	var result: Dictionary = game._send(kind, payload)
	assert(bool(result.ok), "%s rejected: %s" % [kind, result.message])

func advance(seconds: float) -> void:
	game.sim.command("set_paused", {"value":false})
	for i in range(int(seconds * 10)):
		game.sim.step(0.1)
	game._handle_events()
	game._refresh_hud()

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_practice()
	assert(game.practice_mode and bool(game.sim.state.practice))
	assert(not game.tutorial_next.visible)
	# Zoom must preserve the exact world point under the pointer.
	var pointer: Vector2 = root.get_mouse_position() - root.get_visible_rect().size * 0.5
	var before: Vector2 = game.camera.position + pointer / game.camera.zoom
	var wheel = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	game._unhandled_input(wheel)
	var after: Vector2 = game.camera.position + pointer / game.camera.zoom
	assert(before.distance_to(after) < 0.001, "Zoom drifts away from cursor")
	game._toggle_pause()
	assert(game.tutorial_index == 1)
	var founder: int = game.sim.find_card("founder")
	var laptop: int = game.sim.find_card("laptop_old")
	var lead: int = game.sim.find_card("freelance_contract")
	send("stack", {"uid":founder,"target":laptop})
	send("stack", {"uid":lead,"target":laptop})
	# Whole-stack motion retains relative geometry and never targets itself.
	game._sync_cards()
	for uid in game.views:
		game.views[uid].position = game.views[uid].display_position
	game.dragged_uid = laptop
	game.drag_members.clear()
	for uid in [laptop, founder, lead]:
		game.drag_members[uid] = game.views[uid].position - game.views[laptop].position
	var delta_before: Vector2 = game.views[founder].position - game.views[laptop].position
	game.drag_offset = Vector2.ZERO
	game._process(0.0)
	assert((game.views[founder].position - game.views[laptop].position).distance_to(delta_before) < 0.001)
	assert(game._hit_card(game.views[laptop].position + Vector2(15, 15), laptop, true) not in [laptop, founder, lead])
	game.dragged_uid = -1
	game.drag_members.clear()
	advance(35)
	assert(game.sim.state.tutorial_flags.gig)
	send("unstack", {"uid":founder})
	var board: int = game.sim.find_card("whiteboard")
	var marker: int = game.sim.find_card("marker")
	send("stack", {"uid":founder,"target":board})
	send("stack", {"uid":marker,"target":board})
	advance(35)
	assert(game.sim.state.tutorial_flags.concept)
	send("unstack", {"uid":founder})
	var dev: int = game.sim.find_card("dev")
	send("stack", {"uid":dev,"target":laptop})
	send("stack", {"uid":game.sim.find_card("concept"),"target":laptop})
	advance(45)
	assert(game.sim.state.tutorial_flags.prototype)
	send("sell", {"uid":game.sim.find_card("prototype")})
	send("buy_pack", {"id":"early_leads"})
	send("pay_invoice", {"uid":game.sim.find_card("rent_invoice")})
	send("rest", {"uid":dev})
	send("discover", {"uid":game.sim.find_card("idea")})
	game._refresh_hud()
	assert(game.tutorial_index == 9)
	assert(game.menu_page == "practice_done")
	assert(not game.sim.save_game("user://practice_must_not_save.json"))
	assert(not FileAccess.file_exists("user://practice_must_not_save.json"))
	print("Frontend behavior: PASS (cursor zoom, whole-stack drag geometry, self-target exclusion, 9 real tutorial tasks, practice save protection)")
	game.queue_free()
	await process_frame
	quit(0)
