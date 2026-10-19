extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/ChangAnCity.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._set_zoom(2, true)
	scene._select({"key": "FANG-0-5", "name": "光禄坊", "type": "坊"})
	scene.set_building_page(4)
	var panel = scene._ui.get_node("GraphCardPanel")
	for i in range(600):
		await create_timer(0.1).timeout
		if not scene._loading: break
	if scene._error != "" or scene._intro_text.is_empty():
		printerr("LIVE_CARD_INTRO_FAILED: ", scene._error)
		quit(1)
		return
	panel._refresh_ai_history(true)
	assert(panel.ai_history.get_parsed_text().contains(scene._intro_text))
	for button in panel.ai_question_buttons:
		assert(scene._intro_text.contains(button.text))
		assert(button.text != "唐长安城为什么采用里坊制？")
	assert(not scene._intro_text.contains("信息范围"))
	var first_questions: Array = scene._followups.duplicate(true)
	panel.ai_question_buttons[0].pressed.emit()
	for i in range(600):
		await create_timer(0.1).timeout
		if not scene._loading: break
	if scene._error != "" or scene._typing_text.is_empty():
		printerr("LIVE_CARD_FOLLOWUP_FAILED: ", scene._error)
		quit(1)
		return
	scene._typing_visible = mini(10, scene._typing_text.length())
	panel._refresh_ai_history(true)
	assert(panel.ai_history.get_parsed_text().contains(scene._typing_text.left(scene._typing_visible)))
	for button in panel.ai_question_buttons:
		assert(scene._typing_text.contains(button.text))
		assert(button.text != "唐长安城为什么采用里坊制？")
		assert(button.text != "朱雀大街为什么这么宽？")
		for old_question in first_questions: assert(button.text != old_question.q)
	print("LIVE_CARD_RAG_PASS: FANG grid ID mapped; intro visible; direct button answer visible")
	scene.queue_free()
	await process_frame
	quit()
