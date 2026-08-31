extends Control

# 百事录·唐 —— 游戏标题界面（Start）
# 水墨山水风格，与 MainMenu 保持一致；包含开始/设置/退出与设置、关于卡片。

const DESIGN_W := 1280.0
const DESIGN_H := 720.0
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

# ---- palette（与 main_menu 一致）----
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

# 标题
const TITLE_POS := Vector2(640.0, 190.0)

# 三个主按钮（竖排，中下）
const BTN_W := 280.0
const BTN_H := 58.0
const BTN_CX := 640.0
const BTN_START := Rect2(BTN_CX - BTN_W * 0.5, 400.0, BTN_W, BTN_H)
const BTN_SETTINGS := Rect2(BTN_CX - BTN_W * 0.5, 476.0, BTN_W, BTN_H)
const BTN_QUIT := Rect2(BTN_CX - BTN_W * 0.5, 552.0, BTN_W, BTN_H)

# 版本号（左下角）与"关于"按钮（右上角）
const VERSION_RECT := Rect2(28.0, 680.0, 260.0, 24.0)
const ABOUT_RECT := Rect2(1160.0, 28.0, 92.0, 40.0)

# 设置卡片
const SETTINGS_RECT := Rect2(340.0, 80.0, 600.0, 560.0)
const SETTINGS_CLOSE := Rect2(SETTINGS_RECT.end.x - 44.0, SETTINGS_RECT.position.y + 12.0, 28.0, 28.0)
# 音量滑块
const VOL_LABEL := Vector2(400.0, 190.0)
const VOL_TRACK := Rect2(400.0, 225.0, 480.0, 14.0)
const VOL_KNOB_R := 12.0
# 语言选项（中/英）
const LANG_LABEL := Vector2(400.0, 300.0)
const LANG_ZH := Rect2(400.0, 330.0, 150.0, 46.0)
const LANG_EN := Rect2(570.0, 330.0, 150.0, 46.0)
# 分辨率选项（三列均布在卡片内，卡片右边界 940，留出内边距）
const RES_LABEL := Vector2(400.0, 420.0)
const RES_OPTS := [
	Rect2(372.0, 450.0, 170.0, 46.0),
	Rect2(555.0, 450.0, 170.0, 46.0),
	Rect2(738.0, 450.0, 170.0, 46.0),
]

# 关于卡片
const ABOUT_PANEL_RECT := Rect2(390.0, 150.0, 500.0, 420.0)
const ABOUT_CLOSE := Rect2(ABOUT_PANEL_RECT.end.x - 44.0, ABOUT_PANEL_RECT.position.y + 12.0, 28.0, 28.0)

var font_song: Font
var font_hei: Font
var _scale := 1.0
var _offset := Vector2.ZERO

var _settings_open := false
var _about_open := false
var _volume := 0.7
var _lang := "zh"          # "zh" / "en"
var _res_idx := 0          # 0:1280x720 1:1920x1080 2:2560x1440

var _hover_key := ""
var _pressed_key := ""
var _mouse_down := false
var _redraw_accum := 0.0

# 视差滚动：四层山偏移（越远越慢）+ 前景建筑
var _mountain_offsets := [0.0, 0.0, 0.0, 0.0]
const MOUNTAIN_SPEEDS := [6.0, 12.0, 20.0, 30.0]   # 远→近
var _buildings: Array = []   # start 前景建筑群（前/中/后三层）
const BUILDING_SPAN := DESIGN_W + 400.0            # 建筑分布横向范围

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

func _ready() -> void:
	_setup_fonts()
	_init_parallax()
	set_process(true)
	queue_redraw()

# 初始化建筑群：分前/中/后三层
# 前层：下边缘与设置按钮中线对齐（y=505），最快、最大、密度低
# 中层：下边缘位于开始与设置按钮中间（y≈467），中速、略小、密度中
# 后层：下边缘与背景山下边缘对齐（y≈455），最慢、最小、密度高
func _init_parallax() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9901
	var types := ["market", "palace", "pagoda", "pavilion", "gate", "tavern", "tower"]
	# 每层：数量（密度）、速度、缩放、下边缘 y、分布跨度
	var layers := [
		{"count": 4, "speed": 62.0, "scale": 1.05, "base_y": 505.0},  # 前层（低密度）
		{"count": 6, "speed": 48.0, "scale": 0.82, "base_y": 467.0},  # 中层（中密度）
		{"count": 9, "speed": 36.0, "scale": 0.58, "base_y": 455.0},  # 后层（高密度）
	]
	var ti := 0
	for layer in layers:
		var cnt: int = layer["count"]
		var span := BUILDING_SPAN
		var seg_w := span / float(cnt)
		for i in range(cnt):
			var x := seg_w * float(i) + rng.randf_range(seg_w * 0.15, seg_w * 0.85)
			_buildings.append({
				"type": types[ti % types.size()],
				"x": x,
				"speed": layer["speed"] + rng.randf_range(-2.0, 2.0),
				"scale": layer["scale"] * rng.randf_range(0.92, 1.08),
				"base_y": layer["base_y"],
			})
			ti += 1
	# 按 base_y 升序排序：后层(y455)先画 → 中层 → 前层(y505)最后画
	# 保证遮挡关系正确：前遮中、中遮后
	_buildings.sort_custom(func(a, b): return float(a["base_y"]) < float(b["base_y"]))

func _setup_fonts() -> void:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Songti SC", "Songti", "STSongti-SC-Regular", "STHeiti", "PingFang SC", "Heiti SC"])
	sf.allow_system_fallback = true
	font_song = sf
	var hf := SystemFont.new()
	hf.font_names = PackedStringArray(["STHeiti", "PingFang SC", "Heiti SC"])
	hf.allow_system_fallback = true
	font_hei = hf

# 中英文案
func _t(zh: String, en: String) -> String:
	return zh if _lang == "zh" else en

func _process(delta: float) -> void:
	var next_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if next_down != _mouse_down:
		_mouse_down = next_down
		queue_redraw()
	# 视差滚动更新（限频重绘，约 30fps）
	_redraw_accum += delta
	for i in range(_mountain_offsets.size()):
		_mountain_offsets[i] = fmod(_mountain_offsets[i] + MOUNTAIN_SPEEDS[i] * delta, DESIGN_W * 2.0)
	for b in _buildings:
		b["x"] -= float(b["speed"]) * delta
		if float(b["x"]) < -300.0:
			b["x"] = BUILDING_SPAN
	if _redraw_accum >= 0.033:
		_redraw_accum = 0.0
		queue_redraw()

func _draw() -> void:
	var s := minf(size.x / DESIGN_W, size.y / DESIGN_H)
	var off := (size - Vector2(DESIGN_W, DESIGN_H) * s) * 0.5
	_scale = s
	_offset = off
	draw_set_transform(off, 0.0, Vector2(s, s))

	_draw_paper()
	_draw_mountains()
	_draw_ground()
	_draw_foreground_buildings()
	_draw_title()
	_draw_main_buttons()
	_draw_version()
	_draw_about_button()
	if _settings_open:
		_draw_settings_panel()
	if _about_open:
		_draw_about_panel()

# ==================== 背景 ====================
func _draw_paper() -> void:
	var bands := 140
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var c := PAPER_TOP.lerp(PAPER_BOT, t)
		var y0 := DESIGN_H * t
		var y1 := DESIGN_H * (t + 1.0 / bands) + 1.0
		draw_rect(Rect2(0, y0, DESIGN_W, y1 - y0), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260818
	for i in range(260):
		var x := rng.randf_range(0, DESIGN_W)
		var y := rng.randf_range(0, DESIGN_H)
		var a := rng.randf_range(0.02, 0.06)
		draw_circle(Vector2(x, y), rng.randf_range(0.5, 1.6), Color(0.42, 0.38, 0.30, a))

# 周期山脊：正弦频率均为 DESIGN_W 的整数倍 → 天然无缝循环
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
	# fog veils
	var steps := 26
	for i in range(steps):
		var t := float(i) / float(steps)
		var a := t * t * 0.55
		var yy0 := lerpf(300.0, 350.0, t)
		var yy1 := lerpf(300.0, 350.0, t + 1.0 / steps)
		draw_rect(Rect2(0, yy0, DESIGN_W, yy1 - yy0), Color(0.91, 0.89, 0.82, a))

# 前景建筑群（前/中/后三层），向左滑动，速度比山快
# 淡入淡出：建筑中线离开界面后才开始淡出（过渡带 60px）
var _build_fade := 1.0
const FADE_BAND := 60.0

func _draw_foreground_buildings() -> void:
	for b in _buildings:
		var x: float = b["x"]
		var sc: float = b["scale"]
		var by: float = b["base_y"]
		# 以该建筑中心为原点做缩放，y 方向以 base_y 为锚
		var cx := x + 200.0 * sc
		var bw := 300.0 * sc
		# 淡入淡出：仅当中线越过界面边界（cx<0 或 cx>DESIGN_W）时才开始过渡
		if cx + bw * 0.5 < 0.0 or cx - bw * 0.5 > DESIGN_W:
			continue
		var fade := 1.0
		if cx < 0.0:
			fade = clampf(cx / FADE_BAND + 1.0, 0.0, 1.0)
		elif cx > DESIGN_W:
			fade = clampf((DESIGN_W + FADE_BAND - cx) / FADE_BAND, 0.0, 1.0)
		if fade <= 0.01:
			continue
		_build_fade = fade
		draw_set_transform(Vector2(cx, by), 0.0, Vector2(sc, sc))
		match String(b["type"]):
			"market":
				_draw_building_market(fade)
			"palace":
				_draw_building_palace(fade)
			"pagoda":
				_draw_building_pagoda(fade)
			"pavilion":
				_draw_building_pavilion(fade)
			"gate":
				_draw_building_gate(fade)
			"tavern":
				_draw_building_tavern(fade)
			"tower":
				_draw_building_tower(fade)
		draw_set_transform(_offset, 0.0, Vector2(_scale, _scale))

func _draw_ground() -> void:
	draw_rect(Rect2(0, 452.0, DESIGN_W, DESIGN_H - 452.0), Color("#d9cfb0"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(90):
		var x := rng.randf_range(0, DESIGN_W)
		var y := rng.randf_range(458.0, DESIGN_H)
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(4, 16), y + rng.randf_range(-2, 2)), Color(0.40, 0.36, 0.26, 0.05), 0.8)

# ==================== 建筑绘制（相对坐标，原点为建筑底部中心）====================
func _draw_building_market(fade := 1.0) -> void:
	# 市集：沙地 + 矮墙 + 拱门 + 圆顶帐篷 + 摊位
	_ellipse(Vector2(0, -2.0), Vector2(120.0, 16.0), _ca(Color("#cfc4a4"), fade))
	draw_rect(Rect2(-110.0, -78.0, 220.0, 78.0), _ca(Color("#b0a98e"), fade))
	draw_rect(Rect2(-110.0, -86.0, 220.0, 12.0), _ca(Color("#8d8570"), fade))
	_arch(Vector2(0, 0), 26.0, 46.0, _ca(Color("#6f6755"), fade))
	_tent(-70.0, 0.0, 74.0, 60.0, _ca(Color("#cbb887"), fade))
	_tent(55.0, 0.0, 66.0, 52.0, _ca(Color("#bda978"), fade))
	_tent(-6.0, 0.0, 60.0, 46.0, _ca(Color("#d3c290"), fade))
	draw_rect(Rect2(-92.0, -26.0, 30.0, 26.0), _ca(Color("#8a7c5e"), fade))
	draw_rect(Rect2(-100.0, -34.0, 46.0, 9.0), _ca(Color("#b5a270"), fade))

func _draw_building_palace(fade := 1.0) -> void:
	# 宫殿：石台 + 三层殿堂 + 金顶
	var pw := 330.0
	var plat_top := -10.0
	_poly(PackedVector2Array([Vector2(-pw * 0.5, plat_top), Vector2(pw * 0.5, plat_top), Vector2(pw * 0.5 - 24.0, 0), Vector2(-pw * 0.5 + 24.0, 0)]), _ca(Color("#b7b19e"), fade))
	for i in range(6):
		var sy := plat_top + i * 4.0
		draw_line(Vector2(-22.0, sy), Vector2(22.0, sy), _ca(Color("#8f8977"), fade), 2.0)
	var tiers := [[276.0, 56.0], [208.0, 50.0], [146.0, 44.0]]
	var y := plat_top
	var roof_rise := 24.0
	for t in tiers:
		var w: float = t[0]
		var h: float = t[1]
		var wall_top := y - h
		_wall(-w * 0.5, w * 0.5, wall_top, y, _ca(RED_WALL, fade))
		_roof(-w * 0.5 - 12.0, w * 0.5 + 12.0, wall_top, roof_rise, _ca(GOLD, fade))
		y = wall_top - roof_rise * 0.55
	var tw := 92.0
	var th := 62.0
	var twall_top := y - th
	_wall(-tw * 0.5, tw * 0.5, twall_top, y, _ca(RED_WALL, fade))
	_roof(-tw * 0.5 - 14.0, tw * 0.5 + 14.0, twall_top, 30.0, _ca(GOLD, fade))
	_roof(-tw * 0.5 - 7.0, tw * 0.5 + 7.0, twall_top - 20.0, 20.0, _ca(GOLD.darkened(0.06), fade))
	draw_line(Vector2(0, twall_top - 40.0), Vector2(0, twall_top - 52.0), _ca(GOLD_DARK, fade), 3.0)
	draw_circle(Vector2(0, twall_top - 56.0), 4.0, _ca(GOLD_DARK, fade))
	draw_rect(Rect2(-16.0, plat_top - 34.0, 32.0, 34.0), _ca(INK.darkened(0.3), fade))

func _draw_building_pagoda(fade := 1.0) -> void:
	# 佛塔：五层密檐塔
	draw_rect(Rect2(-120.0, -60.0, 240.0, 60.0), _ca(Color("#a29b86"), fade))
	draw_rect(Rect2(-126.0, -72.0, 252.0, 14.0), _ca(Color("#7c7563"), fade))
	_wall(-96.0, -40.0, -96.0, -72.0, _ca(Color("#a89f88"), fade))
	_roof(-102.0, -34.0, -96.0, 16.0, _ca(ROOF_DARK, fade))
	_wall(40.0, 96.0, -96.0, -72.0, _ca(Color("#a89f88"), fade))
	_roof(34.0, 102.0, -96.0, 16.0, _ca(ROOF_DARK, fade))
	var tiers := [[104.0, 24.0], [90.0, 22.0], [76.0, 20.0], [62.0, 18.0], [48.0, 16.0]]
	var y := -72.0
	for t in tiers:
		var w: float = t[0]
		var h: float = t[1]
		_wall(-w * 0.5, w * 0.5, y - h, y, _ca(STONE, fade))
		_roof(-w * 0.5 - 8.0, w * 0.5 + 8.0, y - h, 14.0, _ca(ROOF_DARK, fade))
		y = y - h - 7.0
	draw_line(Vector2(0, y), Vector2(0, y - 26.0), _ca(ROOF_DARK, fade), 3.0)
	draw_circle(Vector2(0, y - 30.0), 4.0, _ca(ROOF_DARK, fade))

func _draw_building_pavilion(fade := 1.0) -> void:
	# 八角凉亭：石座 + 六柱 + 攒尖顶
	draw_rect(Rect2(-56.0, -10.0, 112.0, 10.0), _ca(Color("#b7b19e"), fade))
	var col_x := [-48.0, -29.0, -10.0, 10.0, 29.0, 48.0]
	for x in col_x:
		draw_line(Vector2(x, -10.0), Vector2(x, -44.0), _ca(Color("#6f6755"), fade), 3.0)
	_roof(-58.0, 58.0, -44.0, 30.0, _ca(Color("#8a6a3a"), fade))
	_roof(-40.0, 40.0, -52.0, 18.0, _ca(Color("#a8823e"), fade))
	draw_line(Vector2(0, -66.0), Vector2(0, -74.0), _ca(GOLD_DARK, fade), 2.5)
	draw_circle(Vector2(0, -76.0), 3.0, _ca(GOLD_DARK, fade))

func _draw_building_gate(fade := 1.0) -> void:
	# 城门楼：城台 + 券门 + 二层楼阁
	draw_rect(Rect2(-90.0, -56.0, 180.0, 56.0), _ca(Color("#a89f88"), fade))
	draw_rect(Rect2(-90.0, -62.0, 180.0, 10.0), _ca(Color("#7c7563"), fade))
	_arch(Vector2(0, 0), 24.0, 38.0, _ca(Color("#4a4036"), fade))
	_wall(-52.0, 52.0, -108.0, -56.0, _ca(RED_WALL, fade))
	_roof(-62.0, 62.0, -108.0, 20.0, _ca(Color("#8a6a3a"), fade))
	_wall(-32.0, 32.0, -138.0, -108.0, _ca(RED_WALL, fade))
	_roof(-40.0, 40.0, -138.0, 16.0, _ca(ROOF_DARK, fade))
	draw_line(Vector2(0, -150.0), Vector2(0, -156.0), _ca(GOLD_DARK, fade), 2.0)

func _draw_building_tavern(fade := 1.0) -> void:
	# 酒肆茶楼：两层木楼 + 旗幡
	draw_rect(Rect2(-48.0, -60.0, 96.0, 60.0), _ca(Color("#8a7c5e"), fade))
	draw_rect(Rect2(-52.0, -66.0, 104.0, 10.0), _ca(Color("#6f6755"), fade))
	draw_line(Vector2(-20.0, -30.0), Vector2(-20.0, 0.0), _ca(Color("#5b4028"), fade), 2.0)
	draw_line(Vector2(20.0, -30.0), Vector2(20.0, 0.0), _ca(Color("#5b4028"), fade), 2.0)
	draw_rect(Rect2(-12.0, -40.0, 24.0, 40.0), _ca(INK.darkened(0.3), fade))
	draw_rect(Rect2(-36.0, -60.0, 26.0, 22.0), _ca(Color("#3a362e"), fade))
	draw_rect(Rect2(10.0, -60.0, 26.0, 22.0), _ca(Color("#3a362e"), fade))
	_roof(-56.0, 56.0, -66.0, 20.0, _ca(Color("#5b4028"), fade))
	# 旗幡
	draw_line(Vector2(30.0, -86.0), Vector2(30.0, -110.0), _ca(Color("#5b4028"), fade), 2.0)
	var flag := PackedVector2Array([Vector2(30.0, -110.0), Vector2(52.0, -104.0), Vector2(30.0, -96.0)])
	_poly(flag, _ca(Color("#a83f35"), fade))

func _draw_building_tower(fade := 1.0) -> void:
	# 望楼/高塔：四层 + 塔刹（比佛塔细高）
	draw_rect(Rect2(-44.0, -8.0, 88.0, 8.0), _ca(Color("#a29b86"), fade))
	var tiers := [[70.0, 26.0], [58.0, 24.0], [46.0, 22.0], [34.0, 20.0]]
	var y := -8.0
	for t in tiers:
		var w: float = t[0]
		var h: float = t[1]
		_wall(-w * 0.5, w * 0.5, y - h, y, _ca(STONE, fade))
		_roof(-w * 0.5 - 6.0, w * 0.5 + 6.0, y - h, 12.0, _ca(ROOF_DARK, fade))
		y = y - h - 6.0
	draw_line(Vector2(0, y), Vector2(0, y - 22.0), _ca(ROOF_DARK, fade), 2.5)
	draw_circle(Vector2(0, y - 25.0), 3.5, _ca(ROOF_DARK, fade))

# ---- 建筑基础构件 ----
func _wall(x0: float, x1: float, y_top: float, y_bottom: float, color: Color) -> void:
	color = _ca(color, _build_fade)
	draw_rect(Rect2(x0, y_top, x1 - x0, y_bottom - y_top), color)
	draw_rect(Rect2(x0, y_bottom - 4.0, x1 - x0, 4.0), color.darkened(0.32))
	var cols := 5
	for i in range(1, cols):
		var x := lerpf(x0, x1, float(i) / cols)
		draw_line(Vector2(x, y_top), Vector2(x, y_bottom), color.darkened(0.20), 2.0)

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
	_poly(pts, _ca(color, _build_fade))
	draw_line(Vector2(x0 + w * 0.22, y_top), Vector2(x1 - w * 0.22, y_top), _ca(color, _build_fade).darkened(0.30), 2.5)

func _tent(x: float, y: float, w: float, h: float, color: Color) -> void:
	var col := _ca(color, _build_fade)
	draw_rect(Rect2(x - w * 0.5, y - h * 0.42, w, h * 0.42), col.darkened(0.06))
	var dome_c := Vector2(x, y - h * 0.42)
	var pts := PackedVector2Array()
	for i in range(21):
		var a := PI + float(i) / 20.0 * PI
		pts.append(dome_c + Vector2(cos(a), sin(a)) * (w * 0.5))
	pts.append(Vector2(x + w * 0.5, y - h * 0.42))
	pts.append(Vector2(x - w * 0.5, y - h * 0.42))
	_poly(pts, col)
	draw_circle(Vector2(x, y - h * 0.42 - w * 0.5 - 4.0), 3.0, col.darkened(0.4))

func _arch(c: Vector2, w: float, h: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(17):
		var a := PI + float(i) / 16.0 * PI
		pts.append(Vector2(c.x + cos(a) * w, c.y - h + sin(a) * w))
	pts.append(Vector2(c.x + w, c.y))
	pts.append(Vector2(c.x - w, c.y))
	_poly(pts, _ca(color, _build_fade))

func _ca(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

# ==================== 标题 ====================
func _draw_title() -> void:
	var r := Rect2(TITLE_POS.x - 260.0, TITLE_POS.y - 60.0, 520.0, 100.0)
	_round_rect_fill(r, 16.0, Color(0.13, 0.10, 0.08, 0.30))
	_round_rect_stroke(r, 16.0, Color("#c9a45a", 0.55), 2.0)
	_text_center(font_song, "百事录·唐", 64.0, Color("#3a2c1c"), Vector2(TITLE_POS.x, TITLE_POS.y))
	_text_center(font_hei, _t("—— 长安盛景，百事留录 ——", "— Record of Tang Splendor —"), 15.0, Color("#7c5b38"), Vector2(TITLE_POS.x, TITLE_POS.y + 42.0))

# ==================== 主按钮 ====================
func _draw_main_buttons() -> void:
	_draw_wood_button(BTN_START, _t("开始", "Start"), "start")
	_draw_wood_button(BTN_SETTINGS, _t("设置", "Settings"), "settings")
	_draw_wood_button(BTN_QUIT, _t("退出", "Quit"), "quit")

func _draw_wood_button(r: Rect2, text: String, key: String) -> void:
	var scale := 1.0
	if _pressed_key == key:
		scale = 0.96
	var rr := Rect2(r.position + Vector2((1.0 - scale) * r.size.x * 0.5, (1.0 - scale) * r.size.y * 0.5), r.size * scale)
	_round_rect_fill(rr, 14.0, WOOD)
	_round_rect_fill(Rect2(rr.position + Vector2(4, 4), rr.size - Vector2(8, 8)), 11.0, WOOD_DARK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(5):
		var gy := rr.position.y + rng.randf_range(8.0, rr.size.y - 8.0)
		draw_line(Vector2(rr.position.x + 12.0, gy), Vector2(rr.end.x - 12.0, gy), Color(0, 0, 0, 0.14), 1.0)
	_round_rect_stroke(rr, 14.0, GOLD, 2.5)
	_round_rect_stroke(Rect2(rr.position + Vector2(2, 2), rr.size - Vector2(4, 4)), 12.0, GOLD_DARK, 1.0)
	if _is_hot(key):
		_round_rect_stroke(rr.grow(3.0), 16.0, Color(1.0, 0.9, 0.55, 0.6), 2.0)
	_text_center(font_song, text, 26.0, Color("#efe6d0"), rr.get_center())

func _draw_version() -> void:
	_text_left(font_hei, _t("版本号 v1.0.0.1", "Version v1.0.0.1"), 13.0, Color("#6a5a3a", 0.9), VERSION_RECT.position)

func _draw_about_button() -> void:
	var hot := _is_hot("about")
	var r := ABOUT_RECT
	_round_rect_fill(r, 10.0, Color(0.13, 0.10, 0.08, 0.55) if hot else Color(0.13, 0.10, 0.08, 0.35))
	_round_rect_stroke(r, 10.0, GOLD, 1.8)
	_text_center(font_hei, _t("关于", "About"), 16.0, Color("#efe6d0"), r.get_center())

# ==================== 设置卡片 ====================
func _draw_settings_panel() -> void:
	var pr: Rect2 = SETTINGS_RECT
	_draw_card(pr, 12.0)
	_text_center(font_song, _t("设置", "Settings"), 28.0, Color("#f2e6cc"), Vector2(pr.get_center().x, pr.position.y + 22.0))
	_draw_ink_close(SETTINGS_CLOSE, "settings_close")

	# 音量
	_text_left(font_hei, _t("音量", "Volume"), 17.0, Color("#e8dfc8"), VOL_LABEL)
	_round_rect_fill(VOL_TRACK, 7.0, Color(0.05, 0.06, 0.06, 0.8))
	_round_rect_fill(Rect2(VOL_TRACK.position.x, VOL_TRACK.position.y, VOL_TRACK.size.x * _volume, VOL_TRACK.size.y), 7.0, GOLD)
	_round_rect_stroke(VOL_TRACK, 7.0, Color("#c9a45a", 0.5), 1.0)
	var knob := Vector2(VOL_TRACK.position.x + VOL_TRACK.size.x * _volume, VOL_TRACK.get_center().y)
	draw_circle(knob, VOL_KNOB_R, Color("#efe6d0"))
	draw_arc(knob, VOL_KNOB_R, 0.0, TAU, 24, GOLD, 2.0)
	_text_right(font_hei, "%d%%" % int(_volume * 100.0), 14.0, Color("#e8dfc8"), Vector2(VOL_TRACK.end.x, VOL_LABEL.y))

	# 语言
	_text_left(font_hei, _t("语言", "Language"), 17.0, Color("#e8dfc8"), LANG_LABEL)
	_draw_option_btn(LANG_ZH, _t("中文", "中文"), _lang == "zh", "lang_zh")
	_draw_option_btn(LANG_EN, _t("英文", "English"), _lang == "en", "lang_en")

	# 分辨率
	_text_left(font_hei, _t("画面大小", "Resolution"), 17.0, Color("#e8dfc8"), RES_LABEL)
	for i in range(RES_OPTS.size()):
		_draw_option_btn(RES_OPTS[i], "%dx%d" % [RESOLUTIONS[i].x, RESOLUTIONS[i].y], _res_idx == i, "res_%d" % i)

func _draw_option_btn(r: Rect2, text: String, active: bool, key: String) -> void:
	var bg := Color(0.79, 0.64, 0.36, 0.85) if active else Color(0.12, 0.16, 0.16, 0.6)
	_round_rect_fill(r, 8.0, bg)
	_round_rect_stroke(r, 8.0, Color("#c9a45a", 0.7), 1.5)
	if _is_hot(key):
		_round_rect_stroke(r.grow(2.0), 10.0, Color(1.0, 0.9, 0.55, 0.7), 1.8)
	_text_center(font_hei, text, 15.0, Color("#1f1810") if active else Color("#eaf1f0"), r.get_center())

# ==================== 关于卡片 ====================
func _draw_about_panel() -> void:
	var pr: Rect2 = ABOUT_PANEL_RECT
	_draw_card(pr, 12.0)
	_text_center(font_song, _t("关于", "About"), 26.0, Color("#f2e6cc"), Vector2(pr.get_center().x, pr.position.y + 22.0))
	_draw_ink_close(ABOUT_CLOSE, "about_close")
	_text_center(font_hei, _t("（内容待编辑）", "(To be edited)"), 16.0, Color("#b8aa87", 0.8), pr.get_center())

# ==================== 卡片通用绘制 ====================
func _draw_card(pr: Rect2, radius: float) -> void:
	_round_rect_fill(Rect2(pr.position + Vector2(2, 4), pr.size), radius, Color(0, 0, 0, 0.35))
	_round_rect_fill(pr, radius, Color(0.03, 0.05, 0.05, 0.94))
	_round_rect_stroke(pr, radius, Color("#c9a45a", 0.75), 2.0)
	# 顶部标题条
	_round_rect_fill(Rect2(pr.position, Vector2(pr.size.x, 44)), radius, Color(0.10, 0.13, 0.12, 0.9))
	_round_rect_stroke(Rect2(pr.position, Vector2(pr.size.x, 44)), radius, Color("#c9a45a", 0.5), 1.0)

func _draw_ink_close(r: Rect2, key: String) -> void:
	var hot := _is_hot(key)
	var pressed := _is_pressed(key)
	_round_rect_fill(r, 6.0, Color(0.81, 0.18, 0.15, 0.9) if pressed else (Color(0.75, 0.20, 0.16, 0.8) if hot else Color(0.65, 0.16, 0.13, 0.7)))
	_round_rect_stroke(r, 6.0, Color("#a01c16"), 1.5)
	var c := r.get_center()
	draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), Color.WHITE, 2.5)
	draw_line(c + Vector2(-4, 4), c + Vector2(4, -4), Color.WHITE, 2.5)

# ==================== 交互 ====================
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		var pos := (mb.position - _offset) / _scale
		if mb.pressed:
			_pressed_key = _hit(pos)
			_mouse_down = true
			queue_redraw()
		else:
			var released := _hit(pos)
			if released != "" and released == _pressed_key:
				_activate(released)
			_pressed_key = ""
			_mouse_down = false
			queue_redraw()

# 命中检测（面板优先）
func _hit(pos: Vector2) -> String:
	if _settings_open:
		if SETTINGS_CLOSE.has_point(pos):
			return "settings_close"
		if _hit_option(pos) != "":
			return _hit_option(pos)
		if VOL_TRACK.grow(16.0).has_point(pos):
			return "vol"
		if SETTINGS_RECT.has_point(pos):
			return "settings_panel"
		# 卡片外点击关闭
		return "settings_close_outer"
	if _about_open:
		if ABOUT_CLOSE.has_point(pos):
			return "about_close"
		if ABOUT_PANEL_RECT.has_point(pos):
			return "about_panel"
		return "about_close_outer"
	if ABOUT_RECT.has_point(pos):
		return "about"
	if BTN_START.has_point(pos):
		return "start"
	if BTN_SETTINGS.has_point(pos):
		return "settings"
	if BTN_QUIT.has_point(pos):
		return "quit"
	return ""

func _hit_option(pos: Vector2) -> String:
	if LANG_ZH.has_point(pos):
		return "lang_zh"
	if LANG_EN.has_point(pos):
		return "lang_en"
	for i in range(RES_OPTS.size()):
		if RES_OPTS[i].has_point(pos):
			return "res_%d" % i
	return ""

func _activate(key: String) -> void:
	match key:
		"start":
			SceneTransition.goto_scene(MAIN_MENU_SCENE)
		"settings":
			_settings_open = true
		"quit":
			get_tree().quit()
		"about":
			_about_open = true
		"settings_close", "settings_close_outer":
			_settings_open = false
		"about_close", "about_close_outer":
			_about_open = false
		"lang_zh":
			_lang = "zh"
		"lang_en":
			_lang = "en"
		"res_0", "res_1", "res_2":
			var idx := int(key.substr(4))
			_res_idx = idx
			get_window().size = RESOLUTIONS[idx]
		"vol":
			var pos := (get_viewport().get_mouse_position() - _offset) / _scale
			_volume = clampf((pos.x - VOL_TRACK.position.x) / VOL_TRACK.size.x, 0.0, 1.0)
	queue_redraw()

func _is_hot(key: String) -> bool:
	return key != "" and key == _hover_key

func _is_pressed(key: String) -> bool:
	return _is_hot(key) and _mouse_down

# ==================== helpers ====================
func _text_center(font: Font, text: String, size: float, color: Color, center: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var asc := font.get_ascent(size)
	var desc := font.get_descent(size)
	var baseline_y := center.y + (asc - desc) * 0.5
	draw_string(font, Vector2(center.x - w * 0.5, baseline_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_left(font: Font, text: String, size: float, color: Color, pos: Vector2) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _text_right(font: Font, text: String, size: float, color: Color, right: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(right.x - w, right.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)

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
	for i in range(seg + 1):
		var a := PI + float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + radius + cos(a) * radius, y + radius + sin(a) * radius))
	for i in range(seg + 1):
		var a := PI * 1.5 + float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + w - radius + cos(a) * radius, y + radius + sin(a) * radius))
	for i in range(seg + 1):
		var a := float(i) / seg * (PI * 0.5)
		pts.append(Vector2(x + w - radius + cos(a) * radius, y + h - radius + sin(a) * radius))
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
