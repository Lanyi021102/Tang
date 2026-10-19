extends Node
# Public, read-only graph endpoints; independent from the LLM request channel.
var base_url := "http://127.0.0.1:8080"
var timeout_seconds := 12.0
var pending: Array[HTTPRequest] = []

func cancel_all() -> void:
	# Finish coroutines as well as cancelling sockets.
	for req in pending.duplicate():
		req.cancel_request()
		req.request_completed.emit(HTTPRequest.RESULT_REQUEST_FAILED, 0, PackedStringArray(), PackedByteArray())

func request_json(path: String, payload: Variant = null) -> Dictionary:
	if not (base_url.begins_with("http://") or base_url.begins_with("https://")):
		return {"ok": false, "error": "图谱服务地址无效"}
	var req := HTTPRequest.new()
	req.timeout = timeout_seconds
	add_child(req)
	pending.append(req)
	var method := HTTPClient.METHOD_GET if payload == null else HTTPClient.METHOD_POST
	var body := "" if payload == null else JSON.stringify(payload)
	var err := req.request(base_url.trim_suffix("/") + path, ["Content-Type: application/json"], method, body)
	if err != OK:
		pending.erase(req)
		req.queue_free()
		return {"ok": false, "error": "无法启动图谱查询（%d）" % err}
	var response: Array = await req.request_completed
	pending.erase(req)
	req.queue_free()
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "error": "图谱服务不可达或请求超时；请启动知识图谱后端。"}
	var code := int(response[1])
	if code != 200:
		return {"ok": false, "error": "图谱接口 HTTP %d；请核对实体是否已导入、审核并发布。" % code}
	var parser := JSON.new()
	if parser.parse(response[3].get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"ok": false, "error": "图谱接口返回了无效 JSON"}
	return {"ok": true, "data": parser.data}

static func resolve_entity(entity: Dictionary, index: Array) -> Dictionary:
	var key := str(entity.get("entity_id", entity.get("key", entity.get("id", ""))))
	for item in index:
		if key != "" and (key == str(item.key) or key == str(item.id)):
			return item
	var name := str(entity.get("name", "")).strip_edges()
	var kind := str(entity.get("type", ""))
	if key.begins_with("FANG-") or kind == "坊": kind = "Fang"
	if key.begins_with("STREET-") or kind == "街道": kind = "Road"
	var matches: Array = []
	for item in index:
		if name != "" and str(item.name) == name and (kind == "" or str(item.type) == kind):
			matches.append(item)
	# Ambiguity must be resolved by stable ID, not by taking the first result.
	return matches[0] if matches.size() == 1 else {}
