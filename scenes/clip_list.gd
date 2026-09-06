extends Control
# 
#

var overlay  # 
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
	elif kind == "codex_cards":
		_draw_codex_cards()

# ==================== 图鉴知识卡片轮播（裁剪容器内，超出外框隐藏） ====================
func _draw_codex_cards() -> void:
	var map = overlay.map
	var area: Rect2 = map.codex_card_area()
	var csize: Vector2 = map.codex_card_size()
	var stride: float = map.codex_card_stride()
	var entries: Array = map._cards_of_type(map._card_type_idx)
	var center_screen := Vector2(area.get_center().x, area.get_center().y)
	var anim: float = map._card_focus_anim
	var page_anim: float = map._card_page_anim
	for i in range(entries.size()):
		var d := anim - float(i)
		if absf(d) > 1.7:
			continue
		var fd := clampf(absf(d), 0.0, 1.0)
		var focus_amount := 1.0 - fd
		var sc := lerpf(1.0, 0.84, fd)
		var w := csize.x * sc
		var h := csize.y * sc
		var cx := center_screen.x - d * stride
		var card_screen := Rect2(cx - w * 0.5, center_screen.y - h * 0.5, w, h)
		var card := Rect2(card_screen.position - position, card_screen.size)
		_draw_knowledge_card(card, entries[i], focus_amount, page_anim, map)

func _draw_knowledge_card(card: Rect2, e: Dictionary, focus_amount: float, page_anim: float, map) -> void:
	var page: int = clampi(int(round(page_anim)), 0, 2)
	var flip := absf(page_anim - float(page))
	var scale_x := cos(flip * PI * 0.5)
	scale_x = maxf(scale_x, 0.01)
	var center_x := card.position.x + card.size.x * 0.5
	var half_w := card.size.x * 0.5 * scale_x
	var flipped_card := Rect2(center_x - half_w, card.position.y, half_w * 2.0, card.size.y)
	if page == 0:
		_draw_card_front(flipped_card, e, focus_amount, map)
	elif page == 1:
		_draw_card_back(flipped_card, e, focus_amount, map)
	else:
		_draw_card_spatial(flipped_card, e, focus_amount, map)
	if focus_amount < 1.0:
		var wht := (1.0 - focus_amount) * 0.5
		_round_rect_fill(card, 8.0, Color(0.0, 0.0, 0.0, wht))

func _draw_card_front(card: Rect2, e: Dictionary, focus: float, map) -> void:
	_round_rect_fill(card, 8.0, Color("#1a1510"))
	_round_rect_stroke(card, 8.0, Color(0.78, 0.65, 0.38, 0.6), 1.5)
	if focus >= 0.98:
		_round_rect_stroke(card.grow(-2.0), 6.0, Color(0.93, 0.75, 0.34, 0.5), 1.4)
	var img_path := String(e.get("image", ""))
	var img_h := card.size.y * 0.45
	var img_r := Rect2(card.position.x + 10.0, card.position.y + 10.0, card.size.x - 20.0, img_h)
	if img_path != "" and ResourceLoader.exists(img_path):
		var tex = load(img_path)
		if tex:
			draw_texture_rect(tex, img_r, false)
	else:
		_round_rect_fill(img_r, 4.0, Color("#2a2318"))
	var img_note := String(e.get("imageNote", ""))
	if img_note != "":
		_text_left(map.font_hei, img_note, 9.0, Color(0.7, 0.6, 0.4, 0.8), Vector2(img_r.position.x + 4.0, img_r.end.y - 6.0))
	var text_y := img_r.end.y + 12.0
	var pinyin := String(e.get("pinyin", ""))
	if pinyin != "":
		_text_left(map.font_hei, pinyin, 11.0, Color(0.7, 0.6, 0.4), Vector2(card.position.x + 14.0, text_y + 4.0))
		text_y += 18.0
	var name := String(e.get("name", ""))
	_text_left(map.font_song, name, 24.0, Color("#f0e0b8"), Vector2(card.position.x + 14.0, text_y + 20.0))
	text_y += 28.0
	var subtitle := String(e.get("subtitle", ""))
	if subtitle != "":
		_text_left(map.font_hei, subtitle, 12.0, Color(0.85, 0.75, 0.5), Vector2(card.position.x + 14.0, text_y + 6.0))
		text_y += 18.0
	var period := String(e.get("period", ""))
	if period != "":
		_text_left(map.font_hei, period, 10.0, Color(0.6, 0.5, 0.35), Vector2(card.position.x + 14.0, text_y + 4.0))
		text_y += 16.0
	var summary := String(e.get("summary", ""))
	if summary != "":
		var summary_y := card.end.y - 80.0
		draw_multiline_string(map.font_hei, Vector2(card.position.x + 14.0, summary_y), summary, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 28.0, 13.0, 3, Color(0.8, 0.72, 0.55), BRK)
	var symbol := String(e.get("symbol", ""))
	if symbol != "":
		var seal_r := Rect2(card.end.x - 46.0, card.end.y - 46.0, 34.0, 34.0)
		_round_rect_fill(seal_r, 3.0, Color(0.72, 0.18, 0.12, 0.85))
		_text_center(map.font_song, symbol, 16.0, Color("#f0e0b8"), seal_r.get_center())

func _draw_card_back(card: Rect2, e: Dictionary, focus: float, map) -> void:
	_round_rect_fill(card, 8.0, Color("#1c1812"))
	_round_rect_stroke(card, 8.0, Color(0.78, 0.65, 0.38, 0.6), 1.5)
	if focus >= 0.98:
		_round_rect_stroke(card.grow(-2.0), 6.0, Color(0.93, 0.75, 0.34, 0.5), 1.4)
	var y := card.position.y + 16.0
	var type_label := String(e.get("typeLabel", ""))
	var name := String(e.get("name", ""))
	_text_left(map.font_song, name, 20.0, Color("#f0e0b8"), Vector2(card.position.x + 14.0, y + 16.0))
	var badge_r := Rect2(card.position.x + 14.0, y + 24.0, float(type_label.length()) * 14.0 + 12.0, 22.0)
	_round_rect_fill(badge_r, 3.0, Color(0.72, 0.18, 0.12, 0.7))
	_text_center(map.font_hei, type_label, 11.0, Color("#f0e0b8"), badge_r.get_center())
	y += 56.0
	draw_line(Vector2(card.position.x + 14.0, y), Vector2(card.end.x - 14.0, y), Color(0.6, 0.5, 0.3, 0.4), 1.0)
	y += 10.0
	var facts: Array = e.get("facts", [])
	for f in facts:
		if f is Array and f.size() >= 2:
			var label := String(f[0])
			var value := String(f[1])
			_text_left(map.font_hei, label, 11.0, Color(0.6, 0.5, 0.35), Vector2(card.position.x + 14.0, y + 10.0))
			_text_left(map.font_song, value, 13.0, Color("#e0d0a8"), Vector2(card.position.x + 70.0, y + 10.0))
			y += 22.0
	y += 8.0
	draw_line(Vector2(card.position.x + 14.0, y), Vector2(card.end.x - 14.0, y), Color(0.6, 0.5, 0.3, 0.4), 1.0)
	y += 10.0
	var ev_type := String(e.get("evidenceType", ""))
	if ev_type != "":
		_text_left(map.font_hei, ev_type, 10.0, Color(0.5, 0.7, 0.5), Vector2(card.position.x + 14.0, y + 8.0))
		y += 18.0
	var quote := String(e.get("quote", ""))
	if quote != "":
		draw_multiline_string(map.font_song, Vector2(card.position.x + 20.0, y + 12.0), quote, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 40.0, 12.0, 4, Color(0.85, 0.78, 0.58), BRK)
		y += 60.0
	var source := String(e.get("source", ""))
	if source != "":
		_text_left(map.font_hei, "—— " + source, 10.0, Color(0.55, 0.48, 0.35), Vector2(card.position.x + 14.0, y + 4.0))

func _draw_card_spatial(card: Rect2, e: Dictionary, focus: float, map) -> void:
	_round_rect_fill(card, 8.0, Color("#141820"))
	_round_rect_stroke(card, 8.0, Color(0.5, 0.6, 0.7, 0.5), 1.5)
	if focus >= 0.98:
		_round_rect_stroke(card.grow(-2.0), 6.0, Color(0.4, 0.6, 0.8, 0.4), 1.4)
	var card_type := String(e.get("type", ""))
	var spatial: Dictionary = map._spatial_info
	var info: Dictionary = spatial.get(card_type, {})
	var text := String(info.get("text", ""))
	var src := String(info.get("source", ""))
	var y := card.position.y + 20.0
	_text_center(map.font_song, "空间关系 · " + String(e.get("typeLabel", "")), 16.0, Color("#a0c0d8"), Vector2(card.get_center().x, y + 8.0))
	y += 32.0
	draw_line(Vector2(card.position.x + 20.0, y), Vector2(card.end.x - 20.0, y), Color(0.4, 0.5, 0.6, 0.4), 1.0)
	y += 14.0
	if text != "":
		draw_multiline_string(map.font_hei, Vector2(card.position.x + 16.0, y + 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 32.0, 13.0, 12, Color(0.75, 0.82, 0.88), BRK)
	if src != "":
		_text_left(map.font_hei, "—— " + src, 10.0, Color(0.5, 0.55, 0.6), Vector2(card.position.x + 16.0, card.end.y - 24.0))

# ==================== 大事记列表 ====================
func _draw_hist_list() -> void:
	var map = overlay.map
	var detail_e: float = map._ease_in_out_cubic(clampf(map._hist_detail_anim, 0.0, 1.0))
	var panel_e: float = map._ease_in_out_cubic(clampf(map._hist_anim, 0.0, 1.0))
	var sel: int = map._hist_selected
	# 第一遍：画所有行（左列=公元年份居中，右列=主要内容一行，垂直居中）
	var asc_t: float = map.font_times.get_ascent(22.0)
	var desc_t: float = map.font_times.get_descent(22.0)
	var asc_s: float = map.font_song.get_ascent(16.0)
	var desc_s: float = map.font_song.get_descent(16.0)
	for i in range(map._timeline.size()):
		var er: Rect2 = map.hist_event_rect(i)
		var local := Rect2(er.position - position, er.size)
		var ev = map._timeline[i]
		var year: int = ev["year"]
		var title := String(ev["title"])
		var selected: bool = sel == i
		var key := "hist_%d" % i
		var row_col := Color(0.22, 0.42, 0.38, 0.86) if selected else Color(0.16, 0.26, 0.29, 0.8)
		var border := Color("#d9efc8", 0.95) if selected else Color(0.79, 0.64, 0.36, 0.4)
		_draw_ink_component(overlay._ink_history_row, local, 7.0, row_col, border, 1.0, key, selected)
		var cy := local.get_center().y
		# 左列：年份（Times，水平+垂直居中）
		var year_col_cx := local.position.x + 34.0
		_text_center(map.font_times, "%d" % year, 22.0, Color("#fff0aa") if _is_hot(key) else (Color("#d9efc8") if selected else Color("#d8c9a0")), Vector2(year_col_cx, cy))
		# 竖直分隔线
		var sep_x := local.position.x + 58.0
		draw_line(Vector2(sep_x, local.position.y + 9.0), Vector2(sep_x, local.end.y - 9.0), Color(0.79, 0.64, 0.36, 0.32), 1.0)
		# 右列：标题（一行，左对齐，垂直居中）
		draw_string(map.font_song, Vector2(sep_x + 16.0, cy + (asc_s - desc_s) * 0.5), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16.0, Color("#f2eccf") if selected else Color("#eaf1f0"))
	# 第二遍：画选中行的绿色细节框（置于所有行之上；其后行已被下推，不遮挡）
	if sel >= 0 and sel < map._timeline.size() and detail_e > 0.01 and panel_e > 0.01:
		var er2: Rect2 = map.hist_event_rect(sel)
		var l2 := Rect2(er2.position - position, er2.size)
		var ev2 = map._timeline[sel]
		var desc := String(ev2["desc"])
		var dh: float = map._hist_detail_shift() * (0.9 if map._hist_detail_anim < 1.0 else 1.0)
		var dr := Rect2(l2.position.x + 8.0, l2.end.y - 1.0, l2.size.x - 16.0, maxf(dh, 6.0))
		var fa := detail_e * panel_e
		_round_rect_fill(dr, 6.0, Color(0.16, 0.40, 0.28, 0.40 * fa))
		_round_rect_stroke(dr, 6.0, Color("#7bbf82", 0.6 * fa), 1.2)
		# 介绍跟随动画逐字（逐行）显示
		var visible: int = int(desc.length() * detail_e)
		var base_y: float = dr.position.y + 6.0 + map.font_hei.get_ascent(12.0)
		draw_multiline_string(map.font_hei, Vector2(dr.position.x + 12.0, base_y), desc.substr(0, visible), HORIZONTAL_ALIGNMENT_LEFT, dr.size.x - 24.0, 12.0, 2, Color("#e6f2dd", 0.92 * fa), BRK)

# ==================== 图鉴条目列表 ====================
func _draw_codex_list() -> void:
	var map = overlay.map
	var entries: Array = map.codex_entries(map._card_type_idx)
	var collected: Array = map.codex_collected_list(map._card_type_idx)
	var focus: int = clampi(map._card_focus, 0, maxi(0, entries.size() - 1))
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
	var ha: float = overlay._hover_alpha_of(key)
	if ha <= 0.001:
		return
	var glow := rect.grow(8.0)
	if overlay._ink_hover_mist:
		draw_texture_rect(overlay._ink_hover_mist, glow, false, Color(1, 1, 1, 0.5 * alpha * ha))
	var stroke_alpha := 0.9 * alpha * ha
	var stroke_width := 2.0
	if _is_pressed(key):
		stroke_alpha = 1.0 * alpha * maxf(ha, 0.85)
		stroke_width = 2.8
	_round_rect_stroke(rect.grow(1.0), radius + 1.0, Color(0.99, 0.97, 0.9, stroke_alpha), stroke_width)

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
