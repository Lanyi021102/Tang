extends ScrollContainer

var host
var content: Control
var current_key := ""
var rows: Array = []

func _ready() -> void:
	position = Vector2(870, 272)
	size = Vector2(350, 335)
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content = Control.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.draw.connect(_draw_rows)
	add_child(content)
	visible = false

func _process(_delta: float) -> void:
	if host == null: return
	visible = host._panel_page == 2 and not host._selected.is_empty() and not host._far_card_open and not host._codex_open and not host._hist_open
	if not visible: return
	var entity: Dictionary = DataManager.card_entity(host._selected)
	visible = str(entity.get("type", "")) in ["Fang", "Road"]
	if not visible: return
	var next_key := str(entity.get("key", ""))
	if current_key == next_key: return
	current_key = next_key
	rows = DataManager.card_rows(entity)
	scroll_vertical = 0
	var height := 0.0
	for row in rows:
		var measured: Vector2 = host.font_hei.get_multiline_string_size(str(row[1]), HORIZONTAL_ALIGNMENT_LEFT, 270.0, 13, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
		height += maxf(measured.y, 17.0) + 14.0
	content.custom_minimum_size = Vector2(0, height + 8)
	content.queue_redraw()

func _draw_rows() -> void:
	if host == null: return
	var y := 0.0
	var width := 338.0
	for row in rows:
		content.draw_string(host.font_hei, Vector2(0, y + 14), str(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#98702f"))
		var value := str(row[1])
		var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND
		var measured: Vector2 = host.font_hei.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, width - 66, 13, -1, flags)
		content.draw_multiline_string(host.font_hei, Vector2(60, y + 14), value, HORIZONTAL_ALIGNMENT_LEFT, width - 66, 13, -1, Color("#dfc784"), flags)
		var height := maxf(measured.y, 17.0)
		content.draw_line(Vector2(0, y + height + 8), Vector2(width, y + height + 8), Color("#c99b45", 0.22), 1.0)
		y += height + 14
