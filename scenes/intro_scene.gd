extends Control
# 场景2「舆图展开」：独立转场场景。
# 进入（从开始菜单切来）时以「卷轴」滚入覆盖并显示「舆图展开·入司理事」；点击「轻点继续」后以同一卷轴动效滚出，进入场景3「长安地图」。

const MAP_SCENE := "res://scenes/ChangAnCity.tscn"
const ENTER := 0.6    # 卷轴滚入覆盖时长
const EXIT := 0.9     # 卷轴滚出揭示时长

var phase := 0        # 0=滚入, 1=等待「轻点继续」, 2=滚出
var t := 0.0
var font_song: Font
var font_hei: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 中文 qiji-fallback，英文/数字 Times New Roman（打包 FontFile，全平台一致）
	font_song = FontKit.composite()
	font_hei = FontKit.composite()
	# 从「开始菜单」卷轴滚入完毕后切换过来，直接处于已覆盖（舆图展开呈现）状态
	phase = 1
	t = ENTER
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if phase == 0:
		t += delta
		if t >= ENTER:
			t = ENTER
			phase = 1
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		if phase == 0:
			t = ENTER
			phase = 1
		elif phase == 1:
			SceneTransition.goto_scene_intro(MAP_SCENE)   # 卷帘盖住场景加载，加载完成后滚出揭示
		queue_redraw()

func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _reveal() -> float:
	# 0=全遮, 1=全露
	if phase == 0:
		return 1.0 - _ease(t / ENTER)
	elif phase == 1:
		return 0.0
	return _ease(t / EXIT)

func _text_alpha() -> float:
	if phase == 0:
		return clampf((t / ENTER - 0.25) / 0.5, 0.0, 1.0)
	elif phase == 1:
		return 1.0
	return clampf(1.0 - t / (EXIT * 0.55), 0.0, 1.0)

func _draw() -> void:
	var sz := size
	var k := sz.y / 720.0
	# 墨色底：即便卷帘全程未遮也始终为墨色，杜绝灰屏穿帮
	draw_rect(Rect2(0.0, 0.0, sz.x, sz.y), Color("#0a1512"))
	var rev := _reveal()
	var cx := sz.x * (1.0 - rev)   # 帘右缘：0(露)→sz.x(遮)
	draw_rect(Rect2(0.0, 0.0, cx, sz.y), Color("#0d1a16"))
	draw_line(Vector2(cx, 0.0), Vector2(cx, sz.y), Color("#c9a45a", 0.85), 3.0)
	draw_line(Vector2(cx + 3.0, 0.0), Vector2(cx + 3.0, sz.y), Color("#e5cf9a", 0.35), 1.0)
	var ta := _text_alpha()
	if ta > 0.0 and font_song:
		var cy := sz.y * 0.46
		_draw_center(font_song, "舆 图 展 开", 62.0 * k, Color("#f2e7cf", ta), Vector2(sz.x * 0.5, cy))
		_draw_center(font_song, "入司理事", 34.0 * k, Color("#dfcda6", ta), Vector2(sz.x * 0.5, cy + 46.0 * k))
	if phase == 1:
		var pulse := 0.5 + 0.24 * sin(Time.get_ticks_msec() / 250.0)
		_draw_center(font_hei, "轻点继续", 14.0 * k, Color(0.86, 0.82, 0.7, clampf(pulse, 0.0, 1.0)), Vector2(sz.x * 0.5, sz.y - 40.0 * k))

func _draw_center(font: Font, text: String, fs: float, color: Color, c: Vector2) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	draw_string(font, Vector2(c.x - w * 0.5, c.y + (asc - desc) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
