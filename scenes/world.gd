extends Node2D
# 世界渲染层：地面绘制（基于步坐标系统）

var map

const TW := 128.0
const TH := 64.0
const GRID_COLS := 12
const GRID_ROWS := 13
const STEP := 0.1
const GROUND := Color("#d8ccab")
const CITY_ROAD := Color("#8fb8c9")

func _ready() -> void:
	pass

# 步坐标 → 等距屏幕坐标（与 changan_map.gd 保持一致）
func _step_iso(sx: float, sy: float) -> Vector2:
	return Vector2((sx - sy) * STEP * 64.0, (sx + sy) * STEP * 32.0)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)

func _draw() -> void:
	_draw_ground()

func _draw_ground() -> void:
	# 城市总尺寸：东西 9663 步，南北 8668 步
	var city_ew := 9663.0
	var city_ns := 8668.0
	# 外扩 200 步作为郊外
	var pad := 200.0
	var x0 := -pad
	var y0 := -pad
	var x1 := city_ew + pad
	var y1 := city_ns + pad
	# 大地面（郊外）
	var tl := _step_iso(x0, y0)
	var tr := _step_iso(x1, y0)
	var br := _step_iso(x1, y1)
	var bl := _step_iso(x0, y1)
	_poly(PackedVector2Array([tl, tr, br, bl]), GROUND)
	# 城区地面（道路色——蓝色，坊间间隙自然形成道路网络）
	var ctl := _step_iso(0.0, 0.0)
	var ctr := _step_iso(city_ew, 0.0)
	var cbr := _step_iso(city_ew, city_ns)
	var cbl := _step_iso(0.0, city_ns)
	_poly(PackedVector2Array([ctl, ctr, cbr, cbl]), CITY_ROAD)
	# 城墙（最后绘制，确保在蓝色城区之上可见）
	var wall_pts := PackedVector2Array([ctl, ctr, cbr, cbl])
	for i in range(4):
		draw_line(wall_pts[i], wall_pts[(i + 1) % 4], Color("#6f6648"), 2.5)
