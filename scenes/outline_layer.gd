extends Node2D
# 选中/悬停坊的菱形描边层（世界坐标，位于地图上方、UI 下方）

var map

func _ready() -> void:
	pass

func _draw() -> void:
	if map == null:
		return
	# 悬停描边
	if map._hover_outline.size() >= 2:
		for i in range(map._hover_outline.size() - 1):
			draw_line(map._hover_outline[i], map._hover_outline[i + 1], Color(0.02, 0.03, 0.025, 0.45), 5.0)
			draw_line(map._hover_outline[i], map._hover_outline[i + 1], Color(0.95, 0.78, 0.36, 0.58), 2.0)
	# 选中描边（非线性揭示动画：从无到有缓慢淡出金边）
	var reveal: float = map.outline_reveal()
	if map._fang_outline.size() >= 2 and reveal > 0.001:
		for i in range(map._fang_outline.size() - 1):
			draw_line(map._fang_outline[i], map._fang_outline[i + 1], Color(0.02, 0.03, 0.025, 0.78 * reveal), 7.0)
			draw_line(map._fang_outline[i], map._fang_outline[i + 1], Color(0.97, 0.83, 0.46, 0.94 * reveal), 3.0)
