class_name Portrait
extends RefCounted
## Procedural character portraits. Each role has a silhouette drawn from simple
## shapes in a 0..1 coordinate space, tinted by faction colors. Replace this with
## real art later by giving UnitData a Texture2D and drawing that instead.

const SKINS := [
	Color("#f1c9a5"), Color("#d9a27a"), Color("#a86f4c"), Color("#7a4b32"),
	Color("#b9d39a"), Color("#9fb7e0"), Color("#d8a0c8"),
]


static func draw(ci: CanvasItem, r: Rect2, role: StringName, faction_id: StringName, seed_text: String) -> void:
	var f: Dictionary = GameDB.faction(faction_id)
	var fac: Color = f["color"]
	var armor: Color = f["armor"]
	var accent: Color = f["accent"]
	var h := absi(seed_text.hash())

	_background(ci, r, fac, h)
	match role:
		&"trooper":
			_trooper(ci, r, fac, armor, accent)
		&"pilot":
			_pilot(ci, r, fac, armor, accent, h)
		&"construct":
			_construct(ci, r, fac, armor, accent, h)
		&"hunter":
			_hunter(ci, r, fac, armor, accent)
		&"mystic":
			_mystic(ci, r, fac, armor, accent)
		_:
			_officer(ci, r, fac, armor, accent, h)
	# bottom fade so the name plate reads cleanly
	var fade_top := _pt(r, 0, 0.78)
	ci.draw_polygon(
		PackedVector2Array([fade_top, Vector2(r.end.x, fade_top.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55)]))


static func _background(ci: CanvasItem, r: Rect2, fac: Color, h: int) -> void:
	var top := fac.darkened(0.55)
	var bottom := Color(0.02, 0.03, 0.06)
	ci.draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top.darkened(0.3), bottom, bottom]))
	var s := minf(r.size.x, r.size.y)
	for i in 5:
		ci.draw_circle(_pt(r, 0.5, 0.42), s * (0.48 - i * 0.07), Color(fac, 0.05 + i * 0.03))
	for i in 7:
		var x := float((h >> (i * 3)) % 97) / 97.0
		var y := float((h >> (i * 2 + 1)) % 89) / 89.0 * 0.6
		ci.draw_circle(_pt(r, x, y), 1.2 + (i % 2), Color(1, 1, 1, 0.35))


static func _shoulders(ci: CanvasItem, r: Rect2, col: Color, trim: Color) -> void:
	ci.draw_colored_polygon(_poly(r, [0.06, 1.0, 0.16, 0.78, 0.36, 0.69, 0.64, 0.69, 0.84, 0.78, 0.94, 1.0]), col)
	ci.draw_polyline(_poly(r, [0.16, 0.78, 0.36, 0.69, 0.64, 0.69, 0.84, 0.78]), trim, 2.0, true)


static func _trooper(ci: CanvasItem, r: Rect2, fac: Color, armor: Color, accent: Color) -> void:
	var s := minf(r.size.x, r.size.y)
	_shoulders(ci, r, armor.darkened(0.2), fac)
	ci.draw_colored_polygon(_poly(r, [0.42, 0.74, 0.58, 0.74, 0.56, 1.0, 0.44, 1.0]), fac.darkened(0.2))
	ci.draw_circle(_pt(r, 0.5, 0.40), s * 0.21, armor)
	ci.draw_colored_polygon(_poly(r, [0.31, 0.40, 0.69, 0.40, 0.65, 0.60, 0.56, 0.67, 0.44, 0.67, 0.35, 0.60]), armor.darkened(0.08))
	ci.draw_colored_polygon(_poly(r, [0.34, 0.39, 0.66, 0.39, 0.62, 0.48, 0.38, 0.48]), Color(0.04, 0.05, 0.08))
	ci.draw_line(_pt(r, 0.38, 0.47), _pt(r, 0.62, 0.47), Color(accent, 0.8), 2.0, true)
	ci.draw_rect(Rect2(_pt(r, 0.37, 0.29), Vector2(r.size.x * 0.26, r.size.y * 0.03)), fac)
	for i in 3:
		var x := 0.46 + i * 0.04
		ci.draw_line(_pt(r, x, 0.56), _pt(r, x, 0.63), armor.darkened(0.45), 2.0, true)


static func _pilot(ci: CanvasItem, r: Rect2, fac: Color, armor: Color, accent: Color, h: int) -> void:
	var s := minf(r.size.x, r.size.y)
	_shoulders(ci, r, fac.darkened(0.25), armor)
	ci.draw_line(_pt(r, 0.34, 0.72), _pt(r, 0.46, 1.0), armor.darkened(0.2), 4.0, true)
	ci.draw_line(_pt(r, 0.66, 0.72), _pt(r, 0.54, 1.0), armor.darkened(0.2), 4.0, true)
	ci.draw_circle(_pt(r, 0.5, 0.40), s * 0.23, armor)
	ci.draw_colored_polygon(_poly(r, [0.47, 0.17, 0.53, 0.17, 0.54, 0.37, 0.46, 0.37]), fac if h % 2 == 0 else accent)
	ci.draw_colored_polygon(_poly(r, [0.33, 0.37, 0.67, 0.37, 0.64, 0.52, 0.36, 0.52]), accent.darkened(0.35))
	ci.draw_line(_pt(r, 0.37, 0.40), _pt(r, 0.55, 0.40), Color(1, 1, 1, 0.55), 2.0, true)
	ci.draw_colored_polygon(_poly(r, [0.38, 0.52, 0.62, 0.52, 0.58, 0.64, 0.42, 0.64]), armor.darkened(0.3))
	ci.draw_line(_pt(r, 0.44, 0.62), _pt(r, 0.40, 0.76), Color(0.1, 0.1, 0.12), 3.0, true)
	ci.draw_line(_pt(r, 0.56, 0.62), _pt(r, 0.60, 0.76), Color(0.1, 0.1, 0.12), 3.0, true)


static func _construct(ci: CanvasItem, r: Rect2, fac: Color, armor: Color, accent: Color, h: int) -> void:
	var s := minf(r.size.x, r.size.y)
	_shoulders(ci, r, armor.darkened(0.3), fac)
	ci.draw_circle(_pt(r, 0.22, 0.86), s * 0.03, fac)
	ci.draw_circle(_pt(r, 0.78, 0.86), s * 0.03, fac)
	ci.draw_rect(Rect2(_pt(r, 0.45, 0.55), Vector2(r.size.x * 0.10, r.size.y * 0.15)), Color(0.15, 0.16, 0.18))
	ci.draw_line(_pt(r, 0.43, 0.56), _pt(r, 0.40, 0.70), armor.darkened(0.4), 3.0, true)
	ci.draw_line(_pt(r, 0.57, 0.56), _pt(r, 0.60, 0.70), armor.darkened(0.4), 3.0, true)
	ci.draw_colored_polygon(_poly(r, [0.36, 0.22, 0.64, 0.22, 0.69, 0.29, 0.69, 0.52, 0.62, 0.58, 0.38, 0.58, 0.31, 0.52, 0.31, 0.29]), armor)
	ci.draw_line(_pt(r, 0.33, 0.50), _pt(r, 0.67, 0.50), armor.darkened(0.3), 2.0, true)
	ci.draw_line(_pt(r, 0.62, 0.22), _pt(r, 0.67, 0.10), armor.darkened(0.2), 2.0, true)
	ci.draw_circle(_pt(r, 0.67, 0.10), s * 0.025, accent)
	var eye_x := 0.5 if h % 3 != 0 else 0.44
	ci.draw_circle(_pt(r, eye_x, 0.38), s * 0.085, Color(0.05, 0.05, 0.07))
	ci.draw_circle(_pt(r, eye_x, 0.38), s * 0.065, Color(accent, 0.45))
	ci.draw_circle(_pt(r, eye_x, 0.38), s * 0.04, accent)
	ci.draw_circle(_pt(r, eye_x, 0.38), s * 0.015, Color(1, 1, 1, 0.95))
	if h % 3 == 0:
		ci.draw_circle(_pt(r, 0.59, 0.36), s * 0.03, Color(accent, 0.8))


static func _hunter(ci: CanvasItem, r: Rect2, fac: Color, armor: Color, accent: Color) -> void:
	var s := minf(r.size.x, r.size.y)
	ci.draw_colored_polygon(_poly(r, [0.10, 1.0, 0.20, 0.70, 0.5, 0.64, 0.80, 0.70, 0.90, 1.0]), fac.darkened(0.5))
	ci.draw_colored_polygon(_poly(r, [0.18, 1.0, 0.24, 0.80, 0.40, 0.73, 0.60, 0.73, 0.76, 0.80, 0.82, 1.0]), armor.darkened(0.15))
	ci.draw_colored_polygon(_poly(r, [0.35, 0.22, 0.65, 0.22, 0.69, 0.40, 0.66, 0.58, 0.58, 0.66, 0.42, 0.66, 0.34, 0.58, 0.31, 0.40]), armor)
	ci.draw_colored_polygon(_poly(r, [0.34, 0.35, 0.5, 0.43, 0.66, 0.35, 0.66, 0.41, 0.5, 0.50, 0.34, 0.41]), Color(0.03, 0.04, 0.05))
	ci.draw_polyline(_poly(r, [0.36, 0.39, 0.5, 0.46, 0.64, 0.39]), accent, 2.5, true)
	ci.draw_line(_pt(r, 0.68, 0.36), _pt(r, 0.75, 0.18), armor.darkened(0.35), 3.0, true)
	ci.draw_circle(_pt(r, 0.75, 0.18), s * 0.02, accent)
	ci.draw_line(_pt(r, 0.40, 0.27), _pt(r, 0.46, 0.31), armor.darkened(0.4), 1.5, true)


static func _mystic(ci: CanvasItem, r: Rect2, fac: Color, armor: Color, accent: Color) -> void:
	var s := minf(r.size.x, r.size.y)
	var blade_a := _pt(r, 0.20, 0.98)
	var blade_b := _pt(r, 0.31, 0.18)
	ci.draw_line(blade_a, blade_b, Color(accent, 0.18), 14.0, true)
	ci.draw_line(blade_a, blade_b, Color(accent, 0.45), 8.0, true)
	ci.draw_line(blade_a, blade_b, accent.lightened(0.6), 3.0, true)
	ci.draw_line(_pt(r, 0.19, 1.0), _pt(r, 0.21, 0.94), Color(0.25, 0.25, 0.28), 6.0, true)
	ci.draw_colored_polygon(_poly(r, [0.04, 1.0, 0.14, 0.76, 0.34, 0.66, 0.66, 0.66, 0.86, 0.76, 0.96, 1.0]), armor.darkened(0.15))
	ci.draw_polyline(_poly(r, [0.40, 0.70, 0.5, 0.86, 0.60, 0.70]), fac.darkened(0.2), 2.0, true)
	ci.draw_colored_polygon(_poly(r, [0.5, 0.13, 0.70, 0.29, 0.76, 0.62, 0.66, 0.72, 0.34, 0.72, 0.24, 0.62, 0.30, 0.29]), armor)
	ci.draw_colored_polygon(_poly(r, [0.5, 0.29, 0.62, 0.39, 0.62, 0.60, 0.5, 0.67, 0.38, 0.60, 0.38, 0.39]), Color(0.03, 0.03, 0.05))
	for x: float in [0.45, 0.55]:
		ci.draw_circle(_pt(r, x, 0.47), s * 0.04, Color(accent, 0.3))
		ci.draw_circle(_pt(r, x, 0.47), s * 0.018, accent.lightened(0.4))


static func _officer(ci: CanvasItem, r: Rect2, fac: Color, armor: Color, accent: Color, h: int) -> void:
	var s := minf(r.size.x, r.size.y)
	var skin: Color = SKINS[h % SKINS.size()]
	var uniform := fac.darkened(0.5) if h % 2 == 0 else armor.darkened(0.55)
	_shoulders(ci, r, uniform, fac.darkened(0.1))
	ci.draw_colored_polygon(_poly(r, [0.40, 0.67, 0.60, 0.67, 0.58, 0.76, 0.42, 0.76]), uniform.darkened(0.3))
	for i in 3:
		ci.draw_rect(Rect2(_pt(r, 0.26 + i * 0.045, 0.80), Vector2(r.size.x * 0.03, r.size.y * 0.02)), accent if i < 2 else fac)
	ci.draw_rect(Rect2(_pt(r, 0.45, 0.55), Vector2(r.size.x * 0.10, r.size.y * 0.13)), skin.darkened(0.15))
	ci.draw_circle(_pt(r, 0.5, 0.45), s * 0.145, skin)
	ci.draw_colored_polygon(_poly(r, [0.37, 0.45, 0.63, 0.45, 0.59, 0.59, 0.5, 0.64, 0.41, 0.59]), skin)
	ci.draw_circle(_pt(r, 0.45, 0.45), s * 0.013, Color(0.08, 0.06, 0.06))
	ci.draw_circle(_pt(r, 0.55, 0.45), s * 0.013, Color(0.08, 0.06, 0.06))
	ci.draw_line(_pt(r, 0.42, 0.415), _pt(r, 0.47, 0.41), skin.darkened(0.5), 2.0, true)
	ci.draw_line(_pt(r, 0.53, 0.41), _pt(r, 0.58, 0.415), skin.darkened(0.5), 2.0, true)
	ci.draw_line(_pt(r, 0.46, 0.56), _pt(r, 0.54, 0.56), skin.darkened(0.35), 2.0, true)
	ci.draw_colored_polygon(_poly(r, [0.34, 0.37, 0.66, 0.37, 0.70, 0.30, 0.62, 0.21, 0.38, 0.21, 0.30, 0.30]), uniform.darkened(0.15))
	ci.draw_colored_polygon(_poly(r, [0.31, 0.37, 0.69, 0.37, 0.66, 0.41, 0.34, 0.41]), Color(0.04, 0.04, 0.05))
	ci.draw_circle(_pt(r, 0.5, 0.29), s * 0.028, accent)


static func _pt(r: Rect2, x: float, y: float) -> Vector2:
	return r.position + Vector2(x * r.size.x, y * r.size.y)


static func _poly(r: Rect2, coords: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		out.append(_pt(r, float(coords[i]), float(coords[i + 1])))
	return out
