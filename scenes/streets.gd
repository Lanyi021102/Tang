extends Node2D
# 坊间街道 + 朱雀门街 + 水系（静态内容，独立成节点）

const TW := 128.0
const TH := 64.0
const GRID_COLS := 12
const GRID_ROWS := 9

func _iso(c: float, r: float) -> Vector2:
	return Vector2((c - r) * TW * 0.5, (c + r) * TH * 0.5)

func _draw() -> void:
	# 坊间街道（十字网格）
	var col := Color("#e8dbb6")
	for c in range(1, GRID_COLS):
		draw_line(_iso(float(c), 0.0), _iso(float(c), float(GRID_ROWS)), col, 6.0)
	for r in range(1, GRID_ROWS):
		draw_line(_iso(0.0, float(r)), _iso(float(GRID_COLS), float(r)), col, 6.0)
	# 朱雀门街（中央大道）
	draw_line(_iso(5.5, 5.0), _iso(5.5, 9.0), Color("#ece4cd"), 10.0)
	draw_line(_iso(6.5, 5.0), _iso(6.5, 9.0), Color("#ece4cd"), 10.0)
	# 水系（太液池、龙池）
	_ellipse(_iso(8.6, 1.5), Vector2(30, 14), Color("#a9c4b6"))
	_ellipse(_iso(9.7, 5.3), Vector2(26, 18), Color("#a9c4b6"))

func _ellipse(c: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var a := float(i) / 28.0 * TAU
		pts.append(c + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([pts[idx[t]], pts[idx[t + 1]], pts[idx[t + 2]]]), color)
