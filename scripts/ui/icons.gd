class_name Icons
extends RefCounted
## Vector stat icons drawn with CanvasItem primitives (no texture assets).


static func draw_stat(ci: CanvasItem, key: String, c: Vector2, s: float, color_override: Color = Color(0, 0, 0, 0)) -> void:
	var col: Color = GameDB.STAT_COLORS.get(key, Color.WHITE)
	if color_override.a > 0.0:
		col = color_override
	match key:
		"damage":
			ci.draw_colored_polygon(_pts(c, s, [0, -1, 0.8, 0, 0, 1, -0.8, 0]), col)
			ci.draw_colored_polygon(_pts(c, s * 0.45, [0, -1, 0.8, 0, 0, 1, -0.8, 0]), col.lightened(0.5))
		"heal":
			ci.draw_rect(Rect2(c - Vector2(s * 0.3, s), Vector2(s * 0.6, s * 2.0)), col)
			ci.draw_rect(Rect2(c - Vector2(s, s * 0.3), Vector2(s * 2.0, s * 0.6)), col)
		"shield":
			ci.draw_colored_polygon(_pts(c, s, [-0.85, -0.85, 0.85, -0.85, 0.8, 0.1, 0, 1, -0.8, 0.1]), col)
			ci.draw_colored_polygon(_pts(c + Vector2(0, -s * 0.1), s * 0.5, [-0.85, -0.85, 0.85, -0.85, 0.8, 0.1, 0, 1, -0.8, 0.1]), col.lightened(0.35))
		"burn":
			ci.draw_colored_polygon(_pts(c, s, [0, -1, 0.7, 0.15, 0.5, 0.85, -0.5, 0.85, -0.7, 0.15]), col)
			ci.draw_colored_polygon(_pts(c + Vector2(0, s * 0.3), s * 0.5, [0, -1, 0.7, 0.15, 0.5, 0.85, -0.5, 0.85, -0.7, 0.15]), Color("#ffe066"))
		"toxin":
			ci.draw_circle(c + Vector2(0, s * 0.3), s * 0.65, col)
			ci.draw_colored_polygon(_pts(c, s, [0, -1, 0.55, 0.05, -0.55, 0.05]), col)
			ci.draw_circle(c + Vector2(-s * 0.2, s * 0.15), s * 0.18, col.lightened(0.5))
		"ion":
			ci.draw_colored_polygon(_pts(c, s, [0.25, -1, -0.55, 0.15, -0.05, 0.15, -0.25, 1, 0.55, -0.15, 0.05, -0.15]), col)
		"cooldown":
			ci.draw_arc(c, s * 0.85, 0.0, TAU, 20, col, 2.0, true)
			ci.draw_line(c, c + Vector2(0, -s * 0.55), col, 2.0, true)
			ci.draw_line(c, c + Vector2(s * 0.4, 0), col, 2.0, true)
		"casts":
			ci.draw_polyline(_pts(c + Vector2(-s * 0.35, 0), s * 0.7, [-0.5, -1, 0.5, 0, -0.5, 1]), col, 2.5, true)
			ci.draw_polyline(_pts(c + Vector2(s * 0.35, 0), s * 0.7, [-0.5, -1, 0.5, 0, -0.5, 1]), col, 2.5, true)
		"heart":
			ci.draw_circle(c + Vector2(-s * 0.42, -s * 0.2), s * 0.5, col)
			ci.draw_circle(c + Vector2(s * 0.42, -s * 0.2), s * 0.5, col)
			ci.draw_colored_polygon(_pts(c, s, [-0.9, -0.05, 0.9, -0.05, 0, 1]), col)
		"credit":
			ci.draw_circle(c, s, col)
			ci.draw_arc(c, s * 0.7, 0.0, TAU, 20, col.darkened(0.4), 2.0, true)
			ci.draw_colored_polygon(_pts(c, s * 0.45, [0, -1, 0.6, 0, 0, 1, -0.6, 0]), col.darkened(0.4))
		_:
			ci.draw_circle(c, s * 0.6, col)


static func draw_star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)


static func _pts(c: Vector2, s: float, coords: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		out.append(c + Vector2(float(coords[i]), float(coords[i + 1])) * s)
	return out
