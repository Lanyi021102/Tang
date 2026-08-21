extends Node2D
# 单个坊（等距菱形 + 贴图 + 坊名标签）

var tex: Texture2D
var cell := Vector2.ZERO
var fang_name := ""
var map

const SIDE := Color("#8a7348")
const INK := Color("#3a362e")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var NW := Vector2(0, -32)
	var NE := Vector2(64, 0)
	var SE := Vector2(0, 32)
	var SW := Vector2(-64, 0)
	var dn := Vector2(0, 10)
	_poly(PackedVector2Array([SW, SE, SE + dn, SW + dn]), SIDE.darkened(0.1))
	_poly(PackedVector2Array([SE, NE, NE + dn, SE + dn]), SIDE.darkened(0.3))
	var pts := PackedVector2Array([NW, NE, SE, SW])
	var uvs := PackedVector2Array([Vector2(0.5, 0.0), Vector2(1.0, 0.5), Vector2(0.5, 1.0), Vector2(0.0, 0.5)])
	if tex:
		draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)
	else:
		_poly(pts, Color("#cdbb8f"))
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

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)
