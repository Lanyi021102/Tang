extends Node2D
# 点位标记 + 名称标签（读取主脚本的 _points / GRID_POS / _selected / _zoom_idx / font_song）

var map

const TW := 128.0
const TH := 64.0

const ZONE_COLOR := {
	"宫城": Color("#b0432f"),
	"皇城": Color("#a4763a"),
	"大明宫": Color("#c9a45a"),
	"兴庆宫": Color("#7f9468"),
	"外郭城": Color("#5f7380"),
	"地形": Color("#6f6a5c"),
	"坊": Color("#8a7a5a"),
}
const INK := Color("#3a362e")

func _iso(c: float, r: float) -> Vector2:
	return Vector2((c - r) * TW * 0.5, (c + r) * TH * 0.5)

func _draw() -> void:
	for p in map._points:
		var gp: Vector2 = map.GRID_POS.get(String(p["key"]), Vector2(6, 4))
		var c := _iso(gp.x, gp.y) + Vector2(0, -8)
		var col: Color = ZONE_COLOR.get(p["zone"], INK)
		var is_sel: bool = not map._selected.is_empty() and map._selected["key"] == p["key"]
		var rad := 7.0 if is_sel else 5.0
		draw_circle(c, rad + 5.0, Color(col.r, col.g, col.b, 0.18))
		draw_circle(c, rad, Color("#f5eeda"))
		draw_circle(c, rad - 1.5, col)
		draw_arc(c, rad, 0.0, TAU, 24, col.darkened(0.25), 1.2)
		if map._zoom_idx >= 1:
			_draw_label(String(p["name"]), c, is_sel)

func _draw_label(text: String, c: Vector2, bold: bool) -> void:
	var fs := 12.0 if not bold else 13.0
	var w: float = map.font_song.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx: float = c.x - w * 0.5
	var ly: float = c.y - 14.0
	for ox in [-1, 1]:
		for oy in [-1, 1]:
			draw_string(map.font_song, Vector2(lx + ox, ly + oy), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.95, 0.92, 0.85, 0.9))
	draw_string(map.font_song, Vector2(lx, ly), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
