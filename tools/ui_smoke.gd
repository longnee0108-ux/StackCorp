extends SceneTree

# Render a real fresh game, using an isolated APPDATA supplied by the caller.
var game: Node
var suffix: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result = root.get_texture().get_image().save_png(path)
	assert(result == OK, "Could not save visual check")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa"))
	if "--small-window" in OS.get_cmdline_user_args():
		root.size = Vector2i(1000, 650)
		suffix = "-small"
		await process_frame
	var backend: GDScript = load("res://src/backend/game_sim.gd")
	if not backend or not backend.can_instantiate():
		push_error("Backend did not compile; visual check stopped.")
		quit(1)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	DisplayServer.window_set_title("StackCorp — Visual Check")
	await _capture("res://.qa/menu%s.png" % suffix)
	game._new_game()
	game._send("set_paused", {"value":true})
	game.show_tutorial = false
	game._refresh_hud()
	await _capture("res://.qa/table%s.png" % suffix)
	var founder: int = game.sim.find_card("founder")
	var laptop: int = game.sim.find_card("laptop_old")
	var lead: int = game.sim.find_card("freelance_contract")
	assert(game._send("stack", {"uid":founder,"target":laptop}).ok)
	assert(game._send("stack", {"uid":lead,"target":laptop}).ok)
	game._send("set_paused", {"value":false})
	for i in range(40):
		game.sim.step(0.1)
	game._send("set_paused", {"value":true})
	game._sync_cards()
	game._refresh_hud()
	await _capture("res://.qa/working%s.png" % suffix)
	if "--interactive-qa" in OS.get_cmdline_user_args():
		return
	print("UI render check: PASS (menu, fresh table, working stack)")
	game.queue_free()
	await process_frame
	quit(0)
