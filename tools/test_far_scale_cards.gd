extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var data = root.get_node("DataManager")
	# Never send paid requests during this regression test.
	data.llm_config["chat_via_backend"] = false
	data.llm_config["api_key"] = ""
	var scene = load("res://scenes/ChangAnCity.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(data.far_scale_cards.size() == 148)
	for card in data.far_scale_cards:
		var found: Dictionary = scene._find_far_card({"key": card.id, "name": card.name})
		assert(found == card)
		var named: Dictionary = scene._find_far_card({"key": "synthetic", "name": card.name})
		assert(named.name == card.name and named.scale == card.scale)
	scene._set_zoom(0, true)
	scene._select({"key": "TC-FANG-0054", "name": "光禄坊", "type": "Fang"})
	assert(scene._far_card_open)
	assert(scene._far_card.scale == "558 × 500 米")
	assert(scene._selected.is_empty())
	await process_frame
	scene._select({"key": "STREET-test", "name": "无对应尺度道路", "type": "街道"})
	assert(scene._far_card.scale == "尺度暂无")
	await process_frame
	for zoom in [1, 2]:
		scene._set_zoom(zoom, true)
		assert(not scene._far_card_open)
		scene._select(scene._fang_data(0, 5))
		assert(not scene._selected.is_empty())
		assert(not scene._far_card_open)
		await process_frame
		assert(not scene._panel_mini_map.is_empty())
		for page in [2, 3, 1]:
			var button: Rect2 = scene.building_page_rect(page - 1)
			var click_pos: Vector2 = button.get_center() * scene.ui_scale() + scene.ui_visual_offset()
			var motion := InputEventMouseMotion.new()
			motion.position = click_pos
			root.push_input(motion, true)
			for pressed in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.position = click_pos
				event.global_position = click_pos
				event.pressed = pressed
				root.push_input(event, true)
			await process_frame
			assert(scene._panel_page == page)
			scene._panel_anim_t = 1.0
			await process_frame
			scene._ui.queue_redraw()
			await process_frame
	scene.queue_free()
	await process_frame
	print("PASS: 148 V3 cards; far selection/rendering; missing scales; mid/near legacy routing")
	quit()
