extends SceneTree
const Client = preload("res://autoload/GraphClient.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data = root.get_node("DataManager")
	data.llm_config["chat_via_backend"] = false
	data.llm_config["api_key"] = ""
	data.llm_config["graph_base_url"] = "http://127.0.0.1:" + OS.get_environment("GRAPH_TEST_PORT")
	var identity := Client.resolve_entity({"key": "FANG-0-5", "name": "光禄坊", "type": "坊"}, data.graph_entities)
	assert(identity.key == "TC-FANG-0054")
	assert(Client.resolve_entity({"name": "丹凤门街", "type": "Road"}, data.graph_entities).is_empty())
	assert(Client.resolve_entity({"name": "不存在"}, data.graph_entities).is_empty())
	var scene = load("res://scenes/ChangAnCity.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var panel = scene._ui.get_node("GraphCardPanel")
	panel.set_process(false)
	scene._set_zoom(2, true)
	scene._select({"key": "TC-FANG-0054", "name": "光禄坊", "type": "Fang"})
	scene.set_building_page(3)
	panel._process(0)
	assert(not panel.visible)
	# 查询接口保留回归覆盖；第三页产品界面现为九宫格空间图。
	panel.identity = identity
	await create_timer(0.3).timeout
	await panel._query_graph(false)
	await process_frame
	assert(panel.results.get_parsed_text().contains("NORTH_OF"))
	assert(panel.diagram.edges.size() == 1)
	assert(panel.diagram.node_positions.has(identity.id))
	assert(panel.diagram.node_positions[identity.id].distance_to(panel.diagram.size * Vector2(0.5, 0.53)) < 2.0)
	assert(panel.diagram.hop_depths[identity.id] == 0)
	panel.depth.select(2)
	panel.target.text = "TC-FANG-0055"
	await panel._query_graph(true)
	await process_frame
	assert(panel.results.get_parsed_text().contains("路径 1"))
	panel._open_relation("relation-test")
	panel._process(0)
	await create_timer(0.3).timeout
	panel.relation_id = "relation-test"
	await panel._query_evidence()
	await process_frame
	assert(scene._panel_page == 4)
	assert(panel.ai_panel.visible)
	assert(panel.ai_question_buttons.size() == 2)
	assert(not panel.ai_question_buttons[0].text.is_empty())
	scene._typing = true
	scene._typing_text = "模拟回答"
	scene._typing_visible = 2
	panel._refresh_ai_history(true)
	assert(panel.ai_history.get_parsed_text().contains("模拟"))
	scene._typing = false
	scene._typing_text = ""
	scene._typing_visible = 0
	assert(panel.evidence_quote.get_parsed_text().contains("模拟史料原文"))
	assert(panel.evidence_source.text.contains("模拟来源"))
	assert(panel.evidence_panel.position.y > panel.knowledge_body.position.y + panel.knowledge_body.size.y)
	assert(scene._ui.get_node("CardNavigation").buttons.size() == 4)
	scene.set_building_page(2)
	panel._process(0)
	assert(not panel.visible)
	# Changing the selected entity must discard a relationship from the prior entity.
	scene._select({"key": "TC-FANG-0055", "name": "殖业坊", "type": "Fang"})
	scene.set_building_page(4)
	panel._process(0)
	assert(panel.relation_id == "")
	await create_timer(0.3).timeout
	await panel._query_evidence()
	assert(panel.status_label.text.contains("殖业坊"))
	var bad: Dictionary = await panel.client.request_json("/invalid-json")
	assert(not bad.ok)
	var missing: Dictionary = await panel.client.request_json("/missing")
	assert(not missing.ok and missing.error.contains("404"))
	panel.client.base_url = "http://127.0.0.1:1"
	await panel._query_evidence()
	assert(panel.status_label.text.contains("不可达"))
	scene._set_zoom(0, true)
	panel._process(0)
	assert(not panel.visible)
	print("GRAPH_TEST_PASS: four pages, graph, paths, page4 AI/evidence, switching, malformed JSON, 404, offline, far isolation")
	scene.queue_free()
	await process_frame
	quit()
