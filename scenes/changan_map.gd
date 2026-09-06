extends Node2D

# 唐长安城 2.5D 45°等距鸟瞰场景
# Tang Chang'an — 45° isometric bird's-eye view, 3 zoom levels via mouse wheel.

const MENU_SCENE := "res://scenes/Start.tscn"
const UI_SCRIPT := preload("res://scenes/ui_overlay.gd")
const FANG_DIR := "res://assets/fang/"

# UI 逻辑画布基准：所有 UI 常量按 1280x720 设计，由 Overlay/HUD 容器等比放大铺满实际视口（1920x1080 → ×1.5）
const UI_DESIGN_W := 1280.0
const UI_DESIGN_H := 720.0

func ui_scale() -> float:
	return minf(get_viewport_rect().size.x / UI_DESIGN_W, get_viewport_rect().size.y / UI_DESIGN_H)

func ui_visual_offset() -> Vector2:
	var s := ui_scale()
	return (get_viewport_rect().size - Vector2(UI_DESIGN_W * s, UI_DESIGN_H * s)) * 0.5

# 视口/屏幕坐标 → 1280x720 设计坐标（供手写命中判定与绘制换算）
func screen_to_ui(p: Vector2) -> Vector2:
	return (p - ui_visual_offset()) / ui_scale()

const CLOCK_RECT := Rect2(1156.0, 16.0, 84.0, 84.0)
const GROUP_CHAT_RECT := Rect2(940.0, 120.0, 300.0, 380.0)
const BUILDING_PANEL_RECT := Rect2(850.0, 30.0, 390.0, 660.0)
const HIST_TIMELINE_RECT := Rect2(180.0, 652.0, 920.0, 54.0)
const HIST_YEAR_MIN := 582
const HIST_YEAR_MAX := 907
# 右上角时间指示区域（地平线 + 太阳月亮）点击可切换时辰
const TIME_AREA_RECT := Rect2(1112.0, 18.0, 166.0, 108.0)
const SHICHEN := ["子时", "丑时", "寅时", "卯时", "辰时", "巳时", "午时", "未时", "申时", "酉时", "戌时", "亥时"]
const CARD_TYPES := ["Gate", "Fang", "Road", "Canal", "Building"]

# isometric tile size (2:1)
const TW := 128.0
const TH := 64.0
const GRID_COLS := 12
const GRID_ROWS := 13
# 图谱项目坐标以历史城区中心为原点；游戏网格以左上角为原点。
# 东侧坊在底图上比西侧多占一列，因此使用独立的横向偏移。
const WEST_POINT_GRID_OFFSET := Vector2(5.0, 3.0)
const EAST_POINT_GRID_OFFSET := Vector2(6.0, 3.0)

# ==================== 唐长安城真实布局数据 ====================
# 每步对应的像素尺寸（可调）
const STEP := 0.1

# 14 条东西大街路宽（步）—— 表格左侧奇数行 C 列
const EW_STREET_WIDTHS := [19, 40, 155, 40, 120, 44, 40, 54, 55, 55, 54, 59, 39, 19]
# 13 行坊的南北纵深（步）—— 表格左侧偶数行 C 列
const EW_FANG_DEPTHS := [736, 737, 814, 814, 500, 544, 540, 515, 525, 530, 520, 530, 590]
# 东西大街名称（与 EW_STREET_WIDTHS 对应）
const EW_STREET_NAMES := [
	"外郭城东西第一街", "外郭城东西第二街", "外郭城东西第三街", "外郭城东西第四街",
	"外郭城东西第五街", "外郭城东西第六街", "外郭城东西第七街", "外郭城东西第八街",
	"外郭城东西第九街", "外郭城东西第十街", "外郭城东西第十一街", "外郭城东西第十二街",
	"外郭城东西第十三街", "外郭城东西第十四街",
]

# 11 条南北大街路宽（步）—— 表格底部 Row 30 偶数列
const NS_STREET_WIDTHS := [20, 42, 63, 108, 63, 155, 67, 134, 68, 68, 25]
# 10 列坊的东西宽度（步）—— 表格底部 Row 30 奇数列
const NS_FANG_WIDTHS := [1115, 1033, 1020, 683, 558, 562, 700, 1022, 1032, 1125]
# 南北大街名称（与 NS_STREET_WIDTHS 对应）
const NS_STREET_NAMES := [
	"朱雀门街西第五街", "朱雀门街西第四街", "朱雀门街西第三街", "朱雀门街西第二街",
	"朱雀门街西第一街", "朱雀门街", "朱雀门街东第一街", "朱雀门街东第二街",
	"朱雀门街东第三街", "朱雀门街东第四街", "朱雀门街东第五街",
]

# 每条东西大街两侧的坊名（西→东，10 个）
# 街 1-4：中间 7 个为皇城，只渲染西侧 3 坊 + 东侧 3 坊
# 街 5-14：全部 10 坊
const EW_FANG_NAMES := [
	["修真坊","安定坊","修德坊","","","","","光宅坊","长乐坊","入苑坊"],
	["普宁坊","休祥坊","辅兴坊","","","","","永昌坊","太宁坊","兴宁坊"],
	["义宁坊","金城坊","颁政坊","","","","","永兴坊","安兴坊","永嘉坊"],
	["居德坊","醴泉坊","布政坊","","","","","崇仁坊","胜业坊","兴庆宫"],
	["群贤坊","西市","延寿坊","太平坊","光禄坊","兴道坊","务本坊","平康坊","东市","道政坊"],
	["怀德坊","西市","光德坊","通义坊","殖业坊","开化坊","崇义坊","宣阳坊","东市","常乐坊"],
	["崇化坊","怀远坊","延康坊","兴化坊","丰乐坊","安仁坊","长兴坊","亲仁坊","安邑坊","靖恭坊"],
	["丰邑坊","长寿坊","崇贤坊","崇德坊","安业坊","光福坊","永乐坊","永宁坊","宣平坊","新昌坊"],
	["待贤坊","嘉会坊","延福坊","怀贞坊","崇业坊","靖善坊","靖安坊","永崇坊","升平坊","升道坊"],
	["永和坊","永平坊","永安坊","宣义坊","永达坊","兰陵坊","安善坊","昭国坊","修行坊","立政坊"],
	["常安坊","通轨坊","敦义坊","丰安坊","道德坊","开明坊","大业坊","晋昌坊","修政坊","敦化坊"],
	["和平坊","归义坊","大通坊","昌明坊","光行坊","保宁坊","昌乐坊","通善坊","青龙坊","缺名"],
	["永阳坊","昭行坊","大安坊","安乐坊","延祚坊","安义坊","安德坊","通济坊","曲池坊","芙蓉园"],
]
# 注：第 14 街（最后一街）南侧无坊，数据保留为空

var font_song: Font
var font_hei: Font
var font_qiji: Font
var font_times: Font
var fang_tag_tex: Texture2D
var btn_frame_tex: Texture2D
var clock_tex: Texture2D
var dial_tex: Texture2D      # 右上时钟表盘（表盘.png）
var hand_tex: Texture2D      # 右上时钟指针（指针.png，黑底已转透明，长=分针/短=时针共用）
var _points: Array = []
var _cfg: Dictionary = {}
var _square_tex: Array = []  # 正方形坊贴图
var _rect_tex: Array = []    # 长方形坊贴图
var _fang_tex_map: Dictionary = {}  # 坊名 -> 贴图（按名精确匹配 + 分级回落）
var _camera: Camera2D

var _selected: Dictionary = {}
var _selected_fang := Vector2(-1, -1)
var _hover_fang := Vector2(-1, -1)
# 皇宫（宫城+皇城整体）步坐标命中范围，由 _build_world 皇宫节点创建时写入；无效=(-1,-1)
var _palace_step_rect := Rect2(-1.0, -1.0, 0.0, 0.0)
var _local_text := ""
var _loading := false
var _error := ""
var _intro_text := ""
var _intro_visible := 0
var _typing_intro := false
var _type_accum_intro := 0.0
var _chat: Array = []
var _messages: Array = []
var _typing := false
var _typing_text := ""
var _typing_visible := 0
var _type_accum := 0.0
var _type_speed := 45.0
var _pending_intro := false
var _fang_outline := PackedVector2Array()      # 选中坊描边（世界坐标）
var _hover_outline := PackedVector2Array()     # 悬停坊描边（世界坐标）
var _time_of_day := 10.0
var _target_hour := 10.0
var _current_year := 740
var _year_display := 740.0  # 时间轴大圆滑动显示用（平滑插值到 _current_year）
var _timeline: Array = []
var _clock_open := false
var _hist_open := false
var _hist_scroll := 0.0
var _hist_anim := 0.0          # 大事记面板从下到上滑入动画：0=收起, 1=展开
var _hist_anim_target := 0.0
var _hist_selected := -1       # 当前展开细节的大事记索引（-1=无）
var _hist_detail_anim := 0.0   # 细节框往下展开的动画：0=收起, 1=展开
var _year_anim := false
var _year_anim_t := 0.0
var _year_to := 740
var _year_dir := 1.0            # 年份跳转时太阳月亮转动方向：未来顺时针(+1)、过去逆时针(-1)
var _time_anim_active := false  # 时辰切换平滑推进（始终顺时针）
var _time_anim_from := 10.0
var _time_anim_to := 10.0
var _time_anim_t := 0.0
var _time_anim_dur := 1.0
var _left_bar_anim := 1.0            # 左侧功能栏动画：1=展开, 0=收起
var _left_bar_anim_target := 1.0
var _clock_popup_anim := 0.0         # 时辰弹窗下移动画：0=收起, 1=展开
var _clock_popup_anim_target := 0.0
var _year_time_from := 10.0          # 年份跳转时时钟起始时刻（用于非线性过渡）
var _ambient: CanvasModulate
var _bg: TextureRect
var _day_lights: Array = []
var _fang_lights: Array = []
var _sun_light: Sprite2D
var _ts_mat: ShaderMaterial
var _ts_focus_y := 0.5
var _ts_band := 0.4
var _ts_blur := 0.06
var _day_hours := [0.0, 6.0, 12.0, 18.0, 21.0, 24.0]
var _day_colors := [Color("#4e5e88"), Color("#cbb080"), Color("#e6d6b8"), Color("#c08060"), Color("#5a6a90"), Color("#4e5e88")]
var _cam_anim := false
var _cam_anim_t := 0.0
var _cam_anim_dur := 1.3
var _cam_from_zoom := 1.0
var _cam_from_pos := Vector2.ZERO
var _cam_to_zoom := 1.0
var _cam_to_pos := Vector2.ZERO
var _panel_raw := 1.0
var _panel_anim_t := 1.0
var _panel_opening := true
var _knowledge_card_back := false
var _card_flip_anim := 0.0    # 建筑知识卡翻转动画：0=正面, 1=反面（cos 翻转）
var _card_flip_target := 0.0
var _chat_scroll := 0.0
var _groups: Array = []
var _pending_group := -1
var _follow_group := -1
var _group_chat: Array = []
var _group_chat_pending: Array = []
var _chat_timer := 0.0
var _group_chat_title := ""
var _group_chat_open := false
var _kepu: Array = []
var _kepu_kb: Dictionary = {}
var _followups: Array = []
var _speaking: Array = []
var _speak_spawn_timer := 2.0
var _cards: Array = []
var _spatial_info: Dictionary = {}
var _card_page := 1
var _card_page_anim := 0.0
var _codex_open := false
var _card_type_idx := 0
var _card_focus := 0
var _card_focus_anim := 0.0   # 焦点卡片滑动动画（非线性，向 _card_focus 逼近）
var _codex_dragging := false    # 正在拖拽滑动图鉴卡片
var _codex_drag_x := 0.0
var _codex_drag_focus := 0.0
var _codex_scroll := 0.0

var _ui
var _world
var _npcs_node
var _markers_node
var _outline_layer
var _fang_labels  # 顶层坊名标签层（World/FangLabels，z 最高）

# camera zoom state
# 三档离散（近/中/远按钮吸附用）
const ZOOM_LEVELS := [0.0095, 0.04, 0.3]
# 各档滚轮可连续缩放的范围（远/中/近），边界相接，滚轮不可跨档
# 远档下限 = 远景快照值 0.0095：整城约占视口 60%，到该视角后不可继续缩小
# （再小会触发 fang_tile 的 <0.01 zoom 补偿绘制，产生重叠怪图）。
const ZOOM_RANGES := [
	[0.0095, 0.02],
	[0.02, 0.12],
	[0.12, 0.6],
]
const ZOOM_WHEEL_STEP := 1.3   # 每格滚轮缩放倍率（细腻）
var _zoom_idx := 0
var _target_zoom := 0.0095
var _target_pos := Vector2.ZERO
var _free_pan := false
# 坊名上次按 zoom 校准的相机缩放（用于在缩放动画期间逐帧重绘，消除名称大小滞后）
var _last_fang_label_zoom := -1.0

# drag state
var _dragging := false
var _drag_start := Vector2.ZERO
var _moved := false

# 左侧功能栏收起/展开状态
var _left_bar_collapsed := false
const LEFT_BAR_EXPANDED_W := 128.0
const LEFT_BAR_COLLAPSED_W := 44.0

# 底部时间轴收起/展开状态
var _timeline_collapsed := false
# 时间轴收起/展开动画插值：0=收起, 1=展开（非线性，每帧向目标逼近）
var _timeline_anim := 1.0
var _timeline_anim_target := 1.0
# 选中坊描边揭示动画进度：0=无, 1=完全显示（非线性）
var _outline_progress := 0.0
var _outline_target := 0.0
var _prev_fang := Vector2(-1, -1)

# 时间轴收起/展开切换按钮区域（与左侧功能按钮同风格横条；收起钮贴底、展开钮在时间轴上方中央）
func timeline_toggle_rect() -> Rect2:
	if _timeline_collapsed:
		return Rect2(580.0, 686.0, 120.0, 34.0)
	return Rect2(580.0, 610.0, 120.0, 34.0)

func toggle_timeline() -> void:
	_timeline_collapsed = not _timeline_collapsed
	_timeline_anim_target = 0.0 if _timeline_collapsed else 1.0
	# 收起时间轴时同步关闭大事记面板及其细节介绍
	if _timeline_collapsed:
		_hist_open = false
		_hist_anim_target = 0.0
		_hist_selected = -1
	if _ui:
		_ui.queue_redraw()
# 收起/展开切换按钮区域（左下角）
func left_bar_rect() -> Rect2:
	var w := LEFT_BAR_EXPANDED_W if not _left_bar_collapsed else LEFT_BAR_COLLAPSED_W
	return Rect2(0.0, 0.0, w, 648.0)

func left_toggle_rect() -> Rect2:
	if _left_bar_collapsed:
		return Rect2(6.0, 560.0, 32.0, 44.0)
	return Rect2(14.0, 560.0, 100.0, 40.0)

func toggle_left_bar() -> void:
	_left_bar_collapsed = not _left_bar_collapsed
	_left_bar_anim_target = 0.0 if _left_bar_collapsed else 1.0
	if _ui:
		_ui.queue_redraw()

# 同步 HUD 中左侧拦截条宽度与底部栏，收起时让出地图区域；收起时隐藏对应按钮
func _sync_hud_guards() -> void:
	var le := _ease_in_out_cubic(clampf(_left_bar_anim, 0.0, 1.0))
	var w := lerpf(LEFT_BAR_EXPANDED_W, LEFT_BAR_COLLAPSED_W, 1.0 - le)
	var hud := get_node_or_null("UI/HUD")
	if hud == null:
		return
	var left_band = hud.get_node_or_null("LeftOpaqueBand")
	if left_band:
		left_band.offset_right = w
	var left_guard = hud.get_node_or_null("LeftGuard")
	if left_guard:
		left_guard.offset_right = w
	var show := le > 0.5
	for n in ["BtnBack", "BtnNear", "BtnMid", "BtnFar", "BtnCodex"]:
		var btn = hud.get_node_or_null(n)
		if btn:
			btn.visible = show
			if btn is CanvasItem:
				btn.modulate.a = clampf(le, 0.0, 1.0)
	# 时间轴收起：底部改为渐变绘制（见 ui_overlay，隐藏实色块避免突兀）
	var bottom_band = hud.get_node_or_null("BottomOpaqueBand")
	if bottom_band:
		bottom_band.visible = false
	var show_g := _timeline_anim > 0.05
	for n in ["BottomUpperGuard", "BottomLeftGuard", "BottomRightGuard", "BottomLowerGuard"]:
		var g = hud.get_node_or_null(n)
		if g:
			g.visible = show_g
			if g is CanvasItem:
				g.modulate.a = clampf(_timeline_anim, 0.0, 1.0)

# grid -> iso
func _iso(c: float, r: float) -> Vector2:
	return Vector2((c - r) * TW * 0.5, (c + r) * TH * 0.5)

# 步坐标 → 等距屏幕坐标
func _step_iso(sx: float, sy: float) -> Vector2:
	return Vector2((sx - sy) * STEP * 64.0, (sx + sy) * STEP * 32.0)

# 第 ci 列坊的西侧 X 步坐标（累加坊宽+街宽）
func _ns_x(ci: int) -> float:
	var x := 0.0
	for i in range(ci):
		x += float(NS_FANG_WIDTHS[i]) + float(NS_STREET_WIDTHS[i])
	return x

# 第 si 行坊的北侧 Y 步坐标（累加坊深+街宽）
func _ew_y(si: int) -> float:
	var y := 0.0
	for i in range(si):
		y += float(EW_FANG_DEPTHS[i]) + float(EW_STREET_WIDTHS[i])
	return y
	return y


func point_grid_position(p: Dictionary) -> Vector2:
	if not p.has("grid_x") or not p.has("grid_y"):
		return Vector2(6.0, 6.0)
	var source_x := float(p.get("grid_x", 0.0))
	var offset := EAST_POINT_GRID_OFFSET if source_x > 0.0 else WEST_POINT_GRID_OFFSET
	return Vector2(
		source_x + offset.x,
		float(p.get("grid_y", 0.0)) + offset.y
	)

func _ready() -> void:
	_setup_fonts()
	_sync_from_data()
	_build_fangs()
	_assign_generic_fang_textures()
	_build_camera()
	_build_lights()
	_build_world()
	_build_ui()
	_init_npcs()
	_sync_hud_guards()
	NetworkManager.chat_response.connect(_on_chat_response)
	_snap_far_entry()
	_redraw_world()
	# 长安城背景音乐（MusicManager 自动交叉淡入；回首页时切「Chang'an Dawn」）
	MusicManager.play("city")

# 进入 ChangAnCity 即为远景（整城约 60%）快照：把相机直接放到远景档，
# 而非历史遗留的 _set_zoom(3)（会被 clamp 到近景）。
func _snap_far_entry() -> void:
	_zoom_idx = 0
	_target_zoom = ZOOM_LEVELS[0]
	_target_pos = _cam_pos_for(0)
	_camera.zoom = Vector2(_target_zoom, _target_zoom)
	_camera.position = _target_pos
	_cam_anim = false
	_follow_group = -1
	_free_pan = false
	GameManager.set_view_mode("far")
	if _ui:
		_ui.queue_redraw()

func _setup_fonts() -> void:
	# 主字体：英文/数字用 Times New Roman，中文回退到 qiji-fallback（同近景/中景/远景按钮字体）
	var qiji_path := "res://assets/fonts/qiji-fallback.ttf"
	var qiji_ff := FontFile.new()
	if ResourceLoader.exists(qiji_path):
		if qiji_ff.load_dynamic_font(qiji_path) != OK:
			qiji_ff = FontFile.new()
	var base := SystemFont.new()
	base.font_names = PackedStringArray(["Times New Roman", "Times", "Georgia"])
	base.allow_system_fallback = true
	if qiji_ff != null and qiji_ff.get_data() != PackedByteArray():
		base.fallbacks = [qiji_ff]
	font_song = base
	font_hei = base
	font_qiji = qiji_ff
	# 时间轴/大事记的公元年份数字用 Times New Roman
	var tf := SystemFont.new()
	tf.font_names = PackedStringArray(["Times New Roman", "Times", "Georgia", "STIX Two Text", "QIJIFALLBACK"])
	tf.allow_system_fallback = true
	font_times = tf
	# 新美术素材：坊名标签底图 / 左栏按钮框 / 时钟贴图
	fang_tag_tex = load("res://assets/ui/fang_label_tag.png") if ResourceLoader.exists("res://assets/ui/fang_label_tag.png") else null
	btn_frame_tex = load("res://assets/ui/btn_frame.png") if ResourceLoader.exists("res://assets/ui/btn_frame.png") else null
	clock_tex = load("res://assets/ui/clock.png") if ResourceLoader.exists("res://assets/ui/clock.png") else null
	# 右上角时钟：表盘 + 指针（指针黑底在绘制层转透明；同一指针素材复制为分针/时针）
	dial_tex = clock_tex  # 时钟使用 clock.png（而非 dial_face.png）
	hand_tex = _key_out_black("res://assets/ui/hand_needle.png") if ResourceLoader.exists("res://assets/ui/hand_needle.png") else null

# 把黑底 PNG 转成透明底纹理（避免叠加黑色方块）。阈值：RGB 均低于阈值视为背景。
func _key_out_black(path: String) -> Texture2D:
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	var th := 0.28   # 亮度阈值（黑背景 0 ~ 金色/亮色 >0.3）
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < th:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

func _sync_from_data() -> void:
	_points = DataManager.points
	_kepu_kb = DataManager.kepu_kb
	_timeline = DataManager.timeline
	_cards = DataManager.knowledge_cards
	_spatial_info = DataManager.spatial_info
	_cfg = DataManager.llm_config
	if _kepu_kb.is_empty():
		_kepu_kb = KEPU

	GameManager.current_year = _current_year
	GameManager.time_of_day = _time_of_day
	_year_display = float(_current_year)

func _build_fangs() -> void:
	# 贴图加载：按坊名匹配正式图，找不到再按分级回落（贵族/平民）
	_square_tex.clear()
	_rect_tex.clear()
	_fang_tex_map.clear()
	var names := [
		"安仁坊", "布政坊", "崇仁坊", "靖善坊", "平康坊", "亲仁坊", "善和坊",
		"太平坊", "通化坊", "通义坊", "宣阳坊", "东市", "西市",
		"贵族坊1", "贵族坊2", "贵族坊3", "贵族坊4",
		"平民坊1", "平民坊2", "平民坊3", "平民坊4",
	]
	for n in names:
		var p: String = "res://assets/fang/" + n + ".png"
		if ResourceLoader.exists(p):
			_fang_tex_map[n] = load(p)
	print("=== 坊贴图加载完毕：%d 张 ===" % _fang_tex_map.size())

# 给某个坊取贴图：只返回精确匹配的专属贴图，无匹配则返回null（显示纯色）
func _fang_tex_for(fname: String, si: int, ci: int) -> Texture2D:
	# 东市使用西市贴图
	if fname == "东市":
		return _fang_tex_map.get("西市", null)
	# 特定坊使用贵族坊贴图
	if fname == "丰乐坊":
		return _fang_tex_map.get("贵族坊3", null)
	if fname == "安业坊":
		return _fang_tex_map.get("贵族坊4", null)
	if fname == "群贤坊":
		return _fang_tex_map.get("贵族坊1", null)
	if fname == "怀德坊":
		return _fang_tex_map.get("贵族坊2", null)
	if fname == "崇业坊":
		return _fang_tex_map.get("平民坊1", null)
	if fname == "兴化坊":
		return _fang_tex_map.get("平民坊2", null)
	if fname == "崇德坊":
		return _fang_tex_map.get("平民坊3", null)
	# 通用坊贴图分配查找
	if _generic_fang_tex_assign.has(fname):
		return _fang_tex_map.get(_generic_fang_tex_assign[fname], null)
	if _fang_tex_map.has(fname):
		return _fang_tex_map[fname]
	return null

var _generic_fang_tex_assign: Dictionary = {}  # 坊名 -> 分配的贴图名（通用坊随机分配）

# 贴图UV参数表：贴图名 -> {ew, ns, rot}
var _tex_uv_params: Dictionary = {
	"亲仁坊": {"ew": 1.26, "ns": 0.76, "rot": -1.0},
	"安仁坊": {"ew": 1.031, "ns": 0.971, "rot": 0.5},
	"崇仁坊": {"ew": 1.1, "ns": 0.9, "rot": 0.0},
	"平康坊": {"ew": 1.3, "ns": 0.714, "rot": -2.0},
	"宣阳坊": {"ew": 1.25, "ns": 0.714, "rot": -2.0},
	"太平坊": {"ew": 1.111, "ns": 0.909, "rot": 0.0},
	"通义坊": {"ew": 1.111, "ns": 0.909, "rot": 0.0},
	"布政坊": {"ew": 0.962, "ns": 1.064, "rot": 0.0},
	"贵族坊1": {"ew": 1.333, "ns": 0.694, "rot": -1.0},
	"贵族坊2": {"ew": 1.333, "ns": 0.694, "rot": -1.0},
	"贵族坊3": {"ew": 1.02, "ns": 1.02, "rot": 0.0},
	"贵族坊4": {"ew": 1.02, "ns": 1.01, "rot": 0.0},
	"平民坊1": {"ew": 1.0, "ns": 1.0, "rot": 0.0},
	"平民坊2": {"ew": 1.176, "ns": 0.833, "rot": 0.0},
	"平民坊3": {"ew": 1.163, "ns": 0.862, "rot": 0.0},
	"靖善坊": {"ew": 1.0, "ns": 1.0, "rot": 0.0},
}

# 为无贴图的坊按区域规则随机分配贴图
func _assign_generic_fang_textures() -> void:
	# 第5-13街（si=4-12）第1-3列（ci=0-2）、第8-10列（ci=7-9）
	var group_a = ["贵族坊1", "贵族坊2", "平康坊", "宣阳坊", "亲仁坊"]
	# 第5-13街（si=4-12）第4列（ci=3）、第7列（ci=6）
	var group_b = ["太平坊", "通义坊", "平民坊2", "平民坊3"]
	# 第5-13街（si=4-12）第5-6列（ci=4-5）
	var group_c = ["平民坊1", "贵族坊3", "贵族坊4", "安仁坊", "靖善坊"]
	# 第1-4街（si=0-3）第1-3列（ci=0-2）、第8-10列（ci=7-9）
	var group_d = ["布政坊", "崇仁坊"]
	for si in range(13):
		for ci in range(10):
			if si >= EW_FANG_NAMES.size() or ci >= EW_FANG_NAMES[si].size():
				continue
			var fname = EW_FANG_NAMES[si][ci]
			if fname == "":
				continue
			if _fang_tex_map.has(fname) or fname == "东市" or fname == "西市":
				continue
			if fname in ["丰乐坊", "安业坊", "群贤坊", "怀德坊", "崇业坊", "兴化坊", "崇德坊"]:
				continue
			var tex_name: String = ""
			var h: int
			if si >= 4:
				if ci <= 2 or ci >= 7:
					h = hash(Vector2i(ci + 100, si + 100))
					tex_name = group_a[(h % group_a.size() + group_a.size()) % group_a.size()]
				elif ci == 3 or ci == 6:
					h = hash(Vector2i(ci + 200, si + 200))
					tex_name = group_b[(h % group_b.size() + group_b.size()) % group_b.size()]
				elif ci >= 4 and ci <= 5:
					h = hash(Vector2i(ci + 300, si + 300))
					tex_name = group_c[(h % group_c.size() + group_c.size()) % group_c.size()]
			else:
				if ci <= 2 or ci >= 7:
					h = hash(Vector2i(ci + 400, si + 400))
					tex_name = group_d[(h % group_d.size() + group_d.size()) % group_d.size()]
			if tex_name != "":
				_generic_fang_tex_assign[fname] = tex_name
	print("=== 通用坊贴图分配完毕：%d 个坊 ===" % _generic_fang_tex_assign.size())
func _build_camera() -> void:
	_camera = get_node("Camera")
	_camera.make_current()

func _build_lights() -> void:
	_ambient = get_node("Ambient")
	_bg = get_node_or_null("Background/Bg")
	var tex: Texture2D = load("res://assets/light_radial.png") if ResourceLoader.exists("res://assets/light_radial.png") else null
	if tex == null:
		return
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var lights := get_node("Lights")
	_day_lights.append(_add_light(lights, tex, mat, _step_iso(4800.0, 3000.0), Vector2(150, 150), Color(1.0, 0.92, 0.74)))
	_day_lights.append(_add_light(lights, tex, mat, _step_iso(2000.0, 5000.0), Vector2(120, 120), Color(1.0, 0.9, 0.7)))
	_day_lights.append(_add_light(lights, tex, mat, _step_iso(7000.0, 5000.0), Vector2(120, 120), Color(1.0, 0.9, 0.7)))
	# sun light (moves east -> west during the day)
	_sun_light = _add_light(lights, tex, mat, _step_iso(4831.5, 4334.0), Vector2(240, 240), Color(1.0, 0.92, 0.74))
	# night candle lights inside every fang (small lamps)
	var fnl := get_node("FangLights")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 777
	for si in range(14):
		if si >= EW_FANG_DEPTHS.size():
			continue  # 第 14 街南侧无坊
		for ci in range(10):
			if si < EW_FANG_NAMES.size() and ci < EW_FANG_NAMES[si].size():
				if EW_FANG_NAMES[si][ci] == "":
					continue
			var fx := _ns_x(ci) + float(NS_STREET_WIDTHS[ci])
			var fy := _ew_y(si) + float(EW_STREET_WIDTHS[si])
			var fw := float(NS_FANG_WIDTHS[ci])
			var fh := float(EW_FANG_DEPTHS[si])
			var n := rng2.randi_range(1, 3)
			for k in range(n):
				var lc := fx + rng2.randf_range(0.2, 0.8) * fw
				var lr := fy + rng2.randf_range(0.2, 0.8) * fh
				_fang_lights.append(_add_light(fnl, tex, mat, _step_iso(lc, lr), Vector2(50, 50), Color(1.0, 0.78, 0.45)))
	_ts_mat = get_node("TiltShift/ColorRect").material

func _add_light(parent: Node2D, tex: Texture2D, mat: CanvasItemMaterial, pos: Vector2, scl: Vector2, color: Color) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = scl
	s.modulate = color
	s.material = mat
	parent.add_child(s)
	return s

func _build_world() -> void:
	_world = get_node_or_null("World")
	if _world == null:
		_world = load("res://scenes/world.gd").new()
		_world.name = "World"
		add_child(_world)
	_world.map = self
	_npcs_node = get_node_or_null("World/NPCs")
	_markers_node = get_node_or_null("World/Markers")
	_outline_layer = get_node_or_null("World/OutlineLayer")
	for layer in ["NPCs", "Markers"]:
		var n = get_node_or_null("World/" + layer)
		if n:
			n.map = self
	if _outline_layer:
		_outline_layer.map = self
	var buildings = get_node_or_null("World/Buildings")
	if buildings:
		for b in buildings.get_children():
			b.map = self
	# ---- 动态创建坊和街道节点 ----
	var FangScript = preload("res://scenes/fang_tile.gd")
	var StreetScript = preload("res://scenes/street_tile.gd")
	# 确保 Fangs 容器存在
	var fangs_node = get_node_or_null("World/Fangs")
	if fangs_node == null:
		fangs_node = Node2D.new()
		fangs_node.name = "Fangs"
		get_node("World").add_child(fangs_node)
	# 清空旧坊节点
	for child in fangs_node.get_children():
		child.queue_free()
	# 确保 Streets 容器存在
	var streets_node = get_node_or_null("World/Streets")
	if streets_node == null:
		streets_node = Node2D.new()
		streets_node.name = "Streets"
		get_node("World").add_child(streets_node)
	# 清空旧街道节点
	for child in streets_node.get_children():
		child.queue_free()
	# ---- 创建东西大街坊 (14 条街 × 10 列) ----
	for si in range(14):
		if si >= EW_FANG_DEPTHS.size():
			break  # 第 14 街南侧无坊
		var fang_ns_depth := float(EW_FANG_DEPTHS[si])  # 坊的南北纵深
		var fy := _ew_y(si) + float(EW_STREET_WIDTHS[si])  # 坊行北边缘 y
		for ci in range(10):
			var fname: String = EW_FANG_NAMES[si][ci]
			if fname == "":
				continue
			# ---- 西市/东市各占两行，合并为一个地块 ----
			# 第二行（si=5）的市集跳过（已在第一行创建合并地块）
			if (fname == "西市" or fname == "东市") and si == 5:
				continue
			var fang_ew_width := float(NS_FANG_WIDTHS[ci])  # 坊的东西宽度
			var fx := _ns_x(ci) + float(NS_STREET_WIDTHS[ci])  # 坊列西边缘 x
			# 创建坊节点
			var node := Node2D.new()
			node.set_script(FangScript)
			node.name = "坊-%d-%d" % [si, ci]
			var center_sx := fx + fang_ew_width * 0.5
			var center_sy: float
			var draw_h: float = fang_ns_depth
			# 市集（西市/东市）合并：跨两行高度
			if (fname == "西市" or fname == "东市") and si == 4:
				draw_h = fang_ns_depth + float(EW_STREET_WIDTHS[5]) + float(EW_FANG_DEPTHS[5])
				center_sy = fy + draw_h * 0.5
			else:
				center_sy = fy + fang_ns_depth * 0.5
			node.position = _step_iso(center_sx, center_sy)
			node.set("fang_name", fname)
			node.set("fang_w", fang_ew_width * STEP)
			node.set("fang_h", draw_h * STEP)
			node.set("cell", Vector2(ci, si))
			node.set("z_index", int(center_sy * 0.4))
			# 分配正式坊贴图
			node.set("tex", _fang_tex_for(fname, si, ci))
			# 坊特定UV缩放覆盖（无覆盖则使用默认值1.0）
			if fname == "亲仁坊":
				node.set("uv_scale_ew", 1.26)  # ew方向比之前再缩小5%
				node.set("uv_scale_ns", 0.76)  # ns方向缩放
				node.set("uv_rotation_degrees", -1.0)  # 逆时针旋转1度
			if fname == "怀德坊":
				node.set("uv_scale_ew", 1.333)
				node.set("uv_scale_ns", 0.694)
			if fname == "安仁坊":
				node.set("uv_scale_ew", 1.031)  # ew方向缩小3%
				node.set("uv_scale_ns", 0.971)  # ns方向扩大3%
				node.set("uv_rotation_degrees", 0.5)  # 顺时针旋转0.5度
			if fname == "崇仁坊":
				node.set("uv_scale_ew", 1.1)  # ew方向缩小10%
				node.set("uv_scale_ns", 0.9)  # ns方向扩大10%
			if fname == "平康坊":
				node.set("uv_scale_ew", 1.3)  # ew方向缩放
				node.set("uv_scale_ns", 0.714)  # ns方向放大40%
				node.set("uv_rotation_degrees", -2.0)  # 逆时针旋转2度
			if fname == "宣阳坊":
				node.set("uv_scale_ew", 1.25)  # ew方向缩小20%
				node.set("uv_scale_ns", 0.714)  # ns方向放大40%
				node.set("uv_rotation_degrees", -2.0)  # 逆时针旋转2度
			if fname == "太平坊":
				node.set("uv_scale_ew", 1.111)  # ew方向缩小10%
				node.set("uv_scale_ns", 0.909)  # ns方向扩大10%
			if fname == "通义坊":
				node.set("uv_scale_ew", 1.111)  # ew方向缩小10%
				node.set("uv_scale_ns", 0.909)  # ns方向扩大10%
			if fname == "布政坊":
				node.set("uv_scale_ew", 0.962)  # ew方向扩大4%
				node.set("uv_scale_ns", 1.064)  # ns方向缩小6%
			if fname == "西市":
				node.set("uv_scale_ew", 1.042)  # ew方向缩小4%
				node.set("uv_scale_ns", 0.952)  # ns方向扩大5%
			if fname == "东市":
				node.set("uv_scale_ew", 1.042)  # ew方向缩小4%
				node.set("uv_scale_ns", 0.952)  # ns方向扩大5%
			if fname == "安业坊":
				node.set("uv_scale_ew", 1.02)  # ew方向缩小2%
				node.set("uv_scale_ns", 1.01)  # ns方向缩小1%
			if fname == "丰乐坊":
				node.set("uv_scale_ew", 1.02)  # ew方向缩小2%
				node.set("uv_scale_ns", 1.02)  # ns方向缩小2%
			if fname == "群贤坊":
				node.set("uv_scale_ew", 1.333)  # ew方向缩小25%
				node.set("uv_scale_ns", 0.694)  # ns方向扩大44%
				node.set("uv_rotation_degrees", -1.0)  # 逆时针旋转1度
			if fname == "怀德坊":
				node.set("uv_scale_ew", 1.333)
				node.set("uv_scale_ns", 0.694)
				node.set("uv_rotation_degrees", -1.0)  # 逆时针旋转1度
			if fname == "兴化坊":
				node.set("uv_scale_ew", 1.176)  # ew方向缩小15%
				node.set("uv_scale_ns", 0.833)  # ns方向扩大20%
			if fname == "崇德坊":
				node.set("uv_scale_ew", 1.163)  # ew方向缩小14%
				node.set("uv_scale_ns", 0.862)  # ns方向扩大16%
			# 通用坊贴图UV参数：按分配的贴图名查找
			if _generic_fang_tex_assign.has(fname):
				var assigned_tex = _generic_fang_tex_assign[fname]
				if _tex_uv_params.has(assigned_tex):
					var uv = _tex_uv_params[assigned_tex]
					node.set("uv_scale_ew", uv.ew)
					node.set("uv_scale_ns", uv.ns)
					if uv.rot != 0.0:
						node.set("uv_rotation_degrees", uv.rot)
			fangs_node.add_child(node)
			node.call("set_map_ref", self)
	# ---- 皇宫（宫城+皇城整体）贴图：中/近景显示贴图与标签，远景由 fang_tile far_view 显示占位框与标签 ----
	var palace_path := "res://assets/fang/皇宫01.png"
	if ResourceLoader.exists(palace_path):
		var palace_tex: Texture2D = load(palace_path)
		# 皇宫区域：ci=3-6, si=0-3（宫城+皇城共12坊大小）
		# 西边缘=ci=3坊西边缘，东边缘=ci=7坊东边缘，北=si=0坊北缘，南=si=4坊南缘
		var p_west := 0.0
		for ci in range(3):
			p_west += float(NS_FANG_WIDTHS[ci]) + float(NS_STREET_WIDTHS[ci])
		var p_east := p_west + float(NS_FANG_WIDTHS[3]) + float(NS_STREET_WIDTHS[3]) + float(NS_FANG_WIDTHS[4]) + float(NS_STREET_WIDTHS[4]) + float(NS_FANG_WIDTHS[5]) + float(NS_STREET_WIDTHS[5]) + float(NS_FANG_WIDTHS[6])
		var p_north := 0.0
		var p_south := float(EW_FANG_DEPTHS[0]) + float(EW_STREET_WIDTHS[1]) + float(EW_FANG_DEPTHS[1]) + float(EW_STREET_WIDTHS[2]) + float(EW_FANG_DEPTHS[2]) + float(EW_STREET_WIDTHS[3]) + float(EW_FANG_DEPTHS[3])
		var pcx := (p_west + p_east) * 0.5
		var pcy := (p_north + p_south) * 0.5
		var pw_steps := p_east - p_west
		var pw := pw_steps * STEP
		var ph := (p_south - p_north) * STEP
		# E方向偏移：皇宫ew方向总宽度的3%（向右下微调对位）
		var e_offset := pw_steps * 0.03
		var offset_x := e_offset * STEP * 64.0
		var offset_y := e_offset * STEP * 32.0
		var pnode := Node2D.new()
		pnode.set_script(FangScript)
		pnode.name = "皇宫"
		pnode.position = _step_iso(pcx, pcy) + Vector2(offset_x, offset_y)
		pnode.set("fang_name", "宫城")
		pnode.set("fang_w", pw)
		pnode.set("fang_h", ph)
		pnode.set("cell", Vector2(5, 2))
		# z 提到合法上限：盖过横贯宫城/皇城的街道网格（南北街 4095），
		# 顶层 FangLabels 同为 4096 但在 World 末尾创建（后画），保证标签在最上。
		pnode.set("z_index", 4096)
		pnode.set("tex", palace_tex)
		# UV缩放修正：ew方向扩大8%，ns方向缩小10%
		pnode.set("uv_scale_ew", 0.926)
		pnode.set("uv_scale_ns", 1.111)
		fangs_node.add_child(pnode)
		pnode.call("set_map_ref", self)
		# 记录皇宫整体步坐标矩形（供点击命中）
		_palace_step_rect = Rect2(p_west, p_north, p_east - p_west, p_south - p_north)
		print("=== 皇宫贴图加载完毕 ===")
	var fang_area_ew := float(NS_FANG_WIDTHS.reduce(func(a, b): return a + b, 0)) + float(NS_STREET_WIDTHS.reduce(func(a, b): return a + b, 0))  # = 9663
	var fang_area_ns := float(EW_FANG_DEPTHS.reduce(func(a, b): return a + b, 0)) + float(EW_STREET_WIDTHS.reduce(func(a, b): return a + b, 0)) - float(EW_STREET_WIDTHS[0]) - float(EW_STREET_WIDTHS[13])  # 不含南北边界路
	for si in range(15):
		var node := Node2D.new()
		node.set_script(StreetScript)
		var road_w: float
		var road_len: float
		var road_y: float
		var sname: String
		if si < 14:
			road_w = float(EW_STREET_WIDTHS[si])
			road_len = fang_area_ew
			road_y = _ew_y(si)
			sname = EW_STREET_NAMES[si]
		else:
			road_w = float(EW_STREET_WIDTHS[13])
			road_len = fang_area_ew
			road_y = _ew_y(13) + float(EW_FANG_DEPTHS[12])
			sname = "外郭城南墙"
		node.name = "EW街%d" % si
		var center_sx := fang_area_ew * 0.5
		var center_sy := road_y + road_w * 0.5
		node.position = _step_iso(center_sx, center_sy)
		node.set("tile_w", road_len * STEP)
		node.set("tile_h", road_w * STEP)
		node.set("tile_name", sname)
		node.set("tile_type", "东西街道")
		node.set("road_width", int(float(EW_STREET_WIDTHS[mini(si, 13)])))
		node.set("road_length", int(road_len))
		node.set("z_index", int(road_y * 0.4))
		node.set("color", Color("#7fae92"))
		streets_node.add_child(node)
		node.call("set_map_ref", self)
	# ---- 创建南北向街道（只覆盖坊区域）----
	for ci in range(12):
		var node := Node2D.new()
		node.set_script(StreetScript)
		var road_w: float
		var road_len: float
		var road_x: float
		var sname: String
		if ci < 11:
			road_w = float(NS_STREET_WIDTHS[ci])
			road_len = fang_area_ns
			road_x = _ns_x(ci)
			sname = NS_STREET_NAMES[ci]
		else:
			road_w = float(NS_STREET_WIDTHS[10])
			road_len = fang_area_ns
			road_x = _ns_x(10) + float(NS_FANG_WIDTHS[9])
			sname = "外郭城东墙"
		node.name = "NS街%d" % ci
		var center_sx := road_x + road_w * 0.5
		var center_sy := fang_area_ns * 0.5
		node.position = _step_iso(center_sx, center_sy)
		node.set("tile_w", road_w * STEP)
		node.set("tile_h", road_len * STEP)
		node.set("tile_name", sname)
		node.set("tile_type", "南北街道")
		node.set("road_width", int(float(NS_STREET_WIDTHS[mini(ci, 10)])))
		node.set("road_length", int(road_len))
		node.set("z_index", 4095)
		node.set("color", Color("#6f9d84"))
		streets_node.add_child(node)
		node.call("set_map_ref", self)

	# ---- 顶层坊名标签层：挂在 World 最后、z 最高，保证坊标签盖过坊框/街道/建筑 ----
	var labels_node = get_node_or_null("World/FangLabels")
	if labels_node == null:
		var FangLabelsScript := load("res://scenes/fang_labels.gd")
		labels_node = Node2D.new()
		labels_node.name = "FangLabels"
		labels_node.set_script(FangLabelsScript)
		labels_node.z_index = 4096
		_world.add_child(labels_node)
	_fang_labels = labels_node
	_fang_labels.set_map_ref(self)

func _redraw_world() -> void:
	if _world:
		_world.queue_redraw()
	if _npcs_node:
		_npcs_node.queue_redraw()
	if _markers_node:
		_markers_node.queue_redraw()
	if _fang_labels:
		_fang_labels.queue_redraw()

func _build_ui() -> void:
	_ui = get_node("UI/Overlay")
	_ui.map = self
	_apply_ui_canvas_layout.call_deferred()
	get_viewport().size_changed.connect(_apply_ui_canvas_layout)

# 把 Overlay/HUD 固定在 1280x720 逻辑画布并等比放大铺满实际视口（保留 1920 视口）。
# 这样全部 UI 常量（1280 系设计）绘制、HUD 真实按钮、clip 容器都自动放大，命中由 Godot 换算。
func _apply_ui_canvas_layout() -> void:
	var s := ui_scale()
	var off := (get_viewport_rect().size - Vector2(UI_DESIGN_W, UI_DESIGN_H) * s) * 0.5
	for path in ["UI/Overlay", "UI/HUD"]:
		var c := get_node_or_null(path) as Control
		if c == null:
			continue
		c.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		c.offset_left = off.x
		c.offset_top = off.y
		c.offset_right = off.x + UI_DESIGN_W
		c.offset_bottom = off.y + UI_DESIGN_H
		c.pivot_offset = Vector2.ZERO
		c.scale = Vector2(s, s)

# ==================== zoom ====================
func _set_zoom(idx: int, snap: bool = false) -> void:
	var new_idx := clampi(idx, 0, ZOOM_LEVELS.size() - 1)
	if new_idx == _zoom_idx:
		return
	_cam_anim = false
	_follow_group = -1
	_zoom_idx = new_idx
	_target_zoom = ZOOM_LEVELS[_zoom_idx]
	if snap:
		_target_pos = _cam_pos_for(_zoom_idx)
		_camera.zoom = Vector2(_target_zoom, _target_zoom)
		_camera.position = _target_pos
	_free_pan = false
	var _view_mode := "far" if _zoom_idx == 0 else ("near" if _zoom_idx == ZOOM_LEVELS.size() - 1 else "mid")
	GameManager.set_view_mode(_view_mode)
	if _ui:
		_ui.queue_redraw()
	# 缩放变化时触发坊和皇城重绘（更新名字显示）
	var fangs_node = get_node_or_null("World/Fangs")
	if fangs_node:
		for child in fangs_node.get_children():
			child.queue_redraw()

func _cam_pos_for(idx: int) -> Vector2:
	# 城市中心：东西 4831.5 步，南北 4334 步（world.gd 地面菱形几何中心）
	var center := _step_iso(4831.5, 4334.0)
	match idx:
		0:
			# 远景整城：以地面菱形几何中心取景
			return center
		2:
			return _near_fang_center()
		_:
			return _iso(6.0, 6.5) + Vector2(0, 40)

func _near_fang_center() -> Vector2:
	# 默认放大到城南区域（坊密集区）
	return _step_iso(4831.5, 6000.0)

# 滚轮缩放：仅在当前档（_zoom_idx）允许的范围内连续细腻缩放，不跨越档位。
# 跨档需点击「近景 / 中景 / 远景」按钮（_set_zoom）。
func _wheel_zoom(dir: int) -> void:
	if _zoom_idx < 0 or _zoom_idx >= ZOOM_RANGES.size():
		return
	var range_min: float = ZOOM_RANGES[_zoom_idx][0]
	var range_max: float = ZOOM_RANGES[_zoom_idx][1]
	var factor := ZOOM_WHEEL_STEP if dir > 0 else 1.0 / ZOOM_WHEEL_STEP
	_target_zoom = clampf(_target_zoom * factor, range_min, range_max)
	_cam_anim = false
	_free_pan = false
	if _ui:
		_ui.queue_redraw()
	# 缩放变化时触发坊和皇城重绘（更新名字显示）
	_refresh_fang_labels()

# 名称字号按实时 zoom 计算（fs=14/zoom，屏幕恒定）；缩放动画期间相机 zoom 每帧变化，
# 若不逐帧重绘校准，名称会先随地图放大、动画结束又不回落，观感明显滞后。
# 此函数在 _process 每帧相机更新后调用：zoom 与上次校准值有差异时重绘坊标签。
func _sync_fang_label_zoom() -> void:
	var z: float = _camera.zoom.x
	if absf(z - _last_fang_label_zoom) <= 0.0002:
		return
	_last_fang_label_zoom = z
	_refresh_fang_labels()

func _refresh_fang_labels() -> void:
	var fangs_node = get_node_or_null("World/Fangs")
	if fangs_node:
		for child in fangs_node.get_children():
			child.queue_redraw()
	if _fang_labels:
		_fang_labels.queue_redraw()

func _ease_out_cubic(t: float) -> float:
	var u := 1.0 - t
	return 1.0 - u * u * u

func _ease_in_out_cubic(t: float) -> float:
	if t < 0.5:
		return 4.0 * t * t * t
	var u := -2.0 * t + 2.0
	return 1.0 - u * u * u * 0.5

func _ease_out_back(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	var u := t - 1.0
	return 1.0 + c3 * u * u * u + c1 * u * u

func _start_cam_anim(to_zoom: float, to_pos: Vector2) -> void:
	_cam_from_zoom = _camera.zoom.x
	_cam_from_pos = _camera.position
	_cam_to_zoom = to_zoom
	_cam_to_pos = to_pos
	_cam_anim_t = 0.0
	_cam_anim = true
	_target_zoom = to_zoom
	_target_pos = to_pos

func _world_to_screen(world: Vector2) -> Vector2:
	var vs := get_viewport().get_visible_rect().size
	return (world - _camera.position) * _camera.zoom + vs * 0.5

func _update_fang_outline() -> void:
	_fang_outline = _outline_for(_selected_fang)
	_hover_outline = PackedVector2Array()
	if _hover_fang.x >= 0 and _hover_fang != _selected_fang:
		_hover_outline = _outline_for(_hover_fang)
	if _selected_fang != _prev_fang:
		_prev_fang = _selected_fang
		if _selected_fang.x >= 0:
			_outline_progress = 0.0
			_outline_target = 1.0
		else:
			_outline_target = 0.0
	_ui.queue_redraw()
	_refresh_outline_layer()

# 更新时间轴收起/展开动画与选中描边动画（非线性）
func _update_ui_anims(delta: float) -> void:
	if absf(_timeline_anim - _timeline_anim_target) > 0.0005:
		_timeline_anim = lerpf(_timeline_anim, _timeline_anim_target, delta * 7.0)
		_sync_hud_guards()
		if _ui:
			_ui.queue_redraw()
	if absf(_left_bar_anim - _left_bar_anim_target) > 0.0005:
		_left_bar_anim = lerpf(_left_bar_anim, _left_bar_anim_target, delta * 8.0)
		_sync_hud_guards()
		if _ui:
			_ui.queue_redraw()
	if absf(_clock_popup_anim - _clock_popup_anim_target) > 0.0005:
		_clock_popup_anim = lerpf(_clock_popup_anim, _clock_popup_anim_target, delta * 8.0)
		if _ui:
			_ui.queue_redraw()
	if absf(_hist_anim - _hist_anim_target) > 0.0005:
		_hist_anim = lerpf(_hist_anim, _hist_anim_target, delta * 7.0)
		if _ui:
			_ui.queue_redraw()
	if _hist_anim <= 0.02 and _hist_selected >= 0:
		_hist_selected = -1
		_hist_detail_anim = 0.0
	if absf(_hist_detail_anim - (1.0 if _hist_selected >= 0 else 0.0)) > 0.0005:
		_hist_detail_anim = lerpf(_hist_detail_anim, (1.0 if _hist_selected >= 0 else 0.0), delta * 8.0)
		if _ui:
			_ui.queue_redraw()
	if absf(_card_flip_anim - _card_flip_target) > 0.0005:
		_card_flip_anim = lerpf(_card_flip_anim, _card_flip_target, delta * 9.0)
		if _ui:
			_ui.queue_redraw()
	if absf(_outline_progress - _outline_target) > 0.0005:
		_outline_progress = lerpf(_outline_progress, _outline_target, delta * 6.0)
		_refresh_outline_layer()

# 选中描边揭示进度（已应用非线性缓动）
func outline_reveal() -> float:
	return _ease_in_out_cubic(clampf(_outline_progress, 0.0, 1.0))

# 刷新描边层重绘
func _refresh_outline_layer() -> void:
	if _outline_layer:
		_outline_layer.queue_redraw()

func _outline_for(cell: Vector2) -> PackedVector2Array:
	if cell.x < 0:
		return PackedVector2Array()
	var ci := int(cell.x)
	var si := int(cell.y)
	if si >= EW_FANG_DEPTHS.size() or ci >= 10:
		return PackedVector2Array()
	var fx := _ns_x(ci) + float(NS_STREET_WIDTHS[ci])
	var fy := _ew_y(si) + float(EW_STREET_WIDTHS[si])
	var fw := float(NS_FANG_WIDTHS[ci])
	var fh := float(EW_FANG_DEPTHS[si])
	var corners := PackedVector2Array([
		_step_iso(fx, fy),
		_step_iso(fx + fw, fy),
		_step_iso(fx + fw, fy + fh),
		_step_iso(fx, fy + fh),
	])
	var out := PackedVector2Array()
	for p in corners:
		out.append(p)
	out.append(corners[0])
	return out

func set_time(hour: float, smooth := false) -> void:
	var target := clampf(hour, 0.0, 24.0)
	_target_hour = target
	if _year_anim:
		# 手动调时打断年份跳转动画：年份落定，时钟归用户控制
		_year_anim = false
		_current_year = _year_to
		_year_display = float(_current_year)
		GameManager.set_year(_current_year)
	if not smooth:
		_time_of_day = target
		_time_anim_active = false
	else:
		var from := _time_of_day
		if shichen_index(target) == shichen_index(from):
			# 点击当前时辰：直接到位，不空转
			_time_of_day = target
			_time_anim_active = false
		else:
			# 始终顺时针推进：目标不早于当前时刻，必要时绕一圈（+24h）
			var to := target
			if to <= from:
				to += 24.0
			_time_anim_from = from
			_time_anim_to = to
			_time_anim_t = 0.0
			_time_anim_dur = maxf(0.9, (to - from) / 24.0 * 3.0)  # 全圈约3秒，非线性缓动
			_time_anim_active = true
	GameManager.set_time(_target_hour)
	_ui.queue_redraw()

func _update_time(delta: float) -> void:
	if _year_anim:
		_year_anim_t += delta
		# 时钟随年份跳转做非线性过渡（和时辰切换一致），而非匀速转动
		var t := clampf(_year_anim_t / 1.5, 0.0, 1.0)
		var e := _ease_in_out_cubic(t)
		_time_of_day = fposmod(_year_time_from + (fmod(_target_hour - _year_time_from, 24.0)) * e, 24.0)
		# 时钟转动的同时，时间轴大圆同步滑向目标年份
		_year_display = lerpf(_year_display, float(_year_to), delta * 5.0)
		if _year_anim_t >= 1.5:
			_year_anim = false
			_current_year = _year_to
			_year_display = float(_current_year)
			_time_of_day = _target_hour
			GameManager.set_year(_current_year)
			GameManager.set_time(_time_of_day)
			_ui.queue_redraw()
	elif _time_anim_active:
		_time_anim_t += delta
		var t := clampf(_time_anim_t / _time_anim_dur, 0.0, 1.0)
		var e := _ease_in_out_cubic(t)
		_time_of_day = fposmod(lerpf(_time_anim_from, _time_anim_to, e), 24.0)
		_ui.queue_redraw()
		if t >= 1.0:
			_time_anim_active = false
			_time_of_day = fposmod(_time_anim_to, 24.0)
	elif absf(_time_of_day - _target_hour) > 0.02:
		_time_of_day = lerpf(_time_of_day, _target_hour, delta * 4.0)
		_ui.queue_redraw()
	else:
		_time_of_day = _target_hour
	# 非动画状态（如直接点击时间轴事件点）：大圆平滑滑动到目标年份
	if not _year_anim and absf(_year_display - float(_current_year)) > 0.05:
		_year_display = lerpf(_year_display, float(_current_year), delta * 5.0)
		if absf(_year_display - float(_current_year)) <= 0.05:
			_year_display = float(_current_year)
		_ui.queue_redraw()

func _jump_to_year(year: int) -> void:
	_year_to = clampi(year, HIST_YEAR_MIN, HIST_YEAR_MAX)
	# 过去（更早年份）：太阳月亮逆时针转；未来（更晚年份）：顺时针转
	_year_dir = -1.0 if _year_to < _current_year else 1.0
	_year_anim = true
	_year_anim_t = 0.0
	_year_time_from = _time_of_day
	_time_anim_active = false
	_ui.queue_redraw()

# 时间轴大圆当前显示年份（平滑插值中）
func display_year() -> float:
	return _year_display

func shichen_index(hour: float) -> int:
	return (int(hour) % 24) / 2

func shichen_name(i: int) -> String:
	return SHICHEN[i]

func shichen_label(hour: float) -> String:
	return SHICHEN[shichen_index(hour)]

func year_era(year: int) -> String:
	return "隋·大兴城" if year < 618 else "唐·长安城"

func nearby_event_title(year: int) -> String:
	var best := ""
	for ev in _timeline:
		var y: int = ev["year"]
		if y <= year and absi(year - y) <= 10:
			best = String(ev["title"])
	return best

func clock_popup_rect() -> Rect2:
	return Rect2(1124.0, 132.0, 132.0, SHICHEN.size() * 26.0 + 14.0)

func shichen_rect(i: int) -> Rect2:
	var pr := clock_popup_rect()
	return Rect2(pr.position.x + 8.0, pr.position.y + 10.0 + float(i) * 26.0, pr.size.x - 16.0, 22.0)

func group_chat_close_rect() -> Rect2:
	return Rect2(GROUP_CHAT_RECT.end.x - 34.0, GROUP_CHAT_RECT.position.y + 7.0, 24.0, 24.0)

func building_close_rect() -> Rect2:
	return Rect2(BUILDING_PANEL_RECT.end.x - 32.0, BUILDING_PANEL_RECT.position.y + 18.0, 18.0, 18.0)

func followup_button_rect(i: int) -> Rect2:
	var bx := BUILDING_PANEL_RECT.position.x + 14.0
	var by := BUILDING_PANEL_RECT.end.y - 56.0
	var bw := (BUILDING_PANEL_RECT.size.x - 28.0 - 16.0) / 3.0
	return Rect2(bx + float(i) * (bw + 8.0), by, bw, 44.0)

func hist_popup_rect() -> Rect2:
	return Rect2(356.0, 70.0, 568.0, 500.0)

func hist_event_rect(i: int) -> Rect2:
	var pr := hist_popup_rect()
	# 展开的细节框会把其后的行往下推（回流），避免遮住下方内容
	var dy := 0.0
	if _hist_selected >= 0 and i > _hist_selected:
		dy = _hist_detail_shift()
	return Rect2(pr.position.x + 16.0, pr.position.y + 56.0 + float(i) * 52.0 - _hist_scroll + dy, pr.size.x - 32.0, 48.0)

# 展开细节框对下方行的下推量（随非线性动画同步推进）
func _hist_detail_shift() -> float:
	if _hist_selected < 0:
		return 0.0
	return _ease_in_out_cubic(clampf(_hist_detail_anim, 0.0, 1.0)) * 74.0

# 大事记列表最大滚动量（保证最后一项不滚出可视区）
func hist_max_scroll() -> float:
	var pr := hist_popup_rect()
	var list_h := pr.size.y - 56.0 - 12.0
	var content_h := float(_timeline.size()) * 52.0 + _hist_detail_shift()
	return maxf(0.0, content_h - list_h)

# 时间轴某事件点在屏幕上的位置（与 ui_overlay._draw_hist_timeline 的 bar 计算一致）
func timeline_event_screen_pos(i: int) -> Vector2:
	var r: Rect2 = HIST_TIMELINE_RECT
	var bar := Rect2(r.position.x + 18.0, r.position.y + 18.0, r.size.x - 36.0, 6.0)
	var t := (float(_timeline[i]["year"]) - float(HIST_YEAR_MIN)) / float(HIST_YEAR_MAX - HIST_YEAR_MIN)
	return Vector2(bar.position.x + t * bar.size.x, bar.get_center().y)

# 根据屏幕 x 坐标找到最近的事件点索引（容差约 14px），找不到返回 -1
func timeline_event_at_x(x: float) -> int:
	var best := -1
	var best_dist := 14.0
	for i in range(_timeline.size()):
		var d := absf(timeline_event_screen_pos(i).x - x)
		if d < best_dist:
			best_dist = d
			best = i
	return best

func codex_panel_rect() -> Rect2:
	# 居中于 1280x720 UI 逻辑画布（Overlay 被 scale 放大到视口）
	var w := 720.0
	var h := 680.0
	return Rect2((UI_DESIGN_W - w) * 0.5, 20.0, w, h)

func codex_type_rect(i: int) -> Rect2:
	var pr := codex_panel_rect()
	var w := (pr.size.x - 48.0) / 5.0
	return Rect2(pr.position.x + 18.0 + float(i) * w, pr.position.y + 70.0, w - 7.0, 34.0)

func codex_page_btn_rect(i: int) -> Rect2:
	var pr := codex_panel_rect()
	var total_w := 3.0 * 120.0
	var start_x := pr.position.x + (pr.size.x - total_w) * 0.5
	return Rect2(start_x + float(i) * 120.0, pr.position.y + 112.0, 110.0, 30.0)

func codex_entry_rect(i: int) -> Rect2:
	var pr := codex_panel_rect()
	return Rect2(pr.position.x + 20.0, pr.position.y + 120.0 + float(i) * 52.0 - _codex_scroll, pr.size.x - 40.0, 46.0)

func codex_detail_rect() -> Rect2:
	var pr := codex_panel_rect()
	return Rect2(pr.position.x + 20.0, pr.position.y + 326.0, pr.size.x - 40.0, pr.size.y - 346.0)

# 图鉴条目列表最大滚动量（保证最后一项不滚出可视区）
func codex_max_scroll() -> float:
	var pr := codex_panel_rect()
	var detail_rect := codex_detail_rect()
	var list_top: float = pr.position.y + 116.0
	var list_h := detail_rect.position.y - 8.0 - list_top
	var content_h := float(codex_entries(_card_type_idx).size()) * 52.0
	return maxf(0.0, content_h - list_h)

# ---- 图鉴知识卡片轮播 ----
func codex_card_size() -> Vector2:
	return Vector2(340.0, 480.0)

func codex_card_stride() -> float:
	return codex_card_size().x + 28.0

func codex_card_area() -> Rect2:
	var pr := codex_panel_rect()
	var top: float = pr.position.y + 152.0
	return Rect2(pr.position.x + 10.0, top, pr.size.x - 20.0, pr.end.y - 16.0 - top)

func codex_card_count() -> int:
	return _cards_of_type(_card_type_idx).size()

func _cards_of_type(type_idx: int) -> Array:
	if type_idx < 0 or type_idx >= CARD_TYPES.size():
		return []
	var t: String = CARD_TYPES[type_idx]
	var result := []
	for card in _cards:
		if card.get("type", "") == t:
			result.append(card)
	return result

func _current_card() -> Dictionary:
	var cards := _cards_of_type(_card_type_idx)
	if cards.is_empty():
		return {}
	var idx := clampi(_card_focus, 0, cards.size() - 1)
	return cards[idx]

# 焦点卡片滑动动画（非线性缓动）
func _update_codex_carousel(delta: float) -> void:
	var target := float(_card_focus)
	if not _codex_dragging:
		_card_focus_anim = lerpf(_card_focus_anim, target, delta * 6.0)
	else:
		_card_focus_anim = clampf(_codex_drag_focus, 0.0, maxf(0.0, float(codex_card_count() - 1)))
	var page_target := float(_card_page - 1)
	_card_page_anim = lerpf(_card_page_anim, page_target, delta * 8.0)

# 给定屏幕坐标，返回命中的图鉴卡片索引（-1 为未命中）
func codex_card_at(pos: Vector2) -> int:
	var area := codex_card_area()
	var csize := codex_card_size()
	var stride := codex_card_stride()
	var count := codex_card_count()
	if count <= 0:
		return -1
	var center := Vector2(area.get_center().x, area.get_center().y)
	for i in range(count):
		var d := _card_focus_anim - float(i)
		var cx := center.x - d * stride
		var card := Rect2(Vector2(cx - csize.x * 0.5, center.y - csize.y * 0.5), csize)
		if card.has_point(pos):
			return i
	return -1

func codex_collected_count(cat: int) -> int:
	return _cards_of_type(cat).size()

func codex_entries(cat: int) -> Array:
	return _cards_of_type(cat)

func codex_cat_name(i: int) -> String:
	if i < 0 or i >= CARD_TYPES.size():
		return ""
	var labels := {"Gate": "城门", "Fang": "里坊", "Road": "道路", "Canal": "水渠", "Building": "建筑"}
	return labels.get(CARD_TYPES[i], "")

func codex_collected_list(cat: int) -> Array:
	var result := []
	for card in _cards_of_type(cat):
		result.append(card.get("name", ""))
	return result

# 参数为 1280x720 设计系坐标：左侧拦截带（左栏）与底部时间轴带
func _is_screen_ui_band(p: Vector2) -> bool:
	var w := LEFT_BAR_EXPANDED_W if not _left_bar_collapsed else LEFT_BAR_COLLAPSED_W
	if p.x <= w:
		return true
	if not _timeline_collapsed and p.y >= UI_DESIGN_H - 118.0:
		return true
	return false

func _is_blocked_screen_ui_band(p: Vector2) -> bool:
	return _is_screen_ui_band(p) and not HIST_TIMELINE_RECT.has_point(p)

# 点击点（1280x720 设计系）是否落在已展开知识卡片（面板本体或关闭 ✕）上。
# 用于让面板命中优先于与其重叠的右上角时间指示区（TIME_AREA_RECT）。
func _ui_panel_at(p: Vector2) -> bool:
	if _selected.is_empty():
		return false
	if building_close_rect().has_point(p):
		return true
	return BUILDING_PANEL_RECT.has_point(p)

# 知识卡片展开时，其面板区域应拦截对背景地图的点击（但面板内的关闭/追问按钮仍可点）
func _is_panel_blocking(p: Vector2) -> bool:
	if _selected.is_empty():
		return false
	if not BUILDING_PANEL_RECT.has_point(p):
		return false
	# 关闭按钮与追问按钮区域不拦截，让事件继续进入 _handle_click 处理
	if building_close_rect().has_point(p):
		return false
	for i in range(3):
		if followup_button_rect(i).has_point(p):
			return false
	return true

func _ambient_color(hour: float) -> Color:
	for i in range(_day_hours.size() - 1):
		var a: float = _day_hours[i]
		var b: float = _day_hours[i + 1]
		if hour >= a and hour <= b:
			var t := (hour - a) / (b - a)
			t = t * t * (3.0 - 2.0 * t)
			var c0: Color = _day_colors[i]
			var c1: Color = _day_colors[i + 1]
			return c0.lerp(c1, t)
	return _day_colors[0]

func _sun_factor(hour: float) -> float:
	return clampf(sin((hour - 6.0) / 12.0 * PI), 0.0, 1.0)

func _time_period(hour: float) -> String:
	if hour < 5.0:
		return "深夜"
	elif hour < 7.0:
		return "黎明"
	elif hour < 9.0:
		return "清晨"
	elif hour < 11.0:
		return "上午"
	elif hour < 13.0:
		return "正午"
	elif hour < 15.0:
		return "午后"
	elif hour < 18.0:
		return "傍晚"
	elif hour < 20.0:
		return "黄昏"
	elif hour < 22.0:
		return "夜晚"
	return "深夜"

func _update_lighting() -> void:
	if _ambient == null:
		return
	var h := _time_of_day
	_ambient.color = _ambient_color(h)
	if _bg:
		_bg.modulate = _ambient_color(h).lerp(Color.WHITE, 0.18)
	var sun := _sun_factor(h)
	var night := 1.0 - sun
	# move the sun east -> west across the day
	if _sun_light:
		var t := (h - 6.0) / 12.0
		if t < 0.0 or t > 1.0:
			_sun_light.modulate.a = 0.0
		else:
			var cx := _step_iso(4831.5, 4334.0).x
			var cy := _step_iso(4831.5, 4334.0).y
			var sx := lerpf(82000.0, -82000.0, t)
			var sy := -absf(sin(t * PI)) * 68000.0
			_sun_light.position = Vector2(cx + sx, cy + sy)
			var warm := clampf(1.0 - absf(t - 0.5) * 1.6, 0.3, 1.0)
			_sun_light.modulate = Color(1.0, 0.82 + 0.12 * warm, 0.58 + 0.26 * warm, 0.15 + 0.5 * sun)
	for s in _day_lights:
		s.modulate.a = 0.12 + 0.22 * sun
	for s in _fang_lights:
		s.modulate.a = 0.0 + 0.55 * night

func _update_tilt_shift(delta: float) -> void:
	if _ts_mat == null:
		return
	var target_y := 0.5
	var target_band := 0.4
	var target_blur := 0.14
	if _zoom_idx >= 3 and _zoom_idx < ZOOM_LEVELS.size() - 1:
		target_band = 0.3
		target_blur = 0.32
	elif _zoom_idx >= ZOOM_LEVELS.size() - 1:
		# 近景：周围模糊弱化（band 加宽清晰区、blur 降低强度）
		target_band = 0.34
		target_blur = 0.32
	_ts_focus_y = lerpf(_ts_focus_y, target_y, delta * 4.0)
	_ts_band = lerpf(_ts_band, target_band, delta * 4.0)
	_ts_blur = lerpf(_ts_blur, target_blur, delta * 4.0)
	_ts_mat.set_shader_parameter("focus_y", _ts_focus_y)
	_ts_mat.set_shader_parameter("band_width", _ts_band)
	_ts_mat.set_shader_parameter("blur_strength", _ts_blur)

func _process(delta: float) -> void:
	if _camera == null:
		return
	if _follow_group >= 0 and _follow_group < _groups.size():
		var fg: Dictionary = _groups[_follow_group]
		_target_pos = _step_iso(fg["c"], fg["r"])
		_target_zoom = ZOOM_LEVELS[2]
	if _cam_anim:
		_cam_anim_t += delta
		var t := clampf(_cam_anim_t / _cam_anim_dur, 0.0, 1.0)
		var e := _ease_in_out_cubic(t)
		var z := lerpf(_cam_from_zoom, _cam_to_zoom, e)
		_camera.zoom = Vector2(z, z)
		_camera.position = _cam_from_pos.lerp(_cam_to_pos, e)
		if t >= 1.0:
			_cam_anim = false
	else:
		var z: float = _camera.zoom.x
		if absf(z - _target_zoom) > 0.001:
			var nz := lerpf(z, _target_zoom, delta * 6.0)
			_camera.zoom = Vector2(nz, nz)
		var p := _camera.position
		if p.distance_to(_target_pos) > 0.5:
			_camera.position = p.lerp(_target_pos, delta * 6.0)
	_sync_fang_label_zoom()
	if _panel_opening:
		if _panel_raw < 1.0:
			_panel_raw = minf(1.0, _panel_raw + delta / 0.38)
			_panel_anim_t = _ease_out_back(_panel_raw)
			_ui.queue_redraw()
	else:
		if _panel_raw > 0.0:
			_panel_raw = maxf(0.0, _panel_raw - delta / 0.28)
			_panel_anim_t = _panel_raw
			_ui.queue_redraw()
			if _panel_raw <= 0.0:
				_selected = {}
	_update_typing(delta)
	_update_npcs(delta)
	_update_speaking(delta)
	_update_group_chat(delta)
	_update_hover()
	_update_fang_outline()
	_update_ui_anims(delta)
	_update_codex_carousel(delta)
	_update_time(delta)
	_update_lighting()
	_update_tilt_shift(delta)

func _update_typing(delta: float) -> void:
	if _typing_intro and _intro_text != "":
		_type_accum_intro += delta * _type_speed
		var n := int(_type_accum_intro)
		_type_accum_intro -= n
		_intro_visible = mini(_intro_visible + n, _intro_text.length())
		if _intro_visible >= _intro_text.length():
			_typing_intro = false
		_ui.queue_redraw()
	if _typing and _typing_text != "":
		_type_accum += delta * _type_speed
		var n := int(_type_accum)
		_type_accum -= n
		_typing_visible = mini(_typing_visible + n, _typing_text.length())
		if _typing_visible >= _typing_text.length():
			_typing = false
			_chat.append({"role": "ai", "text": _typing_text})
			_typing_text = ""
			_typing_visible = 0
		_ui.queue_redraw()

func _update_group_chat(delta: float) -> void:
	if not _group_chat_open:
		return
	var animating := false
	for m in _group_chat:
		m["age"] += delta
		if m["age"] < 0.35:
			animating = true
	if not _group_chat_pending.is_empty():
		_chat_timer -= delta
		if _chat_timer <= 0.0:
			_chat_timer = 0.55
			_group_chat.append(_group_chat_pending.pop_front())
			animating = true
	if animating:
		_ui.queue_redraw()

func _update_hover() -> void:
	var mp := get_viewport().get_mouse_position()
	var f := Vector2(-1, -1)
	if not _is_pointer_on_ui(mp):
		var world := _camera.get_canvas_transform().affine_inverse() * mp
		f = _fang_at(world)
	if f != _hover_fang:
		_hover_fang = f
		_ui.queue_redraw()

# 鼠标是否悬停在任何 UI（按钮/面板/时间轴/底部栏）之上：此时不触发地图坊 hover
# 参数为视口坐标，内部换算到 1280x720 设计系后与 UI rect 比较
func _is_pointer_on_ui(p: Vector2) -> bool:
	var up := screen_to_ui(p)
	if _is_blocked_screen_ui_band(up):
		return true
	if TIME_AREA_RECT.has_point(up):
		return true
	if HIST_TIMELINE_RECT.has_point(up) and not _timeline_collapsed:
		return true
	if _ui != null and _ui._detect_ui_hover() != "":
		return true
	return false

# ==================== world drawing (moved to world.gd) ====================

func _occupied(c: int, r: int) -> bool:
	if r < 1:
		return true
	# 宫城
	if c >= 4 and c < 8 and r >= 1 and r < 3:
		return true
	# 皇城
	if c >= 4 and c < 8 and r >= 3 and r < 5:
		return true
	# 大明宫
	if c >= 8 and c < 11 and r >= 1 and r < 3:
		return true
	# 兴庆宫
	if c >= 9 and c < 11 and r >= 4 and r < 6:
		return true
	# 西市 / 东市
	if c >= 2 and c < 4 and r >= 5 and r < 7:
		return true
	if c >= 8 and c < 10 and r >= 5 and r < 7:
		return true
	# 朱雀门街 (central column)
	if c == 5 or c == 6:
		if r >= 5 and r < 9:
			return true
	return false

# ==================== input ====================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var wmb := event as InputEventMouseButton
			var up := screen_to_ui(wmb.position)
			if _codex_open and codex_panel_rect().has_point(up):
				_card_focus = clampi(_card_focus - 1, 0, maxi(0, codex_card_count() - 1))
				_ui.queue_redraw()
			elif _hist_open and hist_popup_rect().has_point(up):
				_hist_scroll = maxf(0.0, _hist_scroll - 40.0)
				_ui.queue_redraw()
			elif _panel_has_point(up):
				_chat_scroll = maxf(0.0, _chat_scroll - 40.0)
				_ui.queue_redraw()
			elif _is_screen_ui_band(up):
				return
			else:
				_wheel_zoom(1)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var wmb2 := event as InputEventMouseButton
			var up2 := screen_to_ui(wmb2.position)
			if _codex_open and codex_panel_rect().has_point(up2):
				_card_focus = clampi(_card_focus + 1, 0, maxi(0, codex_card_count() - 1))
				_ui.queue_redraw()
			elif _hist_open and hist_popup_rect().has_point(up2):
				_hist_scroll = minf(_hist_scroll + 40.0, hist_max_scroll())
				_ui.queue_redraw()
			elif _panel_has_point(up2):
				_chat_scroll += 40.0
				_ui.queue_redraw()
			elif _is_screen_ui_band(up2):
				return
			else:
				_wheel_zoom(-1)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mb := event as InputEventMouseButton
			var mp := screen_to_ui(mb.position)
			if mb.pressed:
				if left_toggle_rect().has_point(mp):
					toggle_left_bar()
					return
				if _codex_open and codex_card_area().has_point(mp) and codex_card_count() > 0:
					# 图鉴知识卡片拖拽滑动
					_codex_dragging = true
					_codex_drag_focus = _card_focus_anim
					_codex_drag_x = mp.x
					_dragging = false
					_moved = false
					return
				if _is_screen_ui_band(mp) or _is_panel_blocking(mp):
					_dragging = false
					_moved = false
					_drag_start = mb.position
					return
				_dragging = true
				_drag_start = mb.position
				_moved = false
			else:
				_dragging = false
				if _codex_dragging:
					_codex_dragging = false
					_card_focus = clampi(int(round(_codex_drag_focus)), 0, maxi(0, codex_card_count() - 1))
					_ui.queue_redraw()
					return
				if not _moved:
					_handle_click(mb.position)
		return
	if event is InputEventMouseMotion:
		if _codex_dragging:
			var mmd := event as InputEventMouseMotion
			var stride: float = codex_card_stride()
			if stride > 0.0:
				# mmd.relative 为视口像素；卡片 stride 为设计系，需换算保持拖拽手感
				_codex_drag_focus -= mmd.relative.x / ui_scale() / stride
			_ui.queue_redraw()
			return
		if _dragging:
			var mm2 := event as InputEventMouseMotion
			if mm2.position.distance_to(_drag_start) > 6.0:
				_moved = true
			if _moved:
				_free_pan = true
				var dz: float = _camera.zoom.x
				_target_pos = _camera.position - mm2.relative / dz
				_camera.position = _target_pos

func _panel_has_point(p: Vector2) -> bool:
	if _selected.is_empty():
		return false
	return BUILDING_PANEL_RECT.has_point(p)

func _handle_click(screen_pos: Vector2) -> void:
	# screen_pos 为视口坐标；UI 判定统一换算到 1280x720 设计系，世界点击保留视口坐标
	var ui_pos := screen_to_ui(screen_pos)
	if left_toggle_rect().has_point(ui_pos):
		toggle_left_bar()
		return
	if _clock_open:
		# 时辰选择弹窗打开时：点时辰项切换时间，点弹窗外关闭
		var was_open := _clock_open
		if clock_popup_rect().has_point(ui_pos):
			for i in range(SHICHEN.size()):
				if shichen_rect(i).has_point(ui_pos):
					set_time(float(i * 2), true)
					_clock_open = false
					_clock_popup_anim_target = 0.0
					_ui.queue_redraw()
					return
			return
		_clock_open = false
		_clock_popup_anim_target = 0.0
		_ui.queue_redraw()
		return
	# 右上角时间指示区域命中：弹出时辰选择卡片。
	# 知识卡片展开时其右上角关闭 ✕（及面板本体）与该区域重叠，
	# 必须先让面板命中判定接管，否则 ✕ 永远点不到、卡片关不掉。
	if TIME_AREA_RECT.has_point(ui_pos) and not _ui_panel_at(ui_pos):
		_clock_open = true
		_clock_popup_anim = 0.0
		_clock_popup_anim_target = 1.0
		_hist_open = false
		_hist_anim_target = 0.0
		_hist_selected = -1
		_ui.queue_redraw()
		return
	if _hist_open:
		if hist_popup_rect().has_point(ui_pos):
			for i in range(_timeline.size()):
				if hist_event_rect(i).has_point(ui_pos):
					# 点击事件：跳转到该年 + 展开/收起细节
					_jump_to_year(int(_timeline[i]["year"]))
					if _hist_selected == i:
						_hist_selected = -1  # 点击同一事件：收起
					else:
						_hist_selected = i
						_hist_detail_anim = 0.0  # 换事件时重启打开动画（上一个自然滑出）
					_ui.queue_redraw()
					return
			return
		_hist_open = false
		_hist_anim_target = 0.0
		_hist_selected = -1   # 关闭时细节框随之反向收起
		_ui.queue_redraw()
		return
	if _codex_open:
		if codex_panel_rect().has_point(ui_pos):
			# 关闭按钮
			var pr: Rect2 = codex_panel_rect()
			var close_r := Rect2(pr.end.x - 44.0, pr.position.y + 12.0, 28.0, 28.0)
			if close_r.has_point(ui_pos):
				_codex_open = false
				_ui.queue_redraw()
				return
			for i in range(5):
				if codex_type_rect(i).has_point(ui_pos):
					_card_type_idx = i
					_card_focus = 0
					_codex_scroll = 0.0
					_ui.queue_redraw()
					return
			for j in range(3):
				if codex_page_btn_rect(j).has_point(ui_pos):
					_card_page = j + 1
					_ui.queue_redraw()
					return
			var ci := codex_card_at(ui_pos)
			if ci >= 0:
				_card_focus = ci
				_ui.queue_redraw()
				return
			return
		_codex_open = false
		_ui.queue_redraw()
		return
	if HIST_TIMELINE_RECT.has_point(ui_pos):
		if _timeline_collapsed:
			return
		# 点击时间轴：打开长安城大事记（从下到上非线性滑入）
		_hist_open = true
		_hist_anim = 0.0
		_hist_anim_target = 1.0
		_hist_selected = -1
		_hist_detail_anim = 0.0
		var ev_idx := timeline_event_at_x(ui_pos.x)
		if ev_idx >= 0:
			_hist_scroll = maxf(0.0, float(ev_idx) * 44.0 - 6.0)
		else:
			_hist_scroll = 0.0
		_ui.queue_redraw()
		return
	if _is_blocked_screen_ui_band(ui_pos):
		return
	if _group_chat_open and group_chat_close_rect().has_point(ui_pos):
		_group_chat_open = false
		_ui.queue_redraw()
		return
	if _group_chat_open and GROUP_CHAT_RECT.has_point(ui_pos):
		return
	if not _selected.is_empty():
		if building_close_rect().has_point(ui_pos):
			_deselect()
			return
		if BUILDING_PANEL_RECT.has_point(ui_pos):
			_knowledge_card_back = not _knowledge_card_back
			_card_flip_target = 1.0 if _knowledge_card_back else 0.0
			_ui.queue_redraw()
			return
	var sgi := _speaking_group_at(screen_pos)
	if sgi >= 0:
		_select_group(sgi)
		return
	var world_pos := _camera.get_canvas_transform().affine_inverse() * screen_pos
	var hit := _hit_test(world_pos)
	if not hit.is_empty():
		_selected_fang = Vector2(-1, -1)
		_select(hit)
		return
	# 皇宫（宫城+皇城整体贴图）命中：位于大矩形内 → 打开皇宫知识卡
	if _palace_at(world_pos):
		_selected_fang = Vector2(-1, -1)
		_select(_palace_data())
		_redraw_world()
		return
	var fang := _fang_at(world_pos)
	if fang.x >= 0:
		_selected_fang = fang
		_select(_fang_data(fang.x, fang.y))
		_redraw_world()
		return
	var street := _street_at(world_pos)
	if not street.is_empty():
		_selected_fang = Vector2(-1, -1)
		_select(_street_data(street))
		_redraw_world()
		return
	if not _selected.is_empty():
		_deselect()
	elif _group_chat_open:
		_group_chat_open = false
		_ui.queue_redraw()

# 世界坐标 → 步坐标（逆 ISO）
func _world_to_step(world_pos: Vector2) -> Vector2:
	var sx := (world_pos.x / (STEP * 64.0) + world_pos.y / (STEP * 32.0)) * 0.5
	var sy := (world_pos.y / (STEP * 32.0) - world_pos.x / (STEP * 64.0)) * 0.5
	return Vector2(sx, sy)

# 皇宫区域点击命中：点击坐标转换到步坐标后落在皇宫大矩形内即命中
func _palace_at(world_pos: Vector2) -> bool:
	if _palace_step_rect.size.x <= 0.0 or _palace_step_rect.size.y <= 0.0:
		return false
	var step := _world_to_step(world_pos)
	return _palace_step_rect.has_point(step)

# 皇宫知识卡数据（宫城+皇城整体）
func _palace_data() -> Dictionary:
	return {
		"key": "PALACE-宫城皇城",
		"name": "宫城",
		"trad": "皇城",
		"type": "宫殿",
		"zone": "长安城北 · 宫城与皇城",
		"description": "宫城是皇帝居住与处理朝政的宫殿区，位于长安城北部中央；其南为皇城，集中分布中央官署。二者合称皇宫，是唐长安城的政治中枢。",
		"location": "宫城（北）与皇城（南），朱雀门街中轴线北端",
		"function": "皇帝朝寝与中央官署理政之地",
		"built": "隋开皇二年（582年）始建大兴城宫城",
		"aliases": "宫城; 皇城; 皇宫",
		"quote": "北据高原，南望爽垲，宫殿台阁，周回数里。",
		"source": "《唐两京城坊考》卷一·宫城/皇城",
	}

# 矩形点击检测：世界坐标 → 命中的坊 (si, ci)，未命中返回 Vector2(-1, -1)
func _fang_at(world_pos: Vector2) -> Vector2:
	var step := _world_to_step(world_pos)
	var sx := step.x
	var sy := step.y
	# 查找所在坊行
	var fang_row := -1
	for si in range(EW_FANG_DEPTHS.size()):
		var fy := _ew_y(si) + float(EW_STREET_WIDTHS[si])
		var fh := float(EW_FANG_DEPTHS[si])
		if sy >= fy and sy < fy + fh:
			fang_row = si
			break
	if fang_row < 0:
		return Vector2(-1, -1)
	# 查找所在坊列
	var fang_col := -1
	for ci in range(10):
		var fx := _ns_x(ci) + float(NS_STREET_WIDTHS[ci])
		var fw := float(NS_FANG_WIDTHS[ci])
		if sx >= fx and sx < fx + fw:
			fang_col = ci
			break
	if fang_col < 0:
		return Vector2(-1, -1)
	# 检查是否为皇城空位
	if fang_row < EW_FANG_NAMES.size() and fang_col < EW_FANG_NAMES[fang_row].size():
		if EW_FANG_NAMES[fang_row][fang_col] == "":
			return Vector2(-1, -1)
	return Vector2(fang_col, fang_row)

# 坊数据（用于点击后显示卡片）
func _fang_data(c: float, r: float) -> Dictionary:
	var ci := int(c)
	var si := int(r)
	var fname: String = ""
	if si < EW_FANG_NAMES.size() and ci < EW_FANG_NAMES[si].size():
		fname = EW_FANG_NAMES[si][ci]
	if fname == "":
		fname = "里坊"
	var ew_size := int(float(NS_FANG_WIDTHS[ci]))    # 东西尺寸
	var ns_size := int(float(EW_FANG_DEPTHS[si]))    # 南北尺寸
	var ew_street_name: String = EW_STREET_NAMES[si] if si < EW_STREET_NAMES.size() else ""
	var ns_street_name: String = NS_STREET_NAMES[ci] if ci < NS_STREET_NAMES.size() else ""
	return {
		"key": "FANG-%d-%d" % [ci, si],
		"name": fname,
		"trad": "",
		"type": "坊",
		"zone": "外郭城",
		"description": "%s，东西约%d步，南北约%d步。北侧为%s，东侧为%s。" % [fname, ew_size, ns_size, ew_street_name, ns_street_name],
		"location": "%s · 第%d列" % [ew_street_name, ci + 1],
		"function": "居住与坊内生活",
		"built": "",
		"aliases": "",
		"quote": "",
		"source": "《唐两京城坊考》卷一",
		"ew_size": ew_size,
		"ns_size": ns_size,
		"north_road": ew_street_name,
		"east_road": ns_street_name,
	}

func _fang_name_of(c: int, r: int) -> String:
	if r < EW_FANG_NAMES.size() and c < EW_FANG_NAMES[r].size():
		var n: String = EW_FANG_NAMES[r][c]
		if n != "":
			return n
	return "里坊"

# 街道点击检测：返回 ["ew", idx] 或 ["ns", idx] 或空数组
func _street_at(world_pos: Vector2) -> Array:
	var step := _world_to_step(world_pos)
	var sx := step.x
	var sy := step.y
	# 检查东西向街道（15 条：街0-13 + 南边界街14）
	for si in range(15):
		var road_y: float
		var road_w: float
		if si < 14:
			road_y = _ew_y(si)
			road_w = float(EW_STREET_WIDTHS[si])
		else:
			road_y = _ew_y(13) + float(EW_FANG_DEPTHS[12])
			road_w = float(EW_STREET_WIDTHS[13])
		if sy >= road_y and sy < road_y + road_w:
			return ["ew", si]
	# 检查南北向街道（12 条：街0-10 + 东边界街11）
	for ci in range(12):
		var road_x: float
		var road_w: float
		if ci < 11:
			road_x = _ns_x(ci)
			road_w = float(NS_STREET_WIDTHS[ci])
		else:
			road_x = _ns_x(10) + float(NS_FANG_WIDTHS[9])
			road_w = float(NS_STREET_WIDTHS[10])
		if sx >= road_x and sx < road_x + road_w:
			return ["ns", ci]
	return []

# 街道数据（用于点击后显示卡片）
func _street_data(info: Array) -> Dictionary:
	var dir: String = info[0]
	var idx: int = info[1]
	if dir == "ew" and idx < EW_STREET_WIDTHS.size():
		var w: int = int(float(EW_STREET_WIDTHS[idx]))
		var l: int = 9663
		var sname: String = EW_STREET_NAMES[idx] if idx < EW_STREET_NAMES.size() else "外郭城南墙"
		return {
			"key": "STREET-EW-%d" % idx,
			"name": sname,
			"trad": "",
			"type": "街道",
			"zone": "外郭城",
			"description": "%s，路宽%d步，贯穿东西，全长%d步。" % [sname, w, l],
			"location": sname,
			"function": "城市交通干道",
			"built": "隋开皇二年（582年）",
			"aliases": "",
			"quote": "",
			"source": "《唐两京城坊考》卷一",
			"road_width": w,
			"road_length": l,
		}
	elif dir == "ns" and idx < NS_STREET_WIDTHS.size():
		var w: int = int(float(NS_STREET_WIDTHS[idx]))
		var l: int = 8668
		var sname: String = NS_STREET_NAMES[idx] if idx < NS_STREET_NAMES.size() else "外郭城东墙"
		return {
			"key": "STREET-NS-%d" % idx,
			"name": sname,
			"trad": "",
			"type": "街道",
			"zone": "外郭城",
			"description": "%s，路宽%d步，贯穿南北，全长%d步。" % [sname, w, l],
			"location": sname,
			"function": "城市交通干道",
			"built": "隋开皇二年（582年）",
			"aliases": "",
			"quote": "",
			"source": "《唐两京城坊考》卷一",
			"road_width": w,
			"road_length": l,
		}
	return {}

# ==================== NPC groups ====================
const KEPU := {
	"胡饼": "胡饼是唐代流行的烤面饼，源自西域，长安街市随处可见，常撒芝麻烤制。",
	"炊饼": "炊饼即蒸饼，是唐代常见的面食。",
	"米价": "米是唐代主粮，米价随丰歉波动，官府设常平仓平抑粮价。",
	"坊市": "长安实行坊市制度：坊为居住区、市为交易区，定时开闭。",
	"宵禁": "唐代实行宵禁，入夜击鼓闭坊门，禁止随意通行。",
	"点灯": "唐代照明用油灯与蜡烛，普通百姓多用油灯。",
	"灯会": "上元节长安有灯会，百姓观灯夜游。",
	"酒": "唐代盛行饮酒，长安有酒肆，名酒如兰陵美酒、郢州春。",
	"茶": "唐代饮茶渐盛，陆羽著《茶经》，茶肆兴起。",
	"马球": "马球（击鞠）是唐代贵族与军中流行的运动。",
	"蹴鞠": "蹴鞠是唐代流行的球类运动。",
	"铜钱": "唐代通行货币为开元通宝。",
	"绢帛": "绢帛既是衣料，也可作货币流通。",
	"庙": "长安佛寺众多，佛教兴盛。",
	"道观": "唐代尊崇道教，长安道观林立。",
	"井": "坊内有公共水井，供居民取水。",
	"马": "长安以马、牛车为主要交通工具。",
	"胡商": "长安西市多胡商，经营香料、珠宝等。",
	"饼": "唐代主食有饼、饭、粥，饼类繁多。",
	"药铺": "长安有药铺，医学发达，孙思邈著《千金方》。",
	"炭": "冬季取暖用炭，坊内有炭市。",
	"磨": "粮食加工用石磨、水磨。",
	"桂花": "桂花秋季开放，长安庭院、寺观多有栽植。",
	"下雨": "唐代农耕靠天时，雨水关系庄稼收成。",
	"胡": "唐代与西域往来频繁，长安多胡人胡商。",
	"米": "米是唐代主粮，坊市有米铺。",
}

func _init_npcs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260818
	var names := ["李三郎", "王五娘", "张屠户", "刘掌柜", "陈货郎", "赵书生", "孙绣娘", "周车夫", "郑媒婆", "吴乞儿", "马郎", "崔娘子", "何铁匠", "高药铺", "罗挑夫", "许乞婆", "杜酒娘", "朱牙人", "卫渔夫", "冯更夫", "钱掌柜", "秦瓦匠", "曹磨工", "韩轿夫"]
	var ni := 0
	for g in range(55):
		var size: int = [1, 2, 2, 3, 3][rng.randi() % 5]
		var route := _gen_route(rng)
		var start: Vector2 = route[0]
		var members: Array = []
		for m in range(size):
			var off := _member_offset(size, m)
			members.append({"name": names[ni % names.size()], "dc": off.x, "dr": off.y})
			ni += 1
		_groups.append({
			"c": start.x,
			"r": start.y,
			"route": route,
			"wp": 1,
			"speed": rng.randf_range(0.02, 0.05),
			"members": members,
		})

func _member_offset(size: int, idx: int) -> Vector2:
	if size == 1:
		return Vector2(0, 0)
	if size == 2:
		return Vector2(-0.08, 0.04) if idx == 0 else Vector2(0.08, -0.04)
	var offs := [Vector2(-0.1, 0.06), Vector2(0, -0.04), Vector2(0.1, 0.06)]
	return offs[idx]

func _gen_route(rng: RandomNumberGenerator) -> Array:
	var pts: Array = []
	# 在城市范围内随机生成步坐标路径
	var sx := rng.randf_range(500.0, 9000.0)
	var sy := rng.randf_range(500.0, 8000.0)
	pts.append(Vector2(sx, sy))
	for i in range(rng.randi_range(6, 12)):
		if rng.randf() < 0.5:
			sx = clampf(sx + rng.randf_range(-500.0, 500.0), 200.0, 9400.0)
		else:
			sy = clampf(sy + rng.randf_range(-500.0, 500.0), 200.0, 8400.0)
		pts.append(Vector2(sx, sy))
	return pts

func _update_npcs(delta: float) -> void:
	# 路人 NPC 已按需求停用（不绘制、不移动），保持空转以免多余开销/隐形热区。
	return

func _update_speaking(delta: float) -> void:
	# 说话气泡图标已按需求停用（连同头顶小人图标一并移除）。
	return

func _speaking_group_at(screen_pos: Vector2) -> int:
	if _zoom_idx < 1:
		return -1
	for s in _speaking:
		var gi: int = s["gi"]
		if gi < 0 or gi >= _groups.size():
			continue
		var g: Dictionary = _groups[gi]
		var sp := _world_to_screen(_step_iso(g["c"], g["r"]))
		var c := sp + Vector2(0, -2.0 * _camera.zoom.x)  # 头顶附近
		c.y -= (24.0 + 7.0)  # 圆框半径 + 间距（屏幕像素）
		if screen_pos.distance_to(c) <= 26.0:
			return gi
	return -1

func _select_group(gi: int) -> void:
	var g: Dictionary = _groups[gi]
	_speaking = _speaking.filter(func(s): return int(s["gi"]) != gi)
	if not _selected.is_empty():
		_selected = {}
		_panel_opening = false
		_panel_raw = 0.0
		_panel_anim_t = 0.0
	_follow_group = gi
	_zoom_idx = 2
	_start_cam_anim(ZOOM_LEVELS[2], _step_iso(g["c"], g["r"]))
	var names := PackedStringArray()
	for m in g["members"]:
		names.append(String(m["name"]))
	_group_chat = []
	_kepu = []
	_group_chat_open = true
	_group_chat_title = "、".join(names)
	EventBus.npc_dialogue_started.emit(gi)
	_request_group_dialogue(g, names, gi)

func _request_group_dialogue(g: Dictionary, names: PackedStringArray, gi: int) -> void:
	var n := names.size()
	var scene := "独处" if n == 1 else ("闲聊" if n == 2 else "结伴议论")
	if not NetworkManager.has_api_key():
		_show_group_chat(g, _local_group_lines(n))
		return
	var period := _time_period(_time_of_day)
	var era := year_era(_current_year)
	var ev := nearby_event_title(_current_year)
	var ev_hint := ""
	if ev != "":
		ev_hint = "坊间正议论「" + ev + "」之事，可适当提及。"
	var sys := "你是%d年%s的市井百姓。现在是%s。有%d个人在%s。请为每个人各写一句符合当下时代、生活状态且切合当前时段的对话（如黎明起身、清晨问安、正午吃食、午后劳作、黄昏归家、夜晚点灯等）。%s每句不超过15个字，用口语。每人一行，共%d行，不要编号、不要多余标点。" % [_current_year, era, period, n, scene, ev_hint, n]
	_pending_group = gi
	NetworkManager.request_chat([
		{"role": "system", "content": sys},
		{"role": "user", "content": "请生成这%d个人的对话。" % n},
	], 0.9, 120)

func _local_group_lines(n: int) -> Array:
	var pool := ["今日米价又涨了", "东市新开了家铺子", "这坊里的桂花开了", "郎君吃过了么", "昨夜下了场小雨", "西市的胡商好多", "该回家生火做饭了", "今日的炊饼甚香"]
	var lines: Array = []
	for i in range(n):
		lines.append(pool[(i + _pending_group) % pool.size()])
	return lines

func _show_group_chat(g: Dictionary, lines: Array) -> void:
	var members: Array = g["members"]
	_group_chat = []
	_group_chat_pending = []
	for i in range(members.size()):
		var line := String(lines[i]).strip_edges() if i < lines.size() else ""
		if line == "":
			continue
		_group_chat_pending.append({"name": String(members[i]["name"]), "text": line, "age": 0.0})
	_chat_timer = 0.35
	_detect_kepu(lines)
	_detect_codex("\n".join(lines))
	_pending_group = -1
	_ui.queue_redraw()

func _detect_kepu(lines: Array) -> void:
	_kepu = []
	var seen := {}
	for line in lines:
		var text := String(line)
		for kw in _kepu_kb:
			if text.contains(kw) and not seen.has(kw):
				seen[kw] = true
				_kepu.append({"kw": kw, "text": String(_kepu_kb[kw])})
		if _kepu.size() >= 2:
			break

func _detect_codex(text: String) -> void:
	if text == "":
		return
	for card in _cards:
		var cname := String(card.get("name", ""))
		if cname != "" and text.contains(cname):
			var cat_name := String(card.get("typeLabel", ""))
			EventBus.codex_entry_collected.emit(cat_name, cname)
func _hit_test(pos: Vector2) -> Dictionary:
	for p in _points:
		var gp := point_grid_position(p)
		var c := _iso(gp.x, gp.y) + Vector2(0, -8)
		if pos.distance_to(c) <= 18.0:
			return p
	return {}
func _select(p: Dictionary) -> void:
	_follow_group = -1
	_group_chat_open = false
	_selected = p
	_local_text = _build_local_text(p)
	_followups = _followup_questions(p)
	_error = ""
	_loading = false
	_panel_raw = 0.0
	_panel_anim_t = 0.0
	_panel_opening = true
	_knowledge_card_back = false
	_card_flip_anim = 0.0
	_card_flip_target = 0.0
	_chat_scroll = 0.0
	_intro_text = ""
	_intro_visible = 0
	_typing_intro = false
	_type_accum_intro = 0.0
	_chat = []
	_typing = false
	_typing_text = ""
	_typing_visible = 0
	_redraw_world()
	_ui.queue_redraw()
	EventBus.building_selected.emit(String(p.get("key", "")), p)
	var sys: String = _cfg.get("system_prompt", "")
	_messages = [
		{"role": "system", "content": sys},
		{"role": "user", "content": _build_prompt(p)},
	]
	_pending_intro = true
	_request_llm()

func _deselect() -> void:
	if _selected.is_empty():
		return
	_follow_group = -1
	_group_chat_open = false
	_panel_opening = false
	_selected_fang = Vector2(-1, -1)
	_redraw_world()
	_ui.queue_redraw()
	EventBus.building_deselected.emit()

func ask_followup(q: String) -> void:
	if _selected.is_empty():
		return
	_chat.append({"role": "user", "text": q})
	_messages.append({"role": "user", "content": q})
	_loading = true
	_typing = true
	_typing_text = ""
	_typing_visible = 0
	_pending_intro = false
	_redraw_world()
	_ui.queue_redraw()
	_request_llm()

func _build_local_text(p: Dictionary) -> String:
	var parts := PackedStringArray()
	if String(p.get("description", "")) != "":
		parts.append(String(p["description"]))
	if String(p.get("location", "")) != "":
		parts.append("位置：" + String(p["location"]))
	if String(p.get("function", "")) != "":
		parts.append("职能：" + String(p["function"]))
	return " ｜ ".join(parts)

func _followup_questions(p: Dictionary) -> Array:
	var type := String(p.get("type", ""))
	var qs := [
		{"label": "历史沿革", "q": "请讲讲它的历史沿革。"},
		{"label": "有何典故", "q": "这里有哪些值得了解的典故或轶事？"},
	]
	if type.contains("门"):
		qs = [
			{"label": "城门形制", "q": "这座城门的形制与规模是怎样的？"},
			{"label": "历史事件", "q": "这里见证过哪些历史时刻？"},
		]
	elif type.contains("宫") or type.contains("殿"):
		qs = [
			{"label": "建筑布局", "q": "它的建筑布局与规模是怎样的？"},
			{"label": "历史典故", "q": "这里发生过哪些著名的历史事件？"},
		]
	elif type.contains("水") or type.contains("园") or type.contains("林"):
		qs = [
			{"label": "景致布局", "q": "这里的园林景致是如何布局的？"},
			{"label": "游赏轶事", "q": "这里有哪些游赏的雅事？"},
		]
	elif type.contains("官署") or type.contains("馆"):
		qs = [
			{"label": "职掌事务", "q": "这里执掌哪些政务？"},
			{"label": "历史人物", "q": "有哪些著名人物曾在此任职？"},
		]
	return qs

# ==================== LLM ====================
func _request_llm() -> void:
	if not NetworkManager.has_api_key():
		_error = "未配置 API Key，已显示知识库原文（config/llm_config.json）"
		if _pending_intro:
			_intro_text = _local_text
			_typing_intro = false
		else:
			_chat.append({"role": "ai", "text": "（未配置 API Key，无法追问）"})
			_typing = false
		_ui.queue_redraw()
		return
	if _pending_intro:
		_typing_intro = true
		_intro_text = ""
		_intro_visible = 0
	else:
		_typing = true
		_typing_text = ""
		_typing_visible = 0
	_redraw_world()
	_ui.queue_redraw()
	NetworkManager.request_chat(_messages, 0.7, 500)

func _build_prompt(p: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("请根据以下唐长安城知识库条目，生成一段约120—160字的通俗介绍：")
	lines.append("")
	lines.append("【名称】" + String(p.get("name", "")) + ("（%s）" % String(p.get("trad", "")) if String(p.get("trad", "")) != "" else ""))
	lines.append("【类型】" + String(p.get("type", "")))
	lines.append("【所属区域】" + String(p.get("zone", "")))
	lines.append("【史料描述】" + String(p.get("description", "")))
	lines.append("【位置】" + String(p.get("location", "")))
	lines.append("【职能】" + String(p.get("function", "")))
	if String(p.get("built", "")) != "":
		lines.append("【建造/沿革】" + String(p["built"]))
	var alias_texts := PackedStringArray()
	var aliases: Variant = p.get("aliases", [])
	if aliases is Array:
		for alias in aliases:
			var alias_item_text := str(alias).strip_edges()
			if alias_item_text != "":
				alias_texts.append(alias_item_text)
	else:
		var alias_value_text := str(aliases).strip_edges()
		if alias_value_text != "":
			alias_texts.append(alias_value_text)
	if not alias_texts.is_empty():
		lines.append("【别名】" + "、".join(alias_texts))
	if String(p.get("quote", "")) != "":
		lines.append("【原文引文】" + String(p["quote"]))
	lines.append("【来源】" + String(p.get("source", "")))
	lines.append("")
	lines.append("写完介绍后，请另起一行，先输出标记「【追问】」，然后列出两个可供玩家继续追问的简短问题，每个问题不超过6个字，每行一个、共两行，格式如下：")
	lines.append("【追问】")
	lines.append("问题一")
	lines.append("问题二")
	return "\n".join(lines)

func _on_chat_response(content: String, error: String) -> void:
	_loading = false
	if error != "":
		_error = error
		_ui.queue_redraw()
		return
	if _pending_group >= 0:
		if content != "":
			_parse_group_response(content)
		_pending_group = -1
		_ui.queue_redraw()
		return
	if content != "":
		content = content.strip_edges()
		if _pending_intro:
			var intro := content
			var qs: Array = []
			var idx := content.find("【追问】")
			if idx >= 0:
				intro = content.substr(0, idx).strip_edges()
				var tail := content.substr(idx + "【追问】".length()).strip_edges()
				for line in tail.split("\n"):
					var s := line.strip_edges().trim_prefix("-").trim_prefix("1.").trim_prefix("2.").trim_prefix("1、").trim_prefix("2、").strip_edges()
					if s != "":
						qs.append(s)
					if qs.size() >= 2:
						break
			if intro != "":
				_messages.append({"role": "assistant", "content": intro})
				_intro_text = intro
				_intro_visible = 0
				_typing_intro = true
				_type_accum_intro = 0.0
				_detect_codex(intro)
			else:
				_intro_text = _local_text
				_typing_intro = false
			if qs.size() >= 2:
				_followups = []
				for q in qs:
					_followups.append({"label": String(q), "q": String(q)})
		else:
			_messages.append({"role": "assistant", "content": content})
			_typing_text = content
			_typing_visible = 0
			_typing = true
			_type_accum = 0.0
			_detect_codex(content)
		_error = ""
	_ui.queue_redraw()

func _parse_group_response(content: String) -> void:
	if _pending_group < 0 or _pending_group >= _groups.size():
		return
	var g: Dictionary = _groups[_pending_group]
	var members: Array = g["members"]
	var lines := content.split("\n")
	var clean: Array = []
	for raw in lines:
		var s := raw.strip_edges()
		if s == "":
			continue
		s = s.trim_prefix("1.").trim_prefix("2.").trim_prefix("3.").trim_prefix("1、").trim_prefix("2、").trim_prefix("3、").trim_prefix("-").strip_edges()
		if s == "":
			continue
		if s.length() > 15:
			s = s.substr(0, 15)
		clean.append(s)
		if clean.size() >= members.size():
			break
	_show_group_chat(g, clean)

# ==================== POI grid positions (col, row) ====================
const GRID_POS := {
	"TC-AREA-0001": Vector2(6.0, 2.0),
	"TC-GATE-0017": Vector2(6.0, 3.0),
	"TC-GATE-0018": Vector2(6.0, 1.0),
	"TC-BUILDING-2002": Vector2(6.0, 2.2),
	"TC-BUILDING-2012": Vector2(6.0, 1.7),
	"TC-BUILDING-2013": Vector2(6.0, 1.3),
	"TC-BUILDING-2010": Vector2(4.6, 2.3),
	"TC-BUILDING-2007": Vector2(7.4, 2.3),
	"TC-BUILDING-2009": Vector2(7.7, 2.5),
	"TC-BUILDING-2000": Vector2(8.0, 2.0),
	"TC-BUILDING-2001": Vector2(4.0, 2.0),
	"TC-AREA-0002": Vector2(6.0, 4.0),
	"TC-GATE-0010": Vector2(6.0, 5.0),
	"TC-BUILDING-2129": Vector2(6.5, 4.0),
	"TC-BUILDING-2145": Vector2(4.6, 4.0),
	"TC-BUILDING-2167": Vector2(7.3, 4.0),
	"TC-BUILDING-2172": Vector2(4.2, 4.0),
	"TC-AREA-0003": Vector2(6.0, 6.5),
	"TC-GATE-0001": Vector2(6.0, 8.0),
	"TC-GATE-0005": Vector2(11.0, 4.5),
	"TC-GATE-0006": Vector2(11.0, 2.0),
	"TC-GATE-0007": Vector2(0.0, 2.0),
	"TC-GATE-0008": Vector2(0.0, 5.0),
	"TC-ROAD-0001": Vector2(6.0, 6.5),
	"TC-BUILDING-2014": Vector2(9.5, 2.0),
	"TC-GATE-2075": Vector2(9.5, 3.0),
	"TC-BUILDING-2184": Vector2(9.5, 2.5),
	"TC-BUILDING-2196": Vector2(9.5, 2.0),
	"TC-BUILDING-2208": Vector2(9.5, 1.5),
	"TC-BUILDING-2243": Vector2(10.5, 1.2),
	"TC-BUILDING-2211": Vector2(8.5, 1.5),
	"TC-BUILDING-2270": Vector2(10.0, 5.0),
	"TC-BUILDING-2282": Vector2(10.0, 4.3),
	"TC-BUILDING-2274": Vector2(10.6, 5.5),
	"TC-BUILDING-2272": Vector2(9.7, 5.3),
	"TC-TERRAIN-2000": Vector2(9.5, 0.6),
}
