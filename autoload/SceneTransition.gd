extends CanvasLayer
# 场景切换转场控制器（autoload 单例）
# goto_scene(path)：渐暗黑屏（约0.5s）→ 切换场景 → 渐亮显示

const FADE_OUT := 0.25   # 渐暗时长（秒）
const HOLD := 0.25       # 全黑停留时长（秒）→ 共 0.5s 后切换
const FADE_IN := 0.3     # 渐亮时长（秒）

var _rect: ColorRect
var _fading := false

func _ready() -> void:
	layer = 200
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	_rect.visible = false

# 带渐暗转场的场景切换（调用方无需 await，内部异步执行）
func goto_scene(path: String) -> void:
	if _fading:
		return
	_fading = true
	# 渐暗 + 拦截输入
	_rect.visible = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw1 := create_tween()
	tw1.tween_property(_rect, "color:a", 1.0, FADE_OUT)
	# 等待约 0.5s（渐暗完成 + 全黑停留）后切换场景
	await get_tree().create_timer(FADE_OUT + HOLD).timeout
	get_tree().change_scene_to_file(path)
	# 渐亮
	var tw2 := create_tween()
	tw2.tween_property(_rect, "color:a", 0.0, FADE_IN)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	_fading = false
