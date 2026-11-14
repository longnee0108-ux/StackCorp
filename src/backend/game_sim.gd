class_name StackCorpSim
extends RefCounted
## Authoritative local simulation. Rendering, input and disk locations are adapters.

var state: Dictionary = {}
var db: Dictionary = {}
var _rng = RandomNumberGenerator.new()
var _events: Array = []
var _next_uid: int = 1
var _accumulator: float = 0.0

func _init() -> void:
	for file in ["cards", "recipes", "packs", "difficulty", "balance", "quests", "events"]:
		db[file] = _read_json("res://data/%s.json" % file)
	db["text"] = _read_json("res://data/i18n/en.json")
	for group in ["cards", "packs"]:
		for entry in db[group].values():
			entry["name"] = text(entry.get("name_key", ""))
			entry["description"] = text(entry.get("description_key", ""))
	for group in ["recipes", "quests"]:
		for entry in db[group]:
			entry["name"] = text(entry.get("name_key", ""))

func text(key: String, args: Array = []) -> String:
	var value: String = str(db.get("text", {}).get(key, key))
	return value % args if not args.is_empty() else value

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing data file: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path).trim_prefix("\ufeff"))
	return parsed if parsed != null else {}

func new_run(difficulty: String = "easy", seed_value: int = 0) -> void:
	if not db.difficulty.has(difficulty): difficulty = "easy"
	_rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())
	_next_uid = 1
	_accumulator = 0.0
	_events.clear()
	state = {"schema_version": 1, "difficulty": difficulty, "seed": _rng.seed, "rng_state": str(_rng.state),
		"time": 0.0, "day": 1, "phase": 1, "office": "garage", "board": 0,
		"boards": [{"id": 0, "name": "Garage", "office": "garage", "evictions": 0}],
		"cards": [], "stacks": [], "ideas": [], "quests": [], "cash": 0, "bank": 0,
		"paused": false, "speed": 1, "stock": 0.0, "reputation": 2, "ended": false,
		"victory": false, "endless": false, "notice": "", "tutorial_step": 0,
		"cycle": 0, "quarter": 0, "phase_cycle": 0, "quarter_revenue": 0,
		"quarter_expenses": 0, "last_quarter_revenue": 0, "last_profit": 0,
		"stock_target": float(profile().stock_target), "stock_hold": 0, "buyback_quarter": -1,
		"pack_buys": {}, "produced": {}, "sold": 0, "gigs": 0, "shredded": 0,
		"concealed": 0, "tax_revenue": 0, "next_event": 0.0, "sale_boost_until": 0.0,
		"sale_penalty_until": 0.0, "outage_until": 0.0, "recession_left": 0,
		"inspection_misses": 0, "strike_misses": 0, "emergency_cycle": -1,
		"last_invoice_cycle": -1, "auto_line_clock": 0.0, "next_uid": 1}
	for entry in rules().starter:
		_spawn(str(entry[0]), 0, float(entry[1]), float(entry[2]), true)
	_add_cash(int(profile().start_cash), 0, 300.0, 120.0)
	_schedule_event()
	_sync()

func profile() -> Dictionary:
	return db.difficulty.get(state.get("difficulty", "easy"), {})

func rules() -> Dictionary:
	return db.balance

func definition(id: String) -> Dictionary:
	return db.cards.get(id, {})

func card(uid: int) -> Dictionary:
	for item in state.get("cards", []):
		if int(item.uid) == uid: return item
	return {}

func find_card(id: String, board_id: int = -1) -> int:
	for item in state.get("cards", []):
		if item.id == id and (board_id < 0 or int(item.board) == board_id): return int(item.uid)
	return -1

func _count(id: String, board_id: int = -1) -> int:
	var total: int = 0
	for item in state.cards:
		if item.id == id and (board_id < 0 or int(item.board) == board_id): total += 1
	return total

func _stack(uid: int) -> Dictionary:
	for entry in state.stacks:
		if int(entry.uid) == uid: return entry
	return {}

func capacity(board_id: int = -1) -> int:
	if board_id < 0: board_id = int(state.board)
	if board_id >= state.boards.size(): return 0
	return int(rules().office[state.boards[board_id].office].cap) + int(profile().cap_bonus)

func used_capacity(board_id: int = -1) -> int:
	if board_id < 0: board_id = int(state.board)
	var total: int = 0
	for item in state.cards:
		if int(item.board) == board_id and int(item.get("stored_in", -1)) < 0: total += 1
	return total

func reserved_capacity(board_id: int) -> int:
	var total: int = 0
	for item in state.cards:
		if item.status == "transit" and int(item.get("destination", -1)) == board_id: total += 1
	return total

func cash_available(board_id: int = -1) -> int:
	if board_id < 0: board_id = int(state.get("board", 0))
	var total: int = 0
	for item in state.get("cards", []):
		if int(item.board) == board_id and str(item.id).begins_with("usd_"):
			total += int(str(item.id).trim_prefix("usd_")) * int(item.amount)
	return total

func total_funds(board_id: int = -1) -> int:
	return cash_available(board_id) + int(state.bank)

func pack_price(id: String) -> int:
	if not db.packs.has(id): return 0
	return int(db.packs[id].price) if id == "early_leads" else int(ceil(float(db.packs[id].price) * float(profile().pack_mult)))

func available_packs() -> Array:
	var result: Array = []
	for entry in db.packs.values():
		if int(entry.phase) <= int(state.phase):
			var copy: Dictionary = entry.duplicate(true)
			copy["cost"] = pack_price(entry.id)
			result.append(copy)
	return result

func _spawn(id: String, board_id: int = 0, x: float = 0.0, y: float = 0.0, mandatory: bool = false) -> Dictionary:
	if not db.cards.has(id): return {}
	if not mandatory and used_capacity(board_id) + reserved_capacity(board_id) >= capacity(board_id): return {}
	if id in ["bug", "ai_hallucination"] and _count("bug", board_id) + _count("ai_hallucination", board_id) >= int(profile().bug_cap): return {}
	var result: Dictionary = {"uid": _next_uid, "id": id, "board": board_id, "x": x, "y": y,
		"stack_id": -1, "stress": 0.0, "amount": 1, "progress": 0.0, "status": "",
		"born": float(state.time), "next_damage": float(state.time) + float(rules().bug_damage_seconds),
		"next_clone": float(state.time) + float(rules().bug_clone_seconds)}
	_next_uid += 1
	if id == "bug": result["hp"] = int(rules().bug_hp)
	if id == "ai_hallucination": result["hp"] = int(rules().bug_hp) * 2
	if id == "inspector":
		result["hp"] = int(rules().inspection_hp)
		result["deadline"] = float(state.time) + float(rules().inspection_days) * float(rules().day_seconds)
	if id == "idea":
		var pool: Array = _undiscovered_ideas()
		if pool.is_empty(): return _spawn("coffee", board_id, x, y, mandatory)
		result["idea_id"] = pool[_rng.randi_range(0, pool.size() - 1)]
	state.cards.append(result)
	return result

func _remove(uid: int) -> void:
	var item: Dictionary = card(uid)
	if item.is_empty(): return
	if item.id == "office_safe":
		for wad in state.cards:
			if int(wad.get("stored_in", -1)) == uid:
				wad["stored_in"] = -1
				wad.x = float(item.x) + 170.0
				wad.y = float(item.y) + 35.0
	var stack: Dictionary = _stack(int(item.stack_id))
	if not stack.is_empty():
		stack.cards.erase(uid)
		stack.progress = 0.0
		stack.recipe = ""
	state.cards.erase(item)

func _add_cash(amount: int, board_id: int, x: float = 260.0, y: float = 120.0) -> void:
	var offset: int = 0
	for denomination in rules().denominations:
		var value: int = int(denomination)
		var bills: int = amount / value
		amount %= value
		if bills <= 0: continue
		for item in state.cards:
			if item.id == "usd_%d" % value and int(item.board) == board_id and int(item.amount) < int(rules().bill_wad):
				var added: int = mini(bills, int(rules().bill_wad) - int(item.amount))
				item.amount = int(item.amount) + added
				bills -= added
				if bills <= 0: break
		while bills > 0:
			var wad: Dictionary = _spawn("usd_%d" % value, board_id, x + offset * 32.0, y + offset * 12.0, true)
			wad.amount = mini(bills, int(rules().bill_wad))
			bills -= int(wad.amount)
			offset += 1

func _spend(amount: int, board_id: int, use_bank: bool = false) -> bool:
	if amount < 0 or cash_available(board_id) + (int(state.bank) if use_bank else 0) < amount: return false
	var physical: int = cash_available(board_id)
	var consume: int = mini(physical, amount)
	var location = Vector2(260, 120)
	for item in state.cards.duplicate():
		if int(item.board) == board_id and str(item.id).begins_with("usd_"):
			location = Vector2(float(item.x), float(item.y))
			_remove(int(item.uid))
	_add_cash(physical - consume, board_id, location.x, location.y)
	if use_bank: state.bank = int(state.bank) - (amount - consume)
	return true

func _steal_cash(board_id: int) -> void:
	var exposed: int = 0
	var wads: Array = []
	for item in state.cards:
		if int(item.board) == board_id and str(item.id).begins_with("usd_") and int(item.get("stored_in", -1)) < 0:
			exposed += int(str(item.id).trim_prefix("usd_")) * int(item.amount)
			wads.append(int(item.uid))
	var stolen: int = int(floor(float(exposed) * float(rules().theft_fraction)))
	if stolen <= 0: return
	for uid in wads: _remove(int(uid))
	_add_cash(exposed - stolen, board_id)

func wage_for(uid: int) -> int:
	var person: Dictionary = card(uid)
	if person.is_empty() or definition(person.id).type != "person": return 0
	return int(ceil(float(definition(person.id).wage) * float(profile().wage_mult)))

func _sync() -> void:
	state.cash = cash_available()
	state.rng_state = str(_rng.state)
	state.next_uid = _next_uid
	for board_entry in state.boards:
		board_entry["cap"] = capacity(int(board_entry.id))
		board_entry["rent"] = int(ceil(float(rules().office[board_entry.office].rent) * float(profile().rent_mult)))

func snapshot() -> Dictionary:
	_sync()
	return state.duplicate(true)

func drain_events() -> Array:
	var result: Array = _events.duplicate(true)
	_events.clear()
	return result

func _emit(kind: String, message: String = "", extra: Dictionary = {}) -> void:
	var event: Dictionary = {"type": kind, "message": message}
	event.merge(extra)
	_events.append(event)
	if bool(state.get("practice", false)):
		if kind == "pack_opened": state.tutorial_flags.pack = true
		if kind == "sold": state.tutorial_flags.sold = true
		if kind == "recipe_completed":
			var recipe_id: String = str(extra.get("recipe", ""))
			if recipe_id == "r_gig": state.tutorial_flags.gig = true
			if recipe_id == "r_concept": state.tutorial_flags.concept = true
			if recipe_id == "r_proto": state.tutorial_flags.prototype = true
	if not message.is_empty(): state.notice = message

func _result(ok: bool, key: String = "", args: Array = []) -> Dictionary:
	_sync()
	var message: String = text(key, args) if not key.is_empty() else ""
	if not message.is_empty(): _emit("info" if ok else "warning", message)
	return {"ok": ok, "message": message}

func command(kind: String, payload: Dictionary = {}) -> Dictionary:
	if state.is_empty(): return {"ok": false, "message": ""}
	if kind == "action" and str(payload.get("id", "")) == "start_tutorial":
		new_tutorial()
		return _result(true, "msg.tutorial")
	if kind == "set_paused":
		state.paused = bool(payload.get("value", not state.paused))
		if bool(state.get("practice", false)) and bool(state.paused): state.tutorial_flags.paused = true
		return _result(true)
	if kind == "set_speed":
		state.speed = clampi(int(payload.get("value", 1)), 1, 3)
		return _result(true)
	if kind == "set_board":
		var chosen: int = int(payload.get("board", 0))
		if chosen < 0 or chosen >= state.boards.size(): return _result(false, "msg.board_locked")
		state.board = chosen
		return _result(true)
	if kind == "continue_endless" and bool(state.victory):
		state.ended = false
		state.endless = true
		state.paused = false
		return _result(true, "msg.endless")
	if bool(state.ended): return _result(false, "msg.run_ended")
	var uid: int = int(payload.get("uid", -1))
	var item: Dictionary = card(uid)
	match kind:
		"move":
			if item.is_empty(): return _result(false)
			var stack: Dictionary = _stack(int(item.stack_id))
			var dx: float = float(payload.get("x", item.x)) - float(item.x)
			var dy: float = float(payload.get("y", item.y)) - float(item.y)
			if stack.is_empty():
				item.x = float(item.x) + dx
				item.y = float(item.y) + dy
			else:
				for member in stack.cards:
					var other: Dictionary = card(int(member))
					if not other.is_empty():
						other.x = float(other.x) + dx
						other.y = float(other.y) + dy
			return _result(true)
		"stack": return _join(uid, int(payload.get("target", -1)))
		"unstack":
			if item.is_empty(): return _result(false)
			_detach(uid)
			item.x = float(payload.get("x", item.x))
			item.y = float(payload.get("y", item.y))
			return _result(true)
		"buy_pack": return _buy_pack(str(payload.get("id", "")))
		"sell": return _sell(uid)
		"discover": return _discover(uid)
		"consume": return _consume(uid, int(payload.get("target", -1)))
		"rest":
			if item.is_empty() or definition(item.id).get("type") != "person": return _result(false)
			if item.id == "ai_agent": return _result(false, "msg.ai_rest")
			if item.status != "": return _result(false, "msg.busy")
			_detach(uid)
			item.status = "resting"
			item["recover_at"] = float(state.time) + float(rules().break_seconds)
			if bool(state.get("practice", false)): state.tutorial_flags.relief = true
			return _result(true, "msg.resting")
		"dismiss":
			if item.is_empty() or item.id == "founder" or not definition(item.id).get("type") in ["person", "candidate"]: return _result(false, "msg.cannot_dismiss")
			_remove(uid)
			return _result(true, "msg.dismissed")
		"pay_invoice": return _pay_invoice(uid)
		"deposit":
			if find_card("bank_card", int(state.board)) < 0: return _result(false, "msg.need_bank")
			var limit: int = int(rules().bank_limit if int(state.phase) == 1 else rules().corporate_bank_limit)
			var amount: int = cash_available()
			if not item.is_empty() and str(item.id).begins_with("usd_"): amount = int(item.amount) * int(str(item.id).trim_prefix("usd_"))
			amount = mini(amount, limit - int(state.bank))
			if amount <= 0: return _result(false, "msg.bank_full")
			_spend(amount, int(state.board))
			state.bank = int(state.bank) + amount
			return _result(true, "msg.deposited", [amount])
		"withdraw":
			if find_card("bank_card", int(state.board)) < 0: return _result(false, "msg.need_bank")
			var amount: int = int(payload.get("amount", mini(int(state.bank), 100)))
			if amount <= 0 or amount > int(state.bank): return _result(false, "msg.insufficient")
			state.bank = int(state.bank) - amount
			_add_cash(amount, int(state.board))
			return _result(true, "msg.withdrawn", [amount])
		"action": return _action(str(payload.get("id", "")), uid)
		"next_tutorial":
			state.tutorial_step = int(state.tutorial_step) + 1
			return _result(true)
	return _result(false, "msg.unknown_action")

func _detach(uid: int) -> void:
	var item: Dictionary = card(uid)
	if item.is_empty(): return
	var stack: Dictionary = _stack(int(item.stack_id))
	if not stack.is_empty():
		stack.cards.erase(uid)
		stack.progress = 0.0
		stack.recipe = ""
		stack.pending = false
	item.stack_id = -1
	item.progress = 0.0
	_cleanup_stacks()

func _cleanup_stacks() -> void:
	for stack in state.stacks.duplicate():
		var valid: Array = []
		for uid in stack.cards:
			if not card(int(uid)).is_empty(): valid.append(int(uid))
		stack.cards = valid
		if stack.cards.size() < 2:
			for uid in stack.cards: card(int(uid)).stack_id = -1
			state.stacks.erase(stack)

func _join(uid: int, target_uid: int) -> Dictionary:
	var item: Dictionary = card(uid)
	var target: Dictionary = card(target_uid)
	if item.is_empty() or target.is_empty() or uid == target_uid or int(item.board) != int(target.board): return _result(false)
	if item.status == "transit" or target.status == "transit": return _result(false, "msg.in_transit")
	if item.id == "idea": return _discover(uid)
	if item.id in ["coffee", "team_ticket", "insurance"]: return _consume(uid, target_uid)
	if str(item.id).begins_with("usd_"):
		if str(target.id).begins_with("usd_") and item.id == target.id:
			var count: int = mini(int(item.amount), int(rules().bill_wad) - int(target.amount))
			if count > 0:
				target.amount = int(target.amount) + count
				item.amount = int(item.amount) - count
				if int(item.amount) <= 0: _remove(uid)
				return _result(true)
		if target.id in ["payroll_invoice", "rent_invoice", "tax_notice", "fine"]: return _pay_invoice(target_uid)
		if target.id == "inspector": return _action("settlement", target_uid)
		if target.id == "bank_card": return command("deposit", {"uid": uid})
		if target.id == "bank_counter": return _action("consolidate", target_uid)
		if target.id == "stock_price": return _action("buyback", target_uid)
	if target.id in ["gateway", "truck"]: return _transport(uid)
	if item.id in ["receipt", "ledger_folder"] and target.id == "tax_notice": return _action("file_tax", target_uid)
	if definition(item.id).get("type") == "candidate" and target.id == "founder": return _action("hire", uid)
	if definition(target.id).get("type") == "candidate" and item.id == "founder": return _action("hire", target_uid)
	var first: Dictionary = _stack(int(item.stack_id))
	var second: Dictionary = _stack(int(target.stack_id))
	if not first.is_empty() and first == second: return _result(true)
	var moving: Array = first.cards.duplicate() if not first.is_empty() else [uid]
	var members: Array = second.cards.duplicate() if not second.is_empty() else [target_uid]
	for member in moving:
		if not member in members: members.append(member)
	if members.size() > capacity(int(item.board)): return _result(false, "msg.invalid_stack")
	if second.is_empty():
		second = {"uid": _next_uid, "board": int(item.board), "cards": [], "recipe": "", "progress": 0.0, "duration": 0.0, "pending": false}
		_next_uid += 1
		state.stacks.append(second)
	if not first.is_empty(): state.stacks.erase(first)
	second.cards = members
	second.recipe = ""
	second.progress = 0.0
	second.pending = false
	for index in range(members.size()):
		var member: Dictionary = card(int(members[index]))
		member.stack_id = int(second.uid)
		member.x = float(target.x)
		member.y = float(target.y) + index * 28.0
	return _result(true)

func _buy_pack(id: String) -> Dictionary:
	if not db.packs.has(id): return _result(false, "msg.unknown_pack")
	var pack: Dictionary = db.packs[id]
	if int(pack.phase) > int(state.phase): return _result(false, "msg.pack_locked")
	if used_capacity() + reserved_capacity(int(state.board)) + int(pack.count) > capacity(): return _result(false, "msg.pack_capacity")
	var cost: int = pack_price(id)
	if not _spend(cost, int(state.board)): return _result(false, "msg.insufficient")
	state.quarter_expenses = int(state.quarter_expenses) + cost
	var buys: int = int(state.pack_buys.get(id, 0))
	state.pack_buys[id] = buys + 1
	var x: float = -560.0 + _rng.randf_range(-40.0, 40.0)
	var y: float = -250.0 + _rng.randf_range(-60.0, 60.0)
	for index in range(int(pack.count)):
		var chosen: String = _weighted(pack.pool)
		if index == 0 and buys < pack.get("guarantee", []).size(): chosen = str(pack.guarantee[buys])
		# First two cycles teach the economy without random loss of people or cash.
		if int(state.cycle) < 2 and chosen == "bug": chosen = "freelance_contract"
		_spawn(chosen, int(state.board), x + index * 175.0, y)
	_emit("pack_opened", text("msg.pack_opened", [pack.name]), {"pack": id})
	return _result(true)

func _weighted(weights: Dictionary) -> String:
	var total: float = 0.0
	for value in weights.values(): total += float(value)
	var roll: float = _rng.randf() * total
	for id in weights:
		roll -= float(weights[id])
		if roll <= 0.0: return str(id)
	return str(weights.keys().back())

func sell_price(uid: int) -> int:
	var item: Dictionary = card(uid)
	if item.is_empty(): return 0
	var value: Variant = definition(item.id).get("sell_price")
	if value == null: return 0
	var multiplier: float = float(profile().sell_mult) * (1.0 + (float(state.reputation) - 2.0) * float(rules().reputation_sell))
	if int(item.board) == 1: multiplier *= float(rules().branch_sell)
	if float(state.sale_boost_until) > float(state.time): multiplier *= float(rules().viral_mult)
	if float(state.sale_penalty_until) > float(state.time): multiplier *= float(rules().price_war_mult)
	if int(state.recession_left) > 0: multiplier *= float(profile().recession_sales)
	if item.get("buggy", false): multiplier *= float(rules().buggy_sell_mult)
	if _count("marketing", int(item.board)) > 0: multiplier *= float(rules().marketing_mult)
	return maxi(1, int(round(float(value) * multiplier)))

func _sell(uid: int) -> Dictionary:
	var item: Dictionary = card(uid)
	var price: int = sell_price(uid)
	if item.is_empty() or price <= 0: return _result(false, "msg.cannot_sell")
	if item.id == "laptop_old" and _count("laptop_old") <= 1: return _result(false, "msg.protect_laptop")
	var stack: Dictionary = _stack(int(item.stack_id))
	if not stack.is_empty() and not str(stack.recipe).is_empty() and definition(item.id).type == "equipment": return _result(false, "msg.busy")
	var taxable: bool = definition(item.id).type == "product"
	var board_id: int = int(item.board)
	var x: float = float(item.x)
	var y: float = float(item.y)
	_remove(uid)
	_add_cash(price, board_id, x, y)
	state.quarter_revenue = int(state.quarter_revenue) + price
	state.sold = int(state.sold) + 1
	if int(state.phase) >= 2 and taxable:
		var receipt: Dictionary = _spawn("receipt", board_id, x + 150.0, y, true)
		receipt["value"] = price
		receipt["unfiled_value"] = price
		receipt["tax_period"] = int(state.quarter)
		state.tax_revenue = int(state.tax_revenue) + price
	_emit("sold", text("msg.sold", [price]), {"amount": price})
	return _result(true)

func _discover(uid: int) -> Dictionary:
	var item: Dictionary = card(uid)
	if item.is_empty() or item.id != "idea": return _result(false)
	var id: String = str(item.get("idea_id", ""))
	if not id.is_empty() and not id in state.ideas: state.ideas.append(id)
	_remove(uid)
	if bool(state.get("practice", false)): state.tutorial_flags.idea = true
	return _result(true, "msg.discovered", [idea_name(id)])

func idea_name(id: String) -> String:
	for recipe in db.recipes:
		if recipe.idea == id: return str(recipe.name)
	return id.capitalize().replace("_", " ")

func _undiscovered_ideas() -> Array:
	var result: Array = []
	for phase in range(1, int(state.phase) + 1):
		for id in rules().idea_pools[str(phase)]:
			if not id in state.ideas: result.append(id)
	return result

func _consume(uid: int, target_uid: int) -> Dictionary:
	var item: Dictionary = card(uid)
	var target: Dictionary = card(target_uid)
	if item.is_empty(): return _result(false)
	if item.id == "idea": return _discover(uid)
	if item.id == "coffee":
		if target.is_empty() or definition(target.id).type != "person": return _result(false, "msg.select_person")
		if target.id == "ai_agent": return _result(false, "msg.ai_rest")
		target.stress = maxf(0.0, float(target.stress) - float(rules().coffee_relief))
		target["boost_until"] = float(state.time) + float(rules().day_seconds)
		if target.status == "burnout":
			target.status = ""
			target.stress = 6.0
		_remove(uid)
		if bool(state.get("practice", false)): state.tutorial_flags.relief = true
		return _result(true, "msg.coffee")
	if item.id == "team_ticket":
		if not target.is_empty() and target.id == "headhunter":
			_remove(target_uid)
			_remove(uid)
			return _result(true, "msg.retained")
		var helped: int = 0
		for person in state.cards:
			if int(person.board) == int(item.board) and definition(person.id).type == "person" and person.id != "ai_agent":
				person.stress = maxf(0.0, float(person.stress) - float(rules().team_relief))
				if person.status == "burnout": person.status = ""
				helped += 1
				if helped >= int(rules().team_size): break
		_remove(uid)
		return _result(true)
	if item.id == "insurance":
		var lawsuit: int = find_card("lawsuit", int(item.board))
		if lawsuit < 0: return _result(false, "msg.no_lawsuit")
		_remove(lawsuit)
		_remove(uid)
		return _result(true)
	return _result(false, "msg.cannot_use")

func _matches(id: String, item: Dictionary) -> bool:
	if item.is_empty(): return false
	match id:
		"#person": return definition(item.id).type == "person"
		"#worker": return definition(item.id).type == "person"
		"#builder": return item.id in ["dev", "senior_dev", "ai_agent", "founder"]
		"#designer": return item.id in ["designer", "founder", "ai_agent"]
		"#sales": return item.id in ["sales", "founder", "ai_agent"]
		"#developer": return item.id in ["dev", "senior_dev", "founder", "ai_agent"]
		"#senior": return item.id in ["senior_dev", "ai_agent"]
		"#legal": return item.id in ["accountant", "lawyer"]
		"#low": return item.id in ["intern", "dev", "sales", "designer"]
		"#buggy": return bool(item.get("buggy", false))
	return item.id == id

func _select_for(recipe: Dictionary, candidates: Array) -> Array:
	var result: Array = []
	var needs: Array = [recipe.root]
	needs.append_array(recipe.inputs)
	for need in needs:
		var found: int = -1
		for uid in candidates:
			if not int(uid) in result and _matches(str(need), card(int(uid))):
				found = int(uid)
				break
		if found < 0: return []
		result.append(found)
	return result

func _recipe_by_id(id: String) -> Dictionary:
	for recipe in db.recipes:
		if recipe.id == id: return recipe
	return {}

func _recipe_enabled(recipe: Dictionary) -> bool:
	if int(recipe.phase) > int(state.phase): return false
	if not str(recipe.idea).is_empty() and not recipe.idea in state.ideas: return false
	if recipe.id == "r_series_a" and int(state.phase) != 1: return false
	if recipe.id == "r_expand" and state.office in ["office_floor", "hq_tower"]: return false
	if recipe.id == "r_branch" and state.boards.size() > 1: return false
	if recipe.id == "r_ipo":
		if int(state.phase) != 2 or state.boards.size() < 2 or _count("strike") > 0 or int(state.last_quarter_revenue) < int(profile().ipo_revenue): return false
	return true

func _find_recipe(stack: Dictionary, include_locked: bool = false) -> Dictionary:
	var chosen: Dictionary = {}
	var specificity: int = 0
	for recipe in db.recipes:
		if not include_locked and not _recipe_enabled(recipe): continue
		if recipe.inputs.size() + 1 <= specificity: continue
		var matches: Array = _select_for(recipe, stack.cards)
		if matches.is_empty(): continue
		chosen = recipe
		specificity = recipe.inputs.size() + 1
	return chosen

func _worker_speed(recipe: Dictionary, members: Array) -> float:
	var speed: float = 1.0
	var has_worker: bool = false
	var has_desk: bool = false
	for uid in members:
		var person: Dictionary = card(int(uid))
		if person.is_empty(): continue
		if person.id == "desk": has_desk = true
		if definition(person.id).type != "person": continue
		if person.status in ["hospitalized", "resting", "hiring", "transit"]: return 0.0
		if person.status == "burnout" and str(recipe.get("effect", "")) != "pantry": return 0.0
		if _count("strike", int(person.board)) > 0: return 0.0
		if str(recipe.get("effect", "")) == "pantry": continue
		if person.id == "ai_agent":
			if _count("server_cloud", int(person.board)) == 0: return 0.0
			if float(state.outage_until) > float(state.time) and _count("power_backup", int(person.board)) == 0: return 0.0
		var current: float = float(definition(person.id).get("speed", 1.0))
		if float(person.stress) >= float(rules().stress_tired): current *= float(rules().tired_speed)
		if int(person.get("unpaid", 0)) > 0: current *= float(rules().unpaid_speed)
		if float(person.get("boost_until", 0.0)) > float(state.time): current *= float(rules().coffee_speed)
		if float(person.get("overclock_until", 0.0)) > float(state.time): current *= float(rules().overclock_speed)
		if person.id == "founder" and ("#designer" in recipe.inputs or "#builder" in recipe.inputs or "#sales" in recipe.inputs): current *= 0.5
		if _count("team_leader", int(person.board)) > 0 and person.id != "team_leader": current *= float(rules().leader_mult)
		speed = minf(speed, current) if has_worker else current
		has_worker = true
	if has_desk: speed *= float(rules().desk_mult)
	return speed

func recipe_hint(uid: int) -> String:
	var item: Dictionary = card(uid)
	if item.is_empty(): return ""
	var stack: Dictionary = _stack(int(item.stack_id))
	if not stack.is_empty():
		var recipe: Dictionary = _find_recipe(stack, true)
		if not recipe.is_empty():
			if not _recipe_enabled(recipe): return text("msg.unlock_idea", [idea_name(recipe.idea)])
			if bool(stack.pending): return text("msg.pending")
			return str(recipe.name)
	return str(definition(item.id).get("description", ""))

func _recipe_cost(recipe: Dictionary) -> int:
	if recipe.id == "r_buyout": return buyout_price()
	return int(recipe.get("cost", 0))

func buyout_price() -> int:
	return int(round(float(profile().buyout_base) * (1.0 + float(rules().buyout_growth) * _count("subsidiary"))))

func _assemble(recipe_id: String, preferred_uid: int = -1) -> Dictionary:
	var recipe: Dictionary = _recipe_by_id(recipe_id)
	if recipe.is_empty() or not _recipe_enabled(recipe): return _result(false, "msg.recipe_locked")
	var candidates: Array = []
	if preferred_uid > 0 and not card(preferred_uid).is_empty(): candidates.append(preferred_uid)
	for item in state.cards:
		if int(item.board) == int(state.board) and not item.status in ["transit", "hiring"] and not int(item.uid) in candidates:
			candidates.append(int(item.uid))
	var members: Array = _select_for(recipe, candidates)
	if members.is_empty(): return _result(false, "msg.missing_inputs")
	if cash_available() < _recipe_cost(recipe): return _result(false, "msg.insufficient")
	for uid in members: _detach(int(uid))
	var stack: Dictionary = {"uid": _next_uid, "board": int(state.board), "cards": members, "recipe": recipe.id, "progress": 0.0, "duration": float(recipe.time), "pending": false, "paid": false}
	_next_uid += 1
	state.stacks.append(stack)
	var root: Dictionary = card(int(members[0]))
	for index in range(members.size()):
		var item: Dictionary = card(int(members[index]))
		item.stack_id = stack.uid
		item.x = root.x
		item.y = float(root.y) + index * 28.0
	return _result(true, "msg.job_started", [recipe.name])

func _complete(stack: Dictionary, recipe: Dictionary) -> bool:
	var members: Array = _select_for(recipe, stack.cards)
	if members.is_empty(): return false
	var root: Dictionary = card(int(members[0]))
	var board_id: int = int(stack.board)
	var x: float = float(root.x)
	var y: float = float(root.y)
	var consumed: Array = []
	for need in recipe.consumes:
		for uid in members:
			if not int(uid) in consumed and _matches(str(need), card(int(uid))):
				consumed.append(int(uid))
				break
	var slot_delta: int = recipe.outputs.size() - consumed.size()
	if slot_delta > 0 and used_capacity(board_id) + reserved_capacity(board_id) + slot_delta > capacity(board_id):
		stack.pending = true
		return false
	var cost: int = _recipe_cost(recipe)
	if cost > 0:
		if not _spend(cost, board_id): return false
		if recipe.id != "r_buyout": state.quarter_expenses = int(state.quarter_expenses) + cost
	var effect: String = str(recipe.get("effect", ""))
	if effect == "bug" or effect == "inspection":
		var damage: int = 1
		for uid in members:
			var worker_id: String = str(card(int(uid)).id)
			if worker_id == "senior_dev": damage = maxi(damage, 2)
			if worker_id == "accountant": damage = maxi(damage, 2)
			if worker_id == "lawyer": damage = maxi(damage, 3)
		root.hp = int(root.get("hp", 1)) - damage
		if int(root.hp) <= 0:
			_remove(int(root.uid))
			if effect == "inspection":
				state.inspection_misses = 0
				state.reputation = mini(5, int(state.reputation) + 1)
			_emit("hazard_resolved", text("msg.hazard_resolved"))
		return true
	if effect == "pantry":
		for uid in members:
			var worker: Dictionary = card(int(uid))
			if definition(worker.id).type == "person":
				if worker.status == "burnout":
					worker.status = ""
					worker.stress = float(rules().burnout_recover_stress)
				else: worker.stress = maxf(0.0, float(worker.stress) - float(rules().pantry_relief))
		return true
	if effect == "repair":
		root["buggy"] = false
		return true
	var ledger_value: int = 0
	var unfiled_value: int = 0
	for uid in consumed: ledger_value += int(card(int(uid)).get("value", 0))
	for uid in consumed: unfiled_value += int(card(int(uid)).get("unfiled_value", 0))
	if effect == "shred":
		state.shredded = int(state.shredded) + consumed.size()
		state.concealed = int(state.concealed) + unfiled_value
		state.tax_revenue = maxi(0, int(state.tax_revenue) - unfiled_value)
	for uid in members:
		var worker: Dictionary = card(int(uid))
		if definition(worker.id).type == "person" and worker.id != "ai_agent" and float(worker.get("overclock_until", 0)) <= float(state.time):
			var gain: float = float(recipe.stress) * float(profile().stress_mult)
			for other_uid in members:
				if card(int(other_uid)).id == "ergo_chair": gain *= float(rules().chair_stress_mult)
			worker.stress = minf(float(rules().stress_max), float(worker.stress) + gain)
	for uid in consumed: _remove(int(uid))
	var offset: int = 0
	for output_id in recipe.outputs:
		var product: Dictionary = _spawn(str(output_id), board_id, x + 180.0 + offset * 160.0, y, true)
		if output_id == "ledger_folder":
			product["value"] = ledger_value
			product["unfiled_value"] = unfiled_value
		if output_id == "black_fund": product["value"] = ledger_value
		state.produced[output_id] = int(state.produced.get(output_id, 0)) + 1
		offset += 1
	if recipe.has("cash"):
		var amount: int = int(recipe.cash)
		_add_cash(amount, board_id, x + 180.0, y)
		state.gigs = int(state.gigs) + 1
		state.quarter_revenue = int(state.quarter_revenue) + amount
	match effect:
		"series_a":
			state.phase = 2
			state.office = "coworking"
			state.boards[0].office = "coworking"
			state.boards[0].name = "Coworking"
			state.phase_cycle = 0
			_add_cash(int(rules().series_a_cash), board_id, x + 180.0, y + 220.0)
			_unlock_phase_ideas(2)
			_emit("phase_changed", text("msg.series_a"))
		"expand":
			state.office = "office_floor"
			state.boards[0].office = "office_floor"
			state.boards[0].name = "Office Floor"
			_emit("office_upgraded", text("msg.expanded"))
		"branch":
			state.boards.append({"id": 1, "name": "Branch", "office": "branch", "evictions": 0})
			_spawn("gateway", 1, 0.0, 0.0, true)
			_emit("branch_opened", text("msg.branch_opened"))
		"ipo":
			state.phase = 3
			state.office = "hq_tower"
			state.boards[0].office = "hq_tower"
			state.boards[0].name = "Headquarters"
			state.stock = float(rules().stock_start)
			state.stock_target = float(profile().stock_target)
			state.phase_cycle = 0
			state.quarter_revenue = 0
			state.quarter_expenses = 0
			_unlock_phase_ideas(3)
			_emit("phase_changed", text("msg.ipo"))
		"overclock":
			var founder: Dictionary = card(find_card("founder"))
			founder["overclock_until"] = float(state.time) + float(rules().day_seconds)
			founder["hospital_at"] = founder.overclock_until
		"buyout": _emit("acquired", text("msg.acquired", [_count("subsidiary")]))
	_emit("recipe_completed", "", {"recipe": recipe.id})
	_check_quests()
	return true

func _unlock_phase_ideas(phase: int) -> void:
	# Progression research is guaranteed at funding milestones; Whiteboard remains useful in P1.
	for id in rules().idea_pools[str(phase)]:
		if not id in state.ideas: state.ideas.append(id)

func step(delta: float) -> void:
	if state.is_empty() or bool(state.paused) or bool(state.ended): return
	_accumulator += maxf(0.0, delta) * float(state.speed)
	var tick: float = float(rules().tick)
	while _accumulator >= tick:
		_accumulator -= tick
		_tick(tick)
		if bool(state.ended): break
	_sync()

func _tick(dt: float) -> void:
	var old_day: int = int(state.day)
	state.time = float(state.time) + dt
	state.day = int(floor(float(state.time) / float(rules().day_seconds))) + 1
	_tick_people()
	_tick_hazards()
	_tick_transit()
	_tick_stacks(dt)
	_tick_automation(dt)
	_cleanup_stacks()
	if int(state.day) != old_day: _new_day()
	if float(state.time) >= float(state.next_event):
		_random_event()
		_schedule_event()
	_check_emergency()
	_check_quests()

func _tick_stacks(dt: float) -> void:
	for stack in state.stacks.duplicate():
		var recipe: Dictionary = _find_recipe(stack)
		if recipe.is_empty():
			stack.recipe = ""
			stack.progress = 0.0
			continue
		if stack.recipe != recipe.id:
			stack.recipe = recipe.id
			stack.progress = 0.0
			stack.pending = false
			stack["paid"] = false
		stack.duration = float(recipe.time)
		var speed: float = _worker_speed(recipe, stack.cards)
		if speed <= 0.0: continue
		if cash_available(int(stack.board)) < _recipe_cost(recipe): continue
		stack.progress = minf(float(stack.duration), float(stack.progress) + dt * speed)
		for uid in stack.cards:
			var item: Dictionary = card(int(uid))
			if not item.is_empty(): item.progress = float(stack.progress) / maxf(0.01, float(stack.duration))
		if float(stack.progress) >= float(stack.duration):
			if _complete(stack, recipe):
				stack.progress = 0.0
				stack.pending = false
				stack["paid"] = false

func _tick_people() -> void:
	for person in state.cards.duplicate():
		if definition(person.id).type == "candidate" and person.status == "hiring":
			if float(state.time) >= float(person.get("recover_at", 0)):
				person.id = str(definition(person.id).person)
				person.status = ""
				_emit("hired", text("msg.hired", [definition(person.id).name]))
			continue
		if definition(person.id).type != "person": continue
		if person.status in ["resting", "hospitalized"] and float(state.time) >= float(person.get("recover_at", 0)):
			if person.status == "resting": person.stress = maxf(0.0, float(person.stress) - float(rules().break_relief))
			person.status = ""
		if float(person.get("hospital_at", 0)) > 0 and float(state.time) >= float(person.hospital_at):
			person.hospital_at = 0.0
			person.status = "hospitalized"
			person["recover_at"] = float(state.time) + float(profile().hospital_days) * float(rules().day_seconds)
			_emit("hospitalized", text("msg.hospitalized"))
		if person.id == "ai_agent": continue
		if float(person.stress) >= float(rules().stress_max) and person.status == "":
			person.status = "burnout"
			person["recover_at"] = float(state.time) + float(rules().burnout_days) * float(rules().day_seconds)
			_emit("burnout", text("msg.burnout", [definition(person.id).name]))
		if person.status == "burnout":
			if _count("hr", int(person.board)) > 0 and _count("pantry", int(person.board)) > 0:
				person.status = "resting"
				person.stress = 6.0
				person.recover_at = float(state.time) + float(rules().break_seconds)
			elif float(state.time) >= float(person.recover_at):
				if person.id == "founder":
					person.status = "hospitalized"
					person.stress = 6.0
					person.recover_at = float(state.time) + float(profile().hospital_days) * float(rules().day_seconds)
				else:
					_spawn("lawsuit", int(person.board), float(person.x), float(person.y), true)
					_remove(int(person.uid))
					state.reputation = maxi(0, int(state.reputation) - 1)
					_emit("resigned", text("msg.resigned"))

func _tick_hazards() -> void:
	for item in state.cards.duplicate():
		if item.id == "headhunter" and float(state.time) >= float(item.get("deadline", INF)):
			var target_uid: int = int(item.get("target_uid", -1))
			if not card(target_uid).is_empty() and card(target_uid).id != "founder": _remove(target_uid)
			_remove(int(item.uid))
			_emit("poached", text("msg.poached"))
		if item.id in ["bug", "ai_hallucination"]:
			if float(state.time) >= float(item.next_damage):
				item.next_damage = float(state.time) + float(rules().bug_damage_seconds)
				var nearest: Dictionary = {}
				var distance: float = INF
				for product in state.cards:
					if int(product.board) == int(item.board) and definition(product.id).type == "product" and not product.get("buggy", false):
						var d: float = Vector2(float(product.x) - float(item.x), float(product.y) - float(item.y)).length_squared()
						if d < distance:
							distance = d
							nearest = product
				if not nearest.is_empty(): nearest["buggy"] = true
			if float(state.time) >= float(item.next_clone):
				item.next_clone = float(state.time) + float(rules().bug_clone_cooldown)
				_spawn(str(item.id), int(item.board), float(item.x) + 180.0, float(item.y) + 30.0, true)
		if item.id == "inspector" and float(state.time) >= float(item.deadline):
			state.inspection_misses = int(state.inspection_misses) + 1
			var amount: int = int(ceil(cash_available(int(item.board)) * float(rules().inspection_fine_fraction)))
			_spawn_invoice("fine", amount, int(item.board), float(state.time) + float(rules().day_seconds) * 2)
			_remove(int(item.uid))
			if int(state.inspection_misses) >= int(rules().inspection_loss): _lose("msg.sealed")
		if item.id in ["tax_notice", "fine"] and float(item.get("deadline", INF)) <= float(state.time) and not item.get("late", false):
			item.amount = int(ceil(float(item.amount) * (1.0 + float(rules().late_fine))))
			item["late"] = true
			_emit("late_tax", text("msg.late_tax"))

func _tick_transit() -> void:
	for item in state.cards:
		if item.status == "transit" and float(state.time) >= float(item.get("arrive_at", INF)):
			item.board = int(item.destination)
			item.status = ""
			item.x = float(item.get("destination_x", 0))
			item.y = float(item.get("destination_y", 0))
	for stack in state.stacks:
		if not stack.cards.is_empty(): stack.board = int(card(int(stack.cards[0])).get("board", stack.board))

func _tick_automation(dt: float) -> void:
	state.auto_line_clock = float(state.auto_line_clock) + dt
	if float(state.auto_line_clock) < float(rules().auto_line_seconds): return
	state.auto_line_clock = 0.0
	for line in state.cards.duplicate():
		if line.id != "assembly_line": continue
		var concept: int = -1
		for available in state.cards:
			if available.id == "concept" and int(available.board) == int(line.board) and int(available.stack_id) < 0 and available.status == "":
				concept = int(available.uid)
				break
		if concept >= 0 and used_capacity(int(line.board)) + reserved_capacity(int(line.board)) <= capacity(int(line.board)):
			_remove(concept)
			_spawn("prototype", int(line.board), float(line.x) + 180.0, float(line.y), true)

func payroll_preview(board_id: int = -1) -> Dictionary:
	if board_id < 0: board_id = int(state.board)
	if board_id >= state.boards.size(): return {}
	var rent: int = int(ceil(float(rules().office[state.boards[board_id].office].rent) * float(profile().rent_mult)))
	var wages: int = 0
	for person in state.cards:
		if int(person.board) == board_id and definition(person.id).type == "person": wages += int(ceil(float(definition(person.id).wage) * float(profile().wage_mult)))
		if int(person.board) == board_id and person.id == "server_cloud": wages += int(rules().server_cost)
	var cycle_seconds: float = float(profile().cycle_days) * float(rules().day_seconds)
	return {"rent": rent, "wages": wages, "total": rent + wages, "due_in": cycle_seconds - fmod(float(state.time), cycle_seconds), "due_day": (int(state.cycle) + 1) * int(profile().cycle_days)}

func _spawn_invoice(id: String, amount: int, board_id: int, deadline: float) -> Dictionary:
	if amount <= 0: return {}
	var item: Dictionary = _spawn(id, board_id, 560.0, -150.0 + _count(id, board_id) * 90.0, true)
	item.amount = amount
	item["original_amount"] = amount
	item["deadline"] = deadline
	item["paid"] = false
	if id == "payroll_invoice":
		item["employees"] = []
		for person in state.cards:
			if int(person.board) == board_id and definition(person.id).type == "person": item.employees.append(int(person.uid))
	return item

func _new_day() -> void:
	var cycle_days: int = int(profile().cycle_days)
	var elapsed_days: int = int(state.day) - 1
	if elapsed_days % cycle_days == cycle_days - 1:
		for board_entry in state.boards:
			var preview: Dictionary = payroll_preview(int(board_entry.id))
			var deadline: float = float(state.time) + float(rules().day_seconds)
			_spawn_invoice("rent_invoice", int(preview.rent), int(board_entry.id), deadline)
			_spawn_invoice("payroll_invoice", int(preview.wages), int(board_entry.id), deadline)
		_emit("payroll_warning", text("msg.payroll_warning"))
	if elapsed_days > 0 and elapsed_days % cycle_days == 0: _close_cycle()

func _close_cycle() -> void:
	state.cycle = int(state.cycle) + 1
	state.phase_cycle = int(state.phase_cycle) + 1
	# Payroll is billed against a fixed roster, so transport after the warning
	# cannot charge or penalize an employee in a second office.
	var unpaid_by_employee: Dictionary = {}
	for invoice in state.cards.duplicate():
		if invoice.id != "payroll_invoice" or float(invoice.get("deadline", INF)) > float(state.time) + 0.2: continue
		if not bool(invoice.get("paid", false)) and _can_autopay(int(invoice.board)): _pay_invoice(int(invoice.uid), true)
		for employee_uid in invoice.get("employees", []): unpaid_by_employee[int(employee_uid)] = not bool(invoice.get("paid", false))
	for board_entry in state.boards:
		var board_id: int = int(board_entry.id)
		var rent_unpaid: bool = false
		for invoice in state.cards.duplicate():
			if int(invoice.board) == board_id and invoice.id in ["rent_invoice", "payroll_invoice"] and float(invoice.get("deadline", INF)) <= float(state.time) + 0.2:
				if not bool(invoice.get("paid", false)):
					if _can_autopay(board_id): _pay_invoice(int(invoice.uid), true)
				if not bool(invoice.get("paid", false)):
					if invoice.id == "rent_invoice": rent_unpaid = true
				_remove(int(invoice.uid))
		if rent_unpaid:
			board_entry.evictions = int(board_entry.evictions) + 1
			_emit("eviction", text("msg.eviction", [board_entry.evictions, profile().evictions]))
			if int(board_entry.evictions) >= int(profile().evictions): _lose("msg.evicted")
		else: board_entry.evictions = 0
		var stressed: int = 0
		for person in state.cards.duplicate():
			if int(person.board) != board_id or definition(person.id).type != "person": continue
			if float(person.stress) >= float(rules().stress_tired): stressed += 1
			var employee_unpaid: bool = bool(unpaid_by_employee.get(int(person.uid), false))
			if employee_unpaid and person.id != "founder":
				person["unpaid"] = int(person.get("unpaid", 0)) + 1
				if int(person.unpaid) >= 2:
					_remove(int(person.uid))
					_emit("resigned", text("msg.unpaid_resignation"))
			else:
				person["unpaid"] = 0
				person.stress = maxf(0.0, float(person.stress) - 1.0)
		if int(state.phase) >= 2 and stressed >= int(rules().strike_count) and _count("strike", board_id) == 0:
			_spawn("strike", board_id, 100.0, -220.0, true)
			_emit("strike", text("msg.strike_warning"), {"board": board_id})
		for item in state.cards.duplicate():
			if int(item.board) != board_id: continue
			if item.id == "subsidiary":
				_add_cash(int(rules().subsidiary_income), board_id, float(item.x) + 160.0, float(item.y))
				state.quarter_revenue = int(state.quarter_revenue) + int(rules().subsidiary_income)
			if item.id == "lawsuit":
				_spawn_invoice("fine", int(rules().lawsuit_cost), board_id, float(state.time) + float(rules().day_seconds))
	if _count("strike") > 0:
		state.strike_misses = int(state.strike_misses) + 1
		if int(state.strike_misses) >= 2: _lose("msg.strike_loss")
	else: state.strike_misses = 0
	if int(state.phase) >= 2 and int(state.phase_cycle) % int(rules().quarter_cycles) == 0: _close_quarter()
	_emit("cycle_closed", text("msg.cycle_closed"))

func _can_autopay(board_id: int) -> bool:
	return _count("bank_card", board_id) > 0 and (_count("accountant", board_id) > 0 or _count("hr", board_id) > 0)

func _pay_invoice(uid: int, automatic: bool = false) -> Dictionary:
	var invoice: Dictionary = card(uid)
	if invoice.is_empty() or not invoice.id in ["payroll_invoice", "rent_invoice", "tax_notice", "fine"]: return _result(false, "msg.not_invoice")
	if bool(invoice.get("paid", false)): return _result(false, "msg.already_paid")
	if invoice.id == "tax_notice" and not bool(invoice.get("submitted", false)):
		if automatic and _count("accountant", int(invoice.board)) > 0: invoice["submitted"] = true
		else: return _result(false, "msg.tax_submit_first")
	var board_id: int = int(invoice.board)
	var available: int = cash_available(board_id) + (int(state.bank) if automatic else 0)
	var amount: int = mini(int(invoice.amount), available)
	if amount <= 0: return _result(false, "msg.insufficient")
	_spend(amount, board_id, automatic)
	invoice.amount = int(invoice.amount) - amount
	if invoice.id != "tax_notice": state.quarter_expenses = int(state.quarter_expenses) + amount
	if int(invoice.amount) <= 0:
		invoice["paid"] = true
		if bool(state.get("practice", false)): state.tutorial_flags.paid = true
		if invoice.id in ["tax_notice", "fine"]: _remove(uid)
		return _result(true, "msg.invoice_paid")
	return _result(true, "msg.invoice_partial", [invoice.amount])

func _close_quarter() -> void:
	state.quarter = int(state.quarter) + 1
	state.last_quarter_revenue = int(state.quarter_revenue)
	var tax: int = int(ceil(float(state.tax_revenue) * float(rules().tax_rate)))
	if _count("accountant") > 0: tax = int(ceil(float(tax) * (1.0 - float(rules().accountant_discount))))
	var tax_invoice: Dictionary = _spawn_invoice("tax_notice", tax, 0, float(state.time) + float(rules().tax_due_days) * float(rules().day_seconds))
	if not tax_invoice.is_empty(): tax_invoice["submitted"] = false
	state.tax_revenue = 0
	for record in state.cards:
		if record.id in ["receipt", "ledger_folder"]: record["unfiled_value"] = 0
	state.last_profit = int(state.quarter_revenue) - int(state.quarter_expenses) - tax
	if int(state.phase) >= 3:
		var target: float = maxf(1.0, float(state.stock_target))
		var change: float = clampf((float(state.last_profit) - target) / target * float(rules().stock_profit_weight), -float(rules().stock_profit_weight), float(rules().stock_profit_weight))
		change += (float(state.reputation) - 2.0) * float(rules().stock_reputation_weight)
		state.stock = clampf(float(state.stock) * (1.0 + change / 100.0), 0.0, float(rules().stock_max))
		state.stock_target = target * float(rules().stock_target_growth)
		if float(state.stock) <= float(rules().stock_loss): _lose("msg.takeover")
		if float(state.stock) >= float(rules().stock_win) and _count("subsidiary") >= int(rules().subsidiaries_to_win): state.stock_hold = int(state.stock_hold) + 1
		else: state.stock_hold = 0
		if int(state.stock_hold) >= int(rules().stock_hold) and not bool(state.victory):
			state.victory = true
			state.ended = true
			state.paused = true
			_emit("victory", text("msg.victory"))
		if int(state.recession_left) > 0: state.recession_left = int(state.recession_left) - 1
	state.quarter_revenue = 0
	state.quarter_expenses = 0
	if int(state.quarter) % int(profile().inspection_quarters) == 0:
		_spawn("inspector", 0, 500.0, -300.0, true)
		_emit("inspection", text("msg.inspection_warning"))
		var probability: float = clampf(float(profile().detect) + float(rules().detect_per_ten) * float(state.shredded) / float(rules().bill_wad), 0.0, 1.0)
		if int(state.shredded) > 0 and _rng.randf() < probability:
			_spawn_invoice("fine", int(ceil(float(state.concealed) * float(rules().tax_rate) * float(rules().tax_fraud_mult))), 0, float(state.time) + float(rules().day_seconds) * float(rules().tax_due_days))
			state.reputation = maxi(0, int(state.reputation) - 1)
			state.shredded = 0
			state.concealed = 0
	_emit("quarter_closed", text("msg.quarter_closed", [state.last_quarter_revenue, state.last_profit]))

func _schedule_event() -> void:
	state.next_event = float(state.time) + _rng.randf_range(float(profile().event_min), float(profile().event_max)) * float(rules().day_seconds)

func _random_event() -> void:
	if int(state.cycle) < 2:
		for person in state.cards:
			if definition(person.id).type == "person": person.stress = maxf(0.0, float(person.stress) - 1.0)
		_emit("event", text("event.friday"))
		return
	var weights: Dictionary = {}
	for id in db.events:
		var entry: Dictionary = db.events[id]
		if int(entry.phase) <= int(state.phase): weights[id] = float(entry.weight) * (float(profile().bad_weight) if bool(entry.bad) else 1.0)
	var chosen: String = _weighted(weights)
	match chosen:
		"viral": state.sale_boost_until = float(state.time) + float(profile().cycle_days) * float(rules().day_seconds)
		"price_war": state.sale_penalty_until = float(state.time) + float(profile().cycle_days) * float(rules().day_seconds)
		"drama": state.reputation = maxi(0, int(state.reputation) - 1)
		"friday":
			for person in state.cards:
				if definition(person.id).type == "person": person.stress = maxf(0.0, float(person.stress) - 1.0)
		"theft":
			for board_entry in state.boards:
				_steal_cash(int(board_entry.id))
		"poaching":
			for person in state.cards:
				if definition(person.id).type == "person" and not person.id in ["founder", "ai_agent"]:
					var headhunter: Dictionary = _spawn("headhunter", int(person.board), float(person.x) + 175.0, float(person.y), true)
					headhunter["target_uid"] = int(person.uid)
					headhunter["deadline"] = float(state.time) + float(rules().poaching_days) * float(rules().day_seconds)
					headhunter.amount = int(rules().poaching_fee)
					break
		"outage": state.outage_until = float(state.time) + float(rules().outage_days) * float(rules().day_seconds)
		"recession":
			if int(state.recession_left) == 0:
				var severity: float = 1.0 - float(profile().recession_stock)
				if _count("lobbyist") > 0: severity *= 1.0 - float(rules().recession_lobbyist)
				state.stock = float(state.stock) * (1.0 - severity)
				state.recession_left = int(rules().recession_quarters)
	if int(state.phase) >= 3 and _count("ai_agent") > 0 and _rng.randf() < float(rules().ai_bug_chance): _spawn("ai_hallucination", 0, 300.0, -280.0, true)
	_emit("event", text("event." + chosen))

func _check_emergency() -> void:
	if total_funds() >= 3 or int(state.emergency_cycle) == int(state.cycle): return
	if _count("freelance_contract") + _count("emergency_client") + _count("difficult_client") > 0: return
	var founder: Dictionary = card(find_card("founder"))
	if founder.is_empty(): return
	_spawn("emergency_client", int(founder.board), float(founder.x) + 190.0, float(founder.y), true)
	state.emergency_cycle = int(state.cycle)
	_emit("emergency", text("msg.emergency"))

func _check_quests() -> void:
	for quest in db.quests:
		if quest.id in state.quests: continue
		var done: bool = false
		match str(quest.condition):
			"gig": done = int(state.gigs) > 0
			"phase2": done = int(state.phase) >= 2
			"phase3": done = int(state.phase) >= 3
			"branch": done = state.boards.size() >= 2
			"victory": done = bool(state.victory)
			_: done = int(state.produced.get(quest.condition, 0)) > 0
		if done:
			state.quests.append(quest.id)
			if not str(quest.reward).is_empty() and not quest.reward in state.ideas: state.ideas.append(quest.reward)
			state.reputation = mini(5, int(state.reputation) + 1)
			_emit("quest_completed", text("msg.quest_completed", [quest.name]))

func goals() -> Array:
	var result: Array = []
	for entry in db.quests:
		var copy: Dictionary = entry.duplicate(true)
		copy["completed"] = entry.id in state.quests
		result.append(copy)
	return result

func actions_for(uid: int = -1) -> Array:
	var item: Dictionary = card(uid)
	var result: Array = []
	if item.is_empty():
		for entry in [["series_a", "action.series_a", 0], ["expand", "action.expand", int(rules().expand_cost)], ["branch", "action.branch", int(rules().branch_cost)], ["ipo", "action.ipo", 0], ["buyout", "action.buyout", buyout_price()], ["buyback", "action.buyback", int(rules().buyback_cost)], ["pay_all", "action.pay_all", 0]]:
			if entry[0] == "series_a" and int(state.phase) != 1: continue
			if entry[0] in ["expand", "branch", "ipo"] and int(state.phase) != 2: continue
			if entry[0] in ["buyout", "buyback"] and int(state.phase) != 3: continue
			result.append({"id": entry[0], "label": text(entry[1]), "cost": entry[2], "enabled": true})
		return result
	var type: String = str(definition(item.id).type)
	if type == "candidate": result.append({"id": "hire", "label": text("action.hire"), "cost": int(rules().ai_activation_cost if item.id == "candidate_ai_agent" else rules().hire_cost), "enabled": item.status != "hiring"})
	if type == "person" and item.id != "ai_agent": result.append({"id": "rest", "label": text("action.rest"), "enabled": true})
	if type == "idea": result.append({"id": "discover", "label": text("action.discover"), "enabled": true})
	if type in ["person", "candidate"] and item.id != "founder": result.append({"id": "dismiss", "label": text("action.dismiss"), "enabled": true})
	if item.id in ["payroll_invoice", "rent_invoice", "tax_notice", "fine"]: result.append({"id": "pay_invoice", "label": text("action.pay_invoice"), "cost": int(item.amount), "enabled": not bool(item.get("paid", false))})
	if item.id == "bank_card":
		result.append({"id": "deposit", "label": text("action.deposit"), "enabled": true})
		result.append({"id": "withdraw", "label": text("action.withdraw"), "enabled": int(state.bank) > 0})
	if item.id == "bank_counter": result.append({"id": "consolidate", "label": text("action.consolidate"), "enabled": true})
	if item.id == "office_safe":
		result.append({"id": "store_cash", "label": text("action.store_cash"), "enabled": true})
		result.append({"id": "open_safe", "label": text("action.open_safe"), "enabled": true})
	if item.id == "headhunter":
		result.append({"id": "retain", "label": text("action.retain"), "cost": int(rules().poaching_fee), "enabled": true})
		result.append({"id": "release_employee", "label": text("action.release_employee"), "enabled": true})
	if item.id == "tax_notice" and not bool(item.get("submitted", false)): result.append({"id": "file_tax", "label": text("action.file_tax"), "enabled": true})
	if item.id == "inspector": result.append({"id": "settlement", "label": text("action.settlement"), "cost": int(item.hp) * int(rules().settlement_per_hp), "enabled": true})
	if item.id == "strike": result.append({"id": "resolve_strike", "label": text("action.resolve_strike"), "enabled": true})
	if item.id == "stock_price": result.append({"id": "buyback", "label": text("action.buyback"), "cost": int(rules().buyback_cost), "enabled": true})
	if item.id in ["coffee", "team_ticket", "insurance"]: result.append({"id": "use", "label": text("action.use"), "enabled": true})
	if state.boards.size() > 1 and not item.id in ["gateway", "truck"]: result.append({"id": "transport", "label": text("action.transport"), "enabled": true})
	for recipe in db.recipes:
		if _matches(str(recipe.root), item) and int(recipe.phase) <= int(state.phase): result.append({"id": "craft:" + str(recipe.id), "label": str(recipe.name), "cost": _recipe_cost(recipe), "enabled": _recipe_enabled(recipe)})
	if sell_price(uid) > 0: result.append({"id": "sell", "label": text("action.sell", [sell_price(uid)]), "enabled": true})
	return result

func _action(id: String, uid: int) -> Dictionary:
	var item: Dictionary = card(uid)
	if id.begins_with("craft:"): return _assemble(id.trim_prefix("craft:"), uid)
	match id:
		"series_a": return _assemble("r_series_a")
		"expand": return _assemble("r_expand")
		"branch": return _assemble("r_branch")
		"ipo": return _assemble("r_ipo")
		"buyout": return _assemble("r_buyout", uid)
		"ledger": return _assemble("r_ledger", uid)
		"rest", "sell", "dismiss", "discover", "pay_invoice", "deposit", "withdraw": return command(id, {"uid": uid})
		"use":
			if item.is_empty(): return _result(false)
			var target: int = -1
			var highest: float = -1.0
			for person in state.cards:
				if int(person.board) == int(item.board) and definition(person.id).type == "person" and person.id != "ai_agent" and float(person.stress) > highest:
					highest = float(person.stress)
					target = int(person.uid)
			return _consume(uid, target)
		"hire":
			if item.is_empty() or definition(item.id).type != "candidate" or item.status == "hiring": return _result(false)
			if find_card("founder", int(item.board)) < 0: return _result(false, "msg.need_founder")
			if item.id == "candidate_ai_agent" and _count("server_cloud", int(item.board)) == 0: return _result(false, "msg.need_server")
			var cost: int = int(rules().ai_activation_cost if item.id == "candidate_ai_agent" else rules().hire_cost)
			if not _spend(cost, int(item.board)): return _result(false, "msg.insufficient")
			state.quarter_expenses = int(state.quarter_expenses) + cost
			item.status = "hiring"
			item["recover_at"] = float(state.time) + float(rules().hire_seconds)
			return _result(true, "msg.hiring")
		"pay_all":
			var paid: bool = false
			for invoice in state.cards.duplicate():
				if int(invoice.board) == int(state.board) and invoice.id in ["rent_invoice", "payroll_invoice", "tax_notice", "fine"] and not invoice.get("paid", false):
					var result: Dictionary = _pay_invoice(int(invoice.uid))
					paid = paid or bool(result.ok)
			return _result(paid)
		"consolidate":
			var amount: int = cash_available()
			_spend(amount, int(state.board))
			_add_cash(amount, int(state.board))
			return _result(true)
		"file_tax":
			if item.is_empty() or item.id != "tax_notice": return _result(false)
			item["submitted"] = true
			return _result(true, "msg.tax_submitted")
		"store_cash":
			if item.is_empty() or item.id != "office_safe": return _result(false)
			var stored: int = 0
			for wad in state.cards:
				if int(wad.get("stored_in", -1)) == uid: stored += 1
			if stored >= int(rules().safe_wads): return _result(false, "msg.safe_full")
			for wad in state.cards:
				if int(wad.board) == int(item.board) and str(wad.id).begins_with("usd_") and int(wad.get("stored_in", -1)) < 0:
					_detach(int(wad.uid))
					wad["stored_in"] = uid
					stored += 1
					if stored >= int(rules().safe_wads): break
			return _result(true, "msg.safe_stored")
		"open_safe":
			if item.is_empty() or item.id != "office_safe": return _result(false)
			var offset: int = 0
			for wad in state.cards:
				if int(wad.get("stored_in", -1)) == uid:
					wad["stored_in"] = -1
					wad.x = float(item.x) + 180.0 + offset * 60.0
					wad.y = float(item.y) + 40.0
					offset += 1
			return _result(true, "msg.safe_opened")
		"retain", "release_employee":
			if item.is_empty() or item.id != "headhunter": return _result(false)
			if id == "retain":
				if not _spend(int(rules().poaching_fee), int(item.board)): return _result(false, "msg.insufficient")
			else:
				var person_uid: int = int(item.get("target_uid", -1))
				if not card(person_uid).is_empty() and card(person_uid).id != "founder": _remove(person_uid)
			_remove(uid)
			return _result(true, "msg.retained" if id == "retain" else "msg.poached")
		"settlement":
			if item.is_empty(): item = card(find_card("inspector", int(state.board)))
			if item.is_empty(): return _result(false)
			if not _spend(int(item.hp) * int(rules().settlement_per_hp), int(item.board)): return _result(false, "msg.insufficient")
			_remove(int(item.uid))
			state.inspection_misses = 0
			return _result(true, "msg.hazard_resolved")
		"resolve_strike":
			if item.is_empty(): item = card(find_card("strike", int(state.board)))
			if item.is_empty(): return _result(false)
			if _count("hr", int(item.board)) == 0: return _result(false, "msg.need_hr")
			var people: int = 0
			for person in state.cards:
				if int(person.board) == int(item.board) and definition(person.id).type == "person": people += 1
			if not _spend(people * int(rules().strike_bonus), int(item.board)): return _result(false, "msg.insufficient")
			_remove(int(item.uid))
			state.strike_misses = 0
			for person in state.cards:
				if int(person.board) == int(state.board): person.stress = maxf(0.0, float(person.stress) - float(rules().team_relief))
			return _result(true, "msg.strike_resolved")
		"buyback":
			if int(state.phase) < 3 or int(state.buyback_quarter) == int(state.quarter): return _result(false, "msg.buyback_used")
			if not _spend(int(rules().buyback_cost), int(state.board)): return _result(false, "msg.insufficient")
			state.stock = minf(float(rules().stock_max), float(state.stock) + float(rules().buyback_gain))
			state.buyback_quarter = int(state.quarter)
			return _result(true)
		"transport": return _transport(uid)
	return _result(false, "msg.unknown_action")

func _transport(uid: int) -> Dictionary:
	var item: Dictionary = card(uid)
	if item.is_empty() or state.boards.size() < 2: return _result(false, "msg.board_locked")
	var stack: Dictionary = _stack(int(item.stack_id))
	var members: Array = stack.cards.duplicate() if not stack.is_empty() else [uid]
	if members.size() > int(rules().gateway_max): return _result(false, "msg.transport_limit")
	var destination: int = 1 - int(item.board)
	if used_capacity(destination) + reserved_capacity(destination) + members.size() > capacity(destination): return _result(false, "msg.pack_capacity")
	for member_uid in members:
		if card(int(member_uid)).status != "": return _result(false, "msg.busy")
		if card(int(member_uid)).id == "office_safe":
			for wad in state.cards:
				if int(wad.get("stored_in", -1)) == int(member_uid): return _result(false, "msg.empty_safe")
	for index in range(members.size()):
		var other: Dictionary = card(int(members[index]))
		other.status = "transit"
		other["destination"] = destination
		other["destination_x"] = 0.0
		other["destination_y"] = index * 28.0
		other["arrive_at"] = float(state.time) + float(rules().gateway_time)
	if not stack.is_empty():
		stack.progress = 0.0
		stack.recipe = ""
	return _result(true, "msg.transported")

func _lose(key: String) -> void:
	if bool(state.ended): return
	state.ended = true
	state.paused = true
	_emit("defeat", text(key))

func save_game(path: String = "user://save.json") -> bool:
	if state.is_empty(): return false
	if bool(state.get("practice", false)): return false
	_sync()
	var envelope: Dictionary = {"state": state, "next_uid": _next_uid, "accumulator": _accumulator}
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(envelope))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) == OK

func load_game(path: String = "user://save.json") -> bool:
	if not FileAccess.file_exists(path): return false
	var envelope: Variant = _read_json(path)
	if not envelope is Dictionary or not envelope.get("state") is Dictionary: return false
	var saved: Dictionary = envelope.state
	if not _validate_saved_state(saved, envelope): return false
	state = saved
	_next_uid = int(envelope.next_uid)
	_accumulator = float(envelope.get("accumulator", 0.0))
	_rng.seed = int(state.seed)
	_rng.state = int(str(state.rng_state))
	_events.clear()
	_sync()
	return true

func _validate_saved_state(saved: Dictionary, envelope: Dictionary) -> bool:
	if int(saved.get("schema_version", 0)) != 1 or not db.difficulty.has(saved.get("difficulty", "")): return false
	for field in ["cards", "stacks", "boards", "ideas", "quests"]:
		if not saved.get(field) is Array: return false
	for field in ["produced", "pack_buys"]:
		if not saved.get(field) is Dictionary: return false
	for field in ["time", "day", "phase", "board", "bank", "speed", "stock", "reputation", "cycle", "quarter", "stock_target", "phase_cycle", "quarter_revenue", "quarter_expenses", "tax_revenue", "seed", "next_event", "last_quarter_revenue", "last_profit", "stock_hold", "buyback_quarter", "sold", "gigs", "shredded", "concealed", "sale_boost_until", "sale_penalty_until", "outage_until", "recession_left", "inspection_misses", "strike_misses", "emergency_cycle", "last_invoice_cycle", "auto_line_clock", "tutorial_step"]:
		if not saved.get(field) is float and not saved.get(field) is int: return false
		if not is_finite(float(saved[field])): return false
	for field in ["paused", "ended", "victory", "endless"]:
		if not saved.get(field) is bool: return false
	if not saved.get("office") is String or not rules().office.has(saved.office) or not saved.get("rng_state") is String or not str(saved.rng_state).is_valid_int(): return false
	if saved.boards.is_empty() or saved.boards.size() > 2: return false
	if int(saved.bank) < 0 or int(saved.phase) < 1 or int(saved.phase) > 3 or int(saved.board) < 0 or int(saved.board) >= saved.boards.size(): return false
	for index in range(saved.boards.size()):
		var board: Variant = saved.boards[index]
		if not board is Dictionary: return false
		if int(board.get("id", -1)) != index or not board.get("name") is String or not rules().office.has(board.get("office", "")): return false
		if not board.get("evictions") is float and not board.get("evictions") is int: return false
		if int(board.evictions) < 0: return false
	if saved.boards[0].office != saved.office: return false
	var known: Dictionary = {}
	var max_uid: int = 0
	for item in saved.cards:
		if not item is Dictionary or not db.cards.has(item.get("id", "")): return false
		for required in ["uid", "board", "x", "y", "stack_id", "stress", "amount", "progress", "status", "born", "next_damage", "next_clone"]:
			if not item.has(required): return false
		for field in ["uid", "board", "x", "y", "stack_id", "stress", "amount", "progress", "born", "next_damage", "next_clone"]:
			if not item[field] is float and not item[field] is int: return false
			if not is_finite(float(item[field])): return false
		if not item.status is String: return false
		if int(item.uid) <= 0 or known.has(int(item.uid)) or int(item.board) < 0 or int(item.board) >= saved.boards.size(): return false
		if str(item.id).begins_with("usd_") and (int(item.amount) < 1 or int(item.amount) > int(rules().bill_wad)): return false
		known[int(item.uid)] = item
		max_uid = maxi(max_uid, int(item.uid))
	var stacks: Dictionary = {}
	for entry in saved.stacks:
		if not entry is Dictionary or not entry.get("cards") is Array: return false
		for field in ["uid", "board", "progress", "duration"]:
			if not entry.get(field) is float and not entry.get(field) is int: return false
		if not entry.get("recipe") is String or not entry.get("pending") is bool: return false
		if int(entry.uid) <= 0 or known.has(int(entry.uid)) or stacks.has(int(entry.uid)): return false
		if int(entry.board) < 0 or int(entry.board) >= saved.boards.size() or entry.cards.size() < 2: return false
		if not str(entry.recipe).is_empty() and _recipe_by_id(str(entry.recipe)).is_empty(): return false
		stacks[int(entry.uid)] = entry
		max_uid = maxi(max_uid, int(entry.uid))
		var members: Dictionary = {}
		var normalized_members: Array = []
		for member in entry.cards:
			if not known.has(int(member)) or members.has(int(member)): return false
			if int(known[int(member)].stack_id) != int(entry.uid) or int(known[int(member)].board) != int(entry.board): return false
			members[int(member)] = true
			normalized_members.append(int(member))
		# JSON parses numeric arrays as floats. Normalize IDs before Array membership checks.
		entry.cards = normalized_members
	for item in known.values():
		if int(item.stack_id) >= 0 and (not stacks.has(int(item.stack_id)) or not int(item.uid) in stacks[int(item.stack_id)].cards): return false
		if int(item.get("stored_in", -1)) >= 0:
			if not known.has(int(item.stored_in)) or known[int(item.stored_in)].id != "office_safe" or int(known[int(item.stored_in)].board) != int(item.board): return false
	if int(envelope.get("next_uid", 0)) <= max_uid: return false
	return true

func new_tutorial() -> void:
	new_run("easy", int(rules().practice_seed))
	state["practice"] = true
	state["tutorial_flags"] = {"paused": false, "gig": false, "concept": false, "prototype": false, "sold": false, "pack": false, "paid": false, "relief": false, "idea": false}
	_spawn("dev", 0, 300.0, -60.0, true)
	_spawn("concept", 0, 300.0, 220.0, true)
	_spawn("marker", 0, -160.0, 430.0, true)
	var practice_idea: Dictionary = _spawn("idea", 0, 520.0, 220.0, true)
	practice_idea["idea_id"] = "brew"
	_spawn_invoice("rent_invoice", int(rules().practice_invoice), 0, float(rules().day_seconds) * 8.0)
	state.notice = text("msg.tutorial")
	_sync()


