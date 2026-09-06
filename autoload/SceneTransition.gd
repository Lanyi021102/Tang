extends CanvasLayer
# 场景切换转场控制器（autoload 单例）
# goto_scene(path)：渐暗黑屏（约0.5s）→ 切换场景 → 渐亮显示
# goto_scene(path, color)：可指定渐暗的颜色（如青绿墨色，用于与地图入场墨幕无缝衔接）
# goto_scene_intro(path)：用「卷帘」盖住场景加载，加载完成后再卷轴滚出揭示地图（无缝，无灰屏/黑屏）

const FADE_OUT := 0.25   # 渐暗时长（秒）
const HOLD := 0.25       # 全黑停留时长（秒）→ 共 0.5s 后切换
const FADE_IN := 0.3     # 渐亮时长（秒）
const SCENE_CURTAIN := preload("res://scenes/scene_curtain.gd")

var _rect: ColorRect
var _curtain
var _fading := false

func _ready() -> void:
	layer = 200
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	_rect.visible = false
	_curtain = SCENE_CURTAIN.new()
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.visible = false
	add_child(_curtain)

# 带渐暗转场的场景切换（调用方无需 await，内部异步执行）
func goto_scene(path: String, fade_color: Color = Color.BLACK) -> void:
	if _fading:
		return
	_fading = true
	# 渐暗 + 拦截输入
	_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0)
	_rect.visible = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw1 := create_tween()
	tw1.tween_property(_rect, "color:a", 1.0, FADE_OUT)
	# 等待约 0.5s（渐暗完成 + 停留）后切换场景
	await get_tree().create_timer(FADE_OUT + HOLD).timeout
	get_tree().change_scene_to_file(path)
	# 渐亮
	var tw2 := create_tween()
	tw2.tween_property(_rect, "color:a", 0.0, FADE_IN)
	await tw2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	_fading = false

# 舆图展开→地图：卷帘盖住加载，加载完成后卷轴滚出揭示（无缝衔接）
func goto_scene_intro(path: String) -> void:
	if _fading:
		return
	_fading = true
	_curtain.cover()
	await get_tree().process_frame
	get_tree().change_scene_to_file(path)
	# 让地图在帘后构建完成（构建可能阻塞若干帧，帘保持遮盖，不露灰屏）
	for i in range(4):
		await get_tree().process_frame
	_curtain.rollout()
	await get_tree().create_timer(1.2).timeout
	_fading = false
