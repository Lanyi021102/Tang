extends Control
# 仅展示图谱拓扑。屏幕位置和连线长度不表示历史方位、距离或比例。

const RELATION_LABELS := {
	"LOCATED_IN": "位于", "LOCATED_ON": "坐落于", "CONTAINS": "包含", "PART_OF": "隶属",
	"NORTH_OF": "北邻", "SOUTH_OF": "南邻", "EAST_OF": "东邻", "WEST_OF": "西邻",
	"NORTHEAST_OF": "东北", "NORTHWEST_OF": "西北", "SOUTHEAST_OF": "东南", "SOUTHWEST_OF": "西南",
	"ADJACENT_TO": "相邻", "NEAR": "邻近", "FACING": "相对", "CONNECTS_TO": "连通",
	"CONNECTS": "连接", "FLOWS_THROUGH": "流经", "FLOWS_INTO": "汇入", "ORIGINATES_FROM": "发源",
	"IS_ENTRANCE_OF": "入口", "SPLITS": "分界"
}
const TYPE_COLORS := {
	"Fang": Color("#777b77"), "Road": Color("#b18438"), "Street": Color("#b18438"),
	"Canal": Color("#4d8c9c"), "Water": Color("#4d8c9c"), "Building": Color("#88553c"),
	"Gate": Color("#bd8b2e")
}

var nodes: Array = []
var edges: Array = []
var center_id := ""
var node_positions: Dictionary = {}
var hop_depths: Dictionary = {}
var font: Font

func show_graph(graph: Dictionary, center: String) -> void:
	var all_nodes: Array = graph.get("nodes", [])
	center_id = center
	hop_depths = _calculate_hops(all_nodes, graph.get("edges", []), center)
	all_nodes.sort_custom(func(a, b):
		var da := int(hop_depths.get(str(a.get("id", "")), 99))
		var db := int(hop_depths.get(str(b.get("id", "")), 99))
		if da != db: return da < db
		return str(a.get("label", "")) < str(b.get("label", "")))
	nodes = all_nodes.slice(0, mini(13, all_nodes.size()))
	var visible_ids: Dictionary = {}
	for node in nodes: visible_ids[str(node.get("id", ""))] = true
	edges = []
	for edge in graph.get("edges", []):
		if visible_ids.has(str(edge.get("source", ""))) and visible_ids.has(str(edge.get("target", ""))): edges.append(edge)
	_layout_nodes()
	queue_redraw()

func _calculate_hops(all_nodes: Array, all_edges: Array, center: String) -> Dictionary:
	var result := {center: 0}
	var adjacency: Dictionary = {}
	for node in all_nodes: adjacency[str(node.get("id", ""))] = []
	for edge in all_edges:
		var a := str(edge.get("source", ""))
		var b := str(edge.get("target", ""))
		if not adjacency.has(a): adjacency[a] = []
		if not adjacency.has(b): adjacency[b] = []
		adjacency[a].append(b)
		adjacency[b].append(a)
	var queue: Array = [center]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for next_id in adjacency.get(current, []):
			if result.has(next_id): continue
			result[next_id] = int(result[current]) + 1
			queue.append(next_id)
	return result

func _layout_nodes() -> void:
	node_positions.clear()
	if size.x <= 0.0 or size.y <= 0.0: return
	var center := Vector2(size.x * 0.5, size.y * 0.53)
	var by_hop: Dictionary = {}
	for node in nodes:
		var node_id := str(node.get("id", ""))
		var hop := int(hop_depths.get(node_id, 3))
		if node_id == center_id: hop = 0
		if not by_hop.has(hop): by_hop[hop] = []
		by_hop[hop].append(node)
	node_positions[center_id] = center
	var max_radius := minf(size.x * 0.40, size.y * 0.39)
	for hop in by_hop:
		if int(hop) == 0: continue
		var group: Array = by_hop[hop]
		var radius := max_radius * clampf(float(hop) / 3.0 + 0.18, 0.48, 1.0)
		for i in range(group.size()):
			var angle := -PI * 0.5 + TAU * (float(i) / maxf(group.size(), 1.0)) + float(hop) * 0.32
			node_positions[str(group[i].get("id", ""))] = center + Vector2(cos(angle), sin(angle) * 0.72) * radius

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_nodes()
		queue_redraw()

func _draw() -> void:
	var use_font := font if font != null else ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color("#072b20"), true)
	for x in range(18, int(size.x), 36): draw_line(Vector2(x, 24), Vector2(x, size.y - 14), Color(0.65, 0.55, 0.27, 0.13), 1.0)
	for y in range(28, int(size.y), 36): draw_line(Vector2(8, y), Vector2(size.x - 8, y), Color(0.65, 0.55, 0.27, 0.13), 1.0)
	draw_string(use_font, Vector2(9, 17), "实线＝已发布关系　环层＝跳数", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#8fa58f"))
	for edge in edges: _draw_edge(edge, use_font)
	for node in nodes: _draw_node(node, use_font)

func _draw_edge(edge: Dictionary, use_font: Font) -> void:
	var source := str(edge.get("source", ""))
	var target_id := str(edge.get("target", ""))
	if not node_positions.has(source) or not node_positions.has(target_id): return
	var start: Vector2 = node_positions[source]
	var finish: Vector2 = node_positions[target_id]
	var direction := (finish - start).normalized()
	start += direction * 27.0
	finish -= direction * 27.0
	draw_line(start, finish, Color("#b68b37"), 1.4, true)
	draw_colored_polygon(PackedVector2Array([finish, finish - direction.rotated(0.48) * 7.0, finish - direction.rotated(-0.48) * 7.0]), Color("#d6a843"))
	var relation := str(RELATION_LABELS.get(str(edge.get("type", "")), edge.get("type", "")))
	var middle := (start + finish) * 0.5 + direction.rotated(PI * 0.5) * 8.0
	draw_rect(Rect2(middle - Vector2(18, 9), Vector2(36, 14)), Color(0.02, 0.13, 0.10, 0.88), true)
	draw_string(use_font, middle + Vector2(-17, 2), relation, HORIZONTAL_ALIGNMENT_CENTER, 34, 9, Color("#d4c18b"))

func _draw_node(node: Dictionary, use_font: Font) -> void:
	var node_id := str(node.get("id", ""))
	if not node_positions.has(node_id): return
	var point: Vector2 = node_positions[node_id]
	var focused := node_id == center_id
	var node_size := Vector2(82, 34) if focused else Vector2(66, 27)
	var rect := Rect2(point - node_size * 0.5, node_size)
	var type_name := str(node.get("type", node.get("entity_type", "")))
	var fill: Color = Color("#303630") if focused else TYPE_COLORS.get(type_name, Color("#6f756f"))
	draw_style_box(_box(fill, Color("#e0aa3d") if focused else Color("#c3a45a"), 2 if focused else 1, 5), rect)
	var label := str(node.get("label", node.get("name", node_id)))
	if label.length() > 6: label = label.left(5) + "…"
	draw_string(use_font, point + Vector2(-node_size.x * 0.5 + 4, 4), label, HORIZONTAL_ALIGNMENT_CENTER, node_size.x - 8, 12 if focused else 10, Color("#f0dfae"))
	if not focused:
		var hop := int(hop_depths.get(node_id, 0))
		draw_string(use_font, point + Vector2(node_size.x * 0.5 - 8, -node_size.y * 0.5 + 7), str(hop), HORIZONTAL_ALIGNMENT_CENTER, 10, 8, Color("#f4ca65"))

func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
