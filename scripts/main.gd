extends Control
## Root scene: owns the animated background and swaps between screens.
## Flow: Title -> Commander select -> (Shop <-> Battle) x N -> Summary.

const STARFIELD := preload("res://shaders/starfield.gdshader")

var _screen: Control
var _background: ColorRect


func _ready() -> void:
	theme = UITheme.build()
	_background = ColorRect.new()
	_background.mouse_filter = MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = STARFIELD
	_background.material = mat
	_background.add_to_group("background")
	add_child(_background)
	_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	Sfx.play_music()
	show_title()


func _set_screen(screen: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
	screen.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.25)


func show_title() -> void:
	var s := TitleScreen.new()
	s.start_pressed.connect(show_commanders)
	_set_screen(s)


func show_commanders() -> void:
	var s := CommanderScreen.new()
	s.chosen.connect(_on_commander_chosen)
	_set_screen(s)


func _on_commander_chosen(c: CommanderData) -> void:
	Run.start_run(c)
	show_shop()


func show_shop() -> void:
	var s := ShopScreen.new()
	s.battle_requested.connect(show_battle)
	_set_screen(s)


func show_battle() -> void:
	var s := BattleScreen.new()
	s.finished.connect(_on_battle_finished)
	_set_screen(s)


func _on_battle_finished(won: bool) -> void:
	Run.record_result(won)
	if Run.is_over():
		show_summary()
	else:
		Run.begin_round()
		show_shop()


func show_summary() -> void:
	var s := SummaryScreen.new()
	s.restart.connect(show_title)
	_set_screen(s)
