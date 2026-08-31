extends Node2D
# 单个建筑 / 城门（等距盒体 + 可选贴图 + 可选名称标签）

var map

var c0 := 0.0
var r0 := 0.0
var c1 := 0.0
var r1 := 0.0
var height := 20.0
var top_color := Color.WHITE
var left_color := Color.WHITE
var right_color := Color.WHITE
var label := ""
var label_color := Color.BLACK
var label_size := 18.0
var tex: Texture2D = null

func _iso(c: float, r: float) -> Vector2:
	return Vector2((c - r) * 64.0, (c + r) * 32.0)

func _ready() -> void:
	var cx := (c0 + c1) * 0.5
	var cy := (r0 + r1) * 0.5
	position = _iso(cx, cy)
	queue_redraw()

func _draw() -> void:
	var cx := (c0 + c1) * 0.5
	var cy := (r0 + r1) * 0.5
	var cc := _iso(cx, cy)
	var NW := _iso(c0, r0) - cc
	var NE := _iso(c1, r0) - cc
	var SE := _iso(c1, r1) - cc
	var SW := _iso(c0, r1) - cc
	var dn := Vector2(0, height)
	_poly(PackedVector2Array([SW, SE, SE + dn, SW + dn]), left_color)
	_poly(PackedVector2Array([SE, NE, NE + dn, SE + dn]), right_color)
	if tex:
		var pts := PackedVector2Array([NW, NE, SE, SW])
		var uvs := PackedVector2Array([Vector2(0.5, 0.0), Vector2(1.0, 0.5), Vector2(0.5, 1.0), Vector2(0.0, 0.5)])
		draw_polygon(pts, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), uvs, tex)
	else:
		_poly(PackedVector2Array([NW, NE, SE, SW]), top_color)
	if label != "" and map != null:
		var font: Font = map.font_song
		var w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		draw_string(font, Vector2(-w * 0.5, -6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, label_color)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)
