extends Node
# 数据管理器（DataManager）——统一解析并缓存本地 JSON 数据。
# 图谱工程师/策划只需维护 data/ 目录，其他模块从这里读取，不直接碰文件。

var points: Array = []
var kepu_kb: Dictionary = {}
var codex_kb: Dictionary = {}
var timeline: Array = []
var llm_config: Dictionary = {}

const POINTS_PATH := "res://data/changan_points.json"
const KEPU_KB_PATH := "res://data/kepu_kb.json"
const CODEX_PATH := "res://data/codex_kb.json"
const HISTORY_PATH := "res://data/history_timeline.json"
const CONFIG_PATH := "res://config/llm_config.json"

func _ready() -> void:
	load_all()

func load_all() -> void:
	points = _load_array(POINTS_PATH, "points")
	kepu_kb = _load_dict(KEPU_KB_PATH)
	codex_kb = _load_dict(CODEX_PATH)
	timeline = _load_array(HISTORY_PATH, "timeline")
	llm_config = _load_llm_config()

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
