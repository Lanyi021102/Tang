extends Node
# 数据管理器（DataManager）——统一解析并缓存本地 JSON 数据。
# 图谱工程师/策划只需维护 data/ 目录，其他模块从这里读取，不直接碰文件。

var points: Array = []
var kepu_kb: Dictionary = {}
var codex_kb: Dictionary = {}
var knowledge_cards: Array = []
var far_scale_cards: Array = []
var graph_entities: Array = []
var full_entities: Array = []
var spatial_info: Dictionary = {}
var timeline: Array = []
var llm_config: Dictionary = {}

const POINTS_PATH := "res://data/changan_points.json"
const KEPU_KB_PATH := "res://data/kepu_kb.json"
const CODEX_PATH := "res://data/codex_kb.json"
const KNOWLEDGE_CARDS_PATH := "res://data/knowledge_cards.json"
const HISTORY_PATH := "res://data/history_timeline.json"
const CONFIG_PATH := "res://config/llm_config.json"

func _ready() -> void:
	load_all()

func load_all() -> void:
	points = _load_array(POINTS_PATH, "points")
	far_scale_cards = _load_array("res://data/far_scale_cards.json", "cards")
	graph_entities = _load_array("res://data/graph_entity_index.json", "entities")
	full_entities = _load_array("res://data/generated/entities.json", "entities")
	kepu_kb = _load_dict(KEPU_KB_PATH)
	codex_kb = _load_dict(CODEX_PATH)
	timeline = _load_array(HISTORY_PATH, "timeline")
	llm_config = _load_llm_config()
	var kc_data := _load_dict(KNOWLEDGE_CARDS_PATH)
	if kc_data.has("cards"):
		knowledge_cards = kc_data["cards"]
	if kc_data.has("spatial_info"):
		spatial_info = kc_data["spatial_info"]

func card_entity(selected: Dictionary) -> Dictionary:
	var identity: Dictionary = preload("res://autoload/GraphClient.gd").resolve_entity(selected, graph_entities)
	if identity.is_empty(): return {}
	for entity in full_entities:
		if str(entity.get("key", "")) == str(identity.get("key", "")): return entity
	return {}

func entity_names(value: Variant) -> String:
	var keys: Array = value if value is Array else Array(str(value).replace("；", ";").split(";"))
	var names := PackedStringArray()
	for key in keys:
		for entity in full_entities:
			if str(entity.get("key", "")) == str(key).strip_edges():
				names.append(str(entity.get("name", "")))
				break
	return "、".join(names)

func card_rows(entity: Dictionary) -> Array:
	var props: Dictionary = entity.get("properties", {})
	var rows: Array = []
	var kind := str(entity.get("type", ""))
	if kind == "Fang":
		rows.append(["所属区域", str(props.get("area", ""))])
		var start := str(entity.get("period_start", ""))
		var finish := str(entity.get("period_end", ""))
		rows.append(["存在时期", start + ("—" + finish if finish != "" and finish != start else "")])
		rows.append(["主要功能", str(props.get("primary_function", ""))])
		rows.append(["次要功能", str(props.get("secondary_functions", "")).replace(";", "、")])
		rows.append(["功能依据", str(props.get("function_basis", ""))])
		rows.append(["邻近道路", entity_names(props.get("nearby_road_keys", ""))])
		rows.append(["邻近水渠", entity_names(props.get("nearby_canal_keys", ""))])
	elif kind == "Road":
		rows.append(["道路等级", str(props.get("road_level", ""))])
		rows.append(["道路类型", str(props.get("road_type", ""))])
		rows.append(["走向", str(props.get("direction", ""))])
		rows.append(["位置范围", str(entity.get("location", ""))])
		rows.append(["起点", entity_names(props.get("start_entity_key", ""))])
		rows.append(["终点", entity_names(props.get("end_entity_key", ""))])
		if props.get("original_width_value") != null:
			var width_value := str(props.original_width_value)
			if str(props.original_width_value).is_valid_float() and float(props.original_width_value) == floorf(float(props.original_width_value)):
				width_value = str(int(props.original_width_value))
			rows.append(["原文路宽", width_value + str(props.get("original_width_unit", ""))])
		if props.get("normalized_width_m") != null:
			rows.append(["换算路宽", str(props.normalized_width_m) + "米（换算值）"])
		rows.append(["换算依据", str(props.get("conversion_basis", ""))])
		rows.append(["连接城门", entity_names(props.get("connected_gate_keys", ""))])
		rows.append(["沿线坊区", entity_names(props.get("passing_fang_keys", ""))])
		rows.append(["功能说明", str(entity.get("description", ""))])
	return rows.filter(func(row): return str(row[1]).strip_edges() != "" and str(row[1]) != "<null>")

func _load_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		return parsed
	return {}

func _load_array(path: String, key: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var txt := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary and parsed.has(key):
		return parsed[key]
	return []

func _load_llm_config() -> Dictionary:
	var cfg := {
		"api_base_url": "https://api.deepseek.com/v1",
		"api_key": "",
		"model": "deepseek-v4-flash",
		"timeout_seconds": 30,
		"system_prompt": "你是唐长安城知识图谱的科普讲解员，严格基于用户提供的知识库字段作答。首次收到条目时写一段120—160字的通俗中文介绍，并在介绍末尾用『——据《来源》』格式注明出处；后续收到玩家追问时直接回答该问题。始终区分史料记载与学者推测，不编造知识库之外的事实。",
	}
	var file_cfg := _load_dict(CONFIG_PATH)
	for k in file_cfg:
		cfg[k] = file_cfg[k]
	var env_key := OS.get_environment("LLM_API_KEY")
	if env_key != "":
		cfg["api_key"] = env_key
	var env_url := OS.get_environment("LLM_API_BASE_URL")
	if env_url != "":
		cfg["api_base_url"] = env_url
	return cfg
