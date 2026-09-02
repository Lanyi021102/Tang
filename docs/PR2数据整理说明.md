# PR2 数据整理说明

## 正式游戏数据

### `data/changan_points.json`

- 数据来源：`entities.json` 中 108 个 `Fang` 实体。
- 保留完整实体字段，包括 `properties`、`confidence`、`review_status`、`source_key`。
- 额外提供游戏兼容字段：`zone`、`source_ids`、`grid_x`、`grid_y`。
- 不保留旧版 36 个点位。

### `data/history_timeline.json`

- 数据来源：`entities.json` 中 29 个 `HistoricalEvent` 实体。
- 保留完整实体字段和大事记表字段。
- 额外提供游戏兼容字段：`id`、`year`、`title`、`desc`、`source_ids`、`related_point_ids`。
- 字段映射：`year_ce → year`、`event_name → title`、`summary → desc`。
- 不保留旧版 21 条时间轴。

### `data/research_claims.json`

- 数据来源：联合总表“研究结论表”。
- 共 97 条，`claim_key` 全部唯一且均为“审核通过”。
- 每条固定保留原表全部 18 个字段；空单元格写为 `null`。

## 暂时保留的旧知识库

- `data/kepu_kb.json`：26 条关键词科普文本。
- `data/codex_kb.json`：41 条分类图鉴条目。
- 联合总表中的“科普内容表”和“科普依据关联”当前没有记录，因此 PR2 不覆盖或伪造这两份旧知识库的来源字段。

## 完整图谱数据

`data/generated/` 保存完整实体、关系、来源、史料片段及校验结果。游戏兼容 JSON 是完整数据的派生视图，不应手工删减实体字段。

当前校验基线：1630 个实体（含 108 个坊、29 个历史事件和 38 条道路）、1950 条关系、108 个点位、29 条时间轴、97 条研究结论；无孤立关系、坏证据引用或坏来源引用。

## PR 提交范围

本 PR 只提交知识图谱工程师职责内的数据、转换工具和说明文档：

- `data/changan_points.json`
- `data/history_timeline.json`
- `data/research_claims.json`
- `data/generated/*.json`
- `tools/export_knowledge_graph.py`
- `docs/知识图谱字段说明.md`
- `docs/知识图谱导入说明.md`
- `docs/专题表字段补充说明.md`
- `docs/PR2数据整理说明.md`

明确不包含：

- `autoload/*.gd`
- `scenes/*`
- `addons/godot_mcp/*`
- `data/temporary_draft_check/*`
- `tools/__pycache__/*`
- 未发生变更的 `data/kepu_kb.json`、`data/codex_kb.json`

提交时应使用明确文件列表，不使用 `git add -A`。
