extends Node
# 网络管理器（NetworkManager）——封装 LLM/后端 HTTP 请求。
# 游戏逻辑不关心网络细节，只调用 request_chat 并监听 chat_response 信号。

signal chat_response(content: String, error: String)

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func has_api_key() -> bool:
	return String(DataManager.llm_config.get("api_key", "")) != ""

func request_chat(messages: Array, temperature := 0.7, max_tokens := 500) -> void:
	var cfg := DataManager.llm_config
	var base: String = String(cfg.get("api_base_url", "")).rstrip("/")
	var key: String = String(cfg.get("api_key", ""))
	var body := {
		"model": cfg.get("model", "deepseek-v4-flash"),
		"messages": messages,
		"temperature": temperature,
		"max_tokens": max_tokens,
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + key,
	])
	var err := _http.request(base + "/chat/completions", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		chat_response.emit("", "请求失败（code %d）" % err)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		chat_response.emit("", "网络错误（%d）" % result)
		return
	if response_code != 200:
		chat_response.emit("", "API 返回 %d" % response_code)
		return
	var text := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	var content := ""
	if parsed is Dictionary:
		var choices: Array = parsed.get("choices", [])
		if choices.size() > 0:
			content = String(choices[0].get("message", {}).get("content", ""))
		else:
			var msg := String(parsed.get("error", {}).get("message", ""))
			chat_response.emit("", "API：%s" % msg)
			return
	chat_response.emit(content, "")
