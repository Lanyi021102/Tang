extends Node2D
# 单个坊（等距矩形 + 坊名标签）— 基于步坐标尺寸

var fang_w := 1.0      # 坊东西宽度（步 × STEP）
var fang_h := 1.0      # 坊南北深度（步 × STEP）
var fang_name := ""
var cell := Vector2.ZERO
var map
var tex: Texture2D = null  # 当前坊的贴图
var is_rect := false       # 是否为长方形坊

const SIDE := Color("#8a7348")
const INK := Color("#3a362e")

func _ready() -> void:
	if tex:
		print("[FANG] %s 贴图已设置: %s (%dx%d)" % [fang_name, tex.resource_path, tex.get_width(), tex.get_height()])
	else:
		print("[FANG] %s 贴图为 NULL" % fang_name)
	queue_redraw()

func _draw() -> void:
	var fang_scale := 1.0
	if map != null:
		var zoom: float = map._camera.zoom.x
		if zoom < 0.01:
			fang_scale = 0.1 / maxf(zoom, 0.0001)
	var hw := fang_w * 0.5 * fang_scale * 9.9   # 东西宽度方向 ×2 补偿等距压缩
	var hh := fang_h * 0.5 * fang_scale * 9.9   # 南北深度方向保持不变
	var NW := Vector2((-hw - hh) * 6.4, (-hw + hh) * 3.2)
	var NE := Vector2((hw - hh) * 6.4, (hw + hh) * 3.2)
	var SE := Vector2((hw + hh) * 6.4, (hw - hh) * 3.2)
	var SW := Vector2((-hw + hh) * 6.4, (-hw - hh) * 3.2)
	var dn := Vector2(0, 6)
	_poly(PackedVector2Array([SW, SE, SE + dn, SW + dn]), SIDE.darkened(0.1))
	_poly(PackedVector2Array([SE, NE, NE + dn, SE + dn]), SIDE.darkened(0.3))
	
	# 渲染贴图或默认颜色
	if tex:
		var pts := PackedVector2Array([NW, NE, SE, SW])
		# 等轴视角贴图的 UV 映射 + 缩放调整
		# 基础 UV：菱形贴图的四个角对应图片的中心菱形区域
		# UV: NW=(0.5, 0), NE=(1, 0.5), SE=(0.5, 1), SW=(0, 0.5)
		
		# 计算缩放因子，使贴图菱形完全填满地块菱形
		# 注意：scale_factor < 1.0 会让贴图变大（UV范围缩小，拉伸到相同顶点）
		# scale_factor > 1.0 会让贴图变小（UV范围扩大，压缩到相同顶点）
		
		var uv_center := Vector2(0.5, 0.5)
		var uv_half_x := 0.0  # X方向半宽
		var uv_half_y := 0.0  # Y方向半高
		
		if is_rect:
			# 长方形坊：独立控制长边（X方向）和短边（Y方向）
			uv_half_x = 0.5 * 0.80465  # 长边缩放：从0.7315增加10%到0.80465，再缩短10%
			uv_half_y = 0.5 * 0.605    # 短边保持：0.605不变，确保贴合
		else:
			# 正方形坊：等比例缩放
			var uniform_scale := 0.7986  # 从0.726增加10%到0.7986
			uv_half_x = 0.5 * uniform_scale
			uv_half_y = 0.5 * uniform_scale
		
		var uvs := PackedVector2Array([
			Vector2(0.5 - uv_half_x, 0.5 - uv_half_y),  # NW → 左上角
			Vector2(0.5 + uv_half_x, 0.5 - uv_half_y),  # NE → 右上角
			Vector2(0.5 + uv_half_x, 0.5 + uv_half_y),  # SE → 右下角
			Vector2(0.5 - uv_half_x, 0.5 + uv_half_y)   # SW → 左下角
		])
		
		# 使用标准UV映射，不进行几何旋转
		var final_pts := pts
		
		var colors := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
		draw_polygon(final_pts, colors, uvs, tex)
	else:
		_poly(PackedVector2Array([NW, NE, SE, SW]), Color("#cdbb8f"))
	var outline := PackedVector2Array([NW, NE, SE, SW, NW])
	for i in range(4):
		draw_line(outline[i], outline[i + 1], Color.BLACK, 3.0)
	# 坊名标签
	if fang_name != "" and map != null and map._zoom_idx >= 2:
		var zoom: float = map._camera.zoom.x
		if zoom <= 0.0:
			zoom = 1.0
		var fs := 14.0 / zoom
		var font: Font = map.font_song
		var w: float = font.get_string_size(fang_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var o := 1.0 / zoom
		var off := 26.0 / zoom
		for ox in [-o, o]:
			for oy in [-o, o]:
				draw_string(font, Vector2(-w * 0.5 + ox, -off + oy), fang_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.95, 0.92, 0.85, 0.9))
		draw_string(font, Vector2(-w * 0.5, -off), fang_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)

func set_map_ref(m) -> void:
	map = m

func _poly(points: PackedVector2Array, color: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(points)
	for t in range(0, idx.size(), 3):
		draw_colored_polygon(PackedVector2Array([points[idx[t]], points[idx[t + 1]], points[idx[t + 2]]]), color)
