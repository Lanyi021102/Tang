extends Node2D
# 坊名标签独立顶层绘制层：挂在 World/FangLabels（z 最高），保证标签不被坊框/街道/建筑遮挡。
# 每个坊的标签按 fang 节点世界位置绘制，远景(zoom_idx==0)用屏幕恒定 16px 小字号光栅，
# 中/近景沿用世界字号公式（屏幕字高 12~26px）。

var map

func _ready() -> void:
	queue_redraw()

func set_map_ref(m) -> void:
	map = m
	queue_redraw()

func _draw() -> void:
	if map == null:
		return
	var zcam: float = 0.04
	if map._camera != null:
		zcam = map._camera.zoom.x
	if zcam <= 0.0:
		zcam = 0.04
	var far_view: bool = int(map._zoom_idx) == 0
	var font: Font = map.font_qiji if map.font_qiji != null else map.font_song
	var tag_tex: Texture2D = map.fang_tag_tex
	var fangs := get_node_or_null("Fangs")
	if fangs == null:
		fangs = map.get_node_or_null("World/Fangs")
	if fangs == null:
		return
	for fang in fangs.get_children():
		var fname: String = String(fang.get("fang_name"))
		if fname == "":
			continue
		var scr_h: float = 16.0
		var fs: float
		if far_view:
			fs = scr_h
			# 局部单位 = 屏幕像素：把原点移到坊中心并放大 1/zoom
			draw_set_transform(fang.position, 0.0, Vector2(1.0 / zcam, 1.0 / zcam))
		else:
			scr_h = clampf(14.0 * pow(zcam / 0.04, 0.3), 12.0, 26.0)
			fs = scr_h / zcam
			draw_set_transform(fang.position, 0.0, Vector2.ONE)
		var chars := fname.split("")
		var char_w := 0.0
		for c in chars:
			char_w = maxf(char_w, font.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var line_h := fs * 1.15
		var px := fs * 0.42
		var py := fs * 0.3
		var cw := char_w + px * 2.0
		var ch := line_h * chars.size() + py * 2.0
		if tag_tex != null:
			var tw: float = tag_tex.get_width()
			var th: float = tag_tex.get_height()
			if tw > 0.0 and th > 0.0:
				var pad_y := fs * 0.5
				var tag_h := ch + pad_y * 2.0
				var tag_w := tag_h * (tw / th)
				draw_texture_rect(tag_tex, Rect2(-tag_w * 0.5, -tag_h * 0.5, tag_w, tag_h), false, Color(1, 1, 1, 0.95))
		else:
			var rect := Rect2(-cw * 0.5, -ch * 0.5, cw, ch)
			draw_rect(rect, Color(0.12, 0.10, 0.08, 0.85))
			# 描边：非远景在世界坐标画 1 屏 px；远景 transform 下局部单位即屏幕 px
			var stroke := maxf(1.0 / zcam, 1.0) if not far_view else 1.0
			draw_rect(rect, Color(0.75, 0.68, 0.55, 0.6), false, stroke)
		var text_color := Color(0.95, 0.92, 0.85)
		for i in range(chars.size()):
			var c: String = chars[i]
			var y := -ch * 0.5 + py + line_h * i + fs * 0.8
			# 水平起笔用 em 半宽（-fs/2）而非单字 advance/2：qiji 单字 advance 仅约
			# 0.8em，墨迹实际按 em 格居中，按 advance 起笔会使整列文字偏右。
			draw_string(font, Vector2(-fs * 0.5, y), c, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
