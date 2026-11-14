extends Node2D

const INK = Color("52684e")
var board = 0
var art: Texture2D
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	if ResourceLoader.exists("res://assets/art/office_garden.png"):
		art = load("res://assets/art/office_garden.png")
	queue_redraw()

func _box(rect: Rect2, fill: Color, radius: int = 16, outline: int = 3) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = INK
	style.set_border_width_all(outline)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _draw() -> void:
	rng.seed = 260819
	draw_rect(Rect2(-8000, -8000, 16000, 16000), Color("a1ba94"))
	if art: draw_texture_rect(art, Rect2(-1100, -619, 2200, 1238), false)
	else:
		# A quiet campus beyond the board: the camera can explore the whole place.
		for i in range(75):
			var p = Vector2(rng.randf_range(-2600, 2600), rng.randf_range(-1700, 1700))
			if absf(p.x) < 1170 and absf(p.y) < 710: continue
			_tree(p, rng.randf_range(0.6, 1.6))
		_box(Rect2(-1670, -500, 400, 2200), Color("bec3a5"), 20, 0)
		for y in range(-450, 1500, 110): draw_line(Vector2(-1480, y), Vector2(-1480, y + 45), Color("e8e2bf"), 8)
		_building(Vector2(-1000, -1110), Vector2(600, 280), "GARAGE & CO.")
		_building(Vector2(670, -1080), Vector2(430, 260), "THE OFFICE")
		_box(Rect2(-400, 820, 670, 100), Color("c8c6aa"), 12, 1)
		for x in [-330, -160, 10, 180]:
			_box(Rect2(x, 835, 120, 50), Color("a78058"), 6, 2)
			for yy in [848, 865]: draw_line(Vector2(x + 5, yy), Vector2(x + 115, yy), INK, 2)
		for i in range(70):
			var p = Vector2(rng.randf_range(-2500, 2500), rng.randf_range(-1600, 1600))
			if absf(p.x) < 1180 and absf(p.y) < 740: continue
			draw_line(p, p + Vector2(-3, -9), Color("728e6b"), 2)
			draw_line(p, p + Vector2(5, -7), Color("728e6b"), 2)
	# The illustrated lawn is itself the open playing surface; no opaque box hides it.
	if art: return
	_box(Rect2(-1122, -667, 2244, 1334), Color("647d5b55"), 26, 0)
	_box(Rect2(-1120, -680, 2240, 1320), Color("f7edd0"), 23, 3)
	_box(Rect2(-1107, -667, 2214, 1294), Color("b9d2a7") if board == 0 else Color("b4c9b6"), 15, 3)
	# Sparse cloth marks provide scale without turning the tabletop into a grid.
	for i in range(160):
		var p = Vector2(rng.randf_range(-1080, 1080), rng.randf_range(-640, 600))
		draw_line(p, p + Vector2(3, 1), Color("6a8a6030"), 1)
	for p in [Vector2(-1080, -640), Vector2(1080, -640), Vector2(-1080, 600), Vector2(1080, 600)]:
		draw_circle(p, 4, Color("6c8662"))

func _tree(p: Vector2, size_value: float) -> void:
	draw_circle(p + Vector2(6, 29) * size_value, 43 * size_value, Color("66815d33"))
	draw_line(p, p + Vector2(0, 57) * size_value, INK, 7 * size_value)
	var pts = PackedVector2Array([p + Vector2(0, -73) * size_value, p + Vector2(41, 3) * size_value, p + Vector2(27, 3) * size_value, p + Vector2(51, 39) * size_value, p + Vector2(-48, 39) * size_value, p + Vector2(-26, 3) * size_value, p + Vector2(-40, 3) * size_value, p + Vector2(0, -73) * size_value])
	draw_colored_polygon(pts, Color("b6cba2"))
	draw_polyline(pts, INK, 2 * size_value, true)
	draw_line(p + Vector2(0, 32) * size_value, p + Vector2(0, -42) * size_value, INK, 2 * size_value)
	for y in [-16, 8]:
		draw_line(p + Vector2(0, y) * size_value, p + Vector2(-13, y - 12) * size_value, INK, size_value)
		draw_line(p + Vector2(0, y + 7) * size_value, p + Vector2(13, y - 5) * size_value, INK, size_value)

func _building(p: Vector2, size_value: Vector2, title: String) -> void:
	_box(Rect2(p + Vector2(7, 12), size_value), Color("6e875d66"), 6, 0)
	_box(Rect2(p, size_value), Color("d7c6a3"), 6, 3)
	_box(Rect2(p - Vector2(20, 25), Vector2(size_value.x + 40, 75)), Color("859b79"), 9, 3)
	for x in range(35, int(size_value.x) - 60, 100):
		_box(Rect2(p + Vector2(x, 100), Vector2(70, 90)), Color("bdcfbe"), 2, 2)
		draw_line(p + Vector2(x + 35, 100), p + Vector2(x + 35, 190), INK, 2)
	_box(Rect2(p + Vector2(50, 9), Vector2(size_value.x - 100, 38)), Color("f8edce"), 3, 2)
	draw_string(ThemeDB.fallback_font, p + Vector2(70, 36), title, HORIZONTAL_ALIGNMENT_CENTER, size_value.x - 140, 19, INK)
