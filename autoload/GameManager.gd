extends Node
# 游戏管理器（GameManager）——全局状态（视角模式、年份、时间、图鉴收集进度）。
# 各模块通过它读写共享状态，并通过 EventBus 广播变化。

var view_mode := "mid"   # "far" / "mid" / "near"
var current_year := 740
var time_of_day := 10.0
var codex_collected: Dictionary = {}

func set_view_mode(mode: String) -> void:
	if mode == view_mode:
		return
	view_mode = mode
	EventBus.view_mode_changed.emit(mode)

func set_year(year: int) -> void:
	if year == current_year:
		return
	current_year = year
	EventBus.year_changed.emit(year)

func set_time(hour: float) -> void:
	time_of_day = hour
	EventBus.time_of_day_changed.emit(hour)
