extends SceneTree
## Deterministic risk checks. Progression supplies declared inventory fixtures;
## it is not a normal player bot or evidence of human win-rate targets.
const Sim = preload("res://src/backend/game_sim.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	_money_save()
	_capacity()
	_boards_payroll()
	_safety_tax()
	_progression()
	_practice_catalog()
	print("RESULT: %d checks, %d failures across 6 scenario groups" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func fresh(seed_value: int = 42):
	var sim = Sim.new()
	sim.new_run("easy", seed_value)
	return sim

func write_json(path: String, value: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func _money_save() -> void:
	var s = fresh()
	check(s.cash_available() == 60, "starting cash")
	var before: int = s.cash_available()
	var card_count: int = s.state.cards.size()
	check(not s.command("buy_pack", {"id": "missing"}).ok, "invalid pack rejected")
	check(s.cash_available() == before and s.state.cards.size() == card_count, "rejection conserves resources")
	check(s.command("buy_pack", {"id": "garage_gear"}).ok, "purchase valid pack")
	check(s.cash_available() == before - s.pack_price("garage_gear"), "purchase charged once")
	s._add_cash(220, 0)
	check(s.cash_available() == before - s.pack_price("garage_gear") + 220, "change conserves money")
	for c in s.state.cards:
		if str(c.id).begins_with("usd_"): check(int(c.amount) <= 10, "wad maximum")
	check(s.command("action", {"id": "craft:r_gig"}).ok, "start gig")
	s.step(15.0)
	check(s.save_game("user://scenario_save.json"), "atomic save")
	var loaded = Sim.new()
	check(loaded.load_game("user://scenario_save.json"), "load recipe progress")
	check(loaded.state.rng_state == s.state.rng_state, "save preserves RNG state")
	s.step(16.0)
	loaded.step(16.0)
	check(loaded.cash_available() == s.cash_available() and loaded.state.gigs == 1, "resume exactly once")
	var envelope: Dictionary = {"state": loaded.snapshot(), "next_uid": loaded.state.next_uid}
	envelope.state.boards[0] = {}
	write_json("user://scenario_invalid.json", envelope)
	var old_cash: int = loaded.cash_available()
	check(not loaded.load_game("user://scenario_invalid.json"), "reject malformed board before commit")
	check(loaded.cash_available() == old_cash and loaded.state.boards[0].office == "garage", "failed load preserves current company")
	envelope = {"state": loaded.snapshot(), "next_uid": loaded.state.next_uid}
	envelope.state.stacks.append({"cards": [loaded.find_card("founder")]})
	write_json("user://scenario_invalid.json", envelope)
	check(not loaded.load_game("user://scenario_invalid.json"), "reject malformed stack")
	print("GROUP 1 complete: cash and save/load")

func _capacity() -> void:
	var s = fresh()
	check(not s.command("sell", {"uid": s.find_card("founder")}).ok, "Founder protected")
	check(not s.command("sell", {"uid": s.find_card("laptop_old")}).ok, "last Laptop protected")
	s.command("set_paused", {"value": true})
	s.step(10.0)
	check(s.state.time == 0.0, "pause stops time")
	check(s.command("move", {"uid": s.find_card("founder"), "x": 100.0, "y": 200.0}).ok, "pause allows movement")
	s.command("set_paused", {"value": false})
	while s.used_capacity() <= s.capacity(): s._spawn("coffee", 0, 0, 0, true)
	check(s.command("action", {"id": "craft:r_idea"}).ok, "start full-board recipe")
	s.step(45.2)
	var pending: bool = false
	for stack in s.state.stacks:
		if stack.recipe == "r_idea": pending = bool(stack.pending)
	check(pending, "positive slot growth waits Pending")
	s._remove(s.find_card("coffee"))
	s._remove(s.find_card("coffee"))
	s.step(0.2)
	check(s.find_card("idea") > 0, "release Pending output after freeing slots")
	s.state.phase = 2
	s.state.ideas.append("ledger")
	s._spawn("accountant", 0, 0, 0, true)
	for i in range(10): s._spawn("receipt", 0, i, 0, true)
	check(s.used_capacity() > s.capacity(), "mandatory cards may overfill")
	check(s.command("action", {"id": "craft:r_ledger"}).ok, "start cap-reducing recipe")
	s.step(20.2)
	check(s.find_card("ledger_folder") > 0, "cap-reducing recipe works while over cap")
	print("GROUP 2 complete: pause, protected cards and Pending")

func _boards_payroll() -> void:
	var s = fresh()
	s.state.boards.append({"id": 1, "name": "Branch", "office": "branch", "evictions": 0})
	s._spawn("bank_card", 0, 0, 0, true)
	s._spawn("bank_card", 1, 0, 0, true)
	s._add_cash(200, 0)
	var combined: int = s.cash_available(0) + s.cash_available(1) + s.state.bank
	check(s.command("deposit").ok, "shared bank deposit")
	s.command("set_board", {"board": 1})
	check(s.command("withdraw", {"amount": 100}).ok, "shared bank withdrawal at Branch")
	check(s.cash_available(0) + s.cash_available(1) + s.state.bank == combined, "bank balance not duplicated")
	s.command("set_board", {"board": 0})
	var founder: int = s.find_card("founder")
	check(s.command("action", {"id": "transport", "uid": founder}).ok, "dispatch shipment")
	check(not s.command("rest", {"uid": founder}).ok, "rest cannot cancel transit")
	while s.used_capacity(1) + s.reserved_capacity(1) < s.capacity(1): s._spawn("coffee", 1, 0, 0, true)
	check(not s.command("action", {"id": "transport", "uid": s.find_card("laptop_old")}).ok, "capacity reservations prevent overbooking")
	s.step(20.2)
	check(s.card(founder).board == 1 and s.card(founder).status == "", "shipment arrives at correct board")
	var wages = fresh(43)
	var worker: Dictionary = wages._spawn("dev", 0, 0, 0, true)
	wages._spawn_invoice("payroll_invoice", 999, 0, 0)
	wages._close_cycle()
	check(wages.card(worker.uid).get("unpaid", 0) == 1, "one missed wage marks Unpaid")
	wages._spawn_invoice("payroll_invoice", 999, 0, 0)
	wages._close_cycle()
	check(wages.card(worker.uid).is_empty(), "two missed wages cause resignation")
	var roster = fresh(44)
	roster.state.boards.append({"id": 1, "name": "Branch", "office": "branch", "evictions": 0})
	var moved: Dictionary = roster._spawn("dev", 0, 0, 0, true)
	var unpaid: Dictionary = roster._spawn("sales", 1, 0, 0, true)
	var home_bill: Dictionary = roster._spawn_invoice("payroll_invoice", 11, 0, 0)
	roster._spawn_invoice("payroll_invoice", 9, 1, 0)
	check(roster.command("pay_invoice", {"uid": home_bill.uid}).ok, "pay home-office payroll before transfer")
	check(roster.command("action", {"id": "transport", "uid": moved.uid}).ok, "transfer employee after payroll roster snapshot")
	roster.step(20.2)
	roster._close_cycle()
	check(roster.card(moved.uid).get("unpaid", 0) == 0 and roster.card(unpaid.uid).get("unpaid", 0) == 1, "wage outcome follows employee identity across boards")
	check(roster.cash_available(0) == 49, "cross-board roster does not double-charge wages")
	print("GROUP 3 complete: boards, bank, shipping and payroll")

func _safety_tax() -> void:
	var s = fresh()
	var safe: Dictionary = s._spawn("office_safe", 0, 0, 0, true)
	var money: int = s.cash_available()
	check(s.command("action", {"id": "store_cash", "uid": safe.uid}).ok, "Safe accepts cash")
	s._steal_cash(0)
	check(s.cash_available() == money, "Safe cash immune to theft")
	check(s.command("action", {"id": "open_safe", "uid": safe.uid}).ok, "retrieve Safe cash")
	s._steal_cash(0)
	check(s.cash_available() == money - int(floor(money * s.rules().theft_fraction)), "exposed cash loses configured fraction")
	s.command("action", {"id": "store_cash", "uid": safe.uid})
	s._remove(safe.uid)
	var dangling: bool = false
	for c in s.state.cards:
		if int(c.get("stored_in", -1)) >= 0: dangling = true
	check(not dangling, "removing Safe releases contents")
	s.state.phase = 2
	s.state.ideas.append("shredder")
	s._spawn("shredder", 0, 0, 0, true)
	var old: Dictionary = s._spawn("receipt", 0, 0, 0, true)
	old["value"] = 100
	old["unfiled_value"] = 0
	s.state.tax_revenue = 100
	check(s.command("action", {"id": "craft:r_shred"}).ok, "shred old reported record")
	s.step(5.2)
	check(s.state.tax_revenue == 100, "old Receipt cannot erase new tax revenue")
	s._close_quarter()
	var tax_id: int = s.find_card("tax_notice")
	check(tax_id > 0, "quarter creates tax bill")
	check(not s.command("pay_invoice", {"uid": tax_id}).ok, "file records before paying tax")
	check(s.command("action", {"id": "file_tax", "uid": tax_id}).ok, "file tax records")
	check(s.command("pay_invoice", {"uid": tax_id}).ok, "pay assessed tax")
	check(s.state.quarter_expenses == 0, "accrued tax not expensed twice")
	var candidate: Dictionary = s._spawn("candidate_ai_agent", 0, 0, 0, true)
	check(not s.command("action", {"id": "hire", "uid": candidate.uid}).ok, "AI activation requires server")
	s.state.ideas.append("pantry")
	var pantry: Dictionary = s._spawn("pantry", 0, 0, 0, true)
	var burned: Dictionary = s._spawn("dev", 0, 0, 0, true)
	burned.stress = 10.0
	burned.status = "burnout"
	burned["recover_at"] = float(s.state.time) + 60.0
	check(s.command("stack", {"uid": burned.uid, "target": pantry.uid}).ok, "assign burned-out teammate to Pantry")
	s.step(15.2)
	check(burned.status == "" and burned.stress == 6.0, "Pantry rescues Burnout without HR")
	var hunter: Dictionary = s._spawn("headhunter", 0, 0, 0, true)
	hunter["target_uid"] = burned.uid
	hunter["deadline"] = float(s.state.time) + 60.0
	check(s.command("action", {"id": "retain", "uid": hunter.uid}).ok, "pay retention offer")
	check(not s.card(burned.uid).is_empty() and s.card(hunter.uid).is_empty(), "retention preserves teammate")
	print("GROUP 4 complete: Safe, theft, tax periods and AI activation")

func _progression() -> void:
	var s = fresh(123)
	s.state.ideas.append("series_a")
	for id in ["pitch_deck", "investor", "polished_prototype"]: s._spawn(id, 0, 0, 0, true)
	check(s.command("action", {"id": "series_a"}).ok, "Series A starts with legal prerequisites")
	s.step(60.2)
	check(s.state.phase == 2 and s.state.office == "coworking", "Series A advances phase")
	check(s.find_card("term_sheet") > 0, "funding creates Term Sheet")
	check(not s.command("action", {"id": "ipo"}).ok, "IPO rejects missing prerequisites")
	s._add_cash(300, 0)
	s._spawn("plane_ticket", 0, 0, 0, true)
	check(s.command("action", {"id": "branch"}).ok, "Branch project starts")
	s.step(30.2)
	check(s.state.boards.size() == 2, "Branch creates second board")
	for id in ["lawyer", "accountant", "ledger_folder", "ledger_folder", "ledger_folder"]: s._spawn(id, 0, 0, 0, true)
	s.state.last_quarter_revenue = int(s.profile().ipo_revenue)
	check(s.command("action", {"id": "ipo"}).ok, "IPO accepts completed prerequisites")
	s.step(90.2)
	check(s.state.phase == 3 and s.state.office == "hq_tower" and s.state.stock == 100.0, "IPO starts public company")
	for i in range(3):
		s._add_cash(s.buyout_price(), 0)
		s._spawn("weakened_rival", 0, 0, 0, true)
		check(s.command("action", {"id": "buyout"}).ok, "acquisition starts")
		s.step(60.2)
		check(s._count("subsidiary") == i + 1, "acquisition completes once")
	check(s.state.quarter_expenses == 0, "M&A excluded from operating expenses")
	for i in range(4):
		if s.state.victory: break
		s.state.quarter_revenue = 20000
		s._close_quarter()
	check(s.state.victory and s.state.ended, "Subsidiaries and stock holds produce Victory")
	check(s.command("continue_endless").ok and not s.state.ended, "continue Endless after Victory")
	print("GROUP 5 complete: seeded fixtures Series A, Branch, IPO, M&A, Victory and Endless")

func _practice_catalog() -> void:
	var s = fresh()
	var cash: int = s.cash_available()
	check(s.save_game("user://scenario_main.json"), "save main company")
	check(s.command("action", {"id": "start_tutorial"}).ok and s.state.get("practice", false), "start separate practice company")
	check(not s.save_game("user://scenario_main.json"), "practice cannot overwrite main save")
	s.command("set_paused", {"value": true})
	check(s.state.tutorial_flags.paused, "tutorial follows actual pause")
	s.command("discover", {"uid": s.find_card("idea")})
	check(s.state.tutorial_flags.idea, "tutorial follows actual discovery")
	check(s.load_game("user://scenario_main.json") and s.cash_available() == cash, "main company survives practice")
	for recipe in s.db.recipes:
		for id in [recipe.root] + recipe.inputs + recipe.consumes + recipe.outputs:
			check(str(id).begins_with("#") or s.db.cards.has(id), "valid recipe reference " + str(id))
	for pack in s.db.packs.values():
		for id in pack.pool: check(s.db.cards.has(id), "valid pack reference " + str(id))
	for difficulty in ["easy", "medium", "hard"]:
		s.new_run(difficulty, 42)
		check(s.cash_available() == int(s.profile().start_cash), "difficulty economy")
	print("GROUP 6 complete: practice isolation and data references")
