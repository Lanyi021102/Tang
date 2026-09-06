extends Control
# SceneTransition 用的揭示帘：覆盖住「舆图展开 → 长安地图」的场景加载，再卷轴滚出揭示已加载的地图，实现无缝衔接。

const EXIT := 0.9   # 卷轴滚出揭示时长（秒）

var _reveal := 0.0    # 0=全遮, 1=全露
var _rolling := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func cover() -> void:
	_reveal = 0.0
	_rolling = false
	visible = true
	queue_redraw()

func rollout() -> void:
	_reveal = 0.0
	_rolling = true
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if _rolling:
		_reveal += delta / EXIT
		if _reveal >= 1.0:
			_reveal = 1.0
			_rolling = false
			visible = false
		queue_redraw()

func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

func _draw() -> void:
	if not visible:
		return
	var sz := size
	var cx := sz.x * (1.0 - _smooth(_reveal))   # 帘右缘：全遮(0)→滚出(sz.x)
	draw_rect(Rect2(0.0, 0.0, cx, sz.y), Color("#0a1512"))
	draw_line(Vector2(cx, 0.0), Vector2(cx, sz.y), Color("#c9a45a", 0.85), 3.0)
	draw_line(Vector2(cx + 3.0, 0.0), Vector2(cx + 3.0, sz.y), Color("#e5cf9a", 0.35), 1.0)
