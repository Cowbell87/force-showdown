class_name CommanderScreen
extends Control
## Pick one of three random commanders. Each grants a passive for the whole run.

signal chosen(commander: CommanderData)

const CHOICES := 3


func _ready() -> void:
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 28)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(root)

	var title := UITheme.header("CHOOSE YOUR COMMANDER", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var sub := UITheme.label("Your commander's ability applies to every battle in this campaign.", 18, UITheme.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	root.add_child(row)

	var pool := GameDB.commanders.duplicate()
	pool.shuffle()
	for i in mini(CHOICES, pool.size()):
		row.add_child(_commander_card(pool[i]))


func _commander_card(c: CommanderData) -> Control:
	var fac := GameDB.faction(c.faction)
	var fac_col: Color = fac["color"]
	var normal_box := UITheme.box(UITheme.PANEL_BG, fac_col.darkened(0.2), 14, 3, 20)
	var hover_box := UITheme.box(Color(0.06, 0.1, 0.18, 0.95), UITheme.GOLD_BRIGHT, 14, 3, 20)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 560)
	panel.add_theme_stylebox_override("panel", normal_box)
	panel.mouse_entered.connect(func():
		panel.add_theme_stylebox_override("panel", hover_box)
		Sfx.play("hover", -10.0)
	)
	panel.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", normal_box))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var portrait := PortraitView.new(Vector2(340, 280)).show_commander(c)
	box.add_child(portrait)

	var name_label := UITheme.header(c.display_name.to_upper(), 30)
	name_label.add_theme_color_override("font_color", UITheme.TEXT)
	box.add_child(name_label)
	box.add_child(UITheme.label("%s  ·  %s" % [c.title, fac["name"]], 16, fac_col.lightened(0.2)))
	box.add_child(UITheme.label(c.ability_name, 22, UITheme.GOLD))
	var desc := UITheme.label(c.ability_text, 18, UITheme.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(340, 0)
	box.add_child(desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var pick := UITheme.button("TAKE COMMAND", func(): _pick(c), 20)
	box.add_child(pick)
	return panel


func _pick(c: CommanderData) -> void:
	Sfx.play("levelup")
	chosen.emit(c)
