class_name UITheme
extends RefCounted
## Shared look: dark navy panels, brushed-gold trim, cyan highlights.
## Everything is built in code so it can be tweaked in one place.

const GOLD := Color("#d8b25a")
const GOLD_BRIGHT := Color("#ffe39a")
const CYAN := Color("#5fd4ff")
const RED := Color("#ff4d5e")
const GREEN := Color("#4fe08a")
const TEXT := Color("#e6eefb")
const MUTED := Color("#8ea3bf")
const PANEL_BG := Color(0.035, 0.06, 0.115, 0.88)
const PANEL_BORDER := Color("#2c4a6e")

static var _font: Font
static var _title_font: Font


static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Avenir Next Condensed", "Avenir Next", "Futura", "Bahnschrift", "Roboto Condensed", "Helvetica Neue", "Arial"])
		f.font_weight = 600
		_font = f
	return _font


static func title_font() -> Font:
	if _title_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Futura", "Avenir Next Condensed", "Bahnschrift", "Eurostile", "Arial Black", "Arial"])
		f.font_weight = 800
		_title_font = f
	return _title_font


static func box(bg: Color = PANEL_BG, border: Color = PANEL_BORDER, radius: int = 10, border_width: int = 2, margin: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 18

	var normal := box(Color("#10203a"), GOLD.darkened(0.3), 6, 2, 10)
	var hover := box(Color("#183259"), GOLD, 6, 2, 10)
	var pressed := box(Color("#0a1628"), GOLD_BRIGHT, 6, 2, 10)
	var disabled := box(Color("#0b1220"), Color("#333c4a"), 6, 2, 10)
	for s: StyleBoxFlat in [normal, hover, pressed, disabled]:
		s.content_margin_left = 20
		s.content_margin_right = 20
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = 4
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD_BRIGHT)
	t.set_color("font_pressed_color", "Button", GOLD_BRIGHT)
	t.set_color("font_disabled_color", "Button", Color("#56637a"))

	t.set_stylebox("panel", "PanelContainer", box())
	t.set_stylebox("panel", "Panel", box())
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.03, 0.06, 0.12, 0.96), CYAN.darkened(0.3), 6, 1, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	return t


static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func header(text: String, size: int = 24) -> Label:
	var l := label(text, size, GOLD)
	l.add_theme_font_override("font", title_font())
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return l


static func button(text: String, callback: Callable, size: int = 20) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func():
		Sfx.play("click")
		callback.call()
	)
	b.mouse_entered.connect(func():
		if not b.disabled:
			Sfx.play("hover", -14.0)
	)
	return b


static func panel(border: Color = PANEL_BORDER, bg: Color = PANEL_BG, margin: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, 10, 2, margin))
	return p


static func html(c: Color) -> String:
	return c.to_html(false)
