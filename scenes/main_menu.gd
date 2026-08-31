extends Control

# 盛唐水墨山水 - 手机游戏开始菜单
# Chinese ink-wash landscape start menu (procedurally drawn)

const DESIGN_W := 1280.0
const DESIGN_H := 720.0

# ---- palette (soft sage green / fog gray / rice-paper beige) ----
const PAPER_TOP := Color("#efe9d8")
const PAPER_BOT := Color("#e3dac2")
const INK := Color("#3a362e")
const INK_SOFT := Color("#4a463c")
const RED_WALL := Color("#a83f35")
const RED_WALL_DARK := Color("#8c322a")
const GOLD := Color("#c9a45a")
const GOLD_DARK := Color("#a8823e")
const STONE := Color("#9a9484")
const ROOF_DARK := Color("#6d675c")
const BAMBOO := Color("#cdbb8f")
const BAMBOO_EDGE := Color("#7a6a4a")
const WOOD := Color("#5b4028")
const WOOD_DARK := Color("#46301c")
const PATH_COLOR := Color("#d8c797")
const NODE_COLOR := Color(0.85, 0.78, 0.58, 0.65)

const ENTER_RECT := Rect2(510.0, 626.0, 260.0, 54.0)
const MAP_SCENE := "res://scenes/ChangAnCity.tscn"
const START_SCENE := "res://scenes/Start.tscn"
const BACK_RECT := Rect2(40.0, 640.0, 120.0, 44.0)

var font_song: Font
var font_hei: Font
var _scale := 1.0
var _offset := Vector2.ZERO

# 按钮点击反馈与提示
var _pressed_key := ""            # 当前按下的按钮（"guixu"/"weipai"/"tansuo"）
var _toast_text := ""             # 提示文本
var _toast_time := 0.0            # 提示剩余时间（秒）
const TOAST_DURATION := 2.0
const WOODBOX_RECT := Rect2(60.0, 40.0, 200.0, 46.0)
const WEIPAI_CENTER := Vector2(1090.0, 620.0)
const TANSUO_CENTER := Vector2(1222.0, 620.0)
const BUTTON_R := 46.0
# 左右切换关卡按钮（垂直居中）
const PREV_CENTER := Vector2(48.0, 360.0)
const NEXT_CENTER := Vector2(1232.0, 360.0)
const NAV_R := 40.0

# 视差滚动：四层山偏移（越远越慢）
var _mountain_offsets := [0.0, 0.0, 0.0, 0.0]
const MOUNTAIN_SPEEDS := [6.0, 12.0, 20.0, 30.0]
# 静态背景纹理缓存（纸张 + 地面），避免每帧重复随机绘制
var _paper_tex: ImageTexture
var _ground_tex: ImageTexture

func _ready() -> void:
	_setup_fonts()
	_build_static_textures()
	set_process(true)
	queue_redraw()

# 预渲染纸张与地面静态纹理（仅一次）
func _build_static_textures() -> void:
	_paper_tex = _render_paper_texture()
	_ground_tex = _render_ground_texture()

func _render_paper_texture() -> ImageTexture:
	var img := Image.create(DESIGN_W, DESIGN_H, false, Image.FORMAT_RGBA8)
	for y in range(DESIGN_H):
		var t := float(y) / float(DESIGN_H - 1)
		var c := PAPER_TOP.lerp(PAPER_BOT, t)
		img.fill_rect(Rect2i(0, y, DESIGN_W, 1), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260818
	for i in range(700):
		var x := rng.randi_range(0, DESIGN_W - 1)
		var y := rng.randi_range(0, DESIGN_H - 1)
		var a := rng.randf_range(0.02, 0.06)
		var col := Color(0.42, 0.38, 0.30, a)
		img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _render_ground_texture() -> ImageTexture:
	var img := Image.create(DESIGN_W, DESIGN_H, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(0, 452, DESIGN_W, DESIGN_H - 452), Color("#d9cfb0"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(300):
		var x := rng.randi_range(0, DESIGN_W - 1)
		var y := rng.randi_range(458, DESIGN_H - 1)
		var a := rng.randf_range(0.03, 0.08)
		var col := Color(0.40, 0.36, 0.26, a)
		img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _setup_fonts() -> void:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Songti SC", "Songti", "STSongti-SC-Regular", "STHeiti", "PingFang SC", "Heiti SC"])
	sf.allow_system_fallback = true
	font_song = sf
	var hf := SystemFont.new()
	hf.font_names = PackedStringArray(["STHeiti", "PingFang SC", "Heiti SC"])
	hf.allow_system_fallback = true
	font_hei = hf

func _draw() -> void:
	var s := minf(size.x / DESIGN_W, size.y / DESIGN_H)
	var off := (size - Vector2(DESIGN_W, DESIGN_H) * s) * 0.5
	_scale = s
	_offset = off
	draw_set_transform(off, 0.0, Vector2(s, s))

	_draw_paper()
	_draw_mountains()
	_draw_ground()
	_draw_pond(560.0, 545.0, 205.0, 70.0)
	_draw_path()
	_draw_buildings()
	_draw_figures()
	_draw_ui()
	_draw_toast()

# ==================== background / paper ====================
func _draw_paper() -> void:
	if _paper_tex:
		draw_texture_rect(_paper_tex, Rect2(0, 0, DESIGN_W, DESIGN_H), false, Color.WHITE)
	else:
		var bands := 140
		for i in range(bands):
			var t := float(i) / float(bands - 1)
			var c := PAPER_TOP.lerp(PAPER_BOT, t)
			var y0 := DESIGN_H * t
			var y1 := DESIGN_H * (t + 1.0 / bands) + 1.0
			draw_rect(Rect2(0, y0, DESIGN_W, y1 - y0), c)

func _ridge(seedv: int, base_y: float, amp: float, offset: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seedv
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var p3 := rng.randf_range(0.0, TAU)
	var pts := PackedVector2Array()
	var f1 := 5.0 / DESIGN_W * TAU
	var f2 := 2.0 / DESIGN_W * TAU
	var f3 := 1.0 / DESIGN_W * TAU
	for i in range(161):
		var x := float(i) / 160.0 * DESIGN_W
		var sx := x + offset  # 偏移采样 → 向左滑动
		var h := absf(sin(sx * f1 + p1)) * amp * 0.55 \
			+ absf(sin(sx * f2 + p2)) * amp * 0.7 \
			+ absf(sin(sx * f3 + p3)) * amp * 0.28
		pts.append(Vector2(x, base_y - h))
	return pts

func _mountain_layer(seedv: int, base_y: float, amp: float, color: Color, offset: float) -> void:
	var ridge := _ridge(seedv, base_y, amp, offset)
	var poly := PackedVector2Array()
	for p in ridge:
		poly.append(p)
	poly.append(Vector2(DESIGN_W, base_y + 260.0))
	poly.append(Vector2(0.0, base_y + 260.0))
	_poly(poly, color)

func _draw_mountains() -> void:
	_mountain_layer(11, 300.0, 62.0, Color("#d9ddcf"), _mountain_offsets[0])
	_mountain_layer(23, 348.0, 74.0, Color("#c2cab5"), _mountain_offsets[1])
	_mountain_layer(37, 398.0, 82.0, Color("#a9b59a"), _mountain_offsets[2])
	_mountain_layer(51, 455.0, 96.0, Color("#8d9d7e"), _mountain_offsets[3])
	# fog veils between layers
	_fog(300.0, 350.0)
	_fog(352.0, 402.0)
	_fog(410.0, 462.0)

func _fog(y0: float, y1: float) -> void:
	var steps := 26
	var col := Color("#e7e2d1")
	for i in range(steps):
		var t := float(i) / float(steps)
		var a := t * t * 0.75
		var yy0 := lerpf(y0, y1, t)
		var yy1 := lerpf(y0, y1, t + 1.0 / steps)
		draw_rect(Rect2(0, yy0, DESIGN_W, yy1 - yy0), Color(col.r, col.g, col.b, a))

func _draw_ground() -> void:
	if _ground_tex:
		draw_texture_rect(_ground_tex, Rect2(0, 0, DESIGN_W, DESIGN_H), false, Color.WHITE)
	else:
		var g := Color("#d9cfb0")
		draw_rect(Rect2(0, 452.0, DESIGN_W, DESIGN_H - 452.0), g)
	# horizon soft line
	draw_rect(Rect2(0, 452.0, DESIGN_W, 3.0), Color(0.55, 0.52, 0.42, 0.18))

# ==================== path ====================
func _sample_smooth(pts: PackedVector2Array, steps: int) -> PackedVector2Array:
	if pts.size() < 2:
		return pts
	var p := PackedVector2Array()
	p.append(pts[0])
	for x in pts:
		p.append(x)
	p.append(pts[pts.size() - 1])
	var out := PackedVector2Array()
	for i in range(1, p.size() - 2):
		var p0 := p[i - 1]
		var p1 := p[i]
		var p2 := p[i + 1]
		var p3 := p[i + 2]
		for j in range(steps):
			var t := float(j) / float(steps)
			var t2 := t * t
			var t3 := t2 * t
			var q := 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
			out.append(q)
	out.append(p[p.size() - 2])
	return out

func _draw_dashed(samples: PackedVector2Array, color: Color, width: float, dash: float, gap: float) -> void:
	var on := true
	var remaining := dash
	for i in range(1, samples.size()):
		var a := samples[i - 1]
		var b := samples[i]
		var seglen := a.distance_to(b)
		var dir := (b - a).normalized()
		var walked := 0.0
		while walked < seglen:
			var need := remaining
			if walked + need > seglen:
				need = seglen - walked
			var sa := a + dir * walked
			var sb := a + dir * (walked + need)
			if on:
				draw_line(sa, sb, color, width)
			walked += need
			remaining -= need
			if remaining <= 0.0001:
				on = not on
				remaining = dash if on else gap

func _draw_path() -> void:
	var ctrl := PackedVector2Array([
		Vector2(120.0, 492.0),
		Vector2(255.0, 472.0),
		Vector2(430.0, 520.0),
		Vector2(640.0, 502.0),
		Vector2(840.0, 512.0),
		Vector2(1040.0, 470.0),
		Vector2(1180.0, 470.0),
	])
	var main := _sample_smooth(ctrl, 12)
	_draw_dashed(main, Color(0.72, 0.64, 0.44, 0.9), 3.2, 12.0, 9.0)

	# branch up to top badge
	var branch := _sample_smooth(PackedVector2Array([Vector2(640.0, 502.0), Vector2(640.0, 330.0), Vector2(640.0, 176.0)]), 10)
	_draw_dashed(branch, Color(0.72, 0.64, 0.44, 0.9), 3.2, 12.0, 9.0)

	# translucent beige circular nodes
	_node(Vector2(255.0, 472.0), 13.0)
	_node(Vector2(430.0, 515.0), 11.0)
	_node(Vector2(640.0, 502.0), 13.0)
	_node(Vector2(840.0, 508.0), 11.0)
	_node(Vector2(1040.0, 470.0), 13.0)
	_node(Vector2(640.0, 176.0), 10.0)

func _node(c: Vector2, r: float) -> void:
	draw_circle(c, r, NODE_COLOR)
	draw_arc(c, r, 0.0, TAU, 40, Color(0.60, 0.52, 0.32, 0.55), 2.0)
	draw_circle(c, r * 0.26, Color(0.55, 0.46, 0.28, 0.7))

# ==================== buildings ====================
func _draw_buildings() -> void:
	_draw_market(260.0, 470.0)
	_draw_palace(640.0, 470.0)
	_draw_pagoda(1040.0, 470.0)

func _draw_palace(cx: float, base_y: float) -> void:
	var pw := 330.0
	var plat_top := base_y - 10.0
	# stone platform
	_poly(PackedVector2Array([
		Vector2(cx - pw * 0.5, plat_top),
		Vector2(cx + pw * 0.5, plat_top),
		Vector2(cx + pw * 0.5 - 24.0, base_y),
		Vector2(cx - pw * 0.5 + 24.0, base_y),
	]), Color("#b7b19e"))
	# stairs
	for i in range(6):
		var sx0 := cx - 22.0
		var sx1 := cx + 22.0
		var sy := plat_top + i * 4.0
		draw_line(Vector2(sx0, sy), Vector2(sx1, sy), Color("#8f8977"), 2.0)

	var tiers := [[276.0, 56.0], [208.0, 50.0], [146.0, 44.0]]
	var y := plat_top
	var roof_rise := 24.0
	for t in tiers:
		var w: float = t[0]
		var h: float = t[1]
		var wall_top := y - h
		_wall(cx - w * 0.5, cx + w * 0.5, wall_top, y, RED_WALL)
		_roof(cx - w * 0.5 - 12.0, cx + w * 0.5 + 12.0, wall_top, roof_rise, GOLD)
		y = wall_top - roof_rise * 0.55

	# top pavilion (double roof)
	var tw := 92.0
	var th := 62.0
	var twall_top := y - th
	_wall(cx - tw * 0.5, cx + tw * 0.5, twall_top, y, RED_WALL)
	_roof(cx - tw * 0.5 - 14.0, cx + tw * 0.5 + 14.0, twall_top, 30.0, GOLD)
	_roof(cx - tw * 0.5 - 7.0, cx + tw * 0.5 + 7.0, twall_top - 20.0, 20.0, GOLD.darkened(0.06))
	# finial
	draw_line(Vector2(cx, twall_top - 40.0), Vector2(cx, twall_top - 52.0), GOLD_DARK, 3.0)
	draw_circle(Vector2(cx, twall_top - 56.0), 4.0, GOLD_DARK)

	# central gate (tier 1)
	draw_rect(Rect2(cx - 16.0, plat_top - 34.0, 32.0, 34.0), INK.darkened(0.3))
	# red banner strips on gate
	draw_rect(Rect2(cx - 3.0, plat_top - 40.0, 6.0, 40.0), RED_WALL_DARK)

func _wall(x0: float, x1: float, y_top: float, y_bottom: float, color: Color) -> void:
	draw_rect(Rect2(x0, y_top, x1 - x0, y_bottom - y_top), color)
	draw_rect(Rect2(x0, y_bottom - 4.0, x1 - x0, 4.0), color.darkened(0.32))
	var cols := 5
	for i in range(1, cols):
		var x := lerpf(x0, x1, float(i) / cols)
		draw_line(Vector2(x, y_top), Vector2(x, y_bottom), color.darkened(0.20), 2.0)
	# windows between columns
	var sec_w := (x1 - x0) / cols
	for i in range(cols):
		var wx := x0 + sec_w * (i + 0.5)
		var wy := y_top + (y_bottom - y_top) * 0.28
		var ww := sec_w * 0.34
		var wh := (y_bottom - y_top) * 0.36
		draw_rect(Rect2(wx - ww * 0.5, wy, ww, wh), INK.darkened(0.35))

func _roof(x0: float, x1: float, y_eave: float, rise: float, color: Color) -> void:
	var w := x1 - x0
	var y_top := y_eave - rise
	var tip := w * 0.07
	var sag := rise * 0.20
	var pts := PackedVector2Array([
		Vector2(x0 - tip, y_eave - sag * 0.5),
		Vector2(x0 + w * 0.22, y_top),
		Vector2(x1 - w * 0.22, y_top),
		Vector2(x1 + tip, y_eave - sag * 0.5),
		Vector2((x0 + x1) * 0.5, y_eave + sag),
	])
	_poly(pts, color)
	draw_line(Vector2(x0 + w * 0.22, y_top), Vector2(x1 - w * 0.22, y_top), color.darkened(0.30), 2.5)
	# eave shadow
	draw_line(Vector2(x0 + w * 0.22, y_top), Vector2(x0, y_eave - sag * 0.5), color.darkened(0.22), 2.0)
	draw_line(Vector2(x1 - w * 0.22, y_top), Vector2(x1, y_eave - sag * 0.5), color.darkened(0.22), 2.0)

func _draw_market(cx: float, base_y: float) -> void:
	# sand patch
	_ellipse(Vector2(cx, base_y - 2.0), Vector2(120.0, 16.0), Color("#cfc4a4"))
	# low wall / gate behind
	draw_rect(Rect2(cx - 110.0, base_y - 78.0, 220.0, 78.0), Color("#b0a98e"))
	draw_rect(Rect2(cx - 110.0, base_y - 86.0, 220.0, 12.0), Color("#8d8570"))
	# arched gate
	_arch(Vector2(cx, base_y), 26.0, 46.0, Color("#6f6755"))
	# dome tents (silk-road style)
	_tent(cx - 70.0, base_y, 74.0, 60.0, Color("#cbb887"))
	_tent(cx + 55.0, base_y, 66.0, 52.0, Color("#bda978"))
	_tent(cx - 6.0, base_y, 60.0, 46.0, Color("#d3c290"))
	# market stall awning (left of gate)
	var sx := cx - 78.0
	draw_rect(Rect2(sx - 14.0, base_y - 26.0, 30.0, 26.0), Color("#8a7c5e"))
	draw_rect(Rect2(sx - 22.0, base_y - 34.0, 46.0, 9.0), Color("#b5a270"))
	draw_line(Vector2(sx - 22.0, base_y - 34.0), Vector2(sx - 22.0, base_y - 30.0), Color("#8d7c58"), 2.0)
	draw_line(Vector2(sx + 24.0, base_y - 34.0), Vector2(sx + 24.0, base_y - 30.0), Color("#8d7c58"), 2.0)

func _tent(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x - w * 0.5, y - h * 0.42, w, h * 0.42), color.darkened(0.06))
	var dome_c := Vector2(x, y - h * 0.42)
	var pts := PackedVector2Array()
	for i in range(21):
		var a := PI + float(i) / 20.0 * PI
		pts.append(dome_c + Vector2(cos(a), sin(a)) * (w * 0.5))
	pts.append(Vector2(x + w * 0.5, y - h * 0.42))
	pts.append(Vector2(x - w * 0.5, y - h * 0.42))
	_poly(pts, color)
	draw_circle(Vector2(x, y - h * 0.42 - w * 0.5 - 4.0), 3.0, color.darkened(0.4))
	# stripes
	for i in range(-2, 3):
		var sx := x + i * w * 0.16
		if absf(sx - x) < w * 0.02:
			continue
		draw_line(Vector2(sx, y - h * 0.42), Vector2(sx, y - h * 0.42 - w * 0.46), color.darkened(0.22), 1.5)
	# door
	draw_rect(Rect2(x - w * 0.14, y - h * 0.30, w * 0.28, h * 0.30), INK.darkened(0.35))

func _arch(c: Vector2, w: float, h: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(17):
		var a := PI + float(i) / 16.0 * PI
		pts.append(Vector2(c.x + cos(a) * w, c.y - h + sin(a) * w))
	pts.append(Vector2(c.x + w, c.y))
	pts.append(Vector2(c.x - w, c.y))
	_poly(pts, color)

func _draw_pagoda(cx: float, base_y: float) -> void:
	# 等比缩小至原来一半：以底部中心为锚点，x/y 均 0.5 缩放（保持比例）
	draw_set_transform(Vector2(cx, base_y), 0.0, Vector2(0.5, 0.5))
	# courtyard（相对坐标）
	draw_rect(Rect2(-120.0, -60.0, 240.0, 60.0), Color("#a29b86"))
	draw_rect(Rect2(-126.0, -72.0, 252.0, 14.0), Color("#7c7563"))
	draw_rect(Rect2(-26.0, -40.0, 52.0, 40.0), INK.darkened(0.32))
	# two small side pavilions
	_wall(-96.0, -40.0, -96.0, -72.0, Color("#a89f88"))
	_roof(-102.0, -34.0, -96.0, 16.0, ROOF_DARK)
	_wall(40.0, 96.0, -96.0, -72.0, Color("#a89f88"))
	_roof(34.0, 102.0, -96.0, 16.0, ROOF_DARK)
	# pagoda tiers
	var tiers := [[104.0, 24.0], [90.0, 22.0], [76.0, 20.0], [62.0, 18.0], [48.0, 16.0]]
	var y := -72.0
	for t in tiers:
		var w: float = t[0]
		var h: float = t[1]
		_wall(-w * 0.5, w * 0.5, y - h, y, STONE)
		_roof(-w * 0.5 - 8.0, w * 0.5 + 8.0, y - h, 14.0, ROOF_DARK)
		y = y - h - 7.0
	# spire
	draw_line(Vector2(0, y), Vector2(0, y - 26.0), ROOF_DARK, 3.0)
	draw_circle(Vector2(0, y - 30.0), 4.0, ROOF_DARK)
	# 恢复主绘制变换
	draw_set_transform(_offset, 0.0, Vector2(_scale, _scale))

func _draw_pond(cx: float, cy: float, rx: float, ry: float) -> void:
	_ellipse(Vector2(cx, cy), Vector2(rx, ry), Color("#8fb094"))
	_ellipse(Vector2(cx, cy), Vector2(rx * 0.97, ry * 0.97), Color("#a3c2a5"))
	# ripples
	for i in range(3):
		draw_arc(Vector2(cx - rx * 0.3, cy - ry * 0.2), rx * (0.18 + 0.12 * i), 0.6, 2.4, 16, Color(1, 1, 1, 0.28), 1.5)
	# lotus leaves
	_lotus_leaf(Vector2(cx - rx * 0.45, cy - ry * 0.1), 14.0)
	_lotus_leaf(Vector2(cx + rx * 0.35, cy + ry * 0.15), 16.0)
	_lotus_leaf(Vector2(cx - rx * 0.05, cy + ry * 0.4), 12.0)
	_lotus_leaf(Vector2(cx + rx * 0.55, cy - ry * 0.3), 12.0)
	# lotus flowers
	_lotus_flower(Vector2(cx - rx * 0.28, cy + ry * 0.28), 1.0)
	_lotus_flower(Vector2(cx + rx * 0.2, cy - ry * 0.2), 0.9)
	# koi hint
	draw_circle(Vector2(cx + rx * 0.05, cy + ry * 0.1), 4.0, Color("#c06a4a"))

func _lotus_leaf(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color("#6f8f6c"))
	draw_line(c, c + Vector2(cos(-0.7), sin(-0.7)) * r, Color("#a3c2a5"), 2.5)

func _lotus_flower(c: Vector2, s: float) -> void:
	var p := Color("#d98a9a")
	var core := Color("#e9c75a")
	for k in range(5):
		var a := float(k) / 5.0 * TAU + 0.5
		var pc := c + Vector2(cos(a), sin(a)) * 3.0 * s
		_ellipse(pc, Vector2(3.2 * s, 1.7 * s), p, a)
	draw_circle(c, 2.4 * s, core)

func _draw_figures() -> void:
	var f := INK_SOFT
	_figure(400.0, 512.0, 16.0, f)
	_figure(710.0, 510.0, 15.0, f)
	_figure(900.0, 508.0, 14.0, f)
	_figure(520.0, 505.0, 13.0, f)
	# camels near market
	_camel(320.0, 476.0, 26.0, INK_SOFT)
	_camel(360.0, 480.0, 22.0, INK_SOFT)
	_camel(300.0, 482.0, 20.0, Color(0.36, 0.32, 0.26, 0.85))

func _figure(x: float, y: float, s: float, color: Color) -> void:
	draw_circle(Vector2(x, y - s * 0.82), s * 0.12, color)
	_poly(PackedVector2Array([
		Vector2(x - s * 0.17, y - s * 0.66),
		Vector2(x + s * 0.17, y - s * 0.66),
		Vector2(x + s * 0.11, y),
		Vector2(x - s * 0.11, y),
	]), color)

func _camel(x: float, y: float, s: float, color: Color) -> void:
	var lw := maxf(s * 0.09, 1.4)
	for lx in [-0.35, -0.06, 0.26, 0.5]:
		draw_line(Vector2(x + lx * s, y), Vector2(x + lx * s, y - s * 0.52), color, lw)
	_ellipse(Vector2(x, y - s * 0.6), Vector2(s * 0.55, s * 0.17), color)
	draw_circle(Vector2(x - s * 0.22, y - s * 0.78), s * 0.16, color)
	draw_circle(Vector2(x + s * 0.04, y - s * 0.78), s * 0.14, color)
	draw_line(Vector2(x + s * 0.38, y - s * 0.52), Vector2(x + s * 0.62, y - s * 0.98), color, lw)
	draw_circle(Vector2(x + s * 0.66, y - s * 1.03), s * 0.09, color)

# ==================== UI ====================
func _draw_ui() -> void:
	_draw_wood_box(60.0, 40.0)
	_draw_badge(640.0, 80.0)
	_draw_bamboo_v(260.0, 176.0, "西域都护府", "40级")
	_draw_bamboo_v(793.0, 176.0, "长安", "45级")
	_draw_bamboo_v(1040.0, 176.0, "？？", "50级")
	_draw_nav_button(PREV_CENTER, "←", "prev")
	_draw_nav_button(NEXT_CENTER, "→", "next")
	_draw_button(1090.0, 620.0, 46.0, "委派")
	_draw_button(1222.0, 620.0, 46.0, "探索")
	_draw_enter_button()
	_draw_back_button()

# 左下角"返回"按钮（回到 Start 标题界面）
func _draw_back_button() -> void:
	var r := BACK_RECT
	var scale := 1.0
	if _pressed_key == "back":
		scale = 0.96
	var rr := Rect2(r.position + Vector2((1.0 - scale) * r.size.x * 0.5, (1.0 - scale) * r.size.y * 0.5), r.size * scale)
	_round_rect_fill(rr, 10.0, WOOD)
	_round_rect_fill(Rect2(rr.position + Vector2(3, 3), rr.size - Vector2(6, 6)), 8.0, WOOD_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in range(3):
		var gy := rr.position.y + rng.randf_range(8.0, rr.size.y - 8.0)
		draw_line(Vector2(rr.position.x + 10.0, gy), Vector2(rr.end.x - 10.0, gy), Color(0, 0, 0, 0.14), 1.0)
	_round_rect_stroke(rr, 10.0, GOLD, 2.0)
	_round_rect_stroke(Rect2(rr.position + Vector2(2, 2), rr.size - Vector2(4, 4)), 8.0, GOLD_DARK, 1.0)
	# 返回箭头 + 文字
	var arrow_x := rr.position.x + 26.0
	var cy := rr.get_center().y
	draw_line(Vector2(arrow_x + 8.0, cy), Vector2(arrow_x - 8.0, cy), Color("#efe6d0"), 3.0)
	draw_line(Vector2(arrow_x - 8.0, cy), Vector2(arrow_x - 2.0, cy - 6.0), Color("#efe6d0"), 3.0)
	draw_line(Vector2(arrow_x - 8.0, cy), Vector2(arrow_x - 2.0, cy + 6.0), Color("#efe6d0"), 3.0)
	_text_center(font_song, "返回", 18.0, Color("#efe6d0"), Vector2(rr.position.x + 70.0, cy))

# 左右切换关卡按钮（← / →）
func _draw_nav_button(c: Vector2, arrow: String, key: String) -> void:
	var r := NAV_R
	if _pressed_key == key:
		r = NAV_R * 0.94
	draw_circle(c, r, Color("#3a352c"))
	draw_circle(c, r * 0.84, Color("#463f36"))
	draw_circle(c, r * 0.60, Color("#524a3e"))
	draw_arc(c, r, 0.0, TAU, 72, GOLD, 4.0)
	draw_arc(c, r - 4.0, 0.0, TAU, 72, GOLD_DARK, 1.5)
	# 水墨箭头
	var al := r * 0.32
	if arrow == "←":
		draw_line(c + Vector2(al, 0), c + Vector2(-al, 0), Color("#f0e1bb"), 4.0)
		draw_line(c + Vector2(-al, 0), c + Vector2(0, -al), Color("#f0e1bb"), 4.0)
		draw_line(c + Vector2(-al, 0), c + Vector2(0, al), Color("#f0e1bb"), 4.0)
	else:
		draw_line(c + Vector2(-al, 0), c + Vector2(al, 0), Color("#f0e1bb"), 4.0)
		draw_line(c + Vector2(al, 0), c + Vector2(0, -al), Color("#f0e1bb"), 4.0)
		draw_line(c + Vector2(al, 0), c + Vector2(0, al), Color("#f0e1bb"), 4.0)

func _draw_enter_button() -> void:
	var r := ENTER_RECT
	_round_rect_fill(r, 14.0, WOOD)
	_round_rect_fill(Rect2(r.position + Vector2(4, 4), r.size - Vector2(8, 8)), 11.0, WOOD_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(5):
		var gy := r.position.y + rng.randf_range(8.0, r.size.y - 8.0)
		draw_line(Vector2(r.position.x + 12.0, gy), Vector2(r.end.x - 12.0, gy), Color(0, 0, 0, 0.14), 1.0)
	_round_rect_stroke(r, 14.0, GOLD, 2.5)
	_round_rect_stroke(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), 12.0, GOLD_DARK, 1.0)
	_text_center(font_song, "进入长安城", 26.0, Color("#efe6d0"), r.get_center())

# 水墨风提示条（"功能正在开发中"）
func _draw_toast() -> void:
	if _toast_time <= 0.0 or _toast_text == "":
		return
	var alpha := 1.0
	var t := _toast_time / TOAST_DURATION
	if t < 0.3:
		alpha = t / 0.3  # 末尾淡出
	elif t > 0.92:
		alpha = (1.0 - t) / 0.08  # 出现渐入
	var w := 260.0
	var h := 56.0
	var r := Rect2((DESIGN_W - w) * 0.5, 330.0, w, h)
	_round_rect_fill(r, 14.0, Color(0.12, 0.10, 0.08, 0.88 * alpha))
	_round_rect_stroke(r, 14.0, Color("#c9a45a", 0.9 * alpha), 2.0)
	_round_rect_stroke(Rect2(r.position + Vector2(3, 3), r.size - Vector2(6, 6)), 11.0, Color("#8a6a3a", 0.6 * alpha), 1.0)
	_text_center(font_song, _toast_text, 22.0, Color("#efe6d0", alpha), r.get_center())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		var pos := (mb.position - _offset) / _scale
		var key := _hit_button(pos)
		if mb.pressed:
			if key != "":
				_pressed_key = key
				queue_redraw()
			elif ENTER_RECT.has_point(pos):
				SceneTransition.goto_scene(MAP_SCENE)
		else:
			if _pressed_key != "":
				if key == _pressed_key:
					if key == "prev" or key == "next":
						_show_toast("关卡正在开发中")
					elif key == "back":
						SceneTransition.goto_scene(START_SCENE)
					else:
						_show_toast("功能正在开发中")
				_pressed_key = ""
				queue_redraw()

# 判断点击命中的按钮（返回/上一关/下一关/归墟探索/委派/探索），未命中返回空串
func _hit_button(pos: Vector2) -> String:
	if BACK_RECT.has_point(pos):
		return "back"
	if pos.distance_to(PREV_CENTER) <= NAV_R:
		return "prev"
	if pos.distance_to(NEXT_CENTER) <= NAV_R:
		return "next"
	if WOODBOX_RECT.has_point(pos):
		return "guixu"
	if pos.distance_to(WEIPAI_CENTER) <= BUTTON_R:
		return "weipai"
	if pos.distance_to(TANSUO_CENTER) <= BUTTON_R:
		return "tansuo"
	return ""

func _show_toast(text: String) -> void:
	_toast_text = text
	_toast_time = TOAST_DURATION
	queue_redraw()

var _redraw_accum := 0.0

func _process(delta: float) -> void:
	var need_redraw := false
	if _toast_time > 0.0:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_toast_time = 0.0
			_toast_text = ""
			need_redraw = true
		elif int(_toast_time * 20.0) != int((_toast_time + delta) * 20.0):
			need_redraw = true
	# 视差滚动：山体（限频重绘，约 30fps，缓解卡顿）
	_redraw_accum += delta
	for i in range(_mountain_offsets.size()):
		_mountain_offsets[i] = fmod(_mountain_offsets[i] + MOUNTAIN_SPEEDS[i] * delta, DESIGN_W * 2.0)
	if _redraw_accum >= 0.033 or need_redraw:
		_redraw_accum = 0.0
		queue_redraw()

func _draw_badge(cx: float, cy: float) -> void:
	var r := 52.0
	draw_circle(Vector2(cx, cy), r, Color(0.91, 0.87, 0.75, 0.94))
	draw_circle(Vector2(cx, cy), r - 2.0, Color(1, 1, 1, 0.05))
	draw_arc(Vector2(cx, cy), r, 0.0, TAU, 56, Color("#b0432f"), 3.2)
	draw_arc(Vector2(cx, cy), r - 7.0, 0.0, TAU, 56, Color("#b0432f"), 1.2)
	_text_center(font_song, "盛唐", 40.0, Color("#5a3b28"), Vector2(cx, cy - 8.0))
	_text_center(font_song, "40-45级", 18.0, Color("#7c5b38"), Vector2(cx, cy + 22.0))

func _draw_wood_box(x: float, y: float) -> void:
	var w := 200.0
	var h := 46.0
	_round_rect_fill(Rect2(x, y, w, h), 10.0, WOOD)
	_round_rect_fill(Rect2(x + 4.0, y + 4.0, w - 8.0, h - 8.0), 8.0, WOOD_DARK)
	# wood grain
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in range(6):
		var gy := y + rng.randf_range(6.0, h - 6.0)
		draw_line(Vector2(x + 8.0, gy), Vector2(x + w - 8.0, gy), Color(0, 0, 0, 0.16), 1.0)
	_round_rect_stroke(Rect2(x, y, w, h), 10.0, Color("#d8c79a"), 2.0)
	_text_center(font_song, "归墟探索", 22.0, Color("#efe6d0"), Vector2(x + w * 0.5, y + h * 0.5))
	# help icon
	var hx := x + w + 24.0
	var hy := y + h * 0.5
	draw_circle(Vector2(hx, hy), 15.0, Color(0.0, 0.0, 0.0, 0.5))
	draw_arc(Vector2(hx, hy), 15.0, 0.0, TAU, 40, Color("#d8c79a"), 2.0)
	_text_center(font_hei, "?", 20.0, Color("#efe6d0"), Vector2(hx, hy))

func _draw_bamboo_v(cx: float, top_y: float, chars: String, subtext: String) -> void:
	var line_h := 27.0
	var pad := 12.0
	var w := line_h + pad * 2.0
	var h := chars.length() * line_h + 44.0
	var x := cx - w * 0.5
	_round_rect_fill(Rect2(x, top_y, w, h), 9.0, BAMBOO)
	_round_rect_fill(Rect2(x + 4.0, top_y + 4.0, w - 8.0, h - 8.0), 7.0, BAMBOO.lightened(0.08))
	# bamboo slat separations
	for i in range(chars.length() + 2):
		var yy := top_y + 10.0 + i * line_h
		draw_line(Vector2(x + 6.0, yy), Vector2(x + w - 6.0, yy), BAMBOO_EDGE, 1.4)
	_round_rect_stroke(Rect2(x, top_y, w, h), 9.0, BAMBOO_EDGE, 1.6)
	# top tie
	draw_rect(Rect2(cx - 3.0, top_y - 5.0, 6.0, 12.0), Color("#8c4a32"))
	# characters (vertical)
	for i in range(chars.length()):
		var cc := chars.substr(i, 1)
		var cy := top_y + 24.0 + i * line_h
		_text_center(font_song, cc, 20.0, Color("#4a3a26"), Vector2(cx, cy))
	# subtext (level)
	_text_center(font_hei, subtext, 14.0, Color("#6a5a3a"), Vector2(cx, top_y + h - 16.0))

func _draw_button(cx: float, cy: float, r: float, text: String) -> void:
	# 按下反馈：轻微缩小
	var pr := r
	if (_pressed_key == "weipai" and text == "委派") or (_pressed_key == "tansuo" and text == "探索"):
		pr = r * 0.94
	draw_circle(Vector2(cx, cy), pr, Color("#3a352c"))
	draw_circle(Vector2(cx, cy), pr * 0.84, Color("#463f36"))
	draw_circle(Vector2(cx, cy), pr * 0.60, Color("#524a3e"))
	# gold double ring
	draw_arc(Vector2(cx, cy), pr, 0.0, TAU, 72, GOLD, 4.5)
	draw_arc(Vector2(cx, cy), pr - 5.0, 0.0, TAU, 72, GOLD_DARK, 1.6)
	# ink cloud pattern
	_cloud_pattern(Vector2(cx, cy), pr * 0.62, Color("#d8b96a"))
	_text_center(font_song, text, 27.0, Color("#f0e1bb"), Vector2(cx, cy))

func _cloud_pattern(c: Vector2, s: float, color: Color) -> void:
	for k in range(3):
		var a0 := float(k) * TAU / 3.0 + 0.6
		var cc := c + Vector2(cos(a0), sin(a0)) * s * 0.36
		draw_arc(cc, s * 0.20, a0 + PI * 0.4, a0 + PI * 1.6, 18, color, 1.6)
		draw_arc(cc, s * 0.13, a0 - PI * 0.6, a0 + PI * 0.7, 16, color, 1.4)
	draw_arc(c, s * 0.17, 0.0, TAU, 22, color, 1.6)

# ==================== helpers ====================
func _text_center(font: Font, text: String, size: float, color: Color, center: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	var baseline_y := center.y + (asc - desc) * 0.5
	draw_string(font, Vector2(center.x - w * 0.5, baseline_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		var tri := PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]])
		draw_colored_polygon(tri, color)

func _ellipse(c: Vector2, radius: Vector2, color: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in range(28):
		var a := float(i) / 28.0 * TAU
		var p := Vector2(cos(a) * radius.x, sin(a) * radius.y)
		if rot != 0.0:
			p = p.rotated(rot)
		pts.append(c + p)
	_poly(pts, color)

func _round_rect_pts(r: Rect2, radius: float) -> PackedVector2Array:
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	var pts := PackedVector2Array()
	var seg := 8
	# top-left
	for i in range(seg + 1):
		var a := PI + float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + radius + cos(a) * radius, y + radius + sin(a) * radius))
	# top-right
	for i in range(seg + 1):
		var a := PI * 1.5 + float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + w - radius + cos(a) * radius, y + radius + sin(a) * radius))
	# bottom-right
	for i in range(seg + 1):
		var a := float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + w - radius + cos(a) * radius, y + h - radius + sin(a) * radius))
	# bottom-left
	for i in range(seg + 1):
		var a := PI * 0.5 + float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + radius + cos(a) * radius, y + h - radius + sin(a) * radius))
	return pts

func _round_rect_fill(r: Rect2, radius: float, color: Color) -> void:
	_poly(_round_rect_pts(r, radius), color)

func _round_rect_stroke(r: Rect2, radius: float, color: Color, width: float) -> void:
	var pts := _round_rect_pts(r, radius)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], color, width)
	draw_line(pts[pts.size() - 1], pts[0], color, width)
