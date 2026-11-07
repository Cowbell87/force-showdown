class_name BattleScreen
extends Control
## Presents a BattleSim: cards charge and fire energy bolts at the opposing HP
## pool, with floating numbers, impact rings, screen shake and synthesized audio.
## The simulation itself is UI-free; this screen only listens to its signals.

signal finished(won: bool)

const SPEEDS := [1.0, 2.0, 4.0]
const MAX_STEPS_PER_FRAME := 24

var sim: BattleSim
var _opponent: Dictionary
var _stage: Control
var _fx: FxLayer
var _cards: Dictionary = {}
var _bars: Array = [null, null]
var _rows: Array = [null, null]
var _timer_label: Label
var _banner: Label
var _speed_btn: Button
var _speed_index: int = 0
var _running: bool = false
var _skipping: bool = false
var _ended: bool = false
var _accumulator: float = 0.0
var _background_material: ShaderMaterial


func _ready() -> void:
	_opponent = BotGenerator.generate(Run.round_num, Run.rng.randi())
	sim = BattleSim.new()
	sim.setup([
		{"units": Run.team, "commander": Run.commander, "hp": Run.team_hp(), "name": "Your Squad"},
		{"units": _opponent["units"], "commander": _opponent["commander"], "hp": Run.team_hp(), "name": _opponent["name"]},
	])
	_build_ui()
	sim.unit_cast.connect(_on_unit_cast)
	sim.ability_triggered.connect(_on_ability)
	sim.damage_taken.connect(_on_damage)
	sim.healed.connect(_on_healed)
	sim.sudden_death_started.connect(_on_sudden_death)
	sim.battle_ended.connect(_on_battle_ended)

	var bg := get_tree().get_first_node_in_group("background")
	if bg is ColorRect:
		_background_material = (bg as ColorRect).material as ShaderMaterial

	await get_tree().create_timer(0.35).timeout
	_show_banner("ROUND %d  -  ENGAGE" % Run.round_num, UITheme.GOLD_BRIGHT)
	Sfx.play("whoosh")
	await get_tree().create_timer(1.0).timeout
	sim.start()
	_running = true


func _exit_tree() -> void:
	if _background_material != null:
		_background_material.set_shader_parameter("danger", 0.0)


# --- Layout ----------------------------------------------------------------

func _build_ui() -> void:
	_stage = Control.new()
	add_child(_stage)
	_stage.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	_stage.add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var enemy_bar := TeamBar.new()
	enemy_bar.setup(sim, 1, true)
	root.add_child(enemy_bar)
	_bars[1] = enemy_bar
	root.add_child(_unit_row(1))

	var mid := HBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 20)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	_timer_label = UITheme.header("30", 40)
	_timer_label.custom_minimum_size = Vector2(260, 0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid.add_child(_timer_label)
	_speed_btn = UITheme.button("SPEED x1", _on_speed, 16)
	_speed_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(_speed_btn)
	var skip := UITheme.button("SKIP", _on_skip, 16)
	skip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_child(skip)

	root.add_child(_unit_row(0))
	var player_bar := TeamBar.new()
	player_bar.setup(sim, 0, false)
	root.add_child(player_bar)
	_bars[0] = player_bar

	_fx = FxLayer.new()
	_stage.add_child(_fx)

	_banner = UITheme.header("", 72)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.mouse_filter = MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)
	_banner.set_anchors_and_offsets_preset(PRESET_FULL_RECT)


func _unit_row(team_index: int) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	for slot in Run.TEAM_SIZE:
		var card := UnitCard.new()
		card.mouse_filter = MOUSE_FILTER_IGNORE
		var u := sim.unit_at(team_index, slot)
		if u != null:
			card.set_unit(u.data, u.inst.level)
			card.battle_unit = u
			_cards[u] = card
		else:
			card.empty_text = ""
			card.modulate.a = 0.35
		row.add_child(card)
	_rows[team_index] = row
	return row


# --- Loop ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _running or _ended:
		return
	_accumulator += delta * SPEEDS[_speed_index]
	var steps := 0
	while _accumulator >= BattleSim.TICK and steps < MAX_STEPS_PER_FRAME and not sim.over:
		sim.step(BattleSim.TICK)
		_accumulator -= BattleSim.TICK
		steps += 1
	if sim.sudden_death:
		_timer_label.text = "SUDDEN DEATH"
		_timer_label.add_theme_color_override("font_color", UITheme.RED)
	else:
		_timer_label.text = str(ceili(BattleSim.SUDDEN_DEATH_TIME - sim.time))


func _on_speed() -> void:
	_speed_index = (_speed_index + 1) % SPEEDS.size()
	_speed_btn.text = "SPEED x%d" % int(SPEEDS[_speed_index])


func _on_skip() -> void:
	if _ended or not _running:
		return
	_skipping = true
	sim.simulate_to_end()
	_skipping = false


# --- Sim events ------------------------------------------------------------

func _on_unit_cast(u: BattleUnit, effects: Array) -> void:
	if _skipping:
		return
	var card: UnitCard = _cards.get(u)
	if card == null:
		return
	card.pulse()
	var from := _to_fx(card.get_global_rect().get_center())
	var own_bar: TeamBar = _bars[u.team]
	var enemy_bar: TeamBar = _bars[1 - u.team]
	var sound := ""
	var spread := 0.0
	for e: Dictionary in effects:
		var kind: String = e["type"]
		var friendly := kind == "heal" or kind == "shield"
		var target := _to_fx((own_bar if friendly else enemy_bar).bar_center_global())
		target += Vector2(randf_range(-160.0, 160.0) + spread, randf_range(-10.0, 10.0))
		spread += 30.0
		var width := 1.4 if u.data.tier >= 3 else 1.0
		_fx.add_bolt(from, target, GameDB.STAT_COLORS[kind], 0.24 if not friendly else 0.32, width)
		if sound == "":
			sound = _sound_for(u, kind)
	if sound != "":
		Sfx.play(sound, -5.0)


func _sound_for(u: BattleUnit, kind: String) -> String:
	match kind:
		"damage":
			if u.data.role == &"mystic":
				return "blade"
			if u.data.tier == 4 or u.get_stat("damage") >= 18.0:
				return "heavy"
			return "laser"
		"heal", "shield", "burn", "toxin", "ion":
			return kind
	return "laser"


func _on_ability(u: BattleUnit) -> void:
	if _skipping:
		return
	var card: UnitCard = _cards.get(u)
	if card == null or u.data.ability_name == "":
		return
	var pos := _to_fx(card.get_global_rect().get_center()) + Vector2(-80, -130 if u.team == 0 else 110)
	_popup(pos, u.data.ability_name.to_upper(), UITheme.GOLD_BRIGHT, 18, 0.0, 160.0)


func _on_damage(team_index: int, amount: float, kind: String) -> void:
	if _skipping:
		return
	var bar: TeamBar = _bars[team_index]
	var color: Color = GameDB.STAT_COLORS.get(kind, Color.WHITE)
	var delay := 0.2 if kind == "hit" or kind == "ion" else 0.0
	var size_px := clampi(20 + int(amount / 3.0), 20, 48)
	_popup(_popup_anchor(team_index), "-" + UnitData.format_number(roundf(amount)), color, size_px, delay, 120.0, _popup_drift(team_index))
	if kind == "hit":
		get_tree().create_timer(delay).timeout.connect(bar.flash)
		if amount >= 25.0:
			_shake(minf(14.0, amount / 4.0))
			Sfx.play("hit", -6.0)
	elif kind == "sudden":
		_shake(4.0)


func _on_healed(team_index: int, amount: float) -> void:
	if _skipping or amount < 1.0:
		return
	_popup(_popup_anchor(team_index), "+" + UnitData.format_number(roundf(amount)), UITheme.GREEN, 22, 0.25, 120.0, _popup_drift(team_index))


func _on_sudden_death() -> void:
	Sfx.play("alarm", -4.0)
	if not _skipping:
		_show_banner("SUDDEN DEATH", UITheme.RED)
	if _background_material != null:
		create_tween().tween_method(func(v: float): _background_material.set_shader_parameter("danger", v), 0.0, 0.8, 1.0)


func _on_battle_ended(winner: int) -> void:
	_ended = true
	_running = false
	var won := winner == 0
	var loser_bar: TeamBar = _bars[1 - winner]
	var center := _to_fx(loser_bar.bar_center_global())
	for i in 6:
		_fx.add_ring(center + Vector2(randf_range(-220, 220), randf_range(-20, 20)), Color("#ffb347"), randf_range(40, 90), 0.6 + i * 0.1)
	Sfx.play("explosion")
	_shake(16.0)
	await get_tree().create_timer(1.1).timeout
	Sfx.play("victory" if won else "defeat")
	_show_result(won)


# --- Result ----------------------------------------------------------------

func _show_result(won: bool) -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var panel := UITheme.panel(UITheme.GOLD if won else UITheme.RED, Color(0.03, 0.05, 0.1, 0.96), 32)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var title := UITheme.header("VICTORY" if won else "DEFEAT", 72)
	title.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if won else UITheme.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var vs := UITheme.label("vs. %s" % _opponent["name"], 20, UITheme.MUTED)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(vs)

	var lines: Array[String] = []
	lines.append("Battle time: %.1fs" % sim.time)
	var mvp: BattleUnit = null
	for u in sim.teams[0].units:
		if mvp == null or u.damage_done > mvp.damage_done:
			mvp = u
	if mvp != null and mvp.damage_done > 0.0:
		lines.append("MVP: %s  -  %d damage" % [mvp.data.display_name, roundi(mvp.damage_done)])
	if won:
		lines.append("Wins: %d / %d" % [Run.wins + 1, Run.WINS_TO_VICTORY])
	else:
		lines.append("Lives lost: %d  (%d remaining)" % [Run.loss_for_round(Run.round_num), maxi(0, Run.lives - Run.loss_for_round(Run.round_num))])
	for line in lines:
		var l := UITheme.label(line, 20, UITheme.TEXT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)

	var cont := UITheme.button("CONTINUE", func(): finished.emit(won), 22)
	cont.custom_minimum_size = Vector2(260, 54)
	cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(cont)

	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)


# --- Helpers ---------------------------------------------------------------

func _to_fx(global_pos: Vector2) -> Vector2:
	return _fx.get_global_transform().affine_inverse() * global_pos


## Numbers spawn in the open strip between the two card rows: enemy damage just
## under the enemy row, player damage just over the player row, drifting inward.
func _popup_anchor(team_index: int) -> Vector2:
	var bar: TeamBar = _bars[team_index]
	var row: Control = _rows[team_index]
	var x := _to_fx(bar.bar_center_global()).x
	var row_rect := row.get_global_rect()
	var y := row_rect.end.y + 22.0 if team_index == 1 else row_rect.position.y - 52.0
	return Vector2(x, _to_fx(Vector2(0, y)).y)


func _popup_drift(team_index: int) -> float:
	return 34.0 if team_index == 1 else -34.0


func _popup(pos: Vector2, text: String, color: Color, size_px: int, delay: float, width: float = 120.0, drift: float = -50.0) -> void:
	var l := UITheme.label(text, size_px, color)
	l.add_theme_font_override("font", UITheme.title_font())
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(width, 0)
	l.position = pos + Vector2(-width / 2.0 + randf_range(-260.0, 260.0), randf_range(-12.0, 12.0))
	l.modulate.a = 0.0
	l.mouse_filter = MOUSE_FILTER_IGNORE
	_fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(l, "modulate:a", 1.0, 0.05)
	tw.parallel().tween_property(l, "position:y", l.position.y + drift, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.scale = Vector2(1.3, 1.3)
	_banner.pivot_offset = _banner.size / 2.0
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.35)


func _shake(strength: float) -> void:
	var tw := _stage.create_tween()
	for i in 6:
		var falloff := 1.0 - i / 6.0
		tw.tween_property(_stage, "position", Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff, 0.03)
	tw.tween_property(_stage, "position", Vector2.ZERO, 0.04)
