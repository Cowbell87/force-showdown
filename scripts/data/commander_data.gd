class_name CommanderData
extends Resource
## A hero who leads a squad. Each commander has one passive effect that is
## applied by BattleSim._apply_commander (battle effects) or Run (shop effects).

@export var id: StringName
@export var display_name: String = ""
@export var title: String = ""
@export var faction: StringName = &"concord"
@export var role: StringName = &"officer"
## Effect key: front_casts, faction_damage_mult, bonus_gold, team_regen,
## start_shield, enemy_ion, dot_mult, opening_volley.
@export var effect: StringName = &""
@export var params: Dictionary = {}
@export var ability_name: String = ""
@export_multiline var ability_text: String = ""
