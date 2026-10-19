extends Control

const Client = preload("res://autoload/GraphClient.gd")
const Diagram = preload("res://scenes/graph_diagram.gd")
const SPATIAL_TYPES := ["LOCATED_IN", "LOCATED_ON", "CONTAINS", "PART_OF", "NORTH_OF", "SOUTH_OF", "EAST_OF", "WEST_OF", "NORTHEAST_OF", "NORTHWEST_OF", "SOUTHEAST_OF", "SOUTHWEST_OF", "ADJACENT_TO", "NEAR", "FACING", "CONNECTS_TO", "CONNECTS", "FLOWS_THROUGH", "FLOWS_INTO", "ORIGINATES_FROM", "IS_ENTRANCE_OF", "SPLITS"]

var host
var client
var identity: Dictionary = {}
var context := ""
var page := 0
var generation := 0
var graph_generation := 0
var relation_id := ""
var evidence_items: Array = []
var evidence_index := 0

var status_label: Label
var toolbar: HBoxContainer
var target_row: HBoxContainer
var depth: OptionButton
var filter: OptionButton
var target: LineEdit
var diagram
var results: RichTextLabel
var retry: Button
var entity_evidence: Button
var knowledge_body: RichTextLabel
var evidence_panel: PanelContainer
var evidence_title: Label
var evidence_quote: RichTextLabel
var evidence_source: Label
var evidence_counter: Label
var evidence_prev: Button
var evidence_next: Button
var ai_panel: PanelContainer
var ai_history: RichTextLabel
var ai_question_buttons: Array[Button] = []
var ai_signature := ""

func _ready() -> void:
	position = Vector2(874, 112)
	size = Vector2(342, 492)
	mouse_filter = Control.MOUSE_FILTER_STOP
	client = Client.new()
	add_child(client)
	client.base_url = str(DataManager.llm_config.get("graph_base_url", DataManager.llm_config.get("rag_base_url", "http://127.0.0.1:8080")))
	_build_common()
	_build_evidence_page()
	_build_graph_page()
	_build_ai_page()
	_apply_original_fonts()
	_enable_card_clicks(self)
	visible = false

func _enable_card_clicks(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton or child is ScrollBar: continue
		if child is Control and child.mouse_filter == Control.MOUSE_FILTER_STOP:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_enable_card_clicks(child)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if host != null and host._panel_page == 4:
			if not event.pressed: host.set_building_page(1)
			accept_event()

func _apply_original_fonts() -> void:
	if host == null: return
	if host.font_song:
		evidence_title.add_theme_font_override("font", host.font_song)
	if host.font_hei:
		evidence_quote.add_theme_font_override("normal_font", host.font_hei)
		evidence_source.add_theme_font_override("font", host.font_hei)
		evidence_counter.add_theme_font_override("font", host.font_hei)
		ai_history.add_theme_font_override("normal_font", host.font_hei)
		for button in ai_question_buttons: button.add_theme_font_override("font", host.font_hei)

func _build_common() -> void:
	status_label = Label.new()
	status_label.position = Vector2(0, 0)
	status_label.size = Vector2(342, 38)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	add_child(status_label)
	retry = Button.new()
	retry.text = "重新查询"
	retry.position = Vector2(224, 458)
	retry.size = Vector2(118, 30)
	retry.pressed.connect(func():
		if page == 4: _query_evidence()
		elif page == 3: _query_graph(false))
	add_child(retry)

func _build_evidence_page() -> void:
	knowledge_body = RichTextLabel.new()
	knowledge_body.position = Vector2(0, 42)
	knowledge_body.size = Vector2(342, 208)
	knowledge_body.bbcode_enabled = true
	knowledge_body.fit_content = false
	knowledge_body.add_theme_font_size_override("normal_font_size", 13)
	add_child(knowledge_body)
	evidence_panel = PanelContainer.new()
	# 第二页主体继续由原卡片绘制；这里只在最下方叠加史料证据。
	evidence_panel.position = Vector2(0, 308)
	evidence_panel.size = Vector2(342, 142)
	var evidence_style := StyleBoxFlat.new()
	evidence_style.bg_color = Color("#0a291e")
	evidence_style.border_color = Color("#9d7b31")
	evidence_style.set_border_width_all(1)
	evidence_style.set_corner_radius_all(5)
	evidence_panel.add_theme_stylebox_override("panel", evidence_style)
	add_child(evidence_panel)
	var evidence_layer := Control.new()
	evidence_panel.add_child(evidence_layer)
	evidence_title = Label.new()
	evidence_title.position = Vector2(12, 8)
	evidence_title.size = Vector2(310, 22)
	evidence_title.text = "史料原文"
	evidence_title.add_theme_color_override("font_color", Color("#d4a63f"))
	evidence_layer.add_child(evidence_title)
	evidence_quote = RichTextLabel.new()
	evidence_quote.position = Vector2(12, 32)
	evidence_quote.size = Vector2(318, 63)
	evidence_quote.add_theme_font_size_override("normal_font_size", 16)
	evidence_layer.add_child(evidence_quote)
	evidence_source = Label.new()
	evidence_source.position = Vector2(12, 97)
	evidence_source.size = Vector2(318, 22)
	evidence_source.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	evidence_source.add_theme_color_override("font_color", Color("#8fa58f"))
	evidence_source.add_theme_font_size_override("font_size", 13)
	evidence_layer.add_child(evidence_source)
	evidence_prev = Button.new()
	evidence_prev.text = "‹"
	evidence_prev.position = Vector2(220, 113)
	evidence_prev.size = Vector2(30, 25)
	evidence_prev.pressed.connect(func(): _step_evidence(-1))
	evidence_layer.add_child(evidence_prev)
	evidence_counter = Label.new()
	evidence_counter.position = Vector2(251, 115)
	evidence_counter.size = Vector2(46, 22)
	evidence_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	evidence_layer.add_child(evidence_counter)
	evidence_next = Button.new()
	evidence_next.text = "›"
	evidence_next.position = Vector2(298, 113)
	evidence_next.size = Vector2(30, 25)
	evidence_next.pressed.connect(func(): _step_evidence(1))
	evidence_layer.add_child(evidence_next)
	entity_evidence = Button.new()
	entity_evidence.text = "返回实体证据"
	entity_evidence.position = Vector2(0, 458)
	entity_evidence.size = Vector2(150, 30)
	entity_evidence.pressed.connect(func():
		relation_id = ""
		_query_evidence())
	add_child(entity_evidence)

func _build_graph_page() -> void:
	toolbar = HBoxContainer.new()
	toolbar.position = Vector2(0, 0)
	toolbar.size = Vector2(342, 32)
	add_child(toolbar)
	depth = OptionButton.new()
	for n in range(1, 4): depth.add_item("%d 跳" % n)
	toolbar.add_child(depth)
	depth.item_selected.connect(func(_i): _query_graph(false))
	filter = OptionButton.new()
	filter.add_item("空间关系")
	filter.add_item("全部关系")
	filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(filter)
	filter.item_selected.connect(func(_i): _query_graph(false))
	var expand := Button.new()
	expand.text = "展开"
	expand.pressed.connect(func(): _query_graph(false))
	toolbar.add_child(expand)
	target_row = HBoxContainer.new()
	target_row.position = Vector2(0, 36)
	target_row.size = Vector2(342, 32)
	add_child(target_row)
	target = LineEdit.new()
	target.placeholder_text = "目标名称或 TC- 编号"
	target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_row.add_child(target)
	var path_button := Button.new()
	path_button.text = "查路径"
	path_button.pressed.connect(func(): _query_graph(true))
	target_row.add_child(path_button)
	diagram = Diagram.new()
	diagram.position = Vector2(0, 74)
	diagram.size = Vector2(342, 270)
	diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(diagram)
	results = RichTextLabel.new()
	results.position = Vector2(0, 386)
	results.size = Vector2(342, 66)
	results.bbcode_enabled = false
	results.add_theme_font_size_override("normal_font_size", 11)
	results.meta_clicked.connect(_open_relation)
	add_child(results)

func _build_ai_page() -> void:
	ai_panel = PanelContainer.new()
	ai_panel.position = Vector2(0, 0)
	ai_panel.size = Vector2(342, 242)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#082d20")
	style.border_color = Color("#9d7b31")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	ai_panel.add_theme_stylebox_override("panel", style)
	add_child(ai_panel)
	var layer := Control.new()
	ai_panel.add_child(layer)
	var title := Label.new()
	title.text = "AI 对话"
	title.position = Vector2(12, 8)
	title.size = Vector2(318, 24)
	title.add_theme_color_override("font_color", Color("#d4a63f"))
	if host != null and host.font_song: title.add_theme_font_override("font", host.font_song)
	layer.add_child(title)
	ai_history = RichTextLabel.new()
	ai_history.position = Vector2(12, 36)
	ai_history.size = Vector2(318, 116)
	ai_history.bbcode_enabled = true
	ai_history.scroll_following = false
	ai_history.add_theme_font_size_override("normal_font_size", 16)
	layer.add_child(ai_history)
	for i in range(2):
		var question_button := Button.new()
		question_button.position = Vector2(12, 160 + i * 38)
		question_button.size = Vector2(318, 32)
		question_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		question_button.add_theme_font_size_override("font_size", 14)
		question_button.pressed.connect(func(): _send_question(i))
		layer.add_child(question_button)
		ai_question_buttons.append(question_button)
	_refresh_question_buttons()

func _send_question(index: int) -> void:
	if host == null or host._loading: return
	var questions: Array = host._followups
	if index < 0 or index >= questions.size(): return
	var item: Dictionary = questions[index]
	var question := str(item.get("q", item.get("label", ""))).strip_edges()
	if question == "" or host == null or host._loading: return
	host.ask_followup(question)
	_refresh_ai_history(true)

func _refresh_question_buttons() -> void:
	if host == null or ai_question_buttons.is_empty(): return
	var questions: Array = host._followups
	for i in range(ai_question_buttons.size()):
		var button := ai_question_buttons[i]
		if i < questions.size():
			var item: Dictionary = questions[i]
			button.text = str(item.get("label", item.get("q", "追问")))
			button.disabled = host._loading
		else:
			button.text = "生成中…"
			button.disabled = true

func _refresh_ai_history(force: bool = false) -> void:
	if host == null: return
	var signature := str(host._intro_text) + "|" + str(host._typing_text) + "|" + str(host._typing_visible) + "|" + str(host._typing) + "|" + str(host._loading) + "|" + str(host._chat) + "|" + str(host._followups) + "|" + str(host._error)
	if not force and signature == ai_signature: return
	ai_signature = signature
	var text := ""
	if str(host._intro_text).strip_edges() != "":
		text += "[color=#d4a63f]AI[/color]　" + str(host._intro_text).strip_edges() + "\n\n"
	for message in host._chat:
		var role := str(message.get("role", ""))
		var label := "你" if role == "user" else "AI"
		var color := "#e1c77a" if role == "user" else "#d4a63f"
		text += "[color=" + color + "]" + label + "[/color]　" + str(message.get("text", "")) + "\n\n"
	if host._typing and str(host._typing_text) != "":
		var visible_count := clampi(int(host._typing_visible), 0, str(host._typing_text).length())
		var partial := str(host._typing_text).left(visible_count)
		if partial == "": partial = "…"
		text += "[color=#d4a63f]AI[/color]　" + partial + "\n\n"
	if host._loading:
		text += "[color=#8fa58f]AI 正在整理回答…[/color]"
	elif str(host._error) != "":
		text += "\n[color=#e1b483]" + str(host._error) + "[/color]"
	if text == "": text = "可结合当前卡片内容继续提问。"
	var reading_position := ai_history.get_v_scroll_bar().value
	ai_history.text = text
	ai_history.get_v_scroll_bar().value = reading_position
	_refresh_question_buttons()

func _process(_delta: float) -> void:
	if host == null: return
	var active: bool = not host._selected.is_empty() and not host._far_card_open and host._panel_page == 4 and not host._codex_open and not host._hist_open
	visible = active
	var next_context := str(host._selected.get("key", "")) + "|" + str(host._selected.get("name", ""))
	if not active:
		if context != "":
			generation += 1
			client.cancel_all()
			context = ""
		return
	if context == next_context and page == host._panel_page:
		if page == 4: _refresh_ai_history()
		return
	var changed := context != next_context
	context = next_context
	page = host._panel_page
	generation += 1
	client.cancel_all()
	if changed:
		identity = Client.resolve_entity(host._selected, DataManager.graph_entities)
		relation_id = ""
		target.text = ""
	_set_page_visibility()
	results.clear()
	if identity.is_empty():
		status_label.text = "无法唯一对应图谱实体。请核对实体编号；不使用格网替代。"
		return
	if page == 3:
		_query_graph(false)
	elif page == 4:
		_refresh_ai_history(true)
		_query_evidence()

func _set_page_visibility() -> void:
	var evidence_page := page == 4
	var graph_page := page == 3
	# 保留 ui_overlay 中原有第二页的字体和排版，不另绘一层正文。
	knowledge_body.visible = false
	evidence_panel.visible = evidence_page
	entity_evidence.visible = evidence_page and relation_id != ""
	ai_panel.visible = evidence_page
	toolbar.visible = graph_page
	target_row.visible = graph_page
	diagram.visible = graph_page
	results.visible = graph_page
	status_label.visible = graph_page
	retry.visible = false
	status_label.position = Vector2(0, 347)
	status_label.size = Vector2(342, 36)

func _open_relation(value: Variant) -> void:
	relation_id = str(value)
	host.set_building_page(4)

func _fill_original_content() -> void:
	var selected: Dictionary = host._selected
	var lines: Array[String] = []
	lines.append("[font_size=20][color=#d4a63f]" + str(selected.get("name", identity.get("name", ""))) + "[/color][/font_size]")
	if str(selected.get("type", "")) != "": lines.append("类型　" + str(selected.type))
	if str(selected.get("zone", "")) != "": lines.append("区域　" + str(selected.zone))
	if str(selected.get("location", "")) != "": lines.append("位置　" + str(selected.location))
	if str(selected.get("function", "")) != "": lines.append("职能　" + str(selected.function))
	var description := str(selected.get("description", ""))
	if description != "": lines.append("\n" + description)
	knowledge_body.text = "\n".join(lines)

func _query_evidence() -> void:
	if identity.is_empty(): return
	generation += 1
	var ticket := generation
	client.cancel_all()
	_fill_original_content()
	evidence_items = []
	_render_evidence()
	status_label.text = "正在查询公开、已发布的证据…"
	var endpoint := "/api/v1/research/entities/" + str(identity.id)
	if relation_id != "": endpoint = "/api/v1/research/relations/" + relation_id.uri_encode()
	var response: Dictionary = await client.request_json(endpoint)
	if ticket != generation: return
	if not response.ok:
		status_label.text = response.error
		evidence_quote.text = "证据服务暂不可用；原卡片内容仍可查看。"
		return
	var data: Dictionary = response.data
	evidence_items = data.get("evidence", [])
	evidence_index = 0
	if relation_id == "":
		status_label.text = "实体证据：" + str(identity.name)
	else:
		status_label.text = "关系证据：%s → %s" % [str(data.get("source_name", "")), str(data.get("target_name", ""))]
		knowledge_body.text += "\n\n关系　" + str(data.get("type", ""))
	_render_evidence()

func _step_evidence(offset: int) -> void:
	if evidence_items.is_empty(): return
	evidence_index = posmod(evidence_index + offset, evidence_items.size())
	_render_evidence()

func _render_evidence() -> void:
	var count := evidence_items.size()
	evidence_prev.disabled = count <= 1
	evidence_next.disabled = count <= 1
	evidence_counter.text = ("%d/%d" % [evidence_index + 1, count]) if count > 0 else "0/0"
	if count == 0:
		evidence_quote.text = "暂无可公开展示的原文证据。不能将此视为史实已证实。"
		evidence_source.text = "来源：未提供"
		return
	var item: Dictionary = evidence_items[evidence_index]
	evidence_quote.text = str(item.get("original_text", ""))
	var source := str(item.get("source_title", "未注明来源"))
	var chapter := str(item.get("chapter", ""))
	var page_number := str(item.get("page_start", ""))
	evidence_source.text = "来源：%s　%s%s　证据编号：%s" % [source, chapter, (" 第%s页" % page_number) if page_number != "" else "", str(item.get("id", ""))]

func _query_graph(path_mode: bool) -> void:
	if identity.is_empty(): return
	graph_generation += 1
	var ticket := graph_generation
	var selected_generation := generation
	var types: Array = SPATIAL_TYPES if filter.selected == 0 else []
	var hops := depth.selected + 1
	var endpoint := "/api/v1/graph/neighbors?entity_id=" + str(identity.id) + "&depth=" + str(hops)
	var payload: Variant = null
	if path_mode:
		var needle := target.text.strip_edges()
		var destination: Dictionary = Client.resolve_entity({"key": needle, "name": needle}, DataManager.graph_entities)
		if destination.is_empty():
			status_label.text = "目标不存在或同名，请输入唯一 TC- 实体编号。"
			return
		if destination.id == identity.id:
			status_label.text = "起点与终点不能相同。"
			return
		endpoint = "/api/v1/graph/path"
		payload = {"source_id": identity.id, "target_id": destination.id, "max_depth": hops, "max_paths": 5, "relation_types": types}
	else:
		for type_name in types: endpoint += "&relation_types=" + str(type_name).uri_encode()
	client.cancel_all()
	results.clear()
	diagram.show_graph({}, str(identity.id))
	status_label.text = "正在查询图谱；关联路径不等于新推导结论。"
	var response: Dictionary = await client.request_json(endpoint, payload)
	if ticket != graph_generation or selected_generation != generation: return
	if not response.ok:
		status_label.text = response.error
		return
	var data: Dictionary = response.data
	if path_mode:
		var paths: Array = data.get("paths", [])
		status_label.text = "返回 %d 条路径（最多5条）；箭头保留关系方向。" % paths.size()
		if paths.is_empty(): results.add_text("所选条件内未找到路径。")
		for i in range(paths.size()):
			results.add_text("路径 %d · %s 跳\n" % [i + 1, str(paths[i].get("length", ""))])
			_render_edges(paths[i])
		if not paths.is_empty(): diagram.show_graph(paths[0], str(identity.id))
	else:
		var nodes: Array = data.get("nodes", [])
		var graph_edges: Array = data.get("edges", [])
		status_label.text = "%d节点 / %d关系；拓扑不代表历史方位或比例。" % [nodes.size(), graph_edges.size()]
		if data.get("meta", {}).get("truncated", false): status_label.text += " 后端结果已截断。"
		if graph_edges.is_empty(): results.add_text("当前筛选下暂无已发布关系。")
		_render_edges(data)
		diagram.show_graph(data, str(identity.id))

func _render_edges(graph: Dictionary) -> void:
	var names: Dictionary = {}
	for node in graph.get("nodes", []): names[str(node.id)] = str(node.get("label", node.id))
	for edge in graph.get("edges", []):
		var source := str(edge.get("source", ""))
		var destination := str(edge.get("target", ""))
		results.add_text(str(names.get(source, source)) + " — " + str(edge.get("type", "")) + " → " + str(names.get(destination, destination)) + "　")
		results.push_meta(str(edge.get("id", "")))
		results.add_text("[证据]\n")
		results.pop()
