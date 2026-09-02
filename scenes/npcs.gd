extends Node2D
# NPC 人物（非常小，符合人体比例）+ 对话头像气泡（世界空间，随缩放保持可点击大小）

var map
var _avatar_tex: Texture2D

const STEP := 0.1
const AVATAR_R := 24.0  # 头像圆框在屏幕上的半径（像素，保证可点击）
const BUBBLE_GAP := 7.0  # 圆框与头顶的间距（屏幕像素）

func _ready() -> void:
	_avatar_tex = load("res://assets/avatar_placeholder.png") if ResourceLoader.exists("res://assets/avatar_placeholder.png") else null

func _step_iso(sx: float, sy: float) -> Vector2:
	return Vector2((sx - sy) * STEP * 64.0, (sx + sy) * STEP * 32.0)

func _draw() -> void:
	if map == null or map._zoom_idx < 1:
		return
	var zoom: float = map._camera.zoom.x
	for gi in range(map._groups.size()):
		var g: Dictionary = map._groups[gi]
		for m in g["members"]:
			# dc/dr 是网格偏移，转换为步偏移（1 网格单位 ≈ 800 步）
			var sx := float(g["c"]) + float(m["dc"]) * 800.0
			var sy := float(g["r"]) + float(m["dr"]) * 800.0
			var p := _step_iso(sx, sy)
			_draw_figure(p)
	for s in map._speaking:
		var gi: int = s["gi"]
		if gi < 0 or gi >= map._groups.size():
			continue
		var g: Dictionary = map._groups[gi]
		_draw_speak_bubble(_step_iso(float(g["c"]), float(g["r"])), zoom, s)

func _draw_figure(p: Vector2) -> void:
	var s := 1.0
	var col := Color("#4a463c")
	draw_circle(p + Vector2(0, -s * 1.05), s * 0.22, col.darkened(0.1))
	draw_circle(p + Vector2(0, -s * 0.82), s * 0.16, Color("#d8c9a8"))
	_poly(PackedVector2Array([
		Vector2(p.x - s * 0.24, p.y - s * 0.66),
		Vector2(p.x + s * 0.24, p.y - s * 0.66),
		Vector2(p.x + s * 0.15, p.y),
		Vector2(p.x - s * 0.15, p.y),
	]), col)

func _draw_speak_bubble(p: Vector2, zoom: float, spk: Dictionary) -> void:
	var age: float = spk.get("age", 0.0)
	var pop := clampf(age / 0.35, 0.0, 1.0)
	var e: float = map._ease_out_back(pop)
	var scl := lerpf(0.7, 1.0, e)
	var rise: float = (1.0 - e) * 12.0 / zoom
	var r: float = AVATAR_R / zoom
	var gap: float = BUBBLE_GAP / zoom
	var head := p + Vector2(0, -2.0)
	var c := Vector2(p.x, head.y - r - gap - rise)
	draw_set_transform(c, 0.0, Vector2(scl, scl))
	var tw: float = 7.0 / zoom / scl
	_poly(PackedVector2Array([
		Vector2(-tw, r), Vector2(tw, r), Vector2(0, r + (gap + 1.0 / zoom) / scl),
	]), Color(0.96, 0.94, 0.90))
	var d := r * 2.0
	if _avatar_tex:
		draw_texture_rect_region(_avatar_tex, Rect2(-r, -r, d, d), Rect2(0, 0, _avatar_tex.get_width(), _avatar_tex.get_height()))
	else:
		draw_circle(Vector2.ZERO, r, Color("#7a9b8f"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, Color("#8a6a3a"), 2.5 / zoom / scl)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)
