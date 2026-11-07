class_name PortraitView
extends Control
## Control wrapper around Portrait.draw, with a framed border.

var role: StringName = &"officer"
var faction_id: StringName = &"concord"
var seed_text: String = ""
var frame_color: Color = UITheme.GOLD


func _init(size_px: Vector2 = Vector2(96, 96)) -> void:
	custom_minimum_size = size_px
	mouse_filter = MOUSE_FILTER_IGNORE


func show_commander(c: CommanderData) -> PortraitView:
	role = c.role
	faction_id = c.faction
	seed_text = String(c.id)
	frame_color = UITheme.GOLD
	queue_redraw()
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	Portrait.draw(self, r.grow(-3), role, faction_id, seed_text)
	draw_style_box(UITheme.box(Color(0, 0, 0, 0), frame_color, 8, 3, 0), r)
