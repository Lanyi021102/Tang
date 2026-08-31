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
var _ink_paper: Texture2D
var _ink_dark: Texture2D
var _ink_noise: Texture2D
var _ink_edge: Texture2D
var _ink_frame: Texture2D
var _ink_corner: Texture2D
var _ink_separator: Texture2D
var _ink_title_light: Texture2D
var _ink_title_dark: Texture2D
var _ink_chat_bubble_light: Texture2D
var _ink_chat_bubble_dark: Texture2D
var _ink_kepu_box: Texture2D
var _ink_codex_tab_normal: Texture2D
var _ink_codex_tab_active: Texture2D
var _ink_codex_entry_locked: Texture2D
var _ink_codex_entry_unlocked: Texture2D
var _ink_history_row: Texture2D
var _ink_timeline_track: Texture2D
var _ink_timeline_node: Texture2D
var _ink_timeline_node_active: Texture2D
var _ink_shichen_item_normal: Texture2D
var _ink_shichen_item_active: Texture2D
var _ink_close: Texture2D
var _ink_close_hover: Texture2D
var _ink_close_pressed: Texture2D
var _ink_unlock_glow: Texture2D
var _ink_gold_dust: Texture2D
var _ink_hover_mist: Texture2D
var _ink_selection_ring: Texture2D
var _fade := 1.0
var _hover_key := ""
var _mouse_down := false
var _hover_alpha := {}  # key -> 悬停描边透明度（随时间渐入渐出）
var _btn_near: TextureButton
var _btn_mid: TextureButton
var _btn_far: TextureButton
var _hist_clip: Control
var _codex_clip: Control

func _ca(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frost = load("res://assets/frost_noise.png") if ResourceLoader.exists("res://assets/frost_noise.png") else null
	_load_ink_textures()
	_btn_near = get_node("../HUD/BtnNear")
	_create_clip_containers()
	_btn_mid = get_node("../HUD/BtnMid")
	_btn_far = get_node("../HUD/BtnFar")
	# 延迟到下一帧同步切换按钮位置，确保 map 已赋值
	_sync_left_toggle_btn.call_deferred()
	_sync_timeline_toggle_btn.call_deferred()

# 创建列表裁剪容器（clip_contents 实现遮罩式裁剪）
func _create_clip_containers() -> void:
	var clip_script: Script = load("res://scenes/clip_list.gd")
	_hist_clip = clip_script.new()
	_hist_clip.overlay = self
	_hist_clip.kind = "hist"
	_hist_clip.visible = false
	add_child(_hist_clip)
	_codex_clip = clip_script.new()
	_codex_clip.overlay = self
	_codex_clip.kind = "codex"
	_codex_clip.visible = false
	add_child(_codex_clip)

func _load_optional_texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null

func _load_ink_textures() -> void:
	_ink_paper = _load_optional_texture("res://assets/ui/ink/ui_paper_fiber_tile.png")
	_ink_dark = _load_optional_texture("res://assets/ui/ink/ui_dark_ink_wash_tile.png")
	_ink_noise = _load_optional_texture("res://assets/ui/ink/ui_ink_panel_noise_tile.png")
	_ink_edge = _load_optional_texture("res://assets/ui/ink/ui_panel_edge_mask_soft.png")
	_ink_frame = _load_optional_texture("res://assets/ui/ink/ui_panel_frame_9slice.png")
	_ink_corner = _load_optional_texture("res://assets/ui/ink/ui_panel_corner_ink.png")
	_ink_separator = _load_optional_texture("res://assets/ui/ink/ui_brush_separator.png")
	_ink_title_light = _load_optional_texture("res://assets/ui/ink/ui_title_bar_9slice_light.png")
	_ink_title_dark = _load_optional_texture("res://assets/ui/ink/ui_title_bar_9slice_dark.png")
	_ink_chat_bubble_light = _load_optional_texture("res://assets/ui/ink/ui_chat_bubble_left_9slice.png")
	_ink_chat_bubble_dark = _load_optional_texture("res://assets/ui/ink/ui_chat_bubble_ai_9slice.png")
	_ink_kepu_box = _load_optional_texture("res://assets/ui/ink/ui_kepu_box_9slice.png")
	_ink_codex_tab_normal = _load_optional_texture("res://assets/ui/ink/ui_codex_tab_normal_9slice.png")
	_ink_codex_tab_active = _load_optional_texture("res://assets/ui/ink/ui_codex_tab_active_9slice.png")
	_ink_codex_entry_locked = _load_optional_texture("res://assets/ui/ink/ui_codex_entry_locked_9slice.png")
	_ink_codex_entry_unlocked = _load_optional_texture("res://assets/ui/ink/ui_codex_entry_unlocked_9slice.png")
	_ink_history_row = _load_optional_texture("res://assets/ui/ink/ui_history_row_9slice.png")
	_ink_timeline_track = _load_optional_texture("res://assets/ui/ink/ui_timeline_track.png")
	_ink_timeline_node = _load_optional_texture("res://assets/ui/ink/ui_timeline_node.png")
	_ink_timeline_node_active = _load_optional_texture("res://assets/ui/ink/ui_timeline_node_active.png")
	_ink_shichen_item_normal = _load_optional_texture("res://assets/ui/ink/ui_shichen_item_normal_9slice.png")
	_ink_shichen_item_active = _load_optional_texture("res://assets/ui/ink/ui_shichen_item_active_9slice.png")
	_ink_close = _load_optional_texture("res://assets/ui/ink/ui_close_normal.png")
	_ink_close_hover = _load_optional_texture("res://assets/ui/ink/ui_close_hover.png")
	_ink_close_pressed = _load_optional_texture("res://assets/ui/ink/ui_close_pressed.png")
	_ink_unlock_glow = _load_optional_texture("res://assets/ui/ink/ui_unlock_glow.png")
	_ink_gold_dust = _load_optional_texture("res://assets/ui/ink/ui_gold_dust_strip.png")
	_ink_hover_mist = _load_optional_texture("res://assets/ui/ink/ui_hover_mist.png")
	_ink_selection_ring = _load_optional_texture("res://assets/ui/ink/ui_selection_ink_ring.png")

func _process(delta: float) -> void:
	var next_hover := _detect_ui_hover()
	var next_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if next_hover != _hover_key or next_down != _mouse_down:
		_hover_key = next_hover
		_mouse_down = next_down
		queue_redraw()
	_update_hover_alphas(delta)

# 悬停描边透明度：随时间非线性渐入渐出（UI 描边不瞬间切换）
func _update_hover_alphas(delta: float) -> void:
	if _hover_key != "" and not _hover_alpha.has(_hover_key):
		_hover_alpha[_hover_key] = 0.0
	var changed := false
	for k in _hover_alpha.keys():
		var target := 1.0 if k == _hover_key else 0.0
		var cur: float = _hover_alpha[k]
		var nv := lerpf(cur, target, delta * 9.0)
		if absf(nv - cur) > 0.001:
			changed = true
		_hover_alpha[k] = nv
	if changed:
		queue_redraw()

func _hover_alpha_of(key: String) -> float:
	return _hover_alpha.get(key, 0.0)

func _detect_ui_hover() -> String:
	if map == null:
		return ""
	var p := get_viewport().get_mouse_position()
	# 左侧栏收起/展开切换按钮
	if map.left_toggle_rect().has_point(p):
		return "left_toggle"
	# 底部时间轴收起/展开切换按钮
	if map.timeline_toggle_rect().has_point(p):
		return "timeline_toggle"
	# 左侧工具栏按钮（展开状态下；收起时按钮隐藏，不再响应）
	if not map._left_bar_collapsed:
		var left_btns := [
			{"key": "left_back", "rect": Rect2(14.0, 18.0, 100.0, 42.0)},
			{"key": "left_near", "rect": Rect2(20.0, 100.0, 88.0, 88.0)},
			{"key": "left_mid", "rect": Rect2(20.0, 206.0, 88.0, 88.0)},
			{"key": "left_far", "rect": Rect2(20.0, 312.0, 88.0, 88.0)},
			{"key": "left_codex", "rect": Rect2(20.0, 420.0, 88.0, 88.0)},
		]
		for b in left_btns:
			if Rect2(b["rect"]).has_point(p):
				return String(b["key"])
	if map._clock_open:
		if map.clock_popup_rect().has_point(p):
			for i in range(map.SHICHEN.size()):
				if map.shichen_rect(i).has_point(p):
					return "shichen_%d" % i
			return "clock_popup"
		return ""
	if map._hist_open:
		if map.hist_popup_rect().has_point(p):
			for i in range(map._timeline.size()):
				if map.hist_event_rect(i).has_point(p):
					return "hist_%d" % i
			return "hist_popup"
		return ""
	if map._codex_open:
		if map.codex_panel_rect().has_point(p):
			# 关闭按钮
			var close_r := Rect2(map.codex_panel_rect().end.x - 44.0, map.codex_panel_rect().position.y + 12.0, 28.0, 28.0)
			if close_r.has_point(p):
				return "codex_close"
			for i in range(3):
				if map.codex_cat_rect(i).has_point(p):
					return "codex_cat_%d" % i
			var entries: Array = map.codex_entries(map._codex_cat)
			for i in range(entries.size()):
				if map.codex_entry_rect(i).has_point(p):
					return "codex_entry_%d" % i
			if map.codex_detail_rect().has_point(p):
				return "codex_detail"
			return "codex_panel"
		return ""
	if map.HIST_TIMELINE_RECT.has_point(p):
		if map._timeline_collapsed:
			return ""
		var ev_idx: int = map.timeline_event_at_x(p.x)
		if ev_idx >= 0:
			return "timeline_ev_%d" % ev_idx
		return "timeline"
	if map._group_chat_open:
		if map.group_chat_close_rect().has_point(p):
			return "group_close"
		if map.GROUP_CHAT_RECT.has_point(p):
			return "group_panel"
	if not map._selected.is_empty():
		var a := clampf(map._panel_anim_t, 0.0, 1.0)
		var r: Rect2 = map.BUILDING_PANEL_RECT
		r.position.x += (1.0 - a) * 240.0
		var close_rect := Rect2(r.end.x - 34.0, r.position.y + 7.0, 24.0, 24.0)
		if close_rect.has_point(p):
			return "building_close"
		if not map._typing_intro:
			var bx := r.position.x + 14.0
			var by := r.end.y - 56.0
			var bw := (r.size.x - 28.0 - 16.0) / 3.0
			for i in range(3):
				var br := Rect2(bx + float(i) * (bw + 8.0), by, bw, 44.0)
				if br.has_point(p):
					return "followup_%d" % i
		if r.has_point(p):
			return "building_panel"
	return ""

func _is_hot(key: String) -> bool:
	return key != "" and key == _hover_key

func _is_pressed(key: String) -> bool:
	return _is_hot(key) and _mouse_down

func _on_back_pressed() -> void:
	SceneTransition.goto_scene(map.MENU_SCENE)

func _on_left_toggle_pressed() -> void:
	map.toggle_left_bar()
	_sync_left_toggle_btn()

func _on_timeline_toggle_pressed() -> void:
	map.toggle_timeline()
	_sync_timeline_toggle_btn()

# 时间轴收起/展开后同步切换按钮的位置与尺寸
func _sync_timeline_toggle_btn() -> void:
	if map == null:
		return
	var btn = get_node_or_null("../HUD/BtnTimelineToggle")
	if btn == null:
		return
	var tr: Rect2 = map.timeline_toggle_rect()
	btn.position = tr.position
	btn.size = tr.size

# 收起/展开后同步切换按钮的位置与尺寸
func _sync_left_toggle_btn() -> void:
	if map == null:
		return
	var btn = get_node_or_null("../HUD/BtnLeftToggle")
	if btn == null:
		return
	var tr: Rect2 = map.left_toggle_rect()
	btn.position = tr.position
	btn.size = tr.size

func _on_codex_pressed() -> void:
	map._codex_open = not map._codex_open
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

func _sync_focal() -> void:
	if not _btn_near or not _btn_mid or not _btn_far:
		return
	var idx := int(map._zoom_idx)
	_btn_near.self_modulate = Color(1.35, 1.35, 1.35, 1.0) if idx == 2 else Color.WHITE
	_btn_mid.self_modulate = Color(1.35, 1.35, 1.35, 1.0) if idx == 1 else Color.WHITE
	_btn_far.self_modulate = Color(1.35, 1.35, 1.35, 1.0) if idx == 0 else Color.WHITE

func _draw() -> void:
	_sync_focal()
	_draw_screen_ink_vignette()
	_draw_top_function_band()
	_draw_sun_moon()
	_draw_hist_timeline()
	_draw_zoom_hint()
	var has: bool = map != null and map._panel_anim_t > 0.01
	if has:
		_draw_panel()
	_draw_group_chat()
	if map != null and map._clock_open:
		_draw_clock_popup()
	# 裁剪容器显隐跟随面板开关状态（关闭时隐藏，避免残留内容）
	if map != null:
		_hist_clip.visible = map._hist_open
		_codex_clip.visible = false
	if map != null and map._hist_open:
		_draw_hist_popup()
	if map != null and map._codex_open:
		_draw_codex_panel()

func _draw_screen_ink_vignette() -> void:
	var vp := get_viewport_rect()
	var left_w: float = 128.0
	if map != null:
		left_w = map.LEFT_BAR_EXPANDED_W if not map._left_bar_collapsed else map.LEFT_BAR_COLLAPSED_W
	_draw_texture_layer(_ink_dark, Rect2(vp.position.x, vp.position.y, left_w, vp.size.y), true, 0.88)
	if map == null or not map._timeline_collapsed:
		_draw_texture_layer(_ink_dark, Rect2(vp.position.x, vp.end.y - 118.0, vp.size.x, 118.0), true, 0.36)
	_draw_texture_layer(_ink_edge, Rect2(vp.position.x - 10.0, vp.position.y - 8.0, vp.size.x + 20.0, vp.size.y + 16.0), false, 0.26)
	# 左侧边缘装饰宽度跟随收起状态（收起时只保留窄条边缘）
	_draw_texture_layer(_ink_edge, Rect2(-20.0, -6.0, left_w + 32.0, vp.size.y + 12.0), false, 0.55)
	# 左上角墨雾装饰仅展开时显示（收起时窄条放不下）
	if map == null or not map._left_bar_collapsed:
		_draw_texture_layer(_ink_hover_mist, Rect2(104.0, 48.0, 260.0, 124.0), false, 0.12)
	_draw_texture_layer(_ink_hover_mist, Rect2(vp.end.x - 472.0, 96.0, 452.0, 118.0), false, 0.16)

func _draw_top_function_band() -> void:
	if map == null:
		return
	var e: float = map._ease_in_out_cubic(clampf(map._left_bar_anim, 0.0, 1.0))
	# 展开布局（淡入量 = e）
	if e > 0.01:
		var band := Rect2(10.0, 16.0, 106.0, 514.0)
		_draw_texture_layer(_ink_title_dark, band, false, 0.62 * e)
		_text_left(map.font_song, "长安", 24.0, Color("#f2e6cc", e), Vector2(29.0, 50.0))
		_text_left(map.font_hei, "开元图卷", 8.0, Color("#b98a48", e * 0.82), Vector2(58.0, 61.0))
		var btns := [
			{"key": "left_back", "rect": Rect2(14.0, 18.0, 100.0, 42.0), "t": "返回"},
			{"key": "left_near", "rect": Rect2(20.0, 100.0, 88.0, 88.0), "t": "近景"},
			{"key": "left_mid", "rect": Rect2(20.0, 206.0, 88.0, 88.0), "t": "中景"},
			{"key": "left_far", "rect": Rect2(20.0, 312.0, 88.0, 88.0), "t": "远景"},
			{"key": "left_codex", "rect": Rect2(20.0, 420.0, 88.0, 88.0), "t": "图鉴"},
		]
		for b in btns:
			_draw_left_card(Rect2(b["rect"]), String(b["t"]), String(b["key"]))
	# 收起布局（窄条 + 切换按钮，淡入量 = 1-e）
	if e < 0.99:
		var ca := 1.0 - e
		_draw_texture_layer(_ink_title_dark, Rect2(6.0, 16.0, 32.0, 600.0), false, 0.62 * ca)
		var collapsed_r := Rect2(6.0, 560.0, 32.0, 44.0)
		var expanded_r := Rect2(14.0, 560.0, 100.0, 40.0)
		var tr := Rect2(
			lerpf(expanded_r.position.x, collapsed_r.position.x, ca),
			lerpf(expanded_r.position.y, collapsed_r.position.y, ca),
			lerpf(expanded_r.size.x, collapsed_r.size.x, ca),
			lerpf(expanded_r.size.y, collapsed_r.size.y, ca)
		)
		_draw_left_card(tr, "≫" if e < 0.5 else "≪ 收起", "left_toggle")

# 左侧功能按钮：与知识卡片选项（追问按钮）一致的视觉
func _draw_left_card(r: Rect2, text: String, key: String) -> void:
	var label_col := Color("#7a2f22")
	if _is_hot(key):
		label_col = Color("#5a411f") if not _is_pressed(key) else Color("#302010")
	# 不透明浅色底，盖住圆形按钮贴图
	_round_rect_fill(r.grow(1.0), 10.0, Color("#efe5cf", 0.96))
	if _ink_chat_bubble_light:
		draw_texture_rect(_ink_chat_bubble_light, r, false, Color(1, 1, 1, 0.92))
	_round_rect_stroke(r, 8.0, Color(0.48, 0.24, 0.12, 0.7), 1.4)
	_draw_hover_accent(r, 8.0, key, 1.0)
	# 镜头（近景/中景/远景）、返回、图鉴 按钮：字体变大一倍、变高 1.5 倍（围绕按钮中心非均匀缩放）
	var center := r.get_center()
	if key in ["left_back", "left_near", "left_mid", "left_far", "left_codex"]:
		draw_set_transform(center, 0.0, Vector2(2.0, 1.5))
		_text_center(map.font_song, text, 14.0, label_col, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_text_center(map.font_song, text, 14.0, label_col, center)

func _draw_group_chat() -> void:
	if map == null or not map._group_chat_open:
		return
	var r: Rect2 = map.GROUP_CHAT_RECT
	_draw_ink_panel(r, true, 10.0)
	_draw_ink_header(Rect2(r.position, Vector2(r.size.x, 48)), true, 10.0)
	_text_left(map.font_song, "问学斋", 22.0, Color("#f2e6cc"), Vector2(r.position.x + 54.0, r.position.y + 31.0))
	draw_circle(Vector2(r.position.x + 31.0, r.position.y + 24.0), 7.0, Color("#d6b56a", 0.82))
	draw_circle(Vector2(r.position.x + 45.0, r.position.y + 25.0), 6.0, Color("#d6b56a", 0.68))
	draw_circle(Vector2(r.position.x + 38.0, r.position.y + 16.0), 5.0, Color("#d6b56a", 0.56))
	_text_right(map.font_hei, "(12人)", 12.0, Color("#d8c9a0"), Vector2(r.end.x - 52.0, r.position.y + 30.0))
	var cb := Rect2(r.end.x - 34.0, r.position.y + 7.0, 24.0, 24.0)
	_draw_ink_close(cb, 1.0, "group_close")

	_text_left(map.font_hei, "研习长安掌故，考据城市历史。", 12.0, Color("#b8aa87", 0.88), Vector2(r.position.x + 22.0, r.position.y + 74.0))
	var filter := Rect2(r.position.x + 20.0, r.position.y + 94.0, 98.0, 32.0)
	_draw_ink_component(_ink_codex_tab_active, filter, 4.0, Color("#efe5cf", 0.92), Color("#d5aa56", 0.62), 1.0)
	_text_center(map.font_song, "全部", 14.0, Color("#1f1810"), filter.get_center())

	var display_messages: Array = map._group_chat
	if display_messages.is_empty():
		display_messages = [
			{"name": "学者·墨白", "text": "朱雀门街纵贯南北，是城中礼制轴线。", "age": 1.0},
			{"name": "史生·元礼", "text": "西市胡商云集，金银器与香料最盛。", "age": 1.0},
			{"name": "旅人·阿衡", "text": "夜禁之后，坊门闭合，街鼓为号。", "age": 1.0},
			{"name": "雅士·清越", "text": "兴庆宫旁多见曲江宴游轶事。", "age": 1.0},
		]
	var list_top := r.position.y + 138.0
	var list_bottom := r.end.y - 110.0
	var y := list_top
	for msg in display_messages:
		var age: float = msg["age"]
		var pop := clampf(age / 0.32, 0.0, 1.0)
		var e: float = map._ease_out_back(pop)
		var ox: float = lerpf(-18.0, 0.0, e)
		var alpha: float = clampf(age / 0.22, 0.0, 1.0)
		var name := String(msg["name"])
		var text := String(msg["text"])
		var row := Rect2(r.position.x + 18.0 + ox, y, r.size.x - 36.0, 54.0)
		_draw_texture_layer(_ink_separator, Rect2(row.position.x + 42.0, row.end.y - 8.0, row.size.x - 44.0, 12.0), false, 0.28 * alpha)
		draw_arc(row.position + Vector2(25.0, 27.0), 18.0, 0.0, TAU, 32, Color("#a97d3b", 0.55 * alpha), 1.0)
		draw_circle(row.position + Vector2(25.0, 25.0), 6.0, Color("#cbbf9d", 0.74 * alpha))
		draw_arc(row.position + Vector2(25.0, 36.0), 9.0, PI, TAU, 16, Color("#cbbf9d", 0.66 * alpha), 2.0)
		_text_left(map.font_song, name, 13.0, Color(0.86, 0.78, 0.58, alpha), Vector2(row.position.x + 52.0, row.position.y + 18.0))
		_text_right(map.font_hei, map.shichen_label(map._time_of_day), 11.0, Color(0.72, 0.64, 0.48, 0.82 * alpha), Vector2(row.end.x - 4.0, row.position.y + 18.0))
		draw_multiline_string(map.font_hei, Vector2(row.position.x + 52.0, row.position.y + 39.0), text, HORIZONTAL_ALIGNMENT_LEFT, row.size.x - 66.0, 12.0, 1, Color("#c9c1aa", 0.84 * alpha), BRK)
		y += 64.0
		if y > list_bottom:
			break

	var kr := Rect2(r.position.x + 18.0, r.end.y - 100.0, r.size.x - 36.0, 48.0)
	_draw_ink_component(_ink_kepu_box, kr, 6.0, Color("#e9eadb", 0.88), Color(0.6, 0.65, 0.6, 0.36), 0.92)
	_text_left(map.font_song, "科普", 12.0, DAIQING, Vector2(kr.position.x + 11.0, kr.position.y + 17.0))
	if map._kepu.is_empty():
		_text_left(map.font_hei, "知识库占位 · 待接入", 11.0, Color(0.55, 0.55, 0.5), Vector2(kr.position.x + 50.0, kr.position.y + 17.0))
	else:
		var ky := kr.position.y + 32.0
		for k in map._kepu:
			var txt := "「" + String(k["kw"]) + "」" + String(k["text"])
			var fs2 := 11.0
			draw_multiline_string(map.font_hei, Vector2(kr.position.x + 50.0, kr.position.y + 17.0), txt, HORIZONTAL_ALIGNMENT_LEFT, kr.size.x - 60.0, fs2, 1, INK_SOFT, BRK)
			ky += 40.0
			if ky > kr.end.y - 6:
				break
	var input := Rect2(r.position.x + 18.0, r.end.y - 42.0, r.size.x - 76.0, 30.0)
	_draw_ink_component(_ink_chat_bubble_dark, input, 15.0, Color(0.04, 0.06, 0.06, 0.72), Color("#9b763b", 0.45), 0.86)
	_text_left(map.font_hei, "说点什么...", 12.0, Color("#bfb59a", 0.68), Vector2(input.position.x + 14.0, input.position.y + 20.0))
	var send_rect := Rect2(r.end.x - 50.0, r.end.y - 49.0, 38.0, 38.0)
	draw_arc(send_rect.get_center(), 17.0, 0.0, TAU, 30, Color("#b88a40", 0.78), 1.5)
	draw_line(send_rect.get_center() + Vector2(-6.0, 7.0), send_rect.get_center() + Vector2(8.0, -8.0), Color("#efe1b7", 0.9), 2.0)
	draw_line(send_rect.get_center() + Vector2(1.0, -10.0), send_rect.get_center() + Vector2(8.0, -8.0), Color("#efe1b7", 0.9), 2.0)

# 右上角时间指示：地平线 + 太阳/月亮沿半圆轨迹运动（左升起、右落下）
func _draw_sun_moon() -> void:
	if map == null:
		return
	var cx := 1195.0
	var horizon_y := 100.0
	var radius := 62.0
	var hour: float = map._time_of_day
	var area := Rect2(1112.0, 14.0, 166.0, 120.0)
	# 背景颜色随时辰平滑变化（午夜黑 → 清晨红 → 正午白 → 傍晚红 → 午夜黑）
	var bg_col: Color
	if hour < 6.0:
		var tb := hour / 6.0
		bg_col = Color("#0a0d18").lerp(Color("#c96a4a"), tb * tb)   # 夜→晨
	elif hour < 12.0:
		var tb := (hour - 6.0) / 6.0
		bg_col = Color("#c96a4a").lerp(Color("#f7f2e2"), tb * tb)   # 晨→正午
	elif hour < 18.0:
		var tb := (hour - 12.0) / 6.0
		bg_col = Color("#f7f2e2").lerp(Color("#c96a4a"), tb * tb)   # 正午→傍晚
	else:
		var tb := (hour - 18.0) / 6.0
		bg_col = Color("#c96a4a").lerp(Color("#0a0d18"), tb * tb)   # 傍晚→夜
	# 背景圆角面板（区分周围）：上半部分随时辰变色，下半部分固定黑色
	var upper := Rect2(area.position, Vector2(area.size.x, horizon_y - area.position.y + 4.0))
	var lower := Rect2(area.position.x, horizon_y + 2.0, area.size.x, area.end.y - horizon_y - 2.0)
	_round_rect_fill(area, 14.0, Color(0.05, 0.05, 0.07, 0.96))
	_round_rect_fill(upper, 14.0, Color(bg_col.r, bg_col.g, bg_col.b, 0.92))
	# 下半部分固定黑色（遮住底色）
	_round_rect_fill(lower, 6.0, Color(0.04, 0.04, 0.05, 0.98))
	_round_rect_stroke(area, 14.0, Color("#c9a45a", 0.55), 1.5)
	# 地平线
	draw_line(Vector2(cx - 68.0, horizon_y), Vector2(cx + 68.0, horizon_y), Color("#3a362e", 0.85), 2.0)
	draw_line(Vector2(cx - 68.0, horizon_y + 3.0), Vector2(cx + 68.0, horizon_y + 3.0), Color("#3a362e", 0.3), 1.0)
	# 夜晚时背景中的星星
	var is_night: bool = hour < 5.0 or hour >= 19.0
	if is_night:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2024
		for i in range(16):
			var sx := 1118.0 + rng.randf_range(0.0, 152.0)
			var sy := 22.0 + rng.randf_range(0.0, 74.0)
			var tw := 0.5 + rng.randf_range(0.0, 0.8)
			draw_circle(Vector2(sx, sy), tw, Color(0.95, 0.97, 1.0, 0.75))
	# 半圆轨迹（虚线示意）
	var trail := PackedVector2Array()
	for i in range(19):
		var a := PI - float(i) / 18.0 * PI
		trail.append(Vector2(cx + cos(a) * radius, horizon_y - sin(a) * radius))
	for i in range(trail.size() - 1):
		draw_line(trail[i], trail[i + 1], Color("#c9a45a", 0.32), 1.0)
	# 太阳（白天 6-18 时）：正午 12 时在正上方
	var sun_visible: bool = hour >= 6.0 and hour <= 18.0
	if sun_visible:
		var t: float = (hour - 6.0) / 12.0          # 0(6时) → 1(18时)
		var ang: float = PI * (1.0 - t)             # PI(左) → 0(右)
		var pos := Vector2(cx + cos(ang) * radius, horizon_y - sin(ang) * radius)
		# 太阳光晕（放大）
		for i in range(4):
			draw_circle(pos, 22.0 - float(i) * 5.0, Color(1.0, 0.82, 0.45, 0.32 - float(i) * 0.07))
		draw_circle(pos, 12.0, Color("#f4c86a"))
		draw_circle(pos, 9.0, Color("#ffe9a8"))
		# 光芒（放大）
		for i in range(8):
			var ga: float = float(i) / 8.0 * TAU + hour * 0.4
			draw_line(pos + Vector2(cos(ga), sin(ga)) * 14.0, pos + Vector2(cos(ga), sin(ga)) * 21.0, Color("#f4c86a", 0.75), 3.0)
	# 月亮（夜晚 18-6 时）：午夜 0 时在正上方
	var moon_hour: float = fmod(hour + 12.0, 24.0)   # 月亮相位 = 太阳 + 12h
	var moon_visible: bool = moon_hour >= 6.0 and moon_hour <= 18.0
	if moon_visible:
		var t2: float = (moon_hour - 6.0) / 12.0
		var ang2: float = PI * (1.0 - t2)
		var pos2 := Vector2(cx + cos(ang2) * radius, horizon_y - sin(ang2) * radius)
		draw_circle(pos2, 22.0, Color(0.9, 0.95, 1.0, 0.22))
		draw_circle(pos2, 11.0, Color("#e8f0f8"))
		# 月牙（放大，以背景色挖去）
		draw_circle(pos2 + Vector2(-3.8, -1.0), 9.2, Color(bg_col.r, bg_col.g, bg_col.b, 0.96))
		draw_circle(pos2, 11.0, Color("#e8f0f8"))
	# 时间文字（时辰）：地平线下方固定白色
	var label: String = map.shichen_label(hour)
	_text_center(map.font_song, label, 15.0, Color(1.0, 1.0, 1.0, 1.0), Vector2(cx, area.end.y - 14.0))

func _draw_clock_popup() -> void:
	var pr: Rect2 = map.clock_popup_rect()
	var anim: float = clampf(map._clock_popup_anim, 0.0, 1.0)
	var e: float = map._ease_in_out_cubic(anim)
	var slide := (1.0 - e) * 48.0
	var alpha := e
	if alpha <= 0.01:
		return
	pr.position.y += slide
	# 去掉黑黑背景：改为浅色半透明纸面，随时间从上方下拉淡入
	_draw_ink_panel(pr, false, 10.0, alpha * 0.94)
	for i in range(map.SHICHEN.size()):
		var sr: Rect2 = map.shichen_rect(i)
		sr.position.y += slide
		var active: bool = map.shichen_index(map._time_of_day) == i
		var key := "shichen_%d" % i
		_draw_ink_component(_ink_shichen_item_active if active else _ink_shichen_item_normal, sr, 6.0, Color(0.79, 0.64, 0.36, 0.7) if active else Color(0.92, 0.9, 0.84, 0.6), Color(0.79, 0.64, 0.36, 0.35), alpha, key, active)
		var col := Color("#1f1810") if active else (Color("#fff0aa") if _is_hot(key) else Color("#3a3428"))
		_text_center(map.font_song, map.shichen_name(i), 14.0, col, sr.get_center())

func _draw_hist_timeline() -> void:
	var anim: float = clampf(map._timeline_anim, 0.0, 1.0)
	var e: float = map._ease_in_out_cubic(anim)
	# 收起/展开切换按钮：位置随动画在两种状态间滑动
	var collapsed_r := Rect2(560.0, 694.0, 160.0, 26.0)
	var expanded_r := Rect2(560.0, 614.0, 160.0, 26.0)
	var k: float = 1.0 - e
	var tr := Rect2(
		lerpf(expanded_r.position.x, collapsed_r.position.x, k),
		lerpf(expanded_r.position.y, collapsed_r.position.y, k),
		lerpf(expanded_r.size.x, collapsed_r.size.x, k),
		lerpf(expanded_r.size.y, collapsed_r.size.y, k)
	)
	var label := "▲ 展开时间轴" if anim < 0.5 else "▼ 收起"
	_draw_left_card(tr, label, "timeline_toggle")
	# 展开状态的时间轴内容：随动画从下方滑入 + 淡入（非线性）
	if anim > 0.02:
		draw_set_transform(Vector2(0.0, (1.0 - e) * 60.0), 0.0, Vector2.ONE)
		_draw_timeline_content(e)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_timeline_content(alpha: float) -> void:
	var r: Rect2 = map.HIST_TIMELINE_RECT
	var bar := Rect2(r.position.x + 18.0, r.position.y + 18.0, r.size.x - 36.0, 6.0)
	if _ink_timeline_track:
		draw_texture_rect(_ink_timeline_track, Rect2(r.position.x, r.position.y + 2.0, r.size.x, 34.0), false, Color(1, 1, 1, 0.76 * alpha))
	else:
		_round_rect_fill(bar, 4.0, Color(0.18, 0.29, 0.32, 0.5 * alpha))
		_round_rect_stroke(bar, 6.0, Color(0.79, 0.64, 0.36, 0.6 * alpha), 1.5)
	var hot_tl: float = _hover_alpha_of("timeline")
	if hot_tl > 0.01:
		_draw_texture_layer(_ink_hover_mist, Rect2(r.position + Vector2(330.0, -20.0), Vector2(450.0, 82.0)), false, 0.38 * alpha * hot_tl)
		_round_rect_stroke(Rect2(bar.position.x - 8.0, bar.position.y - 6.0, bar.size.x + 16.0, 18.0), 6.0, Color(0.99, 0.97, 0.9, 0.62 * alpha * hot_tl), 1.0)
	var y0: float = map.HIST_YEAR_MIN
	var y1: float = map.HIST_YEAR_MAX
	for i in range(map._timeline.size()):
		var ev = map._timeline[i]
		var y: float = ev["year"]
		var t := (y - y0) / (y1 - y0)
		var ex := bar.position.x + t * bar.size.x
		var hot: float = _hover_alpha_of("timeline_ev_%d" % i)
		if hot > 0.01:
			# hover 高亮：放大节点 + 金色光晕（随悬停渐入）
			if _ink_timeline_node_active:
				draw_texture_rect(_ink_timeline_node_active, Rect2(ex - 14.0, bar.get_center().y - 14.0, 28.0, 28.0), false, Color(1, 1, 1, 1.0 * alpha * hot))
			else:
				draw_circle(Vector2(ex, bar.get_center().y), 5.0, Color(1, 0.94, 0.67, alpha * hot))
				draw_arc(Vector2(ex, bar.get_center().y), 7.0, 0.0, TAU, 24, Color(0.97, 0.83, 0.46, 0.95 * alpha * hot), 2.0)
			draw_arc(Vector2(ex, bar.get_center().y), 10.0, 0.0, TAU, 28, Color(1.0, 0.9, 0.55, 0.55 * alpha * hot), 1.5)
		elif _ink_timeline_node:
			draw_texture_rect(_ink_timeline_node, Rect2(ex - 9.0, bar.get_center().y - 9.0, 18.0, 18.0), false, Color(1, 1, 1, 0.78 * alpha))
		else:
			draw_circle(Vector2(ex, bar.get_center().y), 3.0, Color(0.79, 0.64, 0.36, 0.85 * alpha))
	# 当前年份节点位置（支持滑动动画，用插值年份）
	var disp_year: float = map.display_year()
	var t2 := (disp_year - y0) / (y1 - y0)
	var px := bar.position.x + t2 * bar.size.x
	if _ink_gold_dust:
		draw_texture_rect(_ink_gold_dust, Rect2(px - 150.0, bar.get_center().y - 13.0, 300.0, 26.0), false, Color(1, 1, 1, 0.58 * alpha))
	if _ink_timeline_node_active:
		draw_texture_rect(_ink_timeline_node_active, Rect2(px - 18.0, bar.get_center().y - 18.0, 36.0, 36.0), false, Color(1, 1, 1, 1.0 * alpha))
	else:
		draw_circle(Vector2(px, bar.get_center().y), 7.0, Color(0.94, 0.9, 0.82, alpha))
		draw_arc(Vector2(px, bar.get_center().y), 7.0, 0.0, TAU, 20, Color(DAIQING.r, DAIQING.g, DAIQING.b, 1.0 * alpha), 2.5)
	var year_int: int = int(round(disp_year))
	_text_center(map.font_song, "%d" % year_int, 15.0, Color(0.96, 0.85, 0.55, alpha), Vector2(px, bar.end.y + 23.0))
	_text_center(map.font_hei, map.year_era(year_int), 10.0, Color(0.85, 0.79, 0.63, 0.9 * alpha), Vector2(px, bar.end.y + 39.0))
	_text_left(map.font_hei, "582 开皇二年", 11.0, Color(0.94, 0.88, 0.72, 0.76 * alpha), Vector2(r.position.x + 10.0, r.end.y - 8.0))
	_text_right(map.font_hei, "907 唐亡", 11.0, Color(0.94, 0.88, 0.72, 0.76 * alpha), Vector2(r.end.x - 10.0, r.end.y - 8.0))

func _draw_hist_popup() -> void:
	var pr: Rect2 = map.hist_popup_rect()
	_draw_ink_panel(pr, true, 12.0)
	_text_center(map.font_song, "长安城大事记", 20.0, Color("#f2e6cc"), Vector2(pr.get_center().x, pr.position.y + 28.0))
	var list_top := pr.position.y + 52.0
	var list_bottom := pr.end.y - 6.0
	# 列表区使用裁剪容器：遮罩式裁剪，滚动时边框外内容被隐藏
	_hist_clip.position = Vector2(pr.position.x + 8.0, list_top)
	_hist_clip.size = Vector2(pr.size.x - 16.0, list_bottom - list_top)
	_hist_clip.queue_redraw()
	if map._timeline.is_empty():
		_text_center(map.font_hei, "暂无历史数据", 14.0, Color(0.7, 0.74, 0.72), pr.get_center())

func _draw_codex_panel() -> void:
	var pr: Rect2 = map.codex_panel_rect()
	_draw_ink_panel(pr, true, 10.0)
	_draw_texture_layer(_ink_hover_mist, Rect2(pr.position.x - 46.0, pr.position.y - 28.0, 286.0, 88.0), false, 0.22)
	var title_brush := Rect2(pr.position.x + 18.0, pr.position.y + 20.0, pr.size.x - 124.0, 38.0)
	_draw_ink_component(_ink_codex_tab_active, title_brush, 3.0, Color("#efe5cf", 0.92), Color("#d4ad62", 0.54), 1.0)
	_text_left(map.font_song, "长安图鉴", 23.0, Color("#1f1810"), Vector2(title_brush.position.x + 22.0, title_brush.position.y + 27.0))
	# 关闭按钮（右上角）
	var close_r := Rect2(pr.end.x - 44.0, pr.position.y + 12.0, 28.0, 28.0)
	_draw_ink_close(close_r, 1.0, "codex_close")
	for i in range(3):
		var cr: Rect2 = map.codex_cat_rect(i)
		var active: bool = map._codex_cat == i
		var cnt: int = map.codex_collected_count(i)
		var total: int = map.codex_entries(i).size()
		var key := "codex_cat_%d" % i
		_draw_ink_component(_ink_codex_tab_active if active else _ink_codex_tab_normal, cr, 7.0, Color(0.79, 0.64, 0.36, 0.85) if active else Color(0.16, 0.26, 0.29, 0.7), Color(0.79, 0.64, 0.36, 0.6), 1.0, key, active)
		var tab_col := Color("#1f1810") if active else (Color("#fff0aa") if _is_hot(key) else Color("#eaf1f0"))
		_text_center(map.font_song, map.codex_cat_name(i), 13.0, tab_col, cr.get_center() + Vector2(0.0, -3.0))
		_text_center(map.font_hei, "%d/%d" % [cnt, total], 9.0, Color("#6a4b25", 0.88) if active else Color("#b6a37c", 0.7), cr.get_center() + Vector2(0.0, 12.0))
	# 知识卡片轮播：放入裁剪容器内绘制，超出外框的部分被隐藏
	var area: Rect2 = map.codex_card_area()
	_codex_clip.kind = "codex_cards"
	_codex_clip.position = area.position
	_codex_clip.size = area.size
	_codex_clip.visible = true
	_codex_clip.queue_redraw()
	if map.codex_card_count() <= 0:
		_text_center(map.font_hei, "暂无图鉴数据", 14.0, Color(0.7, 0.74, 0.72), pr.get_center())

# 图鉴知识卡片轮播：中卡聚焦、两侧卡片泛白退后，滑动非线性
func _draw_codex_illustration(r: Rect2, revealed: bool) -> void:
	_round_rect_fill(r, 3.0, Color("#161815", 0.13))
	_round_rect_stroke(r, 3.0, Color("#8a6a3a", 0.32), 1.0)
	var alpha := 0.7 if revealed else 0.34
	_draw_texture_layer(_ink_dark, r, true, 0.12)
	var pen := Color("#3a3021", alpha)
	var ground_y := r.end.y - 12.0
	draw_line(Vector2(r.position.x + 8.0, ground_y), Vector2(r.end.x - 8.0, ground_y - 2.0), pen, 1.2)
	draw_line(Vector2(r.position.x + 18.0, ground_y - 13.0), Vector2(r.position.x + 42.0, ground_y - 25.0), pen, 1.4)
	draw_line(Vector2(r.position.x + 42.0, ground_y - 25.0), Vector2(r.position.x + 70.0, ground_y - 12.0), pen, 1.4)
	draw_line(Vector2(r.position.x + 23.0, ground_y - 12.0), Vector2(r.position.x + 65.0, ground_y - 11.0), pen, 1.1)
	draw_line(Vector2(r.position.x + 29.0, ground_y - 11.0), Vector2(r.position.x + 29.0, ground_y), pen, 1.1)
	draw_line(Vector2(r.position.x + 60.0, ground_y - 10.0), Vector2(r.position.x + 60.0, ground_y), pen, 1.1)
	for i in range(3):
		var x := r.position.x + 34.0 + float(i) * 7.0
		draw_line(Vector2(x, ground_y - 10.0), Vector2(x, ground_y - 2.0), Color("#816133", alpha * 0.74), 0.8)

func _draw_zoom_hint() -> void:
	var names := ["远景（整城）", "中景", "近景（单坊）"]
	var idx := int(map._zoom_idx)
	if idx < 0 or idx >= names.size():
		idx = 1
	var txt: String = "镜头：" + String(names[idx])
	_text_left(map.font_hei, txt, 12.0, Color("#d8c9a0", 0.72), Vector2(42.0, 624.0))

func _frosted(rect: Rect2, radius: float, base: Color, border: Color, a := 1.0) -> void:
	_round_rect_fill(rect, radius, _ca(base, a))
	if _frost and a >= 0.9:
		draw_texture_rect(_frost, rect, true)
	_round_rect_stroke(rect, radius, _ca(border, a), 1.5)

func _draw_texture_layer(tex: Texture2D, rect: Rect2, tile: bool, alpha: float) -> void:
	if tex == null or alpha <= 0.0:
		return
	draw_texture_rect(tex, rect, tile, Color(1, 1, 1, alpha))

func _draw_ink_panel(rect: Rect2, dark: bool, radius: float, alpha := 1.0) -> void:
	var shadow := Rect2(rect.position + Vector2(2.0, 4.0), rect.size)
	_round_rect_fill(shadow, radius, Color(0, 0, 0, 0.28 * alpha))
	var base := Color(0.03, 0.04, 0.04, 0.78 * alpha) if dark else Color(0.91, 0.86, 0.74, 0.80 * alpha)
	var border := Color(0.73, 0.56, 0.28, 0.64 * alpha) if dark else Color(0.48, 0.38, 0.22, 0.48 * alpha)
	_round_rect_fill(rect.grow(-2.0), radius, base)
	var inner := rect.grow(-8.0)
	_draw_texture_layer(_ink_dark if dark else _ink_paper, inner, true, 0.68 * alpha)
	_draw_texture_layer(_ink_noise, inner, true, 0.18 * alpha)
	_draw_texture_layer(_ink_edge, rect.grow(3.0), false, 0.82 * alpha)
	_draw_texture_layer(_ink_frame, rect, false, 0.66 * alpha)
	_round_rect_stroke(rect, radius, border, 1.1)
	if _ink_corner:
		draw_texture_rect(_ink_corner, Rect2(rect.position + Vector2(-12.0, -12.0), Vector2(108.0, 108.0)), false, Color(1, 1, 1, 0.74 * alpha))

func _draw_ink_header(rect: Rect2, dark: bool, radius: float, alpha := 1.0) -> void:
	var title_tex := _ink_title_dark if dark else _ink_title_light
	if title_tex:
		draw_texture_rect(title_tex, rect, false, Color(1, 1, 1, 0.88 * alpha))
		_draw_texture_layer(_ink_separator, Rect2(rect.position + Vector2(18.0, rect.size.y - 7.0), Vector2(rect.size.x - 36.0, 18.0)), false, 0.72 * alpha)
		return
	var base := Color(0.08, 0.12, 0.12, 0.76 * alpha) if dark else Color(0.82, 0.76, 0.62, 0.72 * alpha)
	_round_rect_fill(rect, radius, base)
	_draw_texture_layer(_ink_dark if dark else _ink_paper, rect, true, 0.36 * alpha)
	_draw_texture_layer(_ink_separator, Rect2(rect.position + Vector2(18.0, rect.size.y - 7.0), Vector2(rect.size.x - 36.0, 18.0)), false, 0.72 * alpha)

func _draw_hover_accent(rect: Rect2, radius: float, key: String, alpha := 1.0) -> void:
	var ha := _hover_alpha_of(key)
	if ha <= 0.001:
		return
	var glow := rect.grow(8.0)
	if _ink_hover_mist:
		draw_texture_rect(_ink_hover_mist, glow, false, Color(1, 1, 1, 0.5 * alpha * ha))
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

func _draw_ink_close(rect: Rect2, alpha := 1.0, key := "") -> void:
	var tex := _ink_close
	if _is_pressed(key) and _ink_close_pressed:
		tex = _ink_close_pressed
	elif _is_hot(key) and _ink_close_hover:
		tex = _ink_close_hover
	if tex:
		draw_texture_rect(tex, rect, false, Color(1, 1, 1, alpha))
		_draw_hover_accent(rect, 6.0, key, alpha)
		return
	_round_rect_fill(rect, 6.0, _ca(Color("#cf2d26"), alpha))
	_round_rect_stroke(rect, 6.0, _ca(Color("#a01c16"), alpha), 1.5)
	var cc := rect.get_center()
	draw_line(cc + Vector2(-4, -4), cc + Vector2(4, 4), _ca(Color.WHITE, alpha), 2.5)
	draw_line(cc + Vector2(-4, 4), cc + Vector2(4, -4), _ca(Color.WHITE, alpha), 2.5)
	_draw_hover_accent(rect, 6.0, key, alpha)

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
	_draw_ink_panel(r, true, 14.0, a)
	_draw_ink_header(Rect2(r.position, Vector2(r.size.x, 40)), true, 14.0, a)
	var name := String(map._selected.get("name", ""))
	var type := String(map._selected.get("type", ""))
	_text_left(map.font_song, name, 17.0, _ca(Color("#f2e6cc"), a), Vector2(r.position.x + 14, r.position.y + 25))
	var nw: float = map.font_song.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 17.0).x
	_text_left(map.font_hei, type, 11.0, _ca(Color("#d8c9a0"), a), Vector2(r.position.x + 18 + nw, r.position.y + 25))
	var cb := Rect2(r.end.x - 34.0, r.position.y + 7.0, 24.0, 24.0)
	_draw_ink_close(cb, a, "building_close")
	var body := Rect2(r.position.x + 14, r.position.y + 48, r.size.x - 28, r.size.y - 48 - 72)
	_draw_intro(body)
	var src := String(map._selected.get("source", ""))
	_text_left(map.font_hei, "出处：" + src, 10.0, _ca(Color("#d8c9a0"), a), Vector2(r.position.x + 14, r.end.y - 64))
	if not map._typing_intro:
		_draw_followup_buttons(r)

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
	draw_multiline_string(map.font_hei, Vector2(rect.position.x, y + map.font_hei.get_ascent(fs)), intro, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, _ca(Color("#d7d0bd"), _fade), BRK)
	y += sz.y + 8.0
	for m in map._chat:
		var role := String(m.get("role", ""))
		var text := String(m.get("text", ""))
		var prefix := "问：" if role == "user" else "答："
		var col := _ca(Color("#f3c579"), _fade) if role == "user" else _ca(Color("#eaf1f0"), _fade)
		var tsz: Vector2 = map.font_hei.get_multiline_string_size(prefix + text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, BRK)
		draw_multiline_string(map.font_hei, Vector2(rect.position.x, y + map.font_hei.get_ascent(fs)), prefix + text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, col, BRK)
		y += tsz.y + 6.0
	if map._typing:
		var blink := "▌" if (Time.get_ticks_msec() / 500) % 2 == 0 else ""
		draw_multiline_string(map.font_hei, Vector2(rect.position.x, y + map.font_hei.get_ascent(fs)), "答：" + String(map._typing_text).substr(0, map._typing_visible) + blink, HORIZONTAL_ALIGNMENT_LEFT, width, fs, -1, _ca(Color("#eaf1f0"), _fade), BRK)

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
			_draw_window_button(br, label, Color("#7a2f22"), Color("#8a3b2e"), "followup_%d" % i)
		else:
			_draw_window_button(br, "确认", DAIQING, DAIQING, "followup_%d" % i)

func _draw_window_button(r: Rect2, text: String, text_col: Color, frame_col: Color, key := "") -> void:
	var label_col := text_col
	if _is_hot(key):
		label_col = Color("#5a411f") if not _is_pressed(key) else Color("#302010")
	if _ink_chat_bubble_light:
		draw_texture_rect(_ink_chat_bubble_light, r, false, Color(1, 1, 1, 0.92 * _fade))
		_round_rect_stroke(r, 7.0, Color(frame_col.r, frame_col.g, frame_col.b, 0.65 * _fade), 1.4)
		_draw_hover_accent(r, 7.0, key, _fade)
		_text_center(map.font_song, text, 12.0, label_col, r.get_center())
		return
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
	_draw_hover_accent(r, 7.0, key, _fade)
	_text_center(map.font_song, text, 12.0, label_col, r.get_center())

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
