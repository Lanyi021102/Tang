extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data = root.get_node("DataManager")
	data.llm_config["api_key"] = ""
	data.llm_config["chat_via_backend"] = false
	var scene = load("res://scenes/ChangAnCity.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._set_zoom(2, true)
	var fields = scene._ui.get_node("EntityCardFields")
	for selected in [{"key": "FANG-0-5", "name": "光禄坊", "type": "坊"}, {"key": "TC-ROAD-2000", "name": "皇城横街", "type": "街道"}]:
		scene._select(selected)
		scene.set_building_page(2)
		await process_frame
		await process_frame
		assert(fields.visible)
		assert(fields.rows.size() >= 5)
		var entity: Dictionary = data.card_entity(selected)
		assert(fields.current_key == entity.key)
		for row in fields.rows: assert(not str(row[1]).contains("TC-"))
		if entity.type == "Road": assert(fields.rows.any(func(row): return row[0] == "原文路宽" and row[1] == "300步"))
	print("ENTITY_CARD_PASS: mapped Fang and Road; JSON fields; resolved names; original width")
	scene.queue_free()
	await process_frame
	quit()
