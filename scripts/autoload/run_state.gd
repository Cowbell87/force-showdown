extends Node
## State of the current campaign: commander, squad, credits, shop, wins and lives.
## Screens read from here and call the mutating functions below.

signal changed

const TEAM_SIZE := 5
const SHOP_SIZE := 5
const START_LIVES := 8
const WINS_TO_VICTORY := 10
const BASE_GOLD := 10
const REROLL_COST := 1

## Shop tier weights [common, rare, epic, legendary] by first round they apply.
const TIER_ODDS := [
	[1, [100, 0, 0, 0]],
	[2, [80, 20, 0, 0]],
	[3, [65, 30, 5, 0]],
	[4, [50, 35, 15, 0]],
	[5, [40, 35, 20, 5]],
	[6, [30, 35, 25, 10]],
	[8, [20, 33, 30, 17]],
]

var commander: CommanderData
var team: Array = []
var shop: Array = []
var gold: int = 0
var round_num: int = 0
var wins: int = 0
var lives: int = START_LIVES
var history: Array[bool] = []
var rng := RandomNumberGenerator.new()


func start_run(chosen: CommanderData) -> void:
	commander = chosen
	team = []
	team.resize(TEAM_SIZE)
	wins = 0
	lives = START_LIVES
	round_num = 0
	history.clear()
	rng.randomize()
	begin_round()


func begin_round() -> void:
	round_num += 1
	gold = round_income(commander)
	roll_shop()
	changed.emit()


static func round_income(c: CommanderData) -> int:
	var bonus := 0
	if c != null and c.effect == &"bonus_gold":
		bonus = int(c.params.get("amount", 0))
	return BASE_GOLD + bonus


## Both squads use the same HP pool, growing each round.
func team_hp() -> float:
	return 80.0 + 50.0 * round_num


func loss_for_round(r: int) -> int:
	if r <= 2:
		return 1
	if r <= 4:
		return 2
	return 3


func roll_shop() -> void:
	shop = roll_offers(round_num, rng)


static func roll_offers(r: int, generator: RandomNumberGenerator) -> Array:
	var offers: Array = []
	for i in SHOP_SIZE:
		offers.append(random_unit(r, generator))
	return offers


static func tier_weights(r: int) -> Array:
	var weights: Array = TIER_ODDS[0][1]
	for row: Array in TIER_ODDS:
		if r >= int(row[0]):
			weights = row[1]
	return weights


static func random_unit(r: int, generator: RandomNumberGenerator) -> UnitData:
	var weights := tier_weights(r)
	var total := 0
	for w: int in weights:
		total += w
	var roll := generator.randi_range(1, total)
	var tier := 1
	for i in weights.size():
		roll -= int(weights[i])
		if roll <= 0:
			tier = i + 1
			break
	var pool: Array = GameDB.units_by_tier[tier]
	return pool[generator.randi_range(0, pool.size() - 1)]


func reroll() -> bool:
	if gold < REROLL_COST:
		return false
	gold -= REROLL_COST
	roll_shop()
	changed.emit()
	return true


## Returns {ok: bool, merged: bool, slot: int, reason: String}.
func buy(index: int) -> Dictionary:
	var d: UnitData = shop[index]
	if d == null:
		return {"ok": false, "reason": "Already recruited"}
	if gold < d.cost():
		return {"ok": false, "reason": "Not enough credits"}
	for s in TEAM_SIZE:
		var owned: UnitInstance = team[s]
		if owned != null and owned.data == d and owned.level < UnitInstance.MAX_LEVEL:
			owned.level += 1
			gold -= d.cost()
			shop[index] = null
			changed.emit()
			return {"ok": true, "merged": true, "slot": s}
	var empty := team.find(null)
	if empty == -1:
		return {"ok": false, "reason": "Squad is full - sell a unit first"}
	team[empty] = UnitInstance.new(d)
	gold -= d.cost()
	shop[index] = null
	changed.emit()
	return {"ok": true, "merged": false, "slot": empty}


func sell(slot: int) -> int:
	var owned: UnitInstance = team[slot]
	if owned == null:
		return 0
	var value := owned.sell_value()
	gold += value
	team[slot] = null
	changed.emit()
	return value


func swap(a: int, b: int) -> void:
	var tmp = team[a]
	team[a] = team[b]
	team[b] = tmp
	changed.emit()


func team_datas() -> Array:
	var out: Array = []
	for owned in team:
		out.append(owned.data if owned != null else null)
	return out


func record_result(won: bool) -> void:
	history.append(won)
	if won:
		wins += 1
	else:
		lives -= loss_for_round(round_num)
	changed.emit()


func is_over() -> bool:
	return wins >= WINS_TO_VICTORY or lives <= 0


func is_victory() -> bool:
	return wins >= WINS_TO_VICTORY
