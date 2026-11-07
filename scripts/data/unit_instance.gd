class_name UnitInstance
extends RefCounted
## A unit owned by a squad: its definition plus a level (1-3).
## Buying a duplicate raises the level; each level adds +50% to output stats.

const MAX_LEVEL := 3
const OUTPUT_STATS: Array[String] = ["damage", "heal", "shield", "burn", "toxin", "ion"]

var data: UnitData
var level: int = 1


func _init(d: UnitData, lvl: int = 1) -> void:
	data = d
	level = lvl


func stat(key: String) -> float:
	return UnitInstance.scaled(data, key, level)


func sell_value() -> int:
	return maxi(1, int(data.cost() / 2.0)) * level


static func scaled(d: UnitData, key: String, lvl: int) -> float:
	match key:
		"cooldown":
			return d.cooldown
		"casts":
			return float(d.casts)
	var base: float = float(d.get(key))
	return roundf(base * (1.0 + 0.5 * (lvl - 1)))
