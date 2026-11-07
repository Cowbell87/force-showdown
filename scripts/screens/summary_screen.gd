class_name SummaryScreen
extends Control
## End of campaign: result, record and the final squad.

signal restart


func _ready() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var won := Run.is_victory()
	var title := UITheme.header("CAMPAIGN COMPLETE" if won else "CAMPAIGN LOST", 72)
	title.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT if won else UITheme.RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var record := "%d wins  ·  %d rounds  ·  Commander %s" % [Run.wins, Run.round_num, Run.commander.display_name]
	var rec := UITheme.label(record, 22, UITheme.TEXT)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rec)

	var history := HBoxContainer.new()
	history.alignment = BoxContainer.ALIGNMENT_CENTER
	history.add_theme_constant_override("separation", 6)
	for result in Run.history:
		var pip := UITheme.label("W" if result else "L", 22, UITheme.GREEN if result else UITheme.RED)
		history.add_child(pip)
	box.add_child(history)

	box.add_child(UITheme.header("FINAL SQUAD", 22))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for owned in Run.team:
		var card := UnitCard.new()
		card.mouse_filter = MOUSE_FILTER_IGNORE
		if owned != null:
			card.set_unit(owned.data, owned.level)
		row.add_child(card)
	box.add_child(row)

	var again := UITheme.button("NEW CAMPAIGN", func(): restart.emit(), 24)
	again.custom_minimum_size = Vector2(300, 60)
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(again)
	if won:
		Sfx.play("victory")
