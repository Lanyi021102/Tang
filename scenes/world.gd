extends Node2D
# 世界渲染层：负责地面绘制 + 生成坊子节点（坊为独立节点，见 fang_tile.gd）

var map

const TW := 128.0
const TH := 64.0
const GRID_COLS := 12
const GRID_ROWS := 13
const GROUND := Color("#d8ccab")

func _ready() -> void:
	pass

func _iso(c: float, r: float) -> Vector2:
	return Vector2((c - r) * TW * 0.5, (c + r) * TH * 0.5)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)

func _ellipse(c: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var a := float(i) / 28.0 * TAU
		pts.append(c + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	_poly(pts, color)

func _occupied(c: int, r: int) -> bool:
	if r < 1:
		return true
	if c >= 4 and c < 8 and r >= 1 and r < 3:
		return true
	if c >= 4 and c < 8 and r >= 3 and r < 5:
		return true
	if c >= 8 and c < 11 and r >= 1 and r < 3:
		return true
	if c >= 9 and c < 11 and r >= 4 and r < 6:
		return true
	if c >= 2 and c < 4 and r >= 5 and r < 7:
		return true
	if c >= 8 and c < 10 and r >= 5 and r < 7:
		return true
	if c == 5 or c == 6:
		if r >= 5 and r < 9:
			return true
	return false

func _draw() -> void:
	_draw_ground()

func _draw_ground() -> void:
	var c0 := -2.0
	var r0 := -2.0
	var c1 := float(GRID_COLS) + 2.0
	var r1 := float(GRID_ROWS) + 2.0
	var bl := _iso(c0, r1)
	var tr := _iso(c1, r0)
	var br := _iso(c1, r1)
	var tl := _iso(c0, r0)
	_poly(PackedVector2Array([tl, tr, br, bl]), GROUND)
	var w0 := 0.0
	var w1 := float(GRID_COLS)
	var h0 := 0.0
	var h1 := float(GRID_ROWS)
	var wbl := _iso(w0, h1)
	var wtr := _iso(w1, h0)
	var wbr := _iso(w1, h1)
	var wtl := _iso(w0, h0)
	_iso_box(w0, h0, w1, h1, 6.0, Color("#d9cfb2"), Color("#b7aa88"), Color("#968b68"))
	var pts := PackedVector2Array([wtl, wtr, wbr, wbl])
	for i in range(4):
		draw_line(pts[i], pts[(i + 1) % 4], Color("#6f6648"), 2.5)
	_iso_box(1.0, 0.0, 11.0, 1.0, 3.0, Color("#cdd6bb"), Color("#a8b492"), Color("#83906e"))
	_ellipse(_iso(9.5, 0.4), Vector2(60, 22), Color("#c6c0ad"))

func _iso_box(c0: float, r0: float, c1: float, r1: float, h: float, top: Color, left: Color, right: Color) -> void:
	var NW := _iso(c0, r0)
	var NE := _iso(c1, r0)
	var SE := _iso(c1, r1)
	var SW := _iso(c0, r1)
	var dn := Vector2(0, h)
	_poly(PackedVector2Array([SW, SE, SE + dn, SW + dn]), left)
	_poly(PackedVector2Array([SE, NE, NE + dn, SE + dn]), right)
	_poly(PackedVector2Array([NW, NE, SE, SW]), top)
