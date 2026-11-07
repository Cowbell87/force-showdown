class_name FxLayer
extends Control
## Lightweight effects overlay: energy bolts with glowing trails and impact rings.
## Floating text is added as child Labels by the battle screen.

var _bolts: Array = []
var _rings: Array = []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)


func add_bolt(from: Vector2, to: Vector2, color: Color, duration: float = 0.26, width: float = 1.0) -> void:
	_bolts.append({"from": from, "to": to, "color": color, "t": 0.0, "dur": duration, "w": width})


func add_ring(pos: Vector2, color: Color, radius: float = 34.0, duration: float = 0.35) -> void:
	_rings.append({"pos": pos, "color": color, "t": 0.0, "dur": duration, "r": radius})


func _process(delta: float) -> void:
	if _bolts.is_empty() and _rings.is_empty():
		return
	for b in _bolts:
		b["t"] = float(b["t"]) + delta / float(b["dur"])
		if float(b["t"]) >= 1.0:
			add_ring(b["to"], b["color"], 22.0 * float(b["w"]), 0.25)
	_bolts = _bolts.filter(func(b: Dictionary) -> bool: return float(b["t"]) < 1.0)
	for g in _rings:
		g["t"] = float(g["t"]) + delta / float(g["dur"])
	_rings = _rings.filter(func(g: Dictionary) -> bool: return float(g["t"]) < 1.0)
	queue_redraw()


func _draw() -> void:
	for b in _bolts:
		var k: float = b["t"]
		var from: Vector2 = b["from"]
		var to: Vector2 = b["to"]
		var c: Color = b["color"]
		var w: float = b["w"]
		var head := from.lerp(to, ease(k, 0.6))
		var tail := from.lerp(to, ease(maxf(0.0, k - 0.25), 0.6))
		draw_line(tail, head, Color(c, 0.18), 16.0 * w, true)
		draw_line(tail, head, Color(c, 0.5), 7.0 * w, true)
		draw_line(tail, head, c.lightened(0.65), 2.5 * w, true)
		draw_circle(head, 4.5 * w, c.lightened(0.8))
	for g in _rings:
		var k: float = g["t"]
		var c: Color = g["color"]
		var radius: float = g["r"]
		draw_arc(g["pos"], radius * (0.3 + k), 0.0, TAU, 32, Color(c, 1.0 - k), 5.0 * (1.0 - k) + 1.0, true)
		draw_circle(g["pos"], radius * 0.35 * (1.0 - k), Color(c.lightened(0.6), 0.6 * (1.0 - k)))
