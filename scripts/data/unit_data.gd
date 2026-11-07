class_name UnitData
extends Resource
## Static definition of a recruitable unit. Instances live in GameDB.UNIT_DEFS,
## but you can also save these as .tres files and load them instead.

@export var id: StringName
@export var display_name: String = ""
@export_range(1, 4) var tier: int = 1
@export var faction: StringName = &"concord"
## Portrait silhouette: trooper, pilot, construct, hunter, mystic, officer.
@export var role: StringName = &"trooper"

@export_group("Stats")
@export var cooldown: float = 3.0
@export var damage: int = 0
@export var heal: int = 0
@export var shield: int = 0
@export var burn: int = 0
@export var toxin: int = 0
@export var ion: int = 0
@export var casts: int = 1

@export_group("Ability")
## When the ability fires: "" (none), battle_start, on_cast, ally_cast, on_shielded.
@export var ability_trigger: StringName = &""
## What it does. See BattleSim._run_ability for the full list.
@export var ability_effect: StringName = &""
## Effect parameters, usually {"amount": x} plus "stat", "status" or "faction".
@export var ability_params: Dictionary = {}
@export var ability_name: String = ""
## Description. {a} = amount x level, {p} = amount x level shown as a percent.
@export_multiline var ability_text: String = ""


func cost() -> int:
	return tier + 1


func describe_ability(level: int = 1) -> String:
	if ability_text.is_empty():
		return ""
	var amt: float = float(ability_params.get("amount", 0.0)) * level
	return ability_text.replace("{a}", format_number(amt)).replace("{p}", str(roundi(amt * 100.0)))


static func format_number(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	return "%.1f" % v
