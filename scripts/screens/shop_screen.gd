class_name ShopScreen
extends Control
## Between battles: recruit from the supply depot, merge duplicates into higher
## levels, arrange slots (adjacency matters), sell, then launch the battle.
##
## Controls: click a depot card to recruit. Click a squad card to select it, click
## another slot to swap. Right-click a squad card (or press Sell) to sell it.

signal battle_requested

var _shop_cards: Array[UnitCard] = []
var _team_cards: Array[UnitCard] = []
var _selected: int = -1

var _round_label: Label
var _wins_label: Label
var _lives_label: Label
var _gold_label: Label
var _hp_label: Label
var _msg_label: Label
var _reroll_btn: Button
var _sell_btn: Button
var _detail: RichTextLabel
var _synergy_box: VBoxContainer


func _ready() -> void:
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	root.add_child(_build_top_bar())

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 20)
	root.add_child(mid)
	mid.add_child(_build_synergy_panel())

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 12)
	mid.add_child(center)

	center.add_child(UITheme.header("SUPPLY DEPOT"))
	var shop_row := HBoxContainer.new()
	shop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_row.add_theme_constant_override("separation", 16)
	center.add_child(shop_row)
	for i in Run.SHOP_SIZE:
		var card := UnitCard.new()
		card.show_cost = true
		card.empty_text = "RECRUITED"
		card.pressed.connect(_on_shop_pressed.bind(i))
		card.hovered.connect(_on_shop_hover.bind(i))
		shop_row.add_child(card)
		_shop_cards.append(card)

	var depot_actions := HBoxContainer.new()
	depot_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	depot_actions.add_theme_constant_override("separation", 16)
	center.add_child(depot_actions)
	_reroll_btn = UITheme.button("NEW SHIPMENT  (1)", _on_reroll, 18)
	depot_actions.add_child(_reroll_btn)
	_msg_label = UITheme.label("", 18, UITheme.RED)
	_msg_label.custom_minimum_size = Vector2(360, 0)
	depot_actions.add_child(_msg_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(spacer)

	center.add_child(UITheme.header("YOUR SQUAD"))
	var team_row := HBoxContainer.new()
	team_row.alignment = BoxContainer.ALIGNMENT_CENTER
	team_row.add_theme_constant_override("separation", 16)
	center.add_child(team_row)
	for i in Run.TEAM_SIZE:
		var card := UnitCard.new()
		card.pressed.connect(_on_team_pressed.bind(i))
		card.hovered.connect(_on_team_hover.bind(i))
		team_row.add_child(card)
		_team_cards.append(card)

	var squad_actions := HBoxContainer.new()
	squad_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	squad_actions.add_theme_constant_override("separation", 16)
	center.add_child(squad_actions)
	_sell_btn = UITheme.button("SELL", _on_sell_pressed, 18)
	squad_actions.add_child(_sell_btn)
	var battle_btn := UITheme.button("LAUNCH BATTLE", _on_battle_pressed, 24)
	battle_btn.custom_minimum_size = Vector2(300, 56)
	squad_actions.add_child(battle_btn)

	mid.add_child(_build_detail_panel())
	_refresh()


# --- Layout ----------------------------------------------------------------

func _build_top_bar() -> Control:
	var bar := UITheme.panel(UITheme.GOLD.darkened(0.45), UITheme.PANEL_BG, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	bar.add_child(row)

	var portrait := PortraitView.new(Vector2(64, 64)).show_commander(Run.commander)
	row.add_child(portrait)
	var cmd := VBoxContainer.new()
	cmd.add_theme_constant_override("separation", 0)
	cmd.add_child(UITheme.label("%s  -  %s" % [Run.commander.display_name, Run.commander.title], 20, UITheme.TEXT))
	cmd.add_child(UITheme.label("%s: %s" % [Run.commander.ability_name, Run.commander.ability_text], 15, UITheme.GOLD))
	row.add_child(cmd)

	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(grow)

	_round_label = _stat_pill(row, "ROUND", UITheme.TEXT)
	_wins_label = _stat_pill(row, "WINS", UITheme.GREEN)
	_lives_label = _stat_pill(row, "LIVES", UITheme.RED)
	_hp_label = _stat_pill(row, "SQUAD HP", UITheme.CYAN)
	_gold_label = _stat_pill(row, "CREDITS", UITheme.GOLD_BRIGHT)
	return bar


func _stat_pill(parent: Control, caption: String, color: Color) -> Label:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -4)
	var cap := UITheme.label(caption, 13, UITheme.MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value := UITheme.label("", 30, color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_override("font", UITheme.title_font())
	box.add_child(value)
	parent.add_child(box)
	return value


func _build_synergy_panel() -> Control:
	var panel := UITheme.panel()
	panel.custom_minimum_size = Vector2(270, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UITheme.header("FACTION BONUSES", 20))
	box.add_child(UITheme.label("Distinct units of a faction: 2 / 4", 13, UITheme.MUTED))
	_synergy_box = VBoxContainer.new()
	_synergy_box.add_theme_constant_override("separation", 12)
	box.add_child(_synergy_box)
	return panel


func _build_detail_panel() -> Control:
	var panel := UITheme.panel()
	panel.custom_minimum_size = Vector2(330, 0)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.scroll_active = false
	_detail.custom_minimum_size = Vector2(300, 0)
	_detail.add_theme_font_size_override("normal_font_size", 16)
	_detail.add_theme_font_size_override("bold_font_size", 16)
	panel.add_child(_detail)
	_show_help()
	return panel


# --- State -----------------------------------------------------------------

func _refresh() -> void:
	_round_label.text = str(Run.round_num)
	_wins_label.text = "%d/%d" % [Run.wins, Run.WINS_TO_VICTORY]
	_lives_label.text = str(Run.lives)
	_hp_label.text = str(roundi(Run.team_hp()))
	_gold_label.text = str(Run.gold)

	for i in Run.SHOP_SIZE:
		var d: UnitData = Run.shop[i]
		var card := _shop_cards[i]
		card.set_unit(d)
		card.dimmed = d != null and d.cost() > Run.gold
	for i in Run.TEAM_SIZE:
		var owned: UnitInstance = Run.team[i]
		var card := _team_cards[i]
		if owned != null:
			card.set_unit(owned.data, owned.level)
		else:
			card.set_unit(null)
		card.selected = i == _selected
		card.queue_redraw()

	_reroll_btn.disabled = Run.gold < Run.REROLL_COST
	var sel: UnitInstance = Run.team[_selected] if _selected >= 0 else null
	_sell_btn.disabled = sel == null
	_sell_btn.text = "SELL  (+%d)" % sel.sell_value() if sel != null else "SELL"
	_refresh_synergies()


func _refresh_synergies() -> void:
	for child in _synergy_box.get_children():
		child.queue_free()
	var counts := GameDB.faction_counts(Run.team_datas())
	for fac_id: StringName in GameDB.FACTIONS:
		var fac := GameDB.faction(fac_id)
		var count := int(counts.get(fac_id, 0))
		var tier := GameDB.synergy_tier(count)
		var fac_col: Color = fac["color"]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		var head := UITheme.label("%s   %d" % [fac["name"], count], 17, fac_col if count > 0 else UITheme.MUTED)
		row.add_child(head)
		var shown_tier := maxi(1, tier)
		var text := GameDB.synergy_description(fac_id, shown_tier if tier > 0 else 1)
		if tier < 2:
			text += "  (next at %d)" % GameDB.SYNERGY_THRESHOLDS[tier]
		var body := UITheme.label(text, 13, UITheme.GOLD if tier > 0 else Color(UITheme.MUTED, 0.7))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(240, 0)
		row.add_child(body)
		_synergy_box.add_child(row)


func _flash_message(text: String, good: bool = false) -> void:
	_msg_label.text = text
	_msg_label.add_theme_color_override("font_color", UITheme.GREEN if good else UITheme.RED)
	_msg_label.modulate.a = 1.0
	var tw := _msg_label.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(_msg_label, "modulate:a", 0.0, 0.5)


# --- Input -----------------------------------------------------------------

func _on_shop_pressed(_card: UnitCard, button: int, index: int) -> void:
	if button != MOUSE_BUTTON_LEFT:
		return
	var res := Run.buy(index)
	if not res.get("ok", false):
		Sfx.play("error")
		_flash_message(res.get("reason", ""))
		return
	var slot: int = res["slot"]
	if res.get("merged", false):
		Sfx.play("levelup")
		var owned: UnitInstance = Run.team[slot]
		_flash_message("%s promoted to level %d!" % [owned.data.display_name, owned.level], true)
	else:
		Sfx.play("coin")
	_refresh()
	_team_cards[slot].pulse()


func _on_team_pressed(_card: UnitCard, button: int, index: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		if Run.team[index] != null:
			_sell(index)
		return
	if _selected == -1:
		if Run.team[index] != null:
			_selected = index
			Sfx.play("click")
	elif _selected == index:
		_selected = -1
	else:
		Run.swap(_selected, index)
		Sfx.play("whoosh", -6.0)
		_team_cards[index].pulse()
		_selected = -1
	_refresh()


func _on_sell_pressed() -> void:
	if _selected >= 0:
		_sell(_selected)


func _sell(index: int) -> void:
	var owned: UnitInstance = Run.team[index]
	var value := Run.sell(index)
	Sfx.play("coin", 0.0, 0.0)
	_flash_message("Sold %s for %d credits" % [owned.data.display_name, value], true)
	_selected = -1
	_refresh()


func _on_reroll() -> void:
	if Run.reroll():
		Sfx.play("whoosh", -4.0)
		_refresh()
	else:
		Sfx.play("error")


func _on_battle_pressed() -> void:
	if Run.team.all(func(u): return u == null):
		Sfx.play("error")
		_flash_message("Recruit at least one unit first")
		return
	Sfx.play("whoosh")
	battle_requested.emit()


func _on_shop_hover(_card: UnitCard, index: int) -> void:
	var d: UnitData = Run.shop[index]
	if d != null:
		_show_detail(d, 1, true)


func _on_team_hover(_card: UnitCard, index: int) -> void:
	var owned: UnitInstance = Run.team[index]
	if owned != null:
		_show_detail(owned.data, owned.level, false)


# --- Detail panel ----------------------------------------------------------

func _show_detail(d: UnitData, level: int, in_shop: bool) -> void:
	var tier_col: Color = GameDB.TIER_COLORS[d.tier]
	var fac := GameDB.faction(d.faction)
	var fac_col: Color = fac["color"]
	var s := "[font_size=24][b]%s[/b][/font_size]\n" % d.display_name
	s += "[color=#%s]%s[/color]  ·  [color=#%s]%s[/color]\n" % [UITheme.html(tier_col), GameDB.TIER_NAMES[d.tier], UITheme.html(fac_col), fac["name"]]
	s += "[color=#%s]%s · Level %d[/color]\n\n" % [UITheme.html(UITheme.MUTED), String(d.role).capitalize(), level]
	for key in UnitInstance.OUTPUT_STATS:
		var v := UnitInstance.scaled(d, key, level)
		if v > 0.0:
			var col: Color = GameDB.STAT_COLORS[key]
			s += "[color=#%s]%s[/color]   %s\n" % [UITheme.html(col), GameDB.STAT_NAMES[key], UnitData.format_number(v)]
	s += "Cooldown   %.1fs\n" % d.cooldown
	if d.casts > 1:
		s += "Casts   x%d\n" % d.casts
	if d.ability_name != "":
		s += "\n[color=#%s][b]%s[/b][/color]\n%s\n" % [UITheme.html(UITheme.GOLD), d.ability_name, d.describe_ability(level)]
	else:
		s += "\n[color=#%s]No ability - raw stats.[/color]\n" % UITheme.html(UITheme.MUTED)
	s += "\n[color=#%s]%s[/color]" % [UITheme.html(UITheme.MUTED),
		("Costs %d credits. Buying a copy you own levels it up." % d.cost()) if in_shop
		else ("Sells for %d credits. Right-click to sell." % UnitInstance.new(d, level).sell_value())]
	_detail.text = s


func _show_help() -> void:
	var gold := UITheme.html(UITheme.GOLD)
	var muted := UITheme.html(UITheme.MUTED)
	var s := "[font_size=22][b]FIELD MANUAL[/b][/font_size]\n\n"
	s += "Both squads share one [b]HP pool[/b]. Units cast whenever their cooldown fills.\n\n"
	s += "[color=#%s]Shield[/color] absorbs damage first.\n" % UITheme.html(GameDB.STAT_COLORS["shield"])
	s += "[color=#%s]Burn[/color] hits every 0.5s, then fades by 1.\n" % UITheme.html(GameDB.STAT_COLORS["burn"])
	s += "[color=#%s]Toxin[/color] hits every 1s and never fades.\n" % UITheme.html(GameDB.STAT_COLORS["toxin"])
	s += "[color=#%s]Ion[/color] adds bonus damage to every hit, then drops by 1.\n\n" % UITheme.html(GameDB.STAT_COLORS["ion"])
	s += "[color=#%s]Sudden Death[/color] begins at 30s.\n\n" % UITheme.html(UITheme.RED)
	s += "[color=#%s]Buy duplicates to level units up (max 3). Slot order matters for adjacency and your commander.[/color]\n\n" % gold
	s += "[color=#%s]Hover a card for details.[/color]" % muted
	_detail.text = s
