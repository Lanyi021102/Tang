extends Node2D
# 街道矩形块（可点击交互，高亮显示）

var tile_w := 128.0   # 矩形宽度（像素）
var tile_h := 64.0    # 矩形高度（像素）
var tile_name := ""   # 街道名称
var tile_type := ""   # "东西街道" 或 "南北街道"
var road_width := 0   # 路宽（步）
var road_length := 0  # 路长（步）
var color := Color("#7fae92")
var map

const INK := Color("#2a3a42")
const EDGE := Color("#1a1a1a")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# tile_w / tile_h 是像素值，转换回步空间用于等距投影
	var hw := tile_w * 0.5 / 6.4   # 半步宽
	var hh := tile_h * 0.5 / 3.2   # 半步高
	# 等距投影菱形四角（与 fang_tile 同一公式）
	var NW := Vector2((-hw - hh) * 6.4, (-hw + hh) * 3.2)
	var NE := Vector2((hw - hh) * 6.4, (hw + hh) * 3.2)
	var SE := Vector2((hw + hh) * 6.4, (hw - hh) * 3.2)
	var SW := Vector2((-hw + hh) * 6.4, (-hw - hh) * 3.2)
	# 顶面（整体绘制，无接缝）
	draw_polygon(PackedVector2Array([NW, NE, SE, SW]), PackedColorArray([color, color, color, color]))

func set_map_ref(m) -> void:
	map = m

func _poly(points: PackedVector2Array, c: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), c)
