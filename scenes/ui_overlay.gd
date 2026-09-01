extends Control
# UI overlay (screen-space): frosted back button + zoom hint + right-side chat dialog + AI input.

var map

const ZONE_COLOR := {
	"宫城": Color("#2e4a52"),
	"皇城": Color("#b8935a"),
	"大明宫": Color("#8a6a3a"),
	"兴庆宫": Color("#7a9b7f"),
	"外郭城": Color("#6f7a7e"),
	"地形": Color("#8a826f"),
	"坊": Color("#7a8b80"),
}
const DAIQING := Color("#2e4a52")
const YUEBAI := Color("#eaf1f0")
const JUANBO := Color("#e8dfc8")
const JIN := Color("#c9a45a")
const MOQING := Color("#3a4a44")
const QING := Color("#7a9b8f")
const INK := Color("#3a4a44")
const INK_SOFT := Color("#55665f")
const BRK := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_GRAPHEME_BOUND
const MAX_BUBBLE_W := 350.0
const BUBBLE_FS := 15.0
const USER_BUBBLE := Color(0.48, 0.62, 0.56, 0.92)
const AI_BUBBLE := Color(0.92, 0.95, 0.94, 0.9)

var _frost: Texture2D
var _fade := 1.0
var _btn_near: TextureButton
var _btn_mid: TextureButton
var _btn_far: TextureButton
var _card_textures: Dictionary = {}

func _ca(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frost = load("res://assets/frost_noise.png") if ResourceLoader.exists("res://assets/frost_noise.png") else null
	_btn_near = get_node("../HUD/BtnNear")
	_btn_mid = get_node("../HUD/BtnMid")
	_btn_far = get_node("../HUD/BtnFar")
	_load_card_textures()

func _load_card_textures() -> void:
	var paths := {
		"gate": "res://prototypes/knowledge-cards/assets/zhuque-gate-form-reference.png",
		"fang": "res://prototypes/knowledge-cards/assets/fang-main-transparent.png",
		"road": "res://prototypes/knowledge-cards/assets/zhuque-avenue-main.png",
		"canal": "res://prototypes/knowledge-cards/assets/yongan-canal-main.png",
		"building": "res://prototypes/knowledge-cards/assets/building-main-transparent.png",
	}
	for key in paths:
		var path: String = paths[key]
		if ResourceLoader.exists(path):
			_card_textures[key] = load(path)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(map.MENU_SCENE)

func _on_codex_pressed() -> void:
	map._codex_open = not map._codex_open
	map._clock_open = false
	map._hist_open = false
	if map._codex_open:
		map._group_chat_open = false
		if not map._selected.is_empty():
			map._deselect()
	queue_redraw()

func _on_near_pressed() -> void:
	map._set_zoom(2)

func _on_mid_pressed() -> void:
	map._set_zoom(1)

func _on_far_pressed() -> void:
	map._set_zoom(0)

func _on_clock_pressed() -> void:
	map._clock_open = not map._clock_open
	map._hist_open = false
	queue_redraw()

func _sync_focal() -> void:
	if not _btn_near or not _btn_mid or not _btn_far:
		return
	var idx := int(map._zoom_idx)
	_btn_near.self_modulate = Color(1.35, 1.35, 1.35, 1.0) if idx == 2 else Color.WHITE
	_btn_mid.self_modulate = Color(1.35, 1.35, 1.35, 1.0) if idx == 1 else Color.WHITE
	_btn_far.self_modulate = Color(1.35, 1.35, 1.35, 1.0) if idx == 0 else Color.WHITE

func _draw() -> void:
	_sync_focal()
	_draw_clock_hands()
	_draw_hist_timeline()
	_draw_zoom_hint()
	_draw_fang_outline()
	var has: bool = map != null and map._panel_anim_t > 0.01
	if has:
		_draw_panel()
	_draw_group_chat()
	if map != null and map._clock_open:
		_draw_clock_popup()
	if map != null and map._hist_open:
		_draw_hist_popup()
	if map != null and map._codex_open:
		_draw_codex_panel()

func _draw_group_chat() -> void:
	if map == null or not map._group_chat_open:
		return
	var r: Rect2 = map.GROUP_CHAT_RECT
	_round_rect_fill(r, 14.0, Color("#f2efe6"))
	_round_rect_stroke(r, 14.0, Color("#c9bfa8"), 1.5)
	_round_rect_fill(Rect2(r.position, Vector2(r.size.x, 40)), 14.0, Color("#ddd6c2"))
	_text_left(map.font_song, String(map._group_chat_title), 16.0, INK, Vector2(r.position.x + 14, r.position.y + 25))
	var cb := Rect2(r.end.x - 34.0, r.position.y + 7.0, 24.0, 24.0)
	_round_rect_fill(cb, 6.0, Color("#cf2d26"))
	_round_rect_stroke(cb, 6.0, Color("#a01c16"), 1.5)
	var cc := cb.get_center()
	draw_line(cc + Vector2(-4, -4), cc + Vector2(4, 4), Color.WHITE, 2.5)
	draw_line(cc + Vector2(-4, 4), cc + Vector2(4, -4), Color.WHITE, 2.5)

	var y := r.position.y + 52.0
	for msg in map._group_chat:
		var age: float = msg["age"]
		var pop := clampf(age / 0.32, 0.0, 1.0)
		var e: float = map._ease_out_back(pop)
		var ox: float = lerpf(-18.0, 0.0, e)
		var alpha: float = clampf(age / 0.22, 0.0, 1.0)
		var name := String(msg["name"])
		var text := String(msg["text"])
		_text_left(map.font_hei, name, 10.0, Color(0.45, 0.42, 0.36, alpha), Vector2(r.position.x + 14 + ox, y + 12))
		var fs := 13.0
		var tw: float = map.font_hei.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var bw: float = minf(tw + 16.0, r.size.x - 28.0)
		var brect := Rect2(r.position.x + 12 + ox, y + 16, bw, 24.0)
		_round_rect_fill(brect, 9.0, Color(1, 1, 1, alpha))
		_round_rect_stroke(brect, 9.0, Color(0.25, 0.25, 0.25, 0.12 * alpha), 1.0)
		var asc: float = map.font_hei.get_ascent(fs)
		var desc: float = map.font_hei.get_descent(fs)
		var baseline := brect.get_center().y + (asc - desc) * 0.5
		draw_string(map.font_hei, Vector2(r.position.x + 20 + ox, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.2, 0.19, 0.16, alpha))
		y += 42.0
		if y > r.end.y - 96:
			break

	var kr := Rect2(r.position.x + 10, r.end.y - 88, r.size.x - 20, 78)
	_round_rect_fill(kr, 9.0, Color("#e9eadb"))
	_round_rect_stroke(kr, 9.0, Color(0.6, 0.65, 0.6, 0.5), 1.0)
	_text_left(map.font_song, "科普", 12.0, DAIQING, Vector2(kr.position.x + 9, kr.position.y + 15))
	if map._kepu.is_empty():
		_text_left(map.font_hei, "知识库占位 · 待接入", 11.0, Color(0.55, 0.55, 0.5), Vector2(kr.position.x + 9, kr.position.y + 34))
	else:
		var ky := kr.position.y + 32.0
		for k in map._kepu:
			var txt := "「" + String(k["kw"]) + "」" + String(k["text"])
			var fs2 := 11.0
			draw_multiline_string(map.font_hei, Vector2(kr.position.x + 9, ky + map.font_hei.get_ascent(fs2)), txt, HORIZONTAL_ALIGNMENT_LEFT, kr.size.x - 18, fs2, 3, INK_SOFT, BRK)
			ky += 40.0
			if ky > kr.end.y - 6:
				break

func _draw_clock_hands() -> void:
	var r: Rect2 = map.CLOCK_RECT
	var c := r.get_center()
	var radius := r.size.x * 0.5
	var hour: float = map._time_of_day
	var minutes: float = (hour - floorf(hour)) * 60.0
	var hh: int = int(floorf(hour)) % 12
	var ha: float = (float(hh) + minutes / 60.0) / 12.0 * TAU - PI * 0.5
	var ma: float = minutes / 60.0 * TAU - PI * 0.5
	draw_line(c, c + Vector2(cos(ha), sin(ha)) * (radius * 0.46), Color("#f2e6cc"), 3.0)
	draw_line(c, c + Vector2(cos(ma), sin(ma)) * (radius * 0.68), Color("#eaf1f0"), 2.0)
	draw_circle(c, 3.0, Color("#f2e6cc"))
	_text_center(map.font_song, map.shichen_label(hour), 11.0, Color("#f2e6cc"), Vector2(c.x, r.end.y - 13.0))

func _draw_clock_popup() -> void:
	var pr: Rect2 = map.clock_popup_rect()
	_round_rect_fill(pr, 10.0, Color(0.13, 0.21, 0.24, 0.96))
	_round_rect_stroke(pr, 10.0, Color(0.79, 0.64, 0.36, 0.8), 1.5)
	for i in range(map.SHICHEN.size()):
		var sr: Rect2 = map.shichen_rect(i)
		var active: bool = map.shichen_index(map._time_of_day) == i
		if active:
			_round_rect_fill(sr, 6.0, Color(0.79, 0.64, 0.36, 0.85))
		var col := Color("#f2e6cc") if active else Color("#eaf1f0")
		_text_center(map.font_song, map.shichen_name(i), 14.0, col, sr.get_center())

func _draw_hist_timeline() -> void:
	var r: Rect2 = map.HIST_TIMELINE_RECT
	var bar := Rect2(r.position.x, r.position.y + 12.0, r.size.x, 12.0)
	_round_rect_fill(bar, 6.0, Color(0.18, 0.29, 0.32, 0.5))
	_round_rect_stroke(bar, 6.0, Color(0.79, 0.64, 0.36, 0.6), 1.5)
	var y0: float = map.HIST_YEAR_MIN
	var y1: float = map.HIST_YEAR_MAX
	for ev in map._timeline:
		var y: float = ev["year"]
		var t := (y - y0) / (y1 - y0)
		var ex := bar.position.x + t * bar.size.x
		draw_circle(Vector2(ex, bar.get_center().y), 3.0, Color(0.79, 0.64, 0.36, 0.85))
	var t2 := (float(map._current_year) - y0) / (y1 - y0)
	var px := bar.position.x + t2 * bar.size.x
	draw_circle(Vector2(px, bar.get_center().y), 7.0, Color("#efe6d0"))
	draw_arc(Vector2(px, bar.get_center().y), 7.0, 0.0, TAU, 20, DAIQING, 2.5)
	_text_center(map.font_song, "%d年 · %s" % [map._current_year, map.year_era(map._current_year)], 14.0, Color("#3a2f22"), Vector2(px, bar.position.y - 12.0))
	_text_left(map.font_hei, "582 开皇二年", 11.0, Color(0.42, 0.38, 0.32), Vector2(r.position.x, r.end.y - 8.0))
	_text_right(map.font_hei, "907 唐亡", 11.0, Color(0.42, 0.38, 0.32), Vector2(r.end.x, r.end.y - 8.0))

func _draw_hist_popup() -> void:
	var pr: Rect2 = map.hist_popup_rect()
	_round_rect_fill(pr, 12.0, Color(0.13, 0.21, 0.24, 0.97))
	_round_rect_stroke(pr, 12.0, Color(0.79, 0.64, 0.36, 0.8), 1.5)
	_text_center(map.font_song, "长安城大事记", 20.0, Color("#f2e6cc"), Vector2(pr.get_center().x, pr.position.y + 28.0))
	var list_top := pr.position.y + 52.0
	var list_bottom := pr.end.y - 6.0
	for i in range(map._timeline.size()):
		var er: Rect2 = map.hist_event_rect(i)
		if er.end.y < list_top or er.position.y > list_bottom - 10.0:
			continue
		var ev = map._timeline[i]
		var year: int = ev["year"]
		var title := String(ev["title"])
		var desc := String(ev["desc"])
		var active: bool = map._current_year == year
		_round_rect_fill(er, 7.0, Color(0.16, 0.26, 0.29, 0.8))
		_round_rect_stroke(er, 7.0, Color("#f2e6cc", 0.95) if active else Color(0.79, 0.64, 0.36, 0.4), 1.5)
		_text_left(map.font_song, "%d" % year, 16.0, Color("#f2e6cc") if active else Color("#d8c9a0"), Vector2(er.position.x + 12.0, er.position.y + 17.0))
		_text_left(map.font_hei, title, 15.0, Color("#eaf1f0"), Vector2(er.position.x + 72.0, er.position.y + 17.0))
		_text_left(map.font_hei, desc, 11.0, Color(0.72, 0.76, 0.74), Vector2(er.position.x + 72.0, er.position.y + 31.0))
	if map._timeline.is_empty():
		_text_center(map.font_hei, "暂无历史数据", 14.0, Color(0.7, 0.74, 0.72), pr.get_center())

func _draw_codex_panel() -> void:
	var pr: Rect2 = map.codex_panel_rect()
	_round_rect_fill(pr, 12.0, Color(0.13, 0.21, 0.24, 0.97))
	_round_rect_stroke(pr, 12.0, Color(0.79, 0.64, 0.36, 0.8), 1.5)
	_text_center(map.font_song, "长安图鉴", 22.0, Color("#f2e6cc"), Vector2(pr.get_center().x, pr.position.y + 30.0))
	for i in range(3):
		var cr: Rect2 = map.codex_cat_rect(i)
		var active: bool = map._codex_cat == i
		var cnt: int = map.codex_collected_count(i)
		var total: int = map.codex_entries(i).size()
		_round_rect_fill(cr, 7.0, Color(0.79, 0.64, 0.36, 0.85) if active else Color(0.16, 0.26, 0.29, 0.7))
		_round_rect_stroke(cr, 7.0, Color(0.79, 0.64, 0.36, 0.6), 1.0)
		_text_center(map.font_song, "%s %d/%d" % [map.codex_cat_name(i), cnt, total], 14.0, Color("#f2e6cc") if active else Color("#eaf1f0"), cr.get_center())
	var entries: Array = map.codex_entries(map._codex_cat)
	var collected: Array = map.codex_collected_list(map._codex_cat)
	var list_top := pr.position.y + 100.0
	var list_bottom := pr.end.y - 8.0
	for i in range(entries.size()):
		var er: Rect2 = map.codex_entry_rect(i)
		if er.end.y < list_top or er.position.y > list_bottom - 10.0:
			continue
		var e = entries[i]
		var kw := String(e.get("kw", ""))
		var got: bool = collected.has(kw)
		_round_rect_fill(er, 7.0, Color(0.16, 0.26, 0.29, 0.8))
		_round_rect_stroke(er, 7.0, Color(0.79, 0.64, 0.36, 0.4), 1.0)
		if got:
			_text_left(map.font_song, kw, 15.0, Color("#f2e6cc"), Vector2(er.position.x + 12.0, er.position.y + 16.0))
			_text_left(map.font_hei, String(e.get("desc", "")), 12.0, Color(0.75, 0.78, 0.76), Vector2(er.position.x + 12.0, er.position.y + 31.0))
		else:
			_text_left(map.font_song, "？？？", 15.0, Color(0.55, 0.58, 0.56), Vector2(er.position.x + 12.0, er.position.y + 16.0))
			_text_left(map.font_hei, "尚未发现，去听听市井百姓的闲谈吧", 12.0, Color(0.45, 0.48, 0.46), Vector2(er.position.x + 12.0, er.position.y + 31.0))

func _draw_zoom_hint() -> void:
	var names := ["远景（整城）", "中景", "近景（单坊）"]
	var idx := int(map._zoom_idx)
	if idx < 0 or idx >= names.size():
		idx = 1
	var txt: String = "镜头：" + String(names[idx]) + "  ·  滚轮缩放  ·  拖拽平移"
	_text_left(map.font_hei, txt, 13.0, Color(0.42, 0.38, 0.32), Vector2(40, 690))

func _draw_fang_outline() -> void:
	if map._hover_outline.size() >= 2:
		for i in range(map._hover_outline.size() - 1):
			draw_line(map._hover_outline[i], map._hover_outline[i + 1], Color(1, 1, 1, 0.35), 3.0)
	if map._fang_outline.size() >= 2:
		for i in range(map._fang_outline.size() - 1):
			draw_line(map._fang_outline[i], map._fang_outline[i + 1], Color(1, 1, 1, 0.95), 4.0)

func _frosted(rect: Rect2, radius: float, base: Color, border: Color, a := 1.0) -> void:
	_round_rect_fill(rect, radius, _ca(base, a))
	if _frost and a >= 0.9:
		draw_texture_rect(_frost, rect, true)
	_round_rect_stroke(rect, radius, _ca(border, a), 1.5)

func _para_fill(rect: Rect2, skew: float, color: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(rect.position.x + skew, rect.position.y),
		Vector2(rect.end.x + skew, rect.position.y),
		Vector2(rect.end.x, rect.end.y),
		Vector2(rect.position.x, rect.end.y),
	])
	_poly(pts, color)

func _para_stroke(rect: Rect2, skew: float, color: Color, width: float) -> void:
	var pts := PackedVector2Array([
		Vector2(rect.position.x + skew, rect.position.y),
		Vector2(rect.end.x + skew, rect.position.y),
		Vector2(rect.end.x, rect.end.y),
		Vector2(rect.position.x, rect.end.y),
	])
	for i in range(4):
		draw_line(pts[i], pts[(i + 1) % 4], color, width)

func _draw_panel() -> void:
	if map._selected.is_empty():
		return
	var a := clampf(map._panel_anim_t, 0.0, 1.0)
	_fade = a
	var r: Rect2 = map.BUILDING_PANEL_RECT
	r.position.x += (1.0 - a) * 240.0
	# Match prototypes/knowledge-cards/gallery.html: 390×660, deep green and gilt.
	_round_rect_fill(r, 29.0, _ca(Color("#06261a"), a))
	_round_rect_fill(Rect2(r.position + Vector2(0, r.size.y * 0.48), Vector2(r.size.x, r.size.y * 0.52)), 29.0, _ca(Color("#0b3526"), a))
	_round_rect_stroke(r, 29.0, _ca(Color("#c99b45", 0.45), a), 1.0)
	var name := String(map._selected.get("name", ""))
	var type := String(map._selected.get("type", ""))
	var key := String(map._selected.get("key", ""))
	_text_left(map.font_hei, _entity_kind(type).to_upper() + " · " + _entity_type_en(type), 11.0, _ca(Color("#c99b45"), a), Vector2(r.position.x + 26.0, r.position.y + 34.0))
	_text_right(map.font_hei, key, 10.0, _ca(Color("#9aaa94"), a), Vector2(r.end.x - 48.0, r.position.y + 34.0))
	var cb: Rect2 = map.building_close_rect()
	_round_rect_fill(cb, 9.0, _ca(Color("#c99b45", 0.18), a))
	var cc := cb.get_center()
	draw_line(cc + Vector2(-3, -3), cc + Vector2(3, 3), _ca(Color("#dfc784"), a), 1.5)
	draw_line(cc + Vector2(-3, 3), cc + Vector2(3, -3), _ca(Color("#dfc784"), a), 1.5)

	var p: Dictionary = map._selected
	if map._knowledge_card_back:
		_draw_card_back(p, type, r, a)
	else:
		_draw_card_front(p, type, r, a)

func _draw_card_front(p: Dictionary, type: String, r: Rect2, a: float) -> void:
	var name := String(p.get("name", ""))
	var subtitle := _card_subtitle(p, type)
	_text_left(map.font_hei, _card_pinyin(name), 11.0, _ca(Color("#98702f"), a), Vector2(r.position.x + 26.0, r.position.y + 66.0))
	_text_left(map.font_song, name, 45.0, _ca(Color("#c99b45"), a), Vector2(r.position.x + 26.0, r.position.y + 112.0))
	_text_left(map.font_hei, subtitle, 12.0, _ca(Color("#dfc784"), a), Vector2(r.position.x + 27.0, r.position.y + 133.0))
	var image_rect := Rect2(r.position.x, r.position.y + 148.0, r.size.x, 350.0)
	draw_rect(image_rect, _ca(Color("#0e3a29"), a))
	var tex := _card_texture_for(p, type)
	if tex:
		var texture_key := _card_texture_key(p, type)
		if texture_key == "fang" or texture_key == "building":
			_draw_texture_contain(tex, image_rect.grow(-10.0), a)
		else:
			_draw_texture_cover(tex, image_rect, a)
	else:
		_text_center(map.font_song, _entity_symbol(type), 110.0, _ca(Color("#c99b45"), a), image_rect.get_center())
	draw_line(Vector2(image_rect.position.x, image_rect.position.y), Vector2(image_rect.end.x, image_rect.position.y), _ca(Color("#c99b45", 0.22), a), 1.0)
	draw_line(Vector2(image_rect.position.x, image_rect.end.y), Vector2(image_rect.end.x, image_rect.end.y), _ca(Color("#c99b45", 0.22), a), 1.0)
	_text_right(map.font_hei, _image_note(p, type), 9.0, _ca(Color("#dfc784"), a), Vector2(r.end.x - 15.0, image_rect.end.y - 12.0))

	var x := r.position.x + 26.0
	var w := r.size.x - 52.0
	var y := image_rect.end.y + 18.0
	var desc := String(p.get("description", "暂无简介"))
	_draw_card_text(desc, x, y, w, 3, a, Color("#dfc784"), 12.0)
	_text_left(map.font_hei, String(p.get("period", "隋—唐")), 12.0, _ca(Color("#c99b45"), a), Vector2(x, r.end.y - 35.0))
	_text_left(map.font_hei, "长安城知识图鉴 · 点击卡片翻面", 9.0, _ca(Color("#9aaa94"), a), Vector2(x, r.end.y - 19.0))
	var seal := Rect2(r.end.x - 72.0, r.end.y - 66.0, 46.0, 46.0)
	draw_rect(seal, _ca(Color("#c99b45"), a), false, 1.0)
	_text_center(map.font_song, _entity_symbol(type), 23.0, _ca(Color("#c99b45"), a), seal.get_center())

func _draw_card_back(p: Dictionary, type: String, r: Rect2, a: float) -> void:
	var x := r.position.x + 18.0
	var w := r.size.x - 36.0
	var y := r.position.y + 72.0
	_text_center(map.font_song, _card_subtitle(p, type), 20.0, _ca(Color("#c99b45"), a), Vector2(r.get_center().x, y + 8.0))
	y += 28.0
	var symbol_rect := Rect2(r.get_center().x - 47.0, y, 94.0, 94.0)
	draw_circle(symbol_rect.get_center(), 46.0, _ca(Color("#0d3828"), a))
	draw_arc(symbol_rect.get_center(), 46.0, 0.0, TAU, 48, _ca(Color("#c99b45"), a), 2.0)
	_text_center(map.font_song, _entity_symbol(type), 35.0, _ca(Color("#c99b45"), a), symbol_rect.get_center())
	y = symbol_rect.end.y + 22.0
	for row in _basic_rows(p, type):
		y = _draw_card_row(String(row[0]), String(row[1]), x, y, w, a)
	y += 10.0
	_text_left(map.font_song, "空间与知识关系", 13.0, _ca(Color("#c99b45"), a), Vector2(x, y + 13.0))
	y += 23.0
	for line in _relation_lines(p, type):
		y = _draw_card_relation(String(line), x, y, w, a)
	y += 5.0
	var quote := String(p.get("quote", ""))
	if quote == "":
		quote = "暂无可展示的原文摘录"
	var evidence_rect := Rect2(x, y, w, minf(112.0, r.end.y - 30.0 - y))
	_round_rect_fill(evidence_rect, 8.0, _ca(Color("#04130c"), a))
	draw_line(evidence_rect.position, Vector2(evidence_rect.position.x, evidence_rect.end.y), _ca(Color("#c99b45"), a), 2.0)
	_text_left(map.font_hei, "史料原文", 10.0, _ca(Color("#c99b45"), a), Vector2(x + 10.0, y + 16.0))
	_draw_card_text("“" + quote + "”", x + 10.0, y + 23.0, w - 20.0, 4, a, Color("#c8c6ae"), 11.0)
	_text_right(map.font_hei, "点击卡片返回正面", 9.0, _ca(Color("#9aaa94"), a), Vector2(r.end.x - 26.0, r.end.y - 14.0))

func _card_texture_for(p: Dictionary, type: String) -> Texture2D:
	return _card_textures.get(_card_texture_key(p, type))

func _card_texture_key(p: Dictionary, type: String) -> String:
	var name := String(p.get("name", ""))
	if name == "朱雀门" or type.contains("门"):
		return "gate"
	if type == "坊" or type.contains("里坊"):
		return "fang"
	if type.contains("渠") or type.contains("水"):
		return "canal"
	if type.contains("路") or type.contains("街") or type.contains("道"):
		return "road"
	return "building"

func _entity_symbol(type: String) -> String:
	var kind := _entity_kind(type)
	return "门" if kind == "城门" else ("街" if kind == "道路" else ("坊" if kind == "坊" else "筑"))

func _draw_texture_contain(tex: Texture2D, rect: Rect2, a: float) -> void:
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var draw_size := size * scale
	var dest := Rect2(rect.get_center() - draw_size * 0.5, draw_size)
	draw_texture_rect(tex, dest, false, _ca(Color.WHITE, a))

func _draw_texture_cover(tex: Texture2D, rect: Rect2, a: float) -> void:
	var size := tex.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var source_aspect := size.x / size.y
	var dest_aspect := rect.size.x / rect.size.y
	var source := Rect2(Vector2.ZERO, size)
	if source_aspect > dest_aspect:
		var crop_w := size.y * dest_aspect
		source.position.x = (size.x - crop_w) * 0.5
		source.size.x = crop_w
	else:
		var crop_h := size.x / dest_aspect
		source.position.y = (size.y - crop_h) * 0.53
		source.size.y = crop_h
	draw_texture_rect_region(tex, rect, source, Color(0.80, 0.76, 0.66, a))

func _entity_type_en(type: String) -> String:
	var kind := _entity_kind(type)
	return "GATE" if kind == "城门" else ("ROAD" if kind == "道路" else ("FANG" if kind == "坊" else "BUILDING"))

func _card_pinyin(name: String) -> String:
	var known := {"朱雀门": "ZHŪ QUÈ MÉN", "朱雀大街": "ZHŪ QUÈ DÀ JIĒ", "永安渠": "YǑNG ĀN QÚ", "大兴善寺": "DÀ XĪNG SHÀN SÌ", "兴庆坊": "XĪNG QÌNG FĀNG"}
	return String(known.get(name, "CHANG'AN · KNOWLEDGE CARD"))

func _card_subtitle(p: Dictionary, type: String) -> String:
	var name := String(p.get("name", ""))
	var known := {"朱雀门": "皇城正南门 · 中轴之门", "朱雀大街": "外郭城南北中轴", "永安渠": "城市供水与园林水系", "大兴善寺": "大型寺院建筑群", "兴庆坊": "长安城东部里坊"}
	if known.has(name):
		return String(known[name])
	var zone := String(p.get("zone", "长安城"))
	return zone + " · " + _entity_kind(type)

func _image_note(p: Dictionary, type: String) -> String:
	var key := _card_texture_key(p, type)
	if key == "gate":
		return "形制参考图 · 非唐长安直接复原证据"
	if key == "fang":
		return "坊市空间视觉参考"
	if key == "road":
		return "道路场景示意图"
	if key == "canal":
		return "城市水渠生活场景示意图"
	return "建筑形制视觉参考"

func _draw_card_row(label: String, value: String, x: float, y: float, w: float, a: float) -> float:
	if value == "":
		return y
	_text_left(map.font_hei, label, 10.0, _ca(Color("#98702f"), a), Vector2(x, y + 13.0))
	_text_left(map.font_hei, _shorten(value, 30), 11.0, _ca(Color("#dfc784"), a), Vector2(x + 58.0, y + 13.0))
	draw_line(Vector2(x, y + 19.0), Vector2(x + w, y + 19.0), _ca(Color("#c99b45", 0.22), a), 1.0)
	return y + 23.0

func _draw_card_relation(text: String, x: float, y: float, w: float, a: float) -> float:
	draw_circle(Vector2(x + 4.0, y + 7.0), 2.3, _ca(Color("#c99b45"), a))
	_text_left(map.font_hei, _shorten(text, 43), 10.5, _ca(Color("#b9c4b5"), a), Vector2(x + 13.0, y + 12.0))
	return y + 18.0

func _draw_card_text(text: String, x: float, y: float, w: float, max_lines: int, a: float, color: Color, fs: float) -> float:
	draw_multiline_string(map.font_hei, Vector2(x, y + map.font_hei.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, w, fs, max_lines, _ca(color, a), BRK)
	return y + float(max_lines) * (fs + 4.0)

func _shorten(text: String, limit: int) -> String:
	return text if text.length() <= limit else text.substr(0, limit - 1) + "…"

func _entity_kind(type: String) -> String:
	if type.contains("门"):
		return "城门"
	if type.contains("路") or type.contains("街") or type.contains("道"):
		return "道路"
	if type == "坊" or type.contains("里坊"):
		return "坊"
	return type if type != "" else "实体"

func _basic_rows(p: Dictionary, type: String) -> Array:
	var rows: Array = []
	var zone := String(p.get("zone", ""))
	var period := String(p.get("period", ""))
	var aliases := String(p.get("aliases", ""))
	var location := String(p.get("location", ""))
	var function_text := String(p.get("function", ""))
	var built := String(p.get("built", ""))
	if zone != "": rows.append(["所属", zone])
	if period != "": rows.append(["时期", period])
	if aliases != "": rows.append(["别名", aliases.replace(";", "、")])
	if type.contains("门"):
		if location != "": rows.append(["位置", location])
		if function_text != "": rows.append(["功能", function_text])
	elif type.contains("路") or type.contains("街") or type.contains("道"):
		if location != "": rows.append(["走向", location])
		if function_text != "": rows.append(["作用", function_text])
	else:
		if location != "": rows.append(["位置", location])
		if function_text != "": rows.append(["功能", function_text])
	if built != "": rows.append(["建造/沿革", built])
	return rows.slice(0, 5)

func _relation_lines(p: Dictionary, type: String) -> Array:
	var lines: Array = []
	var location := String(p.get("location", ""))
	var function_text := String(p.get("function", ""))
	var zone := String(p.get("zone", ""))
	if type.contains("门"):
		if zone != "": lines.append("位于「%s」，是城市空间的重要出入口" % zone)
		if location != "": lines.append("方位关系：" + location)
		if function_text != "": lines.append("连接功能：" + function_text)
	elif type.contains("路") or type.contains("街") or type.contains("道"):
		if zone != "": lines.append("道路所在区域：" + zone)
		if location != "": lines.append("沿线路径：" + location)
		if function_text != "": lines.append("道路作用：" + function_text)
	else:
		if zone != "": lines.append("所属城区：" + zone)
		if location != "": lines.append("坊区定位：" + location)
		if function_text != "": lines.append("坊内主要活动：" + function_text)
	if lines.is_empty():
		lines.append("相关实体关系正在整理中")
	return lines.slice(0, 3)

func _draw_section_title(title: String, x: float, y: float, w: float, a: float) -> float:
	draw_line(Vector2(x, y + 16.0), Vector2(x + w, y + 16.0), _ca(Color("#d4c7a9"), a), 1.0)
	_round_rect_fill(Rect2(x, y + 3.0, 82.0, 22.0), 11.0, _ca(Color("#e3d8bd"), a))
	_text_center(map.font_song, title, 12.0, _ca(DAIQING, a), Vector2(x + 41.0, y + 14.0))
	return y + 31.0

func _draw_knowledge_row(label: String, value: String, x: float, y: float, w: float, a: float) -> float:
	if value == "":
		return y
	_text_left(map.font_hei, label, 11.0, _ca(Color("#8a7655"), a), Vector2(x + 2.0, y + 14.0))
	var shown := value
	if shown.length() > 28:
		shown = shown.substr(0, 27) + "…"
	_text_left(map.font_hei, shown, 12.0, _ca(INK, a), Vector2(x + 68.0, y + 14.0))
	return y + 21.0

func _draw_knowledge_text(text: String, x: float, y: float, w: float, max_lines: int, a: float, color: Color) -> float:
	var fs := 12.0
	draw_multiline_string(map.font_hei, Vector2(x + 2.0, y + map.font_hei.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, w - 4.0, fs, max_lines, _ca(color, a), BRK)
	return y + float(max_lines) * 17.0

func _draw_relation_line(text: String, x: float, y: float, w: float, a: float) -> float:
	draw_circle(Vector2(x + 5.0, y + 8.0), 2.5, _ca(JIN, a))
	var shown := text
	if shown.length() > 42:
		shown = shown.substr(0, 41) + "…"
	_text_left(map.font_hei, shown, 11.0, _ca(INK_SOFT, a), Vector2(x + 14.0, y + 13.0))
	return y + 19.0

func _draw_intro(rect: Rect2) -> void:
	var fs := 14.0
	var width := rect.size.x
	var y := rect.position.y
	var intro := ""
	if map._typing_intro and map._intro_text == "":
		intro = "正在生成介绍…"
	elif map._typing_intro:
		var blink := "▌" if (Time.get_ticks_msec() / 500) % 2 == 0 else ""
		intro = String(map._intro_text).substr(0, map._intro_visible) + blink
	else:
		intro = String(map._intro_text)
		if intro == "":
			intro = String(map._local_text)
	var sz: Vector2 = map.font_hei.get_multiline_string_size(intro, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, BRK)
	draw_multiline_string(map.font_hei, Vector2(rect.position.x, y + map.font_hei.get_ascent(fs)), intro, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, _ca(INK_SOFT, _fade), BRK)
	y += sz.y + 8.0
	for m in map._chat:
		var role := String(m.get("role", ""))
		var text := String(m.get("text", ""))
		var prefix := "问：" if role == "user" else "答："
		var col := _ca(Color("#8a5a2a"), _fade) if role == "user" else _ca(INK, _fade)
		var tsz: Vector2 = map.font_hei.get_multiline_string_size(prefix + text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, BRK)
		draw_multiline_string(map.font_hei, Vector2(rect.position.x, y + map.font_hei.get_ascent(fs)), prefix + text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, col, BRK)
		y += tsz.y + 6.0
	if map._typing:
		var blink := "▌" if (Time.get_ticks_msec() / 500) % 2 == 0 else ""
		draw_multiline_string(map.font_hei, Vector2(rect.position.x, y + map.font_hei.get_ascent(fs)), "答：" + String(map._typing_text).substr(0, map._typing_visible) + blink, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, _ca(INK, _fade), BRK)

func _draw_followup_buttons(panel: Rect2) -> void:
	var bx := panel.position.x + 14.0
	var by := panel.end.y - 56.0
	var bw := (panel.size.x - 28.0 - 16.0) / 3.0
	var bh := 44.0
	for i in range(3):
		var br := Rect2(bx + float(i) * (bw + 8.0), by, bw, bh)
		if i < 2:
			var label := "追问"
			if map._followups.size() >= 2:
				label = String(map._followups[i]["label"])
			if label.length() > 6:
				label = label.substr(0, 6)
			_draw_window_button(br, label, Color("#7a2f22"), Color("#8a3b2e"))
		else:
			_draw_window_button(br, "确认", DAIQING, DAIQING)

func _draw_window_button(r: Rect2, text: String, text_col: Color, frame_col: Color) -> void:
	_round_rect_fill(r, 7.0, Color("#f7ecd4"))
	_round_rect_stroke(r, 7.0, frame_col, 2.5)
	var g := r.grow(-6.0)
	_round_rect_stroke(g, 4.0, Color(frame_col.r, frame_col.g, frame_col.b, 0.45), 1.0)
	var cols := 2
	var rows := 2
	for i in range(1, cols):
		var x := g.position.x + g.size.x * float(i) / float(cols)
		draw_line(Vector2(x, g.position.y), Vector2(x, g.end.y), Color(frame_col.r, frame_col.g, frame_col.b, 0.4), 1.0)
	for j in range(1, rows):
		var y := g.position.y + g.size.y * float(j) / float(rows)
		draw_line(Vector2(g.position.x, y), Vector2(g.end.x, y), Color(frame_col.r, frame_col.g, frame_col.b, 0.4), 1.0)
	_text_center(map.font_song, text, 12.0, text_col, r.get_center())

func _text_center(font: Font, text: String, fs: float, color: Color, center: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	draw_string(font, Vector2(center.x - w * 0.5, center.y + (asc - desc) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

func _text_left(font: Font, text: String, fs: float, color: Color, pos: Vector2) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

func _text_right(font: Font, text: String, fs: float, color: Color, right: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(right.x - w, right.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

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
