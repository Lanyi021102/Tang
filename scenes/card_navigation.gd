extends Control
# Real controls handle paging before the map's unhandled mouse input.
var host
var buttons: Array[Button] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	for i in range(4):
		var button := Button.new()
		button.text = ["概述", "详细信息", "空间图谱", "推理问答"][i]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.add_theme_font_size_override("font_size", 16)
		if host != null and host.font_hei: button.add_theme_font_override("font", host.font_hei)
		button.add_theme_color_override("font_color", Color("#e0ca8c"))
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#08291c") if state == "normal" else Color("#98702f")
			style.border_color = Color("#d2a13e")
			style.set_border_width_all(1)
			style.set_corner_radius_all(6)
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(func(): host.set_building_page(i + 1))
		add_child(button)
		buttons.append(button)

func _process(_delta: float) -> void:
	if host == null: return
	visible = not host._selected.is_empty() and not host._far_card_open and not host._codex_open and not host._hist_open and not host._clock_open
	for i in range(buttons.size()):
		var rect: Rect2 = host.building_page_rect(i)
		buttons[i].position = rect.position
		buttons[i].size = rect.size
		var style: StyleBoxFlat = buttons[i].get_theme_stylebox("normal")
		style.bg_color = Color("#98702f") if host._panel_page == i + 1 else Color("#08291c")
