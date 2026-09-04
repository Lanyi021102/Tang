extends Node2D
# 皇城实体（等距菱形 + 立体侧面，与坊相同形式）

var fang_w := 1.0      # 东西宽度（步 × STEP）
var fang_h := 1.0      # 南北深度（步 × STEP）
var map

var _name_vp: SubViewport
var _name_tex: ViewportTexture
var _name_tex_size := 0.0

const SIDE := Color("#a0522d")
const INK := Color("#3a362e")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var fang_scale := 1.0
	var zoom_idx := 0
	if map != null:
		var zoom: float = map._camera.zoom.x
		zoom_idx = map._zoom_idx
		if zoom < 0.01:
			fang_scale = 0.1 / maxf(zoom, 0.0001)
	var hw := fang_w * 0.5 * fang_scale * 2.0
	var hh := fang_h * 0.5 * fang_scale * 1.0
	var NW := Vector2((-hw - hh) * 6.4, (-hw + hh) * 3.2)
	var NE := Vector2((hw - hh) * 6.4, (hw + hh) * 3.2)
	var SE := Vector2((hw + hh) * 6.4, (hw - hh) * 3.2)
	var SW := Vector2((-hw + hh) * 6.4, (-hw - hh) * 3.2)
	var dn := Vector2(0, 6)
	_poly(PackedVector2Array([SW, SE, SE + dn, SW + dn]), SIDE.darkened(0.1))
	_poly(PackedVector2Array([SE, NE, NE + dn, SE + dn]), SIDE.darkened(0.3))
	_poly(PackedVector2Array([NW, NE, SE, SW]), Color("#c4783e"))
	var outline := PackedVector2Array([NW, NE, SE, SW, NW])
	for i in range(4):
		draw_line(outline[i], outline[i + 1], Color.BLACK, 3.0)
	# 仅远景：竖排卡片式名字（居中于菱形）
	if map != null and zoom_idx == 0:
		var zoom: float = map._camera.zoom.x
		if zoom <= 0.0:
			zoom = 1.0
		var name := "皇城"
		var fs := 18.0 / zoom
		var font: Font = map.font_song
		var chars := name.split("")
		var char_w := 0.0
		for c in chars:
			char_w = maxf(char_w, font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var line_h := fs * 1.15
		var px := fs * 0.4
		var py := fs * 0.3
		var cw := char_w + px * 2.0
		var ch := line_h * chars.size() + py * 2.0
		var rect := Rect2(-cw * 0.5, -ch * 0.5, cw, ch)
		draw_rect(rect, Color(0.12, 0.10, 0.08, 0.85))
		draw_rect(rect, Color(0.85, 0.72, 0.50, 0.6), false, maxf(1.5 / zoom, 1.5))
		_ensure_name_tex(fs, font, chars, char_w, line_h, px, py, cw, ch)
		if _name_tex != null:
			draw_texture(_name_tex, Vector2(-cw * 0.5, -ch * 0.5))
		else:
			var text_color := Color(0.95, 0.92, 0.85)
			for i in range(chars.size()):
				var c: String = chars[i]
				var cx_w: float = font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var cy := -ch * 0.5 + py + line_h * i + fs * 0.8
				draw_string(font, Vector2(-cx_w * 0.5, cy), c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)

func _ensure_name_tex(fs: float, font: Font, chars: Array, char_w: float, line_h: float, px: float, py: float, cw: float, ch: float) -> void:
	if _name_tex != null and absf(_name_tex_size - fs) < 1.0:
		return
	_name_tex_size = fs
	if _name_vp != null:
		_name_vp.queue_free()
	_name_vp = SubViewport.new()
	_name_vp.size = Vector2i(ceili(cw), ceili(ch))
	_name_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_name_vp.transparent_bg = true
	var lbl := Label.new()
	lbl.text = ""
	for c in chars:
		lbl.text += c + "\n"
	lbl.text = lbl.text.strip_edges()
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", ceili(fs))
	lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	lbl.position = Vector2.ZERO
	lbl.size = Vector2(ceili(cw), ceili(ch))
	_name_vp.add_child(lbl)
	add_child(_name_vp)
	_name_tex = _name_vp.get_texture()

func set_map_ref(m) -> void:
	map = m

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)
