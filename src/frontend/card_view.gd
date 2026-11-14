extends Node2D

const SIZE = Vector2(148, 202)
const INK = Color("344436")
var card: Dictionary = {}
var definition: Dictionary = {}
var selected = false
var hovered = false
var target = false
var work_progress = -1.0
var work_name = ""
var icon_texture: Texture2D
var display_position = Vector2.ZERO
var compact = false
var reduced_motion = false
var sell_value = -1
var body_font = preload("res://assets/fonts/Nunito.ttf")
var title_font = preload("res://assets/fonts/PatrickHand-Regular.ttf")

func setup(value: Dictionary, spec: Dictionary) -> void:
	card = value
	definition = spec
	var icon_path = "res://assets/icons/%s.svg" % str(card.get("id", ""))
	if ResourceLoader.exists(icon_path):
		icon_texture = load(icon_path)
	else:
		var fallback = "res://assets/icons/%s.svg" % str(spec.get("type", "resource"))
		if ResourceLoader.exists(fallback): icon_texture = load(fallback)
	queue_redraw()

func rect() -> Rect2:
	return Rect2(global_position, SIZE * global_scale)

func _process(delta: float) -> void:
	var lift = Vector2(0, -7) if hovered else Vector2.ZERO
	position = position.lerp(display_position + lift, 1.0 if reduced_motion else minf(delta * 22.0, 1.0))

func _paper(at: Rect2, color: Color, radius: int = 8, border: int = 2) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	draw_style_box(style, at)

func _text(value: String, at: Vector2, size_value: int = 16, color: Color = INK, width: float = 136) -> void:
	draw_string(body_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, width, size_value, color)

func _draw() -> void:
	if card.is_empty(): return
	var kind = str(definition.get("type", "resource"))
	var colors = {"person":"c5dce1", "candidate":"dce4cd", "cash":"cee0a9", "product":"f2c094", "equipment":"dfdfc7", "hazard":"e7afa2", "event":"d9c3dc", "idea":"eee0a6", "document":"fff0d1", "lead":"e1c7ad", "container":"d0c7a7"}
	var color = Color(colors.get(kind, "e9d6ae"))
	var shadow = Color("243c3438")
	_paper(Rect2(Vector2(5, 8), SIZE), shadow, 8, 0)
	if kind == "cash":
		_paper(Rect2(Vector2(2, 4), SIZE), color.darkened(0.1))
		_paper(Rect2(Vector2(1, 2), SIZE), color.lightened(0.1))
	_paper(Rect2(Vector2.ZERO, SIZE), color)
	_paper(Rect2(Vector2(6, 6), Vector2(136, 45)), Color("fff5dc"), 4, 1)
	var name_value = str(definition.get("name", card.get("id", "Card")))
	var size_value = 20
	var lines: Array[String] = []
	var current = ""
	for word in name_value.split(" "):
		var candidate = current + (" " if current != "" else "") + word
		if title_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value).x > 123 and current != "":
			lines.append(current)
			current = word
		else: current = candidate
	if current != "": lines.append(current)
	if lines.size() > 2:
		lines = [" ".join(lines.slice(0, lines.size() - 1)), lines.back()]
		size_value = 16
	for i in range(lines.size()):
		draw_string(title_font, Vector2(12, 33 if lines.size() == 1 else 24 + i * 20), lines[i], HORIZONTAL_ALIGNMENT_LEFT, 124, size_value, INK)
	if icon_texture:
		draw_texture_rect(icon_texture, Rect2(26, 58, 96, 96), false, Color.WHITE)
	else:
		_draw_illustration(str(card.get("id", "")), kind)
	draw_line(Vector2(12, 161), Vector2(136, 161), Color("62705c88"), 1)
	if kind == "cash":
		var bill = int(str(card.get("id", "usd_1")).trim_prefix("usd_"))
		_text("$%d  × %d" % [bill, int(card.get("amount", 1))], Vector2(15, 183), 17)
	elif kind in ["person", "candidate"]:
		var stress = float(card.get("stress", 0))
		for i in range(10):
			draw_circle(Vector2(18 + i * 12, 177), 3.0, INK if float(i) < stress else Color("79908455"))
		_text(str(card.get("status", "")), Vector2(15, 194), 11)
	elif kind == "hazard":
		_text("!  " + str(card.get("status", "Needs attention")), Vector2(14, 183), 12)
	elif sell_value >= 0:
		_text("$%d" % sell_value, Vector2(14, 184), 16)
	else:
		_text(kind.capitalize(), Vector2(14, 183), 12)
	if work_progress >= 0.0:
		_paper(Rect2(5, 207, 138, 32), Color("fff5dc"), 5, 1)
		draw_rect(Rect2(10, 231, 128, 4), Color("ccd4ba"))
		draw_rect(Rect2(10, 231, 128 * clampf(work_progress, 0, 1), 4), INK)
		_text(work_name, Vector2(11, 225), 14, INK, 126)
	if selected or target:
		var edge = StyleBoxFlat.new()
		edge.bg_color = Color.TRANSPARENT
		edge.border_color = Color("e0b960") if target else Color("fff1b7")
		edge.set_border_width_all(4)
		edge.set_corner_radius_all(11)
		draw_style_box(edge, Rect2(-5, -5, SIZE.x + 10, SIZE.y + 10))

func _draw_illustration(id: String, kind: String) -> void:
	var c = Vector2(74, 104)
	var line = Color("3d4d3c")
	if kind in ["person", "candidate"]:
		var hair = Color("635140")
		if id in ["designer", "hr"]: hair = Color("8d5d43")
		_ellipse(c + Vector2(0, 38), Vector2(36, 10), Color("76958b44"))
		_paper(Rect2(c + Vector2(-24, 8), Vector2(48, 38)), Color("fff2d3"), 11, 2)
		draw_circle(c + Vector2(0, -10), 23, line)
		draw_circle(c + Vector2(0, -11), 20, Color("e6b98b"))
		draw_arc(c + Vector2(0, -16), 21, PI, TAU, 16, hair, 10, true)
		draw_circle(c + Vector2(-7, -9), 1.7, line)
		draw_circle(c + Vector2(7, -9), 1.7, line)
		draw_arc(c + Vector2(0, -5), 6, 0.2, PI - 0.2, 10, line, 1.5, true)
		if id in ["founder", "accountant", "senior_dev", "lawyer"]:
			for x in [-9, 9]: draw_arc(c + Vector2(x, -9), 6, 0, TAU, 16, line, 1.5, true)
			draw_line(c + Vector2(-3, -9), c + Vector2(3, -9), line, 1.5)
		if id == "founder":
			draw_line(c + Vector2(0, 12), c + Vector2(-4, 32), Color("b06f52"), 4)
		elif id == "dev" or id == "senior_dev":
			_text("</>", c + Vector2(-16, 32), 16)
		elif id == "ai_agent":
			_paper(Rect2(c + Vector2(-28, -30), Vector2(56, 47)), Color("b9cec1"), 5)
			draw_circle(c + Vector2(-12, -7), 4, INK)
			draw_circle(c + Vector2(12, -7), 4, INK)
			draw_line(c + Vector2(-10, 6), c + Vector2(10, 6), INK, 2)
	elif "laptop" in id or "server" in id or kind == "product":
		_paper(Rect2(c + Vector2(-37, -30), Vector2(74, 51)), Color("697d6b"), 5)
		_paper(Rect2(c + Vector2(-30, -24), Vector2(60, 37)), Color("cfddc2"), 2, 1)
		if "prototype" in id:
			draw_circle(c + Vector2(0, -6), 10, Color("deae78"))
			draw_line(c + Vector2(-6, -5), c + Vector2(-1, 1), INK, 2)
			draw_line(c + Vector2(-1, 1), c + Vector2(8, -12), INK, 2)
		else: _text("{  }", c + Vector2(-20, 1), 21)
		var pts = PackedVector2Array([c + Vector2(-38, 21), c + Vector2(38, 21), c + Vector2(47, 34), c + Vector2(-47, 34)])
		draw_colored_polygon(pts, Color("b7ba9a"))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), line, 2, true)
		draw_line(c + Vector2(-25, 27), c + Vector2(25, 27), line, 1)
	elif "coffee" in id or id == "pantry":
		_ellipse(c + Vector2(0, 35), Vector2(39, 8), Color("adac87"))
		_paper(Rect2(c + Vector2(-26, -17), Vector2(48, 48)), Color("fff1ce"), 7)
		draw_arc(c + Vector2(25, 2), 14, -PI / 2, PI / 2, 20, line, 5, true)
		_ellipse(c + Vector2(-2, -17), Vector2(23, 6), line)
		_ellipse(c + Vector2(-2, -18), Vector2(18, 3), Color("795b40"))
		for x in [-10, 8]: draw_arc(c + Vector2(x, -35), 9, -1.7, 1.2, 12, line, 1.5, true)
	elif kind == "cash":
		_paper(Rect2(c + Vector2(-45, -28), Vector2(90, 57)), Color("d8e8b8"), 3)
		draw_arc(c, 21, 0, TAU, 32, Color("71835b"), 1.5, true)
		_text("$", c + Vector2(-10, 9), 29)
		for x in [-35, 32]: draw_circle(c + Vector2(x, 0), 4, Color("71835b"))
	elif kind == "hazard":
		draw_circle(c, 23, Color("6e614f"))
		draw_line(c + Vector2(0, -21), c + Vector2(0, 22), line, 3)
		for y in [-13, 0, 13]:
			for d in [-1, 1]:
				draw_polyline(PackedVector2Array([c + Vector2(d * 20, y), c + Vector2(d * 34, y - 8), c + Vector2(d * 42, y - 3)]), line, 3, true)
		draw_circle(c + Vector2(-8, -12), 3, Color("fff1d2"))
		draw_circle(c + Vector2(8, -12), 3, Color("fff1d2"))
	elif id == "whiteboard":
		_paper(Rect2(c + Vector2(-43, -34), Vector2(86, 63)), Color("fff9df"), 3)
		draw_line(c + Vector2(-28, 30), c + Vector2(-33, 45), line, 3)
		draw_line(c + Vector2(28, 30), c + Vector2(33, 45), line, 3)
		draw_line(c + Vector2(-31, -18), c + Vector2(4, -18), Color("c77954"), 3)
		draw_line(c + Vector2(-31, -4), c + Vector2(21, -4), Color("78968b"), 2)
		draw_line(c + Vector2(-31, 10), c + Vector2(13, 10), Color("78968b"), 2)
	elif kind == "idea" or id == "concept":
		draw_circle(c + Vector2(0, -10), 24, Color("efd58c"))
		draw_arc(c + Vector2(0, -10), 24, 0, TAU, 32, line, 2, true)
		_paper(Rect2(c + Vector2(-12, 13), Vector2(24, 17)), Color("a3b09a"), 3)
		for i in range(7):
			var a = float(i) * TAU / 7
			draw_line(c + Vector2.from_angle(a) * 34, c + Vector2.from_angle(a) * 42, line, 2)
	elif kind == "equipment" or kind == "container":
		_paper(Rect2(c + Vector2(-36, -31), Vector2(72, 65)), Color("b8baa0"), 4)
		_paper(Rect2(c + Vector2(-25, -20), Vector2(50, 42)), Color("e7ddbc"), 3, 1)
		draw_circle(c + Vector2(8, 1), 10, line)
		draw_line(c + Vector2(8, -9), c + Vector2(8, 11), Color("e7ddbc"), 2)
	else:
		_paper(Rect2(c + Vector2(-30, -40), Vector2(60, 80)), Color("fff4d5"), 3)
		for i in range(4): draw_line(c + Vector2(-19, -21 + i * 12), c + Vector2(18 - (i % 2) * 9, -21 + i * 12), line, 2)
		if kind == "lead":
			draw_circle(c + Vector2(17, 25), 13, Color("bd8866"))
			_text("$", c + Vector2(11, 31), 16, Color("fff4d5"))

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(33): points.append(center + Vector2(cos(float(i) * TAU / 32), sin(float(i) * TAU / 32)) * radius)
	draw_colored_polygon(points, color)

