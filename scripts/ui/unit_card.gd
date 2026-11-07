class_name UnitCard
extends Control
## Collectible-style unit card: tier-colored frame, procedural portrait, level
## stars, stat row and (in battle) a charge bar. Used in the shop and in battle.

signal pressed(card: UnitCard, button: int)
signal hovered(card: UnitCard)

const CARD_SIZE := Vector2(150, 214)

var data: UnitData
var level: int = 1
## When set, stats are read live from the battle unit instead of the base data.
var battle_unit: BattleUnit
var show_cost: bool = false
var selected: bool = false
var dimmed: bool = false
var empty_text: String = "EMPTY"

var _hover: bool = false
var _flash: float = 0.0


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	mouse_filter = MOUSE_FILTER_STOP


func set_unit(d: UnitData, lvl: int = 1) -> void:
	data = d
	level = lvl
	queue_redraw()


func pulse() -> void:
	_flash = 1.0
	pivot_offset = size / 2.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.07, 1.07), 0.06)
	tw.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			pressed.emit(self, event.button_index)
			accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_hover = true
			hovered.emit(self)
			queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			_hover = false
			queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		queue_redraw()
	elif battle_unit != null or (data != null and data.tier == 4):
		queue_redraw()


func _stat(key: String) -> float:
	if battle_unit != null:
		return battle_unit.get_stat(key)
	return UnitInstance.scaled(data, key, level)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var font := UITheme.font()
	if data == null:
		var border := UITheme.GOLD if selected else Color(0.3, 0.45, 0.65, 0.55 if _hover else 0.35)
		draw_style_box(UITheme.box(Color(0.04, 0.07, 0.13, 0.45), border, 12, 2, 0), r)
		draw_string(font, Vector2(0, r.size.y / 2.0 + 6), empty_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, Color(0.55, 0.65, 0.8, 0.55))
		return

	var tier_col: Color = GameDB.TIER_COLORS[data.tier]
	var fac: Dictionary = GameDB.faction(data.faction)
	var fac_col: Color = fac["color"]

	# Outer glow: legendary shimmer, selection, cast flash.
	var glow := 0.0
	if data.tier == 4:
		glow = 0.35 + 0.25 * sin(Time.get_ticks_msec() / 300.0)
	if data.tier == 3:
		glow = 0.25
	if selected or _hover:
		glow = maxf(glow, 0.6)
	glow = maxf(glow, _flash)
	if glow > 0.0:
		var gc := UITheme.GOLD_BRIGHT if selected else tier_col
		for i in 3:
			draw_style_box(UITheme.box(Color(0, 0, 0, 0), Color(gc, glow * (0.45 - i * 0.13)), 14 + i * 2, 3, 0), r.grow(2 + i * 3))

	# Body and portrait
	draw_style_box(UITheme.box(Color(0.03, 0.05, 0.09), tier_col, 12, 3, 0), r)
	var pr := Rect2(6, 6, r.size.x - 12, 116)
	Portrait.draw(self, pr, data.role, data.faction, String(data.id))
	draw_rect(pr, Color(tier_col, 0.6), false, 1.5)
	if _flash > 0.0:
		draw_rect(pr, Color(1, 1, 1, _flash * 0.35))

	# Faction stripe
	draw_rect(Rect2(6, pr.end.y, pr.size.x, 3), fac_col)

	# Charge bar (battle)
	if battle_unit != null:
		var ratio := battle_unit.charge_ratio()
		draw_rect(Rect2(6, pr.end.y - 6, pr.size.x, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(6, pr.end.y - 6, pr.size.x * ratio, 6), UITheme.CYAN.lerp(Color.WHITE, ratio * ratio * 0.6))

	# Name
	var fs := 16
	while fs > 10 and font.get_string_size(data.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 12:
		fs -= 1
	draw_string(font, Vector2(0, pr.end.y + 21), data.display_name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, UITheme.TEXT)
	var sub := "%s  ·  %s" % [GameDB.TIER_NAMES[data.tier].to_upper(), String(data.role).to_upper()]
	draw_string(font, Vector2(0, pr.end.y + 36), sub, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, tier_col)

	# Stat row
	var entries: Array = []
	for key in UnitInstance.OUTPUT_STATS:
		var v := _stat(key)
		if v > 0.0:
			entries.append([key, v])
	var y := pr.end.y + 56
	var slot_w := 34.0
	var x := (r.size.x - slot_w * entries.size()) / 2.0
	for e: Array in entries:
		Icons.draw_stat(self, e[0], Vector2(x + 8, y - 4), 6.0)
		draw_string(font, Vector2(x + 16, y + 1), UnitData.format_number(e[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UITheme.TEXT)
		x += slot_w

	# Cooldown / casts row
	var cd_text := "%.1fs" % _stat("cooldown")
	Icons.draw_stat(self, "cooldown", Vector2(16, r.size.y - 13), 6.0)
	draw_string(font, Vector2(26, r.size.y - 8), cd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.MUTED)
	var casts := int(_stat("casts"))
	if casts > 1:
		Icons.draw_stat(self, "casts", Vector2(r.size.x - 44, r.size.y - 13), 6.0)
		draw_string(font, Vector2(r.size.x - 34, r.size.y - 8), "x%d" % casts, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.GOLD)
	if data.ability_name != "":
		draw_circle(Vector2(r.size.x / 2.0, r.size.y - 13), 4.0, UITheme.GOLD)

	# Level stars
	for i in level:
		Icons.draw_star(self, Vector2(r.size.x - 18 - i * 16, 20), 7.0, UITheme.GOLD_BRIGHT)

	# Cost badge
	if show_cost:
		var c := Vector2(22, 22)
		draw_circle(c, 15.0, Color(0, 0, 0, 0.6))
		Icons.draw_stat(self, "credit", c, 13.0, UITheme.GOLD)
		draw_string(font, c + Vector2(-12, 6), str(data.cost()), HORIZONTAL_ALIGNMENT_CENTER, 24, 17, Color(0.08, 0.06, 0.02))

	if dimmed:
		draw_style_box(UITheme.box(Color(0, 0, 0, 0.5), Color(0, 0, 0, 0), 12, 0, 0), r)
