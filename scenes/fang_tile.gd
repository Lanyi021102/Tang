extends Node2D
# 单个坊（等距矩形 + 坊名标签）— 基于步坐标尺寸

var fang_w := 1.0      # 坊东西宽度（步 × STEP）
var fang_h := 1.0      # 坊南北深度（步 × STEP）
var fang_name := ""
var cell := Vector2.ZERO
var map

const SIDE := Color("#8a7348")
const INK := Color("#3a362e")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var fang_scale := 1.0
	if map != null:
		var zoom: float = map._camera.zoom.x
		if zoom < 0.01:
			fang_scale = 0.1 / maxf(zoom, 0.0001)
	var hw := fang_w * 0.5 * fang_scale * 10.0   # 东西宽度方向 ×2 补偿等距压缩
	var hh := fang_h * 0.5 * fang_scale * 10.0   # 南北深度方向保持不变
	var NW := Vector2((-hw - hh) * 6.4, (-hw + hh) * 3.2)
	var NE := Vector2((hw - hh) * 6.4, (hw + hh) * 3.2)
	var SE := Vector2((hw + hh) * 6.4, (hw - hh) * 3.2)
	var SW := Vector2((-hw + hh) * 6.4, (-hw - hh) * 3.2)
	var dn := Vector2(0, 6)
	_poly(PackedVector2Array([SW, SE, SE + dn, SW + dn]), SIDE.darkened(0.1))
	_poly(PackedVector2Array([SE, NE, NE + dn, SE + dn]), SIDE.darkened(0.3))
	_poly(PackedVector2Array([NW, NE, SE, SW]), Color("#cdbb8f"))
	var outline := PackedVector2Array([NW, NE, SE, SW, NW])
	for i in range(4):
		draw_line(outline[i], outline[i + 1], Color.BLACK, 3.0)
	# 坊名标签
	if fang_name != "" and map != null and map._zoom_idx >= 2:
		var zoom: float = map._camera.zoom.x
		if zoom <= 0.0:
			zoom = 1.0
		var fs := 14.0 / zoom
		var font: Font = map.font_song
		var w: float = font.get_string_size(fang_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var o := 1.0 / zoom
		var off := 26.0 / zoom
		for ox in [-o, o]:
			for oy in [-o, o]:
				draw_string(font, Vector2(-w * 0.5 + ox, -off + oy), fang_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.95, 0.92, 0.85, 0.9))
		draw_string(font, Vector2(-w * 0.5, -off), fang_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)

func set_map_ref(m) -> void:
	map = m

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)
