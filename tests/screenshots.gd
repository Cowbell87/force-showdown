extends Node
## Renders each screen and saves PNGs to user://screenshots (needs a window, not --headless).
## Run: godot --path . res://tests/screenshots.tscn

var _out_dir := "user://screenshots"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await _wait(1.2)
	await _shot("1_title")
	main.show_commanders()
	await _wait(0.8)
	await _shot("2_commanders")
	main._on_commander_chosen(GameDB.commanders[4])
	# give the squad a mid-campaign look
	Run.round_num = 6
	Run.gold = 40
	Run.roll_shop()
	for id: StringName in [&"forge_scrap", &"concord_rifleman", &"veil_duelist", &"forge_sentinel", &"syndicate_kingpin"]:
		Run.team[Run.team.find(null)] = UnitInstance.new(GameDB.get_unit(id), 2)
	Run.team[2].level = 3
	Run.gold = 9
	main.show_shop()
	await _wait(0.8)
	await _shot("3_shop")
	main.show_battle()
	await _wait(5.5)
	await _shot("4_battle")
	await _wait(3.0)
	await _shot("5_battle_later")
	print("Screenshots saved to: ", ProjectSettings.globalize_path(_out_dir))
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [_out_dir, name])
