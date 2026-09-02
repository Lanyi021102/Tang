extends Node
# 网络管理器（NetworkManager）——统一封装 LLM 与 RAG HTTP 请求。
# 旧场景可继续监听 chat_response；新调用应使用带 request_id 的信号。

signal chat_response(content: String, error: String)
signal chat_completed(request_id: String, content: String, metadata: Dictionary)
signal chat_failed(request_id: String, error: Dictionary)
signal request_state_changed(request_id: String, is_running: bool)

const DEFAULT_CHAT_PATH := "/chat/completions"
const DEFAULT_RAG_PATH := "/api/v1/ai/game-chat"
const MAX_ERROR_BODY_LENGTH := 1000

var _http: HTTPRequest
var _active_request_id := ""
var _active_kind := ""
var _active_started_msec := 0
var _active_legacy_signal := false
var _request_sequence := 0


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_apply_timeout()


func has_api_key() -> bool:
	if _uses_backend_chat():
		return _has_rag_access()
	return not _is_placeholder_key(String(DataManager.llm_config.get("api_key", "")))


func is_requesting() -> bool:
	return _active_request_id != ""


func active_request_id() -> String:
	return _active_request_id


# 兼容旧场景。返回值可用于立即识别 ERR_BUSY、未配置等启动错误。
func request_chat(messages: Array, temperature: float = 0.7, max_tokens: int = 500) -> Error:
	return _request_chat_internal(
		_next_request_id("chat"),
		messages,
		{"temperature": temperature, "max_tokens": max_tokens},
		true
	)


# 新接口：调用方提供稳定 request_id，并监听 chat_completed/chat_failed。
func request_chat_with_id(request_id: String, messages: Array, options: Dictionary = {}) -> Error:
	return _request_chat_internal(request_id, messages, options, false)


func request_rag(
	request_id: String,
	query: String,
	point_id: String = "",
	options: Dictionary = {}
) -> Error:
	var clean_id := request_id.strip_edges()
	if clean_id == "":
		return _reject_request(request_id, "invalid_request_id", "request_id 不能为空", ERR_INVALID_PARAMETER, false)
	if query.strip_edges() == "":
		return _reject_request(clean_id, "invalid_query", "RAG query 不能为空", ERR_INVALID_PARAMETER, false)
	if is_requesting():
		return _reject_request(clean_id, "busy", "已有请求正在进行：%s" % _active_request_id, ERR_BUSY, false)

	var cfg := DataManager.llm_config
	var base := String(cfg.get("rag_base_url", cfg.get("api_base_url", ""))).strip_edges()
	if base == "":
		return _reject_request(clean_id, "missing_base_url", "未配置 RAG 服务地址", ERR_INVALID_PARAMETER, false)

	var body := {
		"query": query.strip_edges(),
		"point_id": point_id.strip_edges(),
		"session_id": String(options.get("session_id", cfg.get("rag_session_id", "godot-default"))),
		"top_k": int(options.get("top_k", cfg.get("rag_top_k", 5))),
		"temperature": float(options.get("temperature", cfg.get("temperature", 0.3))),
		"max_tokens": int(options.get("max_tokens", cfg.get("max_tokens", 500))),
	}
	if body["point_id"] == "":
		body.erase("point_id")
	var endpoint := _join_url(base, String(cfg.get("rag_path", DEFAULT_RAG_PATH)))
	return _begin_request(clean_id, "rag", endpoint, body, _build_headers(true), false)


func cancel_request(request_id: String = "") -> bool:
	if not is_requesting():
		return false
	if request_id != "" and request_id != _active_request_id:
		return false
	var cancelled_id := _active_request_id
	var emit_legacy := _active_legacy_signal
	_http.cancel_request()
	_clear_active_request()
	var error := _error_payload(cancelled_id, "cancelled", "请求已取消", 0, 0)
	chat_failed.emit(cancelled_id, error)
	if emit_legacy:
		chat_response.emit("", String(error["message"]))
	return true


func _request_chat_internal(
	request_id: String,
	messages: Array,
	options: Dictionary,
	emit_legacy: bool
) -> Error:
	var clean_id := request_id.strip_edges()
	if clean_id == "":
		return _reject_request(request_id, "invalid_request_id", "request_id 不能为空", ERR_INVALID_PARAMETER, emit_legacy)
	if messages.is_empty():
		return _reject_request(clean_id, "invalid_messages", "messages 不能为空", ERR_INVALID_PARAMETER, emit_legacy)
	if is_requesting():
		return _reject_request(clean_id, "busy", "已有请求正在进行：%s" % _active_request_id, ERR_BUSY, emit_legacy)

	var cfg := DataManager.llm_config
	var via_backend := _uses_backend_chat()
	var base := String(
		cfg.get("rag_base_url", "") if via_backend else cfg.get("api_base_url", "")
	).strip_edges()
	var key := String(
		cfg.get("rag_api_key", "") if via_backend else cfg.get("api_key", "")
	).strip_edges()
	if base == "":
		return _reject_request(clean_id, "missing_base_url", "未配置 LLM API 地址", ERR_INVALID_PARAMETER, emit_legacy)
	if _is_placeholder_key(key):
		return _reject_request(clean_id, "missing_api_key", "未配置有效的 API Key", ERR_UNAUTHORIZED, emit_legacy)

	var body := {
		"model": options.get("model", cfg.get("model", "deepseek-v4-flash")),
		"messages": messages,
		"temperature": float(options.get("temperature", cfg.get("temperature", 0.7))),
		"max_tokens": int(options.get("max_tokens", cfg.get("max_tokens", 500))),
	}
	var path := String(
		cfg.get("backend_chat_path", "/api/v1/ai/game-completions")
		if via_backend
		else cfg.get("chat_path", DEFAULT_CHAT_PATH)
	)
	var endpoint := _join_url(base, path)
	return _begin_request(clean_id, "chat", endpoint, body, _build_headers(via_backend), emit_legacy)


func _begin_request(
	request_id: String,
	kind: String,
	endpoint: String,
	body: Dictionary,
	headers: PackedStringArray,
	emit_legacy: bool
) -> Error:
	_apply_timeout()
	_active_request_id = request_id
	_active_kind = kind
	_active_started_msec = Time.get_ticks_msec()
	_active_legacy_signal = emit_legacy
	request_state_changed.emit(request_id, true)
	var request_error := _http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if request_error != OK:
		var payload := _error_payload(request_id, "request_start_failed", "请求启动失败（code %d）" % request_error, 0, request_error)
		_clear_active_request()
		chat_failed.emit(request_id, payload)
		if emit_legacy:
			chat_response.emit("", String(payload["message"]))
		return request_error
	print("NetworkManager: request=%s kind=%s started" % [request_id, kind])
	return OK


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if not is_requesting():
		return
	var request_id := _active_request_id
	var kind := _active_kind
	var emit_legacy := _active_legacy_signal
	var elapsed_ms := Time.get_ticks_msec() - _active_started_msec
	var response_text := body.get_string_from_utf8()
	_clear_active_request()

	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_failure(request_id, "network_error", "网络错误（%d）" % result, response_code, result, response_text, emit_legacy)
		return
	if response_code < 200 or response_code >= 300:
		var api_message := _extract_error_message(response_text)
		if api_message == "":
			api_message = "API 返回 HTTP %d" % response_code
		_emit_failure(request_id, "http_error", api_message, response_code, result, response_text, emit_legacy)
		return

	var parser := JSON.new()
	var parse_error := parser.parse(response_text)
	if parse_error != OK or not parser.data is Dictionary:
		_emit_failure(request_id, "invalid_json", "响应 JSON 解析失败：%s" % parser.get_error_message(), response_code, parse_error, response_text, emit_legacy)
		return
	var parsed: Dictionary = parser.data
	var extracted := _extract_success(kind, parsed)
	var content := String(extracted.get("content", "")).strip_edges()
	if content == "":
		_emit_failure(request_id, "empty_response", String(extracted.get("error", "API 回答为空")), response_code, OK, response_text, emit_legacy)
		return

	var metadata: Dictionary = extracted.get("metadata", {})
	metadata["request_id"] = request_id
	metadata["kind"] = kind
	metadata["http_status"] = response_code
	metadata["elapsed_ms"] = elapsed_ms
	chat_completed.emit(request_id, content, metadata)
	if emit_legacy:
		chat_response.emit(content, "")
	var usage: Dictionary = metadata.get("usage", {})
	print("NetworkManager: request=%s status=%d elapsed_ms=%d usage=%s" % [request_id, response_code, elapsed_ms, JSON.stringify(usage)])


func _extract_success(kind: String, parsed: Dictionary) -> Dictionary:
	if kind == "rag":
		return {
			"content": String(parsed.get("answer", "")),
			"error": "RAG 响应缺少 answer",
			"metadata": {
				"sources": parsed.get("sources", []),
				"usage": parsed.get("usage", {}),
				"conversation_id": parsed.get("conversation_id", ""),
				"message_id": parsed.get("message_id", ""),
				"linked_entities": parsed.get("linked_entities", []),
				"suggested_questions": parsed.get("suggested_questions", []),
				"confidence": parsed.get("confidence", ""),
				"insufficient_evidence": parsed.get("insufficient_evidence", false),
				"model": parsed.get("model", ""),
			},
		}
	var choices: Variant = parsed.get("choices", [])
	if not choices is Array or choices.is_empty():
		return {"content": "", "error": "API 响应缺少 choices", "metadata": {}}
	var first: Variant = choices[0]
	if not first is Dictionary:
		return {"content": "", "error": "API choices 格式错误", "metadata": {}}
	var message: Variant = first.get("message", {})
	if not message is Dictionary:
		return {"content": "", "error": "API message 格式错误", "metadata": {}}
	return {
		"content": String(message.get("content", "")),
		"metadata": {
			"usage": parsed.get("usage", {}),
			"model": parsed.get("model", ""),
			"finish_reason": first.get("finish_reason", ""),
		},
	}


func _emit_failure(
	request_id: String,
	code: String,
	message: String,
	http_status: int,
	result: int,
	response_text: String,
	emit_legacy: bool
) -> void:
	var payload := _error_payload(request_id, code, message, http_status, result)
	if response_text != "":
		payload["response_body"] = response_text.left(MAX_ERROR_BODY_LENGTH)
	chat_failed.emit(request_id, payload)
	if emit_legacy:
		chat_response.emit("", message)
	print("NetworkManager: request=%s failed code=%s http=%d" % [request_id, code, http_status])


func _reject_request(
	request_id: String,
	code: String,
	message: String,
	error_code: Error,
	emit_legacy: bool
) -> Error:
	var payload := _error_payload(request_id, code, message, 0, error_code)
	chat_failed.emit(request_id, payload)
	if emit_legacy:
		chat_response.emit("", message)
	return error_code


func _error_payload(request_id: String, code: String, message: String, http_status: int, result: int) -> Dictionary:
	return {
		"request_id": request_id,
		"code": code,
		"message": message,
		"http_status": http_status,
		"result": result,
	}


func _extract_error_message(response_text: String) -> String:
	var parsed: Variant = JSON.parse_string(response_text)
	if not parsed is Dictionary:
		return ""
	var error: Variant = parsed.get("error", {})
	if error is Dictionary:
		return String(error.get("message", ""))
	if error is String:
		return error
	return String(parsed.get("message", ""))


func _build_headers(for_rag: bool) -> PackedStringArray:
	var cfg := DataManager.llm_config
	var headers := PackedStringArray(["Content-Type: application/json"])
	var key := String(cfg.get("rag_api_key", cfg.get("api_key", "")) if for_rag else cfg.get("api_key", "")).strip_edges()
	if not _is_placeholder_key(key):
		headers.append(("X-Game-Api-Key: " if for_rag else "Authorization: Bearer ") + key)
	return headers


func _uses_backend_chat() -> bool:
	return bool(DataManager.llm_config.get("chat_via_backend", false))


func _has_rag_access() -> bool:
	var cfg := DataManager.llm_config
	var base := String(cfg.get("rag_base_url", "")).strip_edges()
	var key := String(cfg.get("rag_api_key", "")).strip_edges()
	return base != "" and not _is_placeholder_key(key)


func _apply_timeout() -> void:
	if _http == null:
		return
	var timeout := float(DataManager.llm_config.get("timeout_seconds", 30.0))
	_http.timeout = maxf(timeout, 1.0)


func _join_url(base: String, path: String) -> String:
	var clean_base := base.rstrip("/")
	var clean_path := path.strip_edges()
	if clean_path == "":
		clean_path = DEFAULT_CHAT_PATH
	if not clean_path.begins_with("/"):
		clean_path = "/" + clean_path
	return clean_base + clean_path


func _is_placeholder_key(value: String) -> bool:
	var key := value.strip_edges()
	if key == "":
		return true
	var upper := key.to_upper()
	return key.contains("在此填写") or upper.contains("YOUR_API_KEY") or upper == "API_KEY"


func _next_request_id(prefix: String) -> String:
	_request_sequence += 1
	return "%s-%d-%d" % [prefix, Time.get_ticks_msec(), _request_sequence]


func _clear_active_request() -> void:
	var finished_id := _active_request_id
	_active_request_id = ""
	_active_kind = ""
	_active_started_msec = 0
	_active_legacy_signal = false
	if finished_id != "":
		request_state_changed.emit(finished_id, false)
