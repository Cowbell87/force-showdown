class_name TitleScreen
extends Control

signal start_pressed


func _ready() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var kicker := UITheme.label("A GALACTIC AUTO-BATTLER", 20, UITheme.CYAN)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)

	var title := UITheme.header("FORCE SHOWDOWN", 96)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color(0.45, 0.25, 0.02, 0.85))
	box.add_child(title)

	var blurb := UITheme.label("Recruit heroes from five factions, choose a Commander, and outlast ten rival squads.", 20, UITheme.MUTED)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(blurb)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	box.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	var start := UITheme.button("BEGIN CAMPAIGN", _on_start, 26)
	start.custom_minimum_size = Vector2(320, 64)
	buttons.add_child(start)
	var quit := UITheme.button("QUIT", func(): get_tree().quit(), 22)
	quit.custom_minimum_size = Vector2(160, 64)
	buttons.add_child(quit)

	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "modulate", Color(1.15, 1.08, 0.95), 1.8).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(title, "modulate", Color.WHITE, 1.8).set_trans(Tween.TRANS_SINE)


func _on_start() -> void:
	Sfx.play("whoosh")
	start_pressed.emit()
