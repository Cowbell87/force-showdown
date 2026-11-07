class_name BattleSim
extends RefCounted
## Deterministic auto-battle between two squads. Has no UI dependencies: the
## BattleScreen listens to its signals, and tests can call simulate_to_end().
##
## Rules:
## - Each side has one shared HP pool. Shield absorbs damage first.
## - Units charge their cooldown, then cast `casts` times (MULTICAST_GAP apart).
##   A cast applies every non-zero output stat: Damage/Burn/Toxin/Ion to the
##   enemy, Heal/Shield to the own team.
## - Burn ticks every 0.5s for its stacks, then loses 1 stack.
## - Toxin ticks every 1s for its stacks and never fades.
## - Ion: every direct hit deals bonus damage equal to Ion, then Ion drops by 1.
## - After 30s, Sudden Death deals exponentially growing damage to both sides.

signal unit_cast(unit: BattleUnit, effects: Array)
signal ability_triggered(unit: BattleUnit)
signal damage_taken(team: int, amount: float, kind: String)
signal healed(team: int, amount: float)
signal shield_changed(team: int, amount: float)
signal status_changed(team: int, status: String, stacks: int)
signal sudden_death_started
signal battle_ended(winner: int)

const TICK := 1.0 / 30.0
const MULTICAST_GAP := 0.12
const BURN_INTERVAL := 0.5
const TOXIN_INTERVAL := 1.0
const SUDDEN_DEATH_TIME := 30.0
const SUDDEN_DEATH_INTERVAL := 0.5
const SUDDEN_DEATH_BASE := 6.0
const SUDDEN_DEATH_DOUBLING := 3.0
const MAX_TIME := 120.0
const STATUSES: Array[String] = ["burn", "toxin", "ion"]


class Team:
	var name: String = ""
	var hp: float = 0.0
	var max_hp: float = 0.0
	var shield: float = 0.0
	var status: Dictionary = {"burn": 0, "toxin": 0, "ion": 0}
	var units: Array[BattleUnit] = []
	var commander: CommanderData
	var faction_damage_mult: Dictionary = {}
	var dot_mult: float = 0.0
	var regen: float = 0.0
	var regen_interval: float = 0.0
	var regen_timer: float = 0.0


var teams: Array[Team] = []
var time: float = 0.0
var over: bool = false
var winner: int = -1
var sudden_death: bool = false

var _sd_timer: float = 0.0
var _burn_timer: float = 0.0
var _toxin_timer: float = 0.0
var _cast_queue: Array[Dictionary] = []
var _shield_depth: int = 0


## team_defs: two dictionaries {units: Array[UnitInstance or null], commander, hp, name}.
func setup(team_defs: Array) -> void:
	teams.clear()
	for i in 2:
		var def: Dictionary = team_defs[i]
		var t := Team.new()
		t.name = def.get("name", "Team %d" % (i + 1))
		t.hp = float(def["hp"])
		t.max_hp = t.hp
		t.commander = def.get("commander")
		var lineup: Array = def["units"]
		for s in lineup.size():
			var owned: UnitInstance = lineup[s]
			if owned != null:
				t.units.append(BattleUnit.new(owned, i, s))
		teams.append(t)


## Applies synergies, commanders and battle-start abilities. Call once before stepping.
func start() -> void:
	for i in 2:
		_apply_synergies(i)
	for i in 2:
		_apply_commander(i)

	var starters: Array[BattleUnit] = []
	for t in teams:
		for u in t.units:
			if u.data.ability_trigger == &"battle_start":
				starters.append(u)
	starters.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool:
		if a.data.tier != b.data.tier:
			return a.data.tier > b.data.tier
		if a.team != b.team:
			return a.team < b.team
		return a.slot < b.slot)
	for u in starters:
		_run_ability(u)

	for i in 2:
		shield_changed.emit(i, teams[i].shield)
		for s in STATUSES:
			status_changed.emit(i, s, teams[i].status[s])


func step(delta: float = TICK) -> void:
	if over:
		return
	time += delta

	if not sudden_death and time >= SUDDEN_DEATH_TIME:
		sudden_death = true
		sudden_death_started.emit()
	if sudden_death:
		_sd_timer += delta
		while _sd_timer >= SUDDEN_DEATH_INTERVAL:
			_sd_timer -= SUDDEN_DEATH_INTERVAL
			var dmg := SUDDEN_DEATH_BASE * pow(2.0, (time - SUDDEN_DEATH_TIME) / SUDDEN_DEATH_DOUBLING)
			for i in 2:
				_damage(i, dmg, "sudden")

	for t in teams:
		for u in t.units:
			u.progress += delta
			var cd := u.get_stat("cooldown")
			if u.progress >= cd - 0.0001:
				u.progress = maxf(0.0, u.progress - cd)
				_queue_casts(u)

	var q := 0
	while q < _cast_queue.size():
		var entry: Dictionary = _cast_queue[q]
		entry["timer"] = float(entry["timer"]) - delta
		if float(entry["timer"]) <= 0.0:
			_cast(entry["unit"])
			entry["remaining"] = int(entry["remaining"]) - 1
			entry["timer"] = MULTICAST_GAP
			if int(entry["remaining"]) <= 0:
				_cast_queue.remove_at(q)
				continue
		q += 1

	_burn_timer += delta
	while _burn_timer >= BURN_INTERVAL:
		_burn_timer -= BURN_INTERVAL
		for i in 2:
			var stacks: int = teams[i].status["burn"]
			if stacks > 0:
				_damage(i, stacks, "burn")
				_set_status(i, "burn", stacks - 1)

	_toxin_timer += delta
	while _toxin_timer >= TOXIN_INTERVAL:
		_toxin_timer -= TOXIN_INTERVAL
		for i in 2:
			var stacks: int = teams[i].status["toxin"]
			if stacks > 0:
				_damage(i, stacks, "toxin")

	for i in 2:
		var t := teams[i]
		if t.regen > 0.0:
			t.regen_timer += delta
			while t.regen_timer >= t.regen_interval:
				t.regen_timer -= t.regen_interval
				_heal(i, t.regen)

	_check_end()


## Runs the whole battle instantly. Returns the winner (0 or 1).
func simulate_to_end() -> int:
	var guard := int(MAX_TIME / TICK) + 10
	while not over and guard > 0:
		step(TICK)
		guard -= 1
	return winner


func unit_at(team_index: int, slot_index: int) -> BattleUnit:
	for u in teams[team_index].units:
		if u.slot == slot_index:
			return u
	return null


# --- Casting -----------------------------------------------------------------

func _queue_casts(u: BattleUnit) -> void:
	var count := int(u.get_stat("casts"))
	for entry in _cast_queue:
		if entry["unit"] == u:
			entry["remaining"] = int(entry["remaining"]) + count
			return
	_cast_queue.append({"unit": u, "remaining": count, "timer": 0.0})


func _cast(u: BattleUnit) -> void:
	if over:
		return
	var t := teams[u.team]
	var foe := 1 - u.team
	u.casts_done += 1

	var effects: Array = []
	var dmg := u.get_stat("damage")
	if dmg > 0.0:
		dmg = roundf(dmg * (1.0 + float(t.faction_damage_mult.get(String(u.data.faction), 0.0))))
		effects.append({"type": "damage", "amount": dmg})
	var heal := u.get_stat("heal")
	if heal > 0.0:
		effects.append({"type": "heal", "amount": heal})
	var shield := u.get_stat("shield")
	if shield > 0.0:
		effects.append({"type": "shield", "amount": shield})
	for s in STATUSES:
		var amount := u.get_stat(s)
		if amount > 0.0:
			if s != "ion":
				amount = roundf(amount * (1.0 + t.dot_mult))
			effects.append({"type": s, "amount": amount})

	unit_cast.emit(u, effects)

	for e in effects:
		var amount: float = e["amount"]
		match String(e["type"]):
			"damage":
				u.damage_done += amount
				_damage(foe, amount, "hit")
			"heal":
				_heal(u.team, amount)
			"shield":
				_add_shield(u.team, amount)
			var status:
				_add_status(foe, status, int(amount))

	if u.data.ability_trigger == &"on_cast":
		_run_ability(u)
	for ally in t.units:
		if ally != u and ally.data.ability_trigger == &"ally_cast":
			_run_ability(ally, false)


# --- Abilities -------------------------------------------------------------

func _run_ability(u: BattleUnit, announce: bool = true) -> void:
	var d := u.data
	var p: Dictionary = d.ability_params
	var t := teams[u.team]
	var amt: float = float(p.get("amount", 0.0)) * u.inst.level
	var stat := String(p.get("stat", ""))
	match d.ability_effect:
		&"buff_self":
			u.add_mod(stat, amt)
		&"buff_adjacent":
			for x in t.units:
				if absi(x.slot - u.slot) == 1:
					x.add_mod(stat, amt)
		&"buff_faction":
			var fac := StringName(p.get("faction", ""))
			for x in t.units:
				if x.data.faction == fac:
					x.add_mod(stat, amt)
		&"buff_all":
			for x in t.units:
				x.add_mod(stat, amt)
		&"haste_self":
			u.haste += amt
		&"haste_all":
			for x in t.units:
				x.haste += amt
		&"status_enemy":
			_add_status(1 - u.team, String(p.get("status", "burn")), int(amt))
		&"charge_self":
			u.progress += amt
		&"damage_enemy":
			u.damage_done += amt
			_damage(1 - u.team, amt, "hit")
		&"heal_team":
			_heal(u.team, amt)
		&"shield_team":
			_add_shield(u.team, amt)
		_:
			return
	if announce:
		ability_triggered.emit(u)


func _apply_synergies(i: int) -> void:
	var t := teams[i]
	var datas: Array = []
	for u in t.units:
		datas.append(u.data)
	var counts := GameDB.faction_counts(datas)
	for fac: StringName in counts:
		var tier := GameDB.synergy_tier(int(counts[fac]))
		if tier == 0:
			continue
		var values: Array = GameDB.faction(fac)["synergy_values"]
		var v: float = float(values[tier - 1])
		match fac:
			&"concord":
				for u in t.units:
					if u.data.faction == fac:
						u.add_mod("damage", v)
			&"dominion":
				teams[1 - i].status["burn"] += int(v)
			&"syndicate":
				for u in t.units:
					if u.data.faction == fac:
						u.add_mod("toxin", v)
			&"veil":
				for u in t.units:
					u.haste += v / 100.0
			&"forge":
				t.shield += v


func _apply_commander(i: int) -> void:
	var t := teams[i]
	var c := t.commander
	if c == null:
		return
	var p := c.params
	match c.effect:
		&"front_casts":
			var count := int(p.get("count", 2))
			var sorted_units := t.units.duplicate()
			sorted_units.sort_custom(func(a: BattleUnit, b: BattleUnit) -> bool: return a.slot < b.slot)
			for k in mini(count, sorted_units.size()):
				sorted_units[k].add_mod("casts", 1.0)
		&"faction_damage_mult":
			t.faction_damage_mult[String(p.get("faction", ""))] = float(p.get("mult", 0.0))
		&"team_regen":
			t.regen = float(p.get("amount", 0.0))
			t.regen_interval = maxf(0.1, float(p.get("interval", 2.0)))
		&"start_shield":
			t.shield += float(p.get("amount", 0.0))
		&"enemy_ion":
			teams[1 - i].status["ion"] += int(p.get("amount", 0))
		&"dot_mult":
			t.dot_mult = float(p.get("mult", 0.0))
		&"opening_volley":
			var ratio := float(p.get("ratio", 0.5))
			for u in t.units:
				u.progress = u.get_stat("cooldown") * ratio
		# bonus_gold is a shop effect handled by Run.


# --- Resolution ------------------------------------------------------------

func _damage(ti: int, amount: float, kind: String) -> void:
	if amount <= 0.0 or over:
		return
	var t := teams[ti]
	if kind == "hit":
		var ion: int = t.status["ion"]
		if ion > 0:
			_set_status(ti, "ion", ion - 1)
			_damage(ti, ion, "ion")
	var rest := amount
	if t.shield > 0.0 and kind != "sudden":
		var absorbed := minf(t.shield, rest)
		t.shield -= absorbed
		rest -= absorbed
		shield_changed.emit(ti, t.shield)
	if rest > 0.0:
		t.hp -= rest
	damage_taken.emit(ti, amount, kind)


func _heal(ti: int, amount: float) -> void:
	var t := teams[ti]
	var before := t.hp
	t.hp = minf(t.max_hp, t.hp + amount)
	if t.hp > before:
		healed.emit(ti, t.hp - before)


func _add_shield(ti: int, amount: float) -> void:
	var t := teams[ti]
	t.shield += amount
	shield_changed.emit(ti, t.shield)
	if _shield_depth > 0:
		return
	_shield_depth += 1
	for x in t.units:
		if x.data.ability_trigger == &"on_shielded":
			_run_ability(x, false)
	_shield_depth -= 1


func _add_status(ti: int, status: String, amount: int) -> void:
	if amount <= 0:
		return
	_set_status(ti, status, int(teams[ti].status[status]) + amount)


func _set_status(ti: int, status: String, stacks: int) -> void:
	teams[ti].status[status] = maxi(0, stacks)
	status_changed.emit(ti, status, teams[ti].status[status])


func _check_end() -> void:
	var down0 := teams[0].hp <= 0.0
	var down1 := teams[1].hp <= 0.0
	if not (down0 or down1 or time >= MAX_TIME):
		return
	over = true
	if down1:
		winner = 0  # ties go to the player (team 0)
	elif down0:
		winner = 1
	else:
		winner = 0 if teams[0].hp / teams[0].max_hp >= teams[1].hp / teams[1].max_hp else 1
	battle_ended.emit(winner)
