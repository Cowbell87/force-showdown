extends Node
## Headless smoke test + balance report.
## Run: godot --headless --path . res://tests/smoke_test.tscn
## Exits with code 0 on success, 1 on any failed check.

var _failures: Array[String] = []


func _ready() -> void:
	_check(GameDB.units.size() >= 20, "unit roster loaded")
	_check(GameDB.commanders.size() >= 6, "commanders loaded")
	for tier in [1, 2, 3, 4]:
		_check(not (GameDB.units_by_tier[tier] as Array).is_empty(), "tier %d has units" % tier)
	for u in GameDB.units:
		_check(GameDB.FACTIONS.has(u.faction), "%s has a known faction" % u.id)
		if u.ability_text != "":
			_check(u.ability_effect != &"", "%s ability has an effect" % u.id)

	_test_run_flow()
	_balance_report()
	await _test_screens()

	if _failures.is_empty():
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		for f in _failures:
			printerr("FAILED: " + f)
		get_tree().quit(1)


func _check(cond: bool, what: String) -> void:
	if not cond:
		_failures.append(what)


func _test_run_flow() -> void:
	Run.start_run(GameDB.commanders[0])
	_check(Run.round_num == 1 and Run.gold == Run.round_income(Run.commander), "run starts at round 1 with income")
	var bought := 0
	for i in Run.SHOP_SIZE:
		if Run.buy(i).get("ok", false):
			bought += 1
	_check(bought > 0, "can buy from the shop")
	var sold := Run.sell(Run.team.find(Run.team.filter(func(u): return u != null)[0]))
	_check(sold > 0, "can sell a unit")
	Run.record_result(false)
	_check(Run.lives == Run.START_LIVES - 1, "loss costs a life")
	Run.begin_round()
	_check(Run.round_num == 2, "round advances")


func _balance_report() -> void:
	print("--- Balance: bot (round r) vs bot (round r), 40 battles each ---")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for r: int in [1, 3, 5, 8, 10]:
		var p0_wins := 0
		var total_time := 0.0
		var max_time := 0.0
		for i in 40:
			var a := BotGenerator.generate(r, rng.randi())
			var b := BotGenerator.generate(r, rng.randi())
			var sim := BattleSim.new()
			var hp := 80.0 + 50.0 * r
			sim.setup([
				{"units": a["units"], "commander": a["commander"], "hp": hp},
				{"units": b["units"], "commander": b["commander"], "hp": hp},
			])
			sim.start()
			var w := sim.simulate_to_end()
			_check(sim.over, "battle finishes (round %d)" % r)
			if w == 0:
				p0_wins += 1
			total_time += sim.time
			max_time = maxf(max_time, sim.time)
		print("round %2d: side-0 win rate %3d%%  avg %.1fs  max %.1fs" % [r, roundi(p0_wins * 100.0 / 40.0), total_time / 40.0, max_time])

	print("--- Unit power: each unit (lvl 2) + 4 Legionnaires vs 5 Legionnaires, round 5 HP ---")
	var filler: UnitData = GameDB.get_unit(&"dominion_legionnaire")
	var scores: Array = []
	for u in GameDB.units:
		var wins := 0
		var margin := 0.0
		for side in 2:
			var mine: Array = [UnitInstance.new(u, 2)]
			var theirs: Array = []
			for k in 4:
				mine.append(UnitInstance.new(filler, 1))
			for k in 5:
				theirs.append(UnitInstance.new(filler, 1))
			var sim := BattleSim.new()
			sim.setup([
				{"units": mine if side == 0 else theirs, "commander": null, "hp": 330.0},
				{"units": theirs if side == 0 else mine, "commander": null, "hp": 330.0},
			])
			sim.start()
			var w := sim.simulate_to_end()
			if w == side:
				wins += 1
			margin += sim.teams[side].hp - sim.teams[1 - side].hp
		scores.append([u.display_name, u.tier, margin / 2.0])
	scores.sort_custom(func(x, y): return x[2] > y[2])
	for s in scores:
		print("  T%d %-24s hp margin %7.1f" % [s[1], s[0], s[2]])


func _test_screens() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.show_commanders()
	await get_tree().process_frame
	main._on_commander_chosen(GameDB.commanders[1])
	await get_tree().process_frame
	for i in Run.SHOP_SIZE:
		Run.buy(i)
	main.show_shop()
	await get_tree().process_frame
	main.show_battle()
	var battle := main._screen as BattleScreen
	_check(battle != null and battle.sim != null, "battle screen created a sim")
	if battle != null:
		var start_ms := Time.get_ticks_msec()
		while not battle._running and Time.get_ticks_msec() - start_ms < 5000:
			await get_tree().process_frame
		_check(battle._running, "battle starts")
		var watch_ms := Time.get_ticks_msec()
		while Time.get_ticks_msec() - watch_ms < 1500:
			await get_tree().process_frame
		battle._on_skip()
		_check(battle.sim.over, "battle can be skipped to the end")
		var end_ms := Time.get_ticks_msec()
		while Time.get_ticks_msec() - end_ms < 1800:
			await get_tree().process_frame
	main.show_summary()
	await get_tree().process_frame
	main.queue_free()
	await get_tree().process_frame
