extends Node
# 全局事件总线（EventBus）——各模块之间只通过信号通信，互不直接引用节点路径。
# 用法：EventBus.xxx.connect(callback) / EventBus.xxx.emit(...)

# --- 视角 / 模式 ---
signal view_mode_changed(mode: String)  # "far" / "mid" / "near"

# --- 建筑与地图交互 ---
signal building_selected(building_id: String, data: Dictionary)
signal building_deselected()

# --- NPC 对话 ---
signal npc_dialogue_started(group_id: int)

# --- 环境系统 ---
signal time_of_day_changed(hour: float)
signal year_changed(year: int)

# --- 图鉴 ---
signal codex_entry_collected(category: String, keyword: String)
