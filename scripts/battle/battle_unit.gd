class_name BattleUnit
extends RefCounted
## A unit's live state during one battle. Battle modifiers never touch the
## underlying UnitInstance, so the squad is unchanged after the fight.

const MIN_COOLDOWN := 0.3

var inst: UnitInstance
var data: UnitData
var team: int
var slot: int

## Flat stat modifiers gained during battle (stat key -> amount).
var mods: Dictionary = {}
## Cooldown speed bonus: 0.2 means cooldowns tick 20% faster.
var haste: float = 0.0
## Seconds of charge accumulated toward the next cast.
var progress: float = 0.0

var casts_done: int = 0
var damage_done: float = 0.0


func _init(owned: UnitInstance, team_index: int, slot_index: int) -> void:
	inst = owned
	data = owned.data
	team = team_index
	slot = slot_index


func add_mod(key: String, amount: float) -> void:
	mods[key] = float(mods.get(key, 0.0)) + amount


func get_stat(key: String) -> float:
	if key == "cooldown":
		return maxf(MIN_COOLDOWN, snappedf(inst.stat("cooldown") / (1.0 + haste), 0.05))
	var v: float = inst.stat(key) + float(mods.get(key, 0.0))
	if key == "casts":
		return maxf(1.0, floorf(v))
	return maxf(0.0, v)


func charge_ratio() -> float:
	return clampf(progress / get_stat("cooldown"), 0.0, 1.0)
