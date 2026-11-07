class_name TeamBar
extends Control
## Shared team HP pool display: commander portrait, HP with shield overlay and a
## trailing "recent damage" ghost, plus Burn/Toxin/Ion stack chips.

var sim: BattleSim
var team_index: int = 0
var is_enemy: bool = false

var _shown_hp: float = 0.0
var _ghost_hp: float = 0.0
var _hit_flash: float = 0.0
var _bar_rect := Rect2()


func _init() -> void:
	custom_minimum_size = Vector2(0, 84)
	mouse_filter = MOUSE_FILTER_IGNORE


func setup(battle: BattleSim, index: int, enemy: bool) -> void:
	sim = battle
	team_index = index
	is_enemy = enemy
	_shown_hp = sim.teams[index].hp
	_ghost_hp = _shown_hp


func flash() -> void:
	_hit_flash = 1.0


func bar_center_global() -> Vector2:
	var local := _bar_rect.get_center() if _bar_rect.size.x > 0.0 else size / 2.0
	return get_global_transform() * local


func _process(delta: float) -> void:
	if sim == null:
		return
	var t: BattleSim.Team = sim.teams[team_index]
	_shown_hp = lerpf(_shown_hp, t.hp, minf(1.0, delta * 14.0))
	if _ghost_hp > _shown_hp:
		_ghost_hp = move_toward(_ghost_hp, _shown_hp, delta * t.max_hp * 0.4)
	else:
		_ghost_hp = _shown_hp
	_hit_flash = maxf(0.0, _hit_flash - delta * 4.0)
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	var t: BattleSim.Team = sim.teams[team_index]
	var font := UITheme.font()
	var r := Rect2(Vector2.ZERO, size)
	var accent := UITheme.RED if is_enemy else UITheme.CYAN
	draw_style_box(UITheme.box(Color(0.03, 0.05, 0.1, 0.85), accent.darkened(0.45), 12, 2, 0), r)

	# Commander
	var pr := Rect2(10, 8, 68, 68)
	if t.commander != null:
		Portrait.draw(self, pr, t.commander.role, t.commander.faction, String(t.commander.id))
	draw_style_box(UITheme.box(Color(0, 0, 0, 0), UITheme.GOLD, 8, 2, 0), pr)
	draw_string(font, Vector2(90, 32), t.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 280, 20, accent.lightened(0.3))
	if t.commander != null:
		draw_string(font, Vector2(90, 54), "%s  -  %s" % [t.commander.display_name, t.commander.ability_name], HORIZONTAL_ALIGNMENT_LEFT, 280, 14, UITheme.GOLD)
		draw_string(font, Vector2(90, 72), t.commander.ability_text, HORIZONTAL_ALIGNMENT_LEFT, 280, 12, UITheme.MUTED)

	# HP bar
	var chips_w := 230.0
	_bar_rect = Rect2(390, 18, r.size.x - 390 - chips_w - 20, 48)
	var br := _bar_rect
	draw_style_box(UITheme.box(Color(0.01, 0.02, 0.04), Color(0.25, 0.32, 0.45), 6, 2, 0), br.grow(3))
	var ratio := clampf(_shown_hp / t.max_hp, 0.0, 1.0)
	var ghost := clampf(_ghost_hp / t.max_hp, 0.0, 1.0)
	draw_rect(Rect2(br.position, Vector2(br.size.x * ghost, br.size.y)), Color(1, 0.95, 0.85, 0.75))
	var hp_top := Color("#ff6b5a") if is_enemy else Color("#4fe08a")
	var hp_bottom := hp_top.darkened(0.45)
	if ratio > 0.0:
		var w := br.size.x * ratio
		draw_polygon(
			PackedVector2Array([br.position, br.position + Vector2(w, 0), br.position + Vector2(w, br.size.y), br.position + Vector2(0, br.size.y)]),
			PackedColorArray([hp_top, hp_top, hp_bottom, hp_bottom]))
	if _hit_flash > 0.0:
		draw_rect(br, Color(1, 1, 1, _hit_flash * 0.25))
	if t.shield > 0.0:
		var sw := br.size.x * clampf(t.shield / t.max_hp, 0.0, 1.0)
		var sr := Rect2(br.position, Vector2(sw, br.size.y * 0.42))
		draw_rect(sr, Color(0.35, 0.72, 1.0, 0.85))
		draw_rect(sr, Color(0.8, 0.93, 1.0), false, 1.5)
	for i in range(1, 10):
		var x := br.position.x + br.size.x * i / 10.0
		draw_line(Vector2(x, br.position.y + br.size.y * 0.6), Vector2(x, br.end.y), Color(0, 0, 0, 0.35), 1.0)
	var hp_text := "%d / %d" % [maxi(0, ceili(t.hp)), roundi(t.max_hp)]
	if t.shield > 0.0:
		hp_text += "   +%d SHIELD" % roundi(t.shield)
	draw_string_outline(font, Vector2(br.position.x, br.position.y + 32), hp_text, HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 20, 5, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(br.position.x, br.position.y + 32), hp_text, HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 20, UITheme.TEXT)

	# Status chips
	var cx := br.end.x + 30.0
	for s in BattleSim.STATUSES:
		var stacks: int = t.status[s]
		var col: Color = GameDB.STAT_COLORS[s]
		var chip := Rect2(cx - 16, 22, 66, 40)
		var active := stacks > 0
		draw_style_box(UITheme.box(Color(col, 0.18 if active else 0.04), Color(col, 0.9 if active else 0.2), 8, 2, 0), chip)
		Icons.draw_stat(self, s, Vector2(cx + 2, 42), 9.0, col if active else Color(col, 0.3))
		draw_string(font, Vector2(cx + 16, 50), str(stacks), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UITheme.TEXT if active else UITheme.MUTED)
		cx += 74.0
