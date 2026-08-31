extends Control
# 列表裁剪容器：自身实现绘制（self 为本容器），clip_contents 将内容裁剪到本容器 rect 内，
# 实现滚动时"遮罩式"裁剪——条目超出面板边框的部分被隐藏。

var overlay  # 引用 ui_overlay（读取 map、纹理、hover 状态）
var kind := ""  # "hist" / "codex"

const BRK := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_GRAPHEME_BOUND

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _draw() -> void:
	if overlay == null or overlay.map == null:
		return
	if kind == "hist":
		_draw_hist_list()
	elif kind == "codex":
		_draw_codex_list()

# ==================== 大事记列表 ====================
func _draw_hist_list() -> void:
	var map = overlay.map
	for i in range(map._timeline.size()):
		var er: Rect2 = map.hist_event_rect(i)
		var local := Rect2(er.position - position, er.size)
		var ev = map._timeline[i]
		var year: int = ev["year"]
		var title := String(ev["title"])
		var desc := String(ev["desc"])
		var active: bool = map._current_year == year
		var key := "hist_%d" % i
		_draw_ink_component(overlay._ink_history_row, local, 7.0, Color(0.16, 0.26, 0.29, 0.8), Color("#f2e6cc", 0.95) if active else Color(0.79, 0.64, 0.36, 0.4), 1.0, key, active)
		_text_left(map.font_song, "%d" % year, 16.0, Color("#fff0aa") if _is_hot(key) else (Color("#f2e6cc") if active else Color("#d8c9a0")), Vector2(local.position.x + 12.0, local.position.y + 17.0))
		_text_left(map.font_hei, title, 15.0, Color("#eaf1f0"), Vector2(local.position.x + 72.0, local.position.y + 17.0))
		_text_left(map.font_hei, desc, 11.0, Color(0.72, 0.76, 0.74), Vector2(local.position.x + 72.0, local.position.y + 31.0))

# ==================== 图鉴条目列表 ====================
func _draw_codex_list() -> void:
	var map = overlay.map
	var entries: Array = map.codex_entries(map._codex_cat)
	var collected: Array = map.codex_collected_list(map._codex_cat)
	var focus: int = clampi(map._codex_focus, 0, maxi(0, entries.size() - 1))
	for i in range(entries.size()):
		var er: Rect2 = map.codex_entry_rect(i)
		var local := Rect2(er.position - position, er.size)
		var e = entries[i]
		var kw := String(e.get("kw", ""))
		var got: bool = collected.has(kw)
		var key := "codex_entry_%d" % i
		var active := i == focus
		_draw_ink_component(overlay._ink_codex_entry_unlocked if got else overlay._ink_codex_entry_locked, local, 5.0, Color(0.16, 0.26, 0.29, 0.8), Color(0.79, 0.64, 0.36, 0.4), 0.92, key, active)
		if active:
			_draw_texture_layer(overlay._ink_gold_dust, Rect2(local.position.x - 20.0, local.position.y + 3.0, local.size.x + 40.0, local.size.y - 6.0), false, 0.24)
			draw_circle(Vector2(local.position.x + 13.0, local.position.y + 16.0), 3.5, Color("#d25b2d", 0.9))
		if got:
			_text_left(map.font_song, kw, 17.0, Color("#f2e6cc"), Vector2(local.position.x + 24.0, local.position.y + 19.0))
			draw_multiline_string(map.font_hei, Vector2(local.position.x + 24.0, local.position.y + 38.0), String(e.get("desc", "")), HORIZONTAL_ALIGNMENT_LEFT, local.size.x - 36.0, 11.0, 1, Color(0.75, 0.78, 0.76, 0.9), BRK)
		else:
			_text_left(map.font_song, "未辨残卷", 16.0, Color(0.64, 0.66, 0.61), Vector2(local.position.x + 24.0, local.position.y + 18.0))
			_text_left(map.font_hei, "尚未发现，去听听市井百姓的闲谈吧", 11.0, Color(0.47, 0.49, 0.45), Vector2(local.position.x + 24.0, local.position.y + 37.0))

# ==================== 绘制辅助（本容器上下文） ====================
func _ca(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

func _is_hot(key: String) -> bool:
	return key != "" and key == overlay._hover_key

func _is_pressed(key: String) -> bool:
	return _is_hot(key) and overlay._mouse_down

func _draw_texture_layer(tex: Texture2D, rect: Rect2, tile: bool, alpha: float) -> void:
	if tex == null or alpha <= 0.0:
		return
	draw_texture_rect(tex, rect, tile, Color(1, 1, 1, alpha))

func _draw_hover_accent(rect: Rect2, radius: float, key: String, alpha := 1.0) -> void:
	if not _is_hot(key):
		return
	var glow := rect.grow(8.0)
	if overlay._ink_hover_mist:
		draw_texture_rect(overlay._ink_hover_mist, glow, false, Color(1, 1, 1, 0.48 * alpha))
	var stroke_alpha := 0.72 * alpha
	var stroke_width := 1.5
	if _is_pressed(key):
		stroke_alpha = 0.96 * alpha
		stroke_width = 2.3
	_round_rect_stroke(rect.grow(1.0), radius + 1.0, Color(0.95, 0.78, 0.36, stroke_alpha), stroke_width)

func _draw_ink_component(tex: Texture2D, rect: Rect2, radius: float, fallback: Color, border: Color, alpha := 1.0, key := "", active := false) -> void:
	if tex:
		draw_texture_rect(tex, rect, false, Color(1, 1, 1, alpha))
	else:
		_round_rect_fill(rect, radius, _ca(fallback, alpha))
		_round_rect_stroke(rect, radius, _ca(border, alpha), 1.0)
	if active:
		_round_rect_stroke(rect.grow(-2.0), maxf(2.0, radius - 1.0), Color(0.93, 0.75, 0.34, 0.34 * alpha), 1.0)
	if key != "":
		_draw_hover_accent(rect, radius, key, alpha)

func _text_center(font: Font, text: String, fs: float, color: Color, center: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	draw_string(font, Vector2(center.x - w * 0.5, center.y + (asc - desc) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

func _text_left(font: Font, text: String, fs: float, color: Color, pos: Vector2) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)

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
