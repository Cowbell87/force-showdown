class_name BotGenerator
extends RefCounted
## Builds an opponent squad by replaying the shop phase for every round so far
## with a simple greedy strategy. The same seed always produces the same squad.

const SQUAD_NAMES := [
	"Crimson Talon Squadron", "Hollow Moon Syndicate", "Vanguard Seven",
	"Ashfall Raiders", "Starlight Lancers", "Obsidian Watch",
	"Ghost Reach Militia", "Iron Comet Legion", "Sunspear Company",
	"The Quiet Armada", "Nightglass Cartel", "Azure Wake Battalion",
]
const MAX_REROLLS_PER_ROUND := 4


static func generate(round_num: int, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var commander: CommanderData = GameDB.commanders[rng.randi_range(0, GameDB.commanders.size() - 1)]
	var team: Array = []
	team.resize(Run.TEAM_SIZE)

	for r in range(1, round_num + 1):
		var gold := Run.round_income(commander)
		var shop := Run.roll_offers(r, rng)
		var rerolls := 0
		var guard := 0
		while guard < 60:
			guard += 1
			var merge_cost := _try_merge(team, shop, gold)
			if merge_cost > 0:
				gold -= merge_cost
				continue
			var empty := team.find(null)
			if empty >= 0:
				var best := _best_affordable(shop, gold)
				if best >= 0:
					var d: UnitData = shop[best]
					team[empty] = UnitInstance.new(d)
					gold -= d.cost()
					shop[best] = null
					continue
			else:
				var gained := _try_upgrade(team, shop, gold)
				if gained != NO_UPGRADE:
					gold += gained
					continue
			if gold >= Run.REROLL_COST and rerolls < MAX_REROLLS_PER_ROUND:
				gold -= Run.REROLL_COST
				rerolls += 1
				shop = Run.roll_offers(r, rng)
				continue
			break

	return {
		"commander": commander,
		"units": team,
		"name": SQUAD_NAMES[rng.randi_range(0, SQUAD_NAMES.size() - 1)],
	}


const NO_UPGRADE := -9999


## Levels up an owned unit with a matching shop offer. Returns the cost paid (0 if none).
static func _try_merge(team: Array, shop: Array, gold: int) -> int:
	for i in shop.size():
		var d: UnitData = shop[i]
		if d == null or d.cost() > gold:
			continue
		for s in team.size():
			var owned: UnitInstance = team[s]
			if owned != null and owned.data == d and owned.level < UnitInstance.MAX_LEVEL:
				owned.level += 1
				shop[i] = null
				return d.cost()
	return 0


static func _best_affordable(shop: Array, gold: int) -> int:
	var best := -1
	for i in shop.size():
		var d: UnitData = shop[i]
		if d == null or d.cost() > gold:
			continue
		if best < 0 or d.tier > (shop[best] as UnitData).tier:
			best = i
	return best


## Sells the weakest unit to buy a higher-tier one. Returns the net credit
## change, or NO_UPGRADE when nothing was worth swapping.
static func _try_upgrade(team: Array, shop: Array, gold: int) -> int:
	var weakest := -1
	for s in team.size():
		var owned: UnitInstance = team[s]
		if owned == null:
			continue
		if weakest < 0 or _power(owned) < _power(team[weakest]):
			weakest = s
	if weakest < 0:
		return NO_UPGRADE
	var w: UnitInstance = team[weakest]
	for i in shop.size():
		var d: UnitData = shop[i]
		if d == null:
			continue
		if d.tier > w.data.tier and d.cost() <= gold + w.sell_value():
			var net := w.sell_value() - d.cost()
			team[weakest] = UnitInstance.new(d)
			shop[i] = null
			return net
	return NO_UPGRADE


static func _power(owned: UnitInstance) -> float:
	return owned.data.tier * 2.0 + owned.level
