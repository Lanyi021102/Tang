# LLM 与 RAG 接口说明

## 兼容接口

旧场景默认通过后端的 `/api/v1/ai/game-completions` 代理访问模型。Godot 只保存
`rag_api_key`，百炼 API Key 仅保存在后端 `.env`。

现有场景可以继续调用：

```gdscript
NetworkManager.request_chat(messages, 0.7, 500)
```

并监听：

```gdscript
NetworkManager.chat_response.connect(_on_chat_response)
```

该接口用于兼容当前主场景。新功能应使用带 `request_id` 的接口，避免不同业务的响应串线。

## 带请求编号的 LLM 接口

```gdscript
var error := NetworkManager.request_chat_with_id(
    "building:TC-FANG-0001",
    messages,
    {"temperature": 0.3, "max_tokens": 500}
)
```

成功信号：

```gdscript
signal chat_completed(request_id: String, content: String, metadata: Dictionary)
```

失败信号：

```gdscript
signal chat_failed(request_id: String, error: Dictionary)
```

同一时间只执行一个 HTTP 请求。已有请求时返回 `ERR_BUSY`，调用方应等待、取消旧请求或稍后重试。

## RAG 请求

Godot 调用：

```gdscript
NetworkManager.request_rag(
    "rag:TC-FANG-0001",
    "兴道坊附近有哪些重要建筑？",
    "TC-FANG-0001",
    {"top_k": 5, "temperature": 0.3, "max_tokens": 500}
)
```

后端协议：

本地 Docker Compose 默认通过 http://127.0.0.1:8080 对外提供服务。

```http
POST /api/v1/ai/game-chat
Content-Type: application/json
X-Game-Api-Key: <开发环境可留空；生产环境必填>
```

```json
{
  "query": "兴道坊附近有哪些重要建筑？",
  "point_id": "TC-FANG-0001",
  "session_id": "godot-default",
  "top_k": 5,
  "temperature": 0.3,
  "max_tokens": 500
}
```

成功响应：

```json
{
  "answer": "……",
  "sources": [
    {
      "title": "《唐两京城坊考》",
      "chunk": "……",
      "score": 0.91
    }
  ],
  "usage": {
    "prompt_tokens": 1000,
    "completion_tokens": 180
  }
}
```

`sources`、`usage`、会话编号、关联实体和可信度字段都会放入 `chat_completed` 的 `metadata`。

后端用 `point_id` 查询已发布实体；若业务编号不存在则返回 HTTP 404。`session_id` 用于稳定区分游戏访客。


## 错误对象

```json
{
  "request_id": "rag:TC-FANG-0001",
  "code": "http_error",
  "message": "后端返回的错误说明",
  "http_status": 500,
  "result": 0
}
```

常见 `code`：

- `busy`
- `missing_api_key`
- `missing_base_url`
- `network_error`
- `http_error`
- `invalid_json`
- `empty_response`
- `cancelled`

## 配置

复制 `config/llm_config.json.example` 为不入库的 `config/llm_config.json`，再填写密钥和服务地址。支持配置：

- `api_base_url`、`chat_path`、`api_key`、`model`
- `timeout_seconds`、`temperature`、`max_tokens`
- `rag_base_url`、`rag_path`、`rag_api_key`、`rag_session_id`、`rag_top_k`

后端对应环境变量为 `GAME_API_KEY`。开发环境两端都可暂留空；生产环境后端会拒绝空密钥。客户端内共享密钥仅适合演示部署，正式公网部署应使用短期凭证。

日志只记录请求编号、类型、耗时、HTTP状态和 token usage，不输出API Key。

## 主程后续接入

当前主场景仍使用兼容信号。主程迁移时，应为建筑介绍、玩家追问和NPC群聊分别生成不同的 `request_id`，并按编号处理 `chat_completed/chat_failed`，这样才能彻底避免业务状态串线。
