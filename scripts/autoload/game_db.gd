extends Node
## Content database. Factions, tiers, units and commanders are plain data so that
## adding content is a matter of appending a dictionary. Unit/commander keys match
## the properties on UnitData / CommanderData.

const TIER_NAMES := {1: "Common", 2: "Rare", 3: "Epic", 4: "Legendary"}
const TIER_COLORS := {
	1: Color("#9aaabb"),
	2: Color("#3fa7ff"),
	3: Color("#b45cff"),
	4: Color("#ffc845"),
}

const STAT_NAMES := {
	"damage": "Damage", "heal": "Heal", "shield": "Shield",
	"burn": "Burn", "toxin": "Toxin", "ion": "Ion",
	"cooldown": "Cooldown", "casts": "Casts",
}
const STAT_COLORS := {
	"damage": Color("#ff4d5e"),
	"heal": Color("#4fe08a"),
	"shield": Color("#5ab8ff"),
	"burn": Color("#ff8a2b"),
	"toxin": Color("#b46bff"),
	"ion": Color("#45f0ff"),
	"cooldown": Color("#9fb4cf"),
	"casts": Color("#d8b25a"),
	"sudden": Color("#ff2a2a"),
	"hit": Color("#ffffff"),
}

## Distinct units of one faction needed for synergy tier 1 / tier 2.
const SYNERGY_THRESHOLDS := [2, 4]

const FACTIONS := {
	&"concord": {
		"name": "Concord Alliance",
		"color": Color("#e8643c"), "armor": Color("#d9c9a8"), "accent": Color("#ffa040"),
		"synergy_text": "Concord units gain +{v} Damage",
		"synergy_values": [2, 5],
	},
	&"dominion": {
		"name": "The Dominion",
		"color": Color("#d6283c"), "armor": Color("#e6ebf1"), "accent": Color("#ff3048"),
		"synergy_text": "Enemy team starts with {v} Burn",
		"synergy_values": [3, 8],
	},
	&"syndicate": {
		"name": "Gilded Fang Syndicate",
		"color": Color("#2fbf8f"), "armor": Color("#5d6d5c"), "accent": Color("#7dffb8"),
		"synergy_text": "Syndicate units gain +{v} Toxin",
		"synergy_values": [1, 3],
	},
	&"veil": {
		"name": "Order of the Veil",
		"color": Color("#3f7cff"), "armor": Color("#3a4766"), "accent": Color("#8fd8ff"),
		"synergy_text": "All allies gain +{v}% cooldown speed",
		"synergy_values": [10, 25],
	},
	&"forge": {
		"name": "The Forge",
		"color": Color("#f2b632"), "armor": Color("#a3acb6"), "accent": Color("#ffd84d"),
		"synergy_text": "Team starts with {v} Shield",
		"synergy_values": [20, 60],
	},
}

# --- Units -----------------------------------------------------------------
# ability_trigger: battle_start | on_cast | ally_cast | on_shielded
# ability_effect:  buff_self | buff_adjacent | buff_faction | buff_all | haste_self |
#                  haste_all | status_enemy | charge_self | damage_enemy | heal_team | shield_team
const UNIT_DEFS := [
	# Concord Alliance
	{"id": &"concord_rifleman", "display_name": "Concord Rifleman", "tier": 1, "faction": &"concord", "role": &"trooper",
		"cooldown": 2.0, "damage": 5,
		"ability_trigger": &"battle_start", "ability_effect": &"buff_adjacent", "ability_params": {"stat": "damage", "amount": 1},
		"ability_name": "Covering Fire", "ability_text": "Battle start: adjacent allies gain +{a} Damage."},
	{"id": &"concord_medic", "display_name": "Field Medic", "tier": 1, "faction": &"concord", "role": &"trooper",
		"cooldown": 2.8, "heal": 7,
		"ability_trigger": &"on_cast", "ability_effect": &"buff_self", "ability_params": {"stat": "heal", "amount": 1},
		"ability_name": "Steady Hands", "ability_text": "After each cast, gain +{a} Heal."},
	{"id": &"concord_ace", "display_name": "Starfighter Ace", "tier": 2, "faction": &"concord", "role": &"pilot",
		"cooldown": 2.6, "damage": 7,
		"ability_trigger": &"on_cast", "ability_effect": &"haste_self", "ability_params": {"amount": 0.06},
		"ability_name": "Afterburners", "ability_text": "After each cast, gain +{p}% cooldown speed."},
	{"id": &"concord_commando", "display_name": "Pathfinder Commando", "tier": 3, "faction": &"concord", "role": &"trooper",
		"cooldown": 3.2, "damage": 6, "casts": 2,
		"ability_trigger": &"battle_start", "ability_effect": &"buff_faction", "ability_params": {"faction": "concord", "stat": "damage", "amount": 2},
		"ability_name": "Lead the Charge", "ability_text": "Battle start: Concord allies gain +{a} Damage."},
	{"id": &"concord_marshal", "display_name": "Marshal Orren Vale", "tier": 4, "faction": &"concord", "role": &"officer",
		"cooldown": 3.0, "damage": 10, "shield": 10,
		"ability_trigger": &"battle_start", "ability_effect": &"buff_all", "ability_params": {"stat": "damage", "amount": 4},
		"ability_name": "Rally the Fleet", "ability_text": "Battle start: all allies gain +{a} Damage."},

	# The Dominion
	{"id": &"dominion_legionnaire", "display_name": "Legionnaire", "tier": 1, "faction": &"dominion", "role": &"trooper",
		"cooldown": 1.8, "damage": 4,
		"ability_name": "", "ability_text": ""},
	{"id": &"dominion_flame", "display_name": "Flame Legionnaire", "tier": 2, "faction": &"dominion", "role": &"trooper",
		"cooldown": 2.4, "burn": 3,
		"ability_trigger": &"battle_start", "ability_effect": &"status_enemy", "ability_params": {"status": "burn", "amount": 2},
		"ability_name": "Scorched Earth", "ability_text": "Battle start: the enemy gains {a} Burn."},
	{"id": &"dominion_sniper", "display_name": "Longshot Sniper", "tier": 2, "faction": &"dominion", "role": &"trooper",
		"cooldown": 4.0, "damage": 18,
		"ability_trigger": &"battle_start", "ability_effect": &"charge_self", "ability_params": {"amount": 1.5},
		"ability_name": "Zeroed In", "ability_text": "Starts the battle {a}s charged."},
	{"id": &"dominion_enforcer", "display_name": "Dominion Enforcer", "tier": 3, "faction": &"dominion", "role": &"officer",
		"cooldown": 3.0, "damage": 8,
		"ability_trigger": &"battle_start", "ability_effect": &"buff_faction", "ability_params": {"faction": "dominion", "stat": "damage", "amount": 3},
		"ability_name": "Iron Discipline", "ability_text": "Battle start: Dominion allies gain +{a} Damage."},
	{"id": &"dominion_warlord", "display_name": "Warlord Vexis Kaan", "tier": 4, "faction": &"dominion", "role": &"mystic",
		"cooldown": 3.0, "damage": 20,
		"ability_trigger": &"on_cast", "ability_effect": &"status_enemy", "ability_params": {"status": "burn", "amount": 3},
		"ability_name": "Searing Wrath", "ability_text": "After each cast, the enemy gains {a} Burn."},

	# Gilded Fang Syndicate
	{"id": &"syndicate_runner", "display_name": "Skiff Runner", "tier": 1, "faction": &"syndicate", "role": &"pilot",
		"cooldown": 2.2, "damage": 3, "toxin": 1,
		"ability_name": "", "ability_text": ""},
	{"id": &"syndicate_tracker", "display_name": "Venom Tracker", "tier": 2, "faction": &"syndicate", "role": &"hunter",
		"cooldown": 3.0, "toxin": 3,
		"ability_trigger": &"battle_start", "ability_effect": &"status_enemy", "ability_params": {"status": "toxin", "amount": 1},
		"ability_name": "Tainted Darts", "ability_text": "Battle start: the enemy gains {a} Toxin."},
	{"id": &"syndicate_saboteur", "display_name": "Ion Saboteur", "tier": 2, "faction": &"syndicate", "role": &"hunter",
		"cooldown": 2.4, "damage": 2, "ion": 3,
		"ability_name": "", "ability_text": ""},
	{"id": &"syndicate_collector", "display_name": "Mirelle the Collector", "tier": 3, "faction": &"syndicate", "role": &"hunter",
		"cooldown": 2.8, "damage": 8, "toxin": 2,
		"ability_trigger": &"on_cast", "ability_effect": &"buff_self", "ability_params": {"stat": "toxin", "amount": 1},
		"ability_name": "Bounty Ledger", "ability_text": "After each cast, gain +{a} Toxin."},
	{"id": &"syndicate_kingpin", "display_name": "Kingpin Grasko", "tier": 4, "faction": &"syndicate", "role": &"officer",
		"cooldown": 3.5, "damage": 6,
		"ability_trigger": &"ally_cast", "ability_effect": &"buff_self", "ability_params": {"stat": "damage", "amount": 1},
		"ability_name": "Cut of the Take", "ability_text": "Whenever an ally casts, gain +{a} Damage."},

	# Order of the Veil
	{"id": &"veil_initiate", "display_name": "Veil Initiate", "tier": 1, "faction": &"veil", "role": &"mystic",
		"cooldown": 2.6, "damage": 5,
		"ability_trigger": &"battle_start", "ability_effect": &"haste_self", "ability_params": {"amount": 0.15},
		"ability_name": "Centered", "ability_text": "Battle start: gain +{p}% cooldown speed."},
	{"id": &"veil_guardian", "display_name": "Veil Guardian", "tier": 2, "faction": &"veil", "role": &"mystic",
		"cooldown": 3.4, "shield": 10,
		"ability_trigger": &"on_cast", "ability_effect": &"heal_team", "ability_params": {"amount": 3},
		"ability_name": "Mend", "ability_text": "After each cast, heal your team for {a}."},
	{"id": &"veil_duelist", "display_name": "Veil Duelist", "tier": 3, "faction": &"veil", "role": &"mystic",
		"cooldown": 2.2, "damage": 9,
		"ability_trigger": &"ally_cast", "ability_effect": &"charge_self", "ability_params": {"amount": 0.15},
		"ability_name": "Flowing Form", "ability_text": "Whenever an ally casts, charge {a}s."},
	{"id": &"veil_seer", "display_name": "Grand Seer Ilune", "tier": 4, "faction": &"veil", "role": &"mystic",
		"cooldown": 3.0, "damage": 10, "heal": 15,
		"ability_trigger": &"battle_start", "ability_effect": &"haste_all", "ability_params": {"amount": 0.2},
		"ability_name": "Foresight", "ability_text": "Battle start: all allies gain +{p}% cooldown speed."},

	# The Forge
	{"id": &"forge_scrap", "display_name": "Scrap Construct", "tier": 1, "faction": &"forge", "role": &"construct",
		"cooldown": 3.0, "shield": 7,
		"ability_trigger": &"battle_start", "ability_effect": &"shield_team", "ability_params": {"amount": 5},
		"ability_name": "Plating", "ability_text": "Battle start: give your team {a} Shield."},
	{"id": &"forge_medic", "display_name": "Medic Construct", "tier": 1, "faction": &"forge", "role": &"construct",
		"cooldown": 3.0, "heal": 8,
		"ability_name": "", "ability_text": ""},
	{"id": &"forge_arc", "display_name": "Arc Construct", "tier": 2, "faction": &"forge", "role": &"construct",
		"cooldown": 2.6, "damage": 2, "ion": 3,
		"ability_trigger": &"battle_start", "ability_effect": &"status_enemy", "ability_params": {"status": "ion", "amount": 3},
		"ability_name": "Overcharge", "ability_text": "Battle start: the enemy gains {a} Ion."},
	{"id": &"forge_sentinel", "display_name": "Sentinel Construct", "tier": 3, "faction": &"forge", "role": &"construct",
		"cooldown": 3.6, "shield": 18,
		"ability_trigger": &"on_shielded", "ability_effect": &"damage_enemy", "ability_params": {"amount": 4},
		"ability_name": "Reactive Plating", "ability_text": "Whenever your team gains Shield, deal {a} damage."},
	{"id": &"forge_colossus", "display_name": "Colossus Prime", "tier": 4, "faction": &"forge", "role": &"construct",
		"cooldown": 4.0, "damage": 15, "shield": 30,
		"ability_trigger": &"on_cast", "ability_effect": &"buff_faction", "ability_params": {"faction": "forge", "stat": "shield", "amount": 4},
		"ability_name": "Assembly Line", "ability_text": "After each cast, Forge allies gain +{a} Shield."},
]

# --- Commanders --------------------------------------------------------------
const COMMANDER_DEFS := [
	{"id": &"kessa_vorn", "display_name": "Kessa Vorn", "title": "Fleet Admiral", "faction": &"concord", "role": &"officer",
		"effect": &"front_casts", "params": {"count": 2},
		"ability_name": "Spearhead", "ability_text": "Your two leftmost units gain +1 Cast."},
	{"id": &"dax_rell", "display_name": "Dax Rell", "title": "Strike Commander", "faction": &"concord", "role": &"trooper",
		"effect": &"opening_volley", "params": {"ratio": 0.5},
		"ability_name": "Opening Volley", "ability_text": "All your units start the battle 50% charged."},
	{"id": &"thrax_morrow", "display_name": "Thrax Morrow", "title": "High General", "faction": &"dominion", "role": &"officer",
		"effect": &"faction_damage_mult", "params": {"faction": "dominion", "mult": 0.3},
		"ability_name": "Overwhelming Force", "ability_text": "Dominion units deal +30% Damage."},
	{"id": &"sael_okari", "display_name": "Sael Okari", "title": "Warden of Ash", "faction": &"dominion", "role": &"mystic",
		"effect": &"dot_mult", "params": {"mult": 0.5},
		"ability_name": "Lingering Ruin", "ability_text": "Burn and Toxin you apply are 50% stronger."},
	{"id": &"jex_calder", "display_name": "Jex Calder", "title": "Smuggler Captain", "faction": &"syndicate", "role": &"pilot",
		"effect": &"bonus_gold", "params": {"amount": 2},
		"ability_name": "Hidden Compartments", "ability_text": "Gain +2 Credits every round."},
	{"id": &"rook_danner", "display_name": "Rook Danner", "title": "Bounty Broker", "faction": &"syndicate", "role": &"hunter",
		"effect": &"enemy_ion", "params": {"amount": 4},
		"ability_name": "Disruptor Net", "ability_text": "The enemy starts every battle with 4 Ion."},
	{"id": &"ilyra_sen", "display_name": "Ilyra Sen", "title": "Veil Master", "faction": &"veil", "role": &"mystic",
		"effect": &"team_regen", "params": {"amount": 5, "interval": 2.0},
		"ability_name": "Serenity", "ability_text": "Heal your team for 5 every 2 seconds."},
	{"id": &"b0_lt", "display_name": "B0-LT", "title": "Chief Engineer", "faction": &"forge", "role": &"construct",
		"effect": &"start_shield", "params": {"amount": 60},
		"ability_name": "Overbuilt", "ability_text": "Your team starts every battle with 60 Shield."},
]

var units: Array[UnitData] = []
var units_by_id: Dictionary = {}
var units_by_tier: Dictionary = {1: [], 2: [], 3: [], 4: []}
var commanders: Array[CommanderData] = []


func _ready() -> void:
	for def: Dictionary in UNIT_DEFS:
		var u := UnitData.new()
		for key: String in def:
			if key != "ability_params":
				u.set(key, def[key])
		var params: Dictionary = def.get("ability_params", {})
		u.ability_params = params.duplicate(true)
		units.append(u)
		units_by_id[u.id] = u
		units_by_tier[u.tier].append(u)

	for def: Dictionary in COMMANDER_DEFS:
		var c := CommanderData.new()
		for key: String in def:
			if key != "params":
				c.set(key, def[key])
		var params: Dictionary = def.get("params", {})
		c.params = params.duplicate(true)
		commanders.append(c)


func get_unit(id: StringName) -> UnitData:
	return units_by_id.get(id)


func faction(id: StringName) -> Dictionary:
	return FACTIONS.get(id, FACTIONS[&"concord"])


## Counts distinct units (by id) per faction among the given UnitData entries.
func faction_counts(datas: Array) -> Dictionary:
	var seen := {}
	var counts := {}
	for d in datas:
		if d == null or seen.has(d.id):
			continue
		seen[d.id] = true
		counts[d.faction] = int(counts.get(d.faction, 0)) + 1
	return counts


func synergy_tier(count: int) -> int:
	if count >= SYNERGY_THRESHOLDS[1]:
		return 2
	if count >= SYNERGY_THRESHOLDS[0]:
		return 1
	return 0


func synergy_description(faction_id: StringName, tier: int) -> String:
	var f := faction(faction_id)
	var values: Array = f["synergy_values"]
	var text: String = f["synergy_text"]
	return text.replace("{v}", str(values[clampi(tier, 1, 2) - 1]))
