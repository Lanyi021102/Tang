extends Node2D
# 单个坊（等距矩形 + 坊名标签）— 基于步坐标尺寸

var fang_w := 1.0      # 坊东西宽度（步 × STEP）
var fang_h := 1.0      # 坊南北深度（步 × STEP）
var fang_name := ""
var cell := Vector2.ZERO
var map
var tex: Texture2D = null  # 当前坊的贴图
var uv_top := Vector2(0.5, 0.0)
var uv_bottom := Vector2(0.5, 1.0)
var uv_left := Vector2(0.0, 0.5)
var uv_right := Vector2(1.0, 0.5)

# ========== UV缩放调整（可手动修改） ==========
# 沿等轴测轴方向缩放（非水平/垂直！）
# ew: 沿等轴测↘方向（垂直线顺时针120°）
# ns: 沿等轴测↙方向（垂直线逆时针120°）
# > 1.0 = 贴图缩小, < 1.0 = 贴图放大
var uv_scale_ew := 1.0
var uv_scale_ns := 1.0
# UV旋转角度（顺时针为正，单位：度）
var uv_rotation_degrees := 0.0
# =============================================

const SIDE := Color("#8a7348")
const INK := Color("#3a362e")
# 每张贴图的内容菱形 UV 缓存（同一贴图只算一次）
static var _uv_cache: Dictionary = {}

func _ready() -> void:
	if tex:
		_compute_diamond_uv()
	queue_redraw()

# 由贴图 alpha 内容包围盒，求出内容菱形四顶点 UV（四边中点 = 菱形角），
# 解决图片四周透明留白导致的"黑边 + 内容与地块菱形错位"
func _compute_diamond_uv() -> void:
	var key := String(tex.resource_path) + "_rot" + str(uv_rotation_degrees)
	if _uv_cache.has(key):
		var d: Dictionary = _uv_cache[key]
		uv_top = d["top"]
		uv_bottom = d["bottom"]
		uv_left = d["left"]
		uv_right = d["right"]
		return
	var img := tex.get_image()
	if img == null:
		return
	var w := img.get_width()
	var h := img.get_height()
	var x0 := w; var x1 := 0; var y0 := h; var y1 := 0
	for yy in range(0, h, 3):
		for xx in range(0, w, 3):
			if img.get_pixel(xx, yy).a > 0.05:
				if xx < x0: x0 = xx
				if xx > x1: x1 = xx
				if yy < y0: y0 = yy
				if yy > y1: y1 = yy
	if x1 < x0 or y1 < y0:
		return
	var cxf := float(x0 + x1) * 0.5 / float(w)
	var cyf := float(y0 + y1) * 0.5 / float(h)
	var center := Vector2(cxf, cyf)
	var half_w_uv := (float(x1 - x0) / float(w)) * 0.5
	var half_h_uv := (float(y1 - y0) / float(h)) * 0.5
	# 等轴测UV缩放：转换到等轴测基(1,1)/(1,-1)缩放后转回
	var se := uv_scale_ew
	var sn := uv_scale_ns
	var scale_a := (se + sn) * 0.5
	var scale_b := (se - sn) * 0.5
	var top_off := Vector2(0, -half_h_uv)
	var bot_off := Vector2(0, half_h_uv)
	var left_off := Vector2(-half_w_uv, 0)
	var right_off := Vector2(half_w_uv, 0)
	# 等轴测缩放后的UV偏移
	var top_scaled := Vector2(top_off.x*scale_a + top_off.y*scale_b, top_off.x*scale_b + top_off.y*scale_a)
	var bot_scaled := Vector2(bot_off.x*scale_a + bot_off.y*scale_b, bot_off.x*scale_b + bot_off.y*scale_a)
	var left_scaled := Vector2(left_off.x*scale_a + left_off.y*scale_b, left_off.x*scale_b + left_off.y*scale_a)
	var right_scaled := Vector2(right_off.x*scale_a + right_off.y*scale_b, right_off.x*scale_b + right_off.y*scale_a)
	# UV旋转（绕中心）
	if abs(uv_rotation_degrees) > 0.001:
		var angle := uv_rotation_degrees * PI / 180.0
		var cos_a := cos(angle)
		var sin_a := sin(angle)
		top_scaled = Vector2(top_scaled.x*cos_a - top_scaled.y*sin_a, top_scaled.x*sin_a + top_scaled.y*cos_a)
		bot_scaled = Vector2(bot_scaled.x*cos_a - bot_scaled.y*sin_a, bot_scaled.x*sin_a + bot_scaled.y*cos_a)
		left_scaled = Vector2(left_scaled.x*cos_a - left_scaled.y*sin_a, left_scaled.x*sin_a + left_scaled.y*cos_a)
		right_scaled = Vector2(right_scaled.x*cos_a - right_scaled.y*sin_a, right_scaled.x*sin_a + right_scaled.y*cos_a)
	var d := {
		"top": center + top_scaled,
		"bottom": center + bot_scaled,
		"left": center + left_scaled,
		"right": center + right_scaled,
	}
	_uv_cache[key] = d
	uv_top = d["top"]
	uv_bottom = d["bottom"]
	uv_left = d["left"]
	uv_right = d["right"]

func _draw() -> void:
	var zcam: float = 0.04
	if map != null and map._camera != null:
		zcam = map._camera.zoom.x
	if zcam <= 0.0:
		zcam = 0.04
	var fang_scale := 1.0
	if map != null:
		# 仅在极远（低于远景下限，正常不可达）时放大保持可见；远景 0.0095 以上保持自然缩放
		if zcam < 0.007:
			fang_scale = 0.1 / maxf(zcam, 0.0001)
	var hw := fang_w * 0.5 * fang_scale * 9.9   # 东西宽度方向 ×2 补偿等距压缩
	var hh := fang_h * 0.5 * fang_scale * 9.9   # 南北深度方向保持不变
	var NW := Vector2((-hw - hh) * 6.4, (-hw + hh) * 3.2)
	var NE := Vector2((hw - hh) * 6.4, (hw + hh) * 3.2)
	var SE := Vector2((hw + hh) * 6.4, (hw - hh) * 3.2)
	var SW := Vector2((-hw + hh) * 6.4, (-hw - hh) * 3.2)

	# 中/近景与远景之间的纹理渐显系数：随相机缩放连续过渡（约1秒）
	# 0=远景（淡色框+轮廓）, 1=中/近景（贴图渐显到不透明）
	var far_z: float = 0.0095
	var mid_z: float = 0.04
	if map != null and map.ZOOM_LEVELS.size() >= 2:
		far_z = map.ZOOM_LEVELS[0]
		mid_z = map.ZOOM_LEVELS[1]
	var tex_fade: float = clampf((zcam - far_z) / (mid_z - far_z), 0.0, 1.0)
	if map != null:
		tex_fade = map._ease_in_out_cubic(tex_fade)
	# 远景淡色框随 tex_fade 升高而淡出
	if tex_fade < 0.999:
		_poly(PackedVector2Array([NW, NE, SE, SW]), Color(0.80, 0.76, 0.60, 0.30 * (1.0 - tex_fade)))
		var rim_w := maxf(1.0 / zcam, 1.0)
		var rim_a := 0.85 * (1.0 - tex_fade)
		if rim_a > 0.01:
			draw_polyline(PackedVector2Array([NW, NE, SE, SW, NW]), Color(0.52, 0.45, 0.30, rim_a), rim_w, true)
	# 中/近景：贴图随 tex_fade 从透明渐显到不透明
	if tex_fade > 0.005 and tex:
		var pts := PackedVector2Array([NW, NE, SE, SW])
		# 内容菱形四顶点映射到地块菱形四角（NW=左, NE=下, SE=右, SW=上）
		var uvs := PackedVector2Array([uv_left, uv_bottom, uv_right, uv_top])
		var fc := Color(1, 1, 1, tex_fade)
		draw_polygon(pts, PackedColorArray([fc, fc, fc, fc]), uvs, tex)
	elif tex_fade <= 0.005 and tex == null:
		_poly(PackedVector2Array([NW, NE, SE, SW]), Color("#cdbb8f"))
	# 坊名标签已移入顶层绘制层 scenes/fang_labels.gd（World/FangLabels），保证不被遮挡。
	# 本节点只负责坊体/远景色框。

func set_map_ref(m) -> void:
	map = m

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	if idx.size() < 3:
		return
	for t in range(0, idx.size(), 3):
		var tri := PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]])
		var a := tri[0]
		var b := tri[1]
		var c := tri[2]
		# 跳过退化/共线三角形（大坐标下 triangulation 偶发失败）
		var cross := (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
		if not is_finite(cross) or absf(cross) < 1.0:
			continue
		draw_colored_polygon(tri, color)
