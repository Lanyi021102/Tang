extends Node2D
# 选中/悬停坊的菱形描边层（世界坐标，位于地图上方、UI 下方）

var map

func _ready() -> void:
	pass

func _draw() -> void:
	if map == null:
		return
	if map._zoom_idx != 0: return
	if map._far_card_open:
		_draw_far_selection()
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

func _draw_far_selection() -> void:
	var entity: Dictionary = map._far_selected_entity
	var key := str(entity.get("key", ""))
	var parts := key.split("-")
	var polygon := PackedVector2Array()
	if key.begins_with("FANG-") and parts.size() == 3:
		polygon = map._outline_for(Vector2(int(parts[1]), int(parts[2])))
	elif key.begins_with("STREET-") and parts.size() == 3:
		var index := int(parts[2])
		var x := 0.0
		var y := 0.0
		var width: float = map._ns_x(10)
		var height: float = map._ew_y(13)
		if parts[1].to_upper() == "NS":
			if index < 0 or index >= map.NS_STREET_WIDTHS.size(): return
			x = map._ns_x(index)
			width = float(map.NS_STREET_WIDTHS[index])
			# 朱雀门街从皇宫南界起，不贯穿宫城与皇城。
			if index == 5:
				y = maxf(0.0, map._palace_step_rect.end.y)
				height = maxf(0.0, height - y)
		else:
			if index < 0 or index >= map.EW_STREET_WIDTHS.size(): return
			y = map._ew_y(index)
			height = float(map.EW_STREET_WIDTHS[index])
		polygon = PackedVector2Array([map._step_iso(x, y), map._step_iso(x + width, y), map._step_iso(x + width, y + height), map._step_iso(x, y + height), map._step_iso(x, y)])
	if polygon.size() < 4: return
	draw_colored_polygon(polygon, Color(1.0, 0.68, 0.12, 0.40))
	var stroke: float = 2.5 / maxf(float(map._camera.zoom.x), 0.01)
	draw_polyline(polygon, Color("#f5bb43"), stroke, true)
