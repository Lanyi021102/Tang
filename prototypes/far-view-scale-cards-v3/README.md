# 远景极简尺度卡片 V3

打开 `index.html` 可浏览唐长安城全部 108 坊与 40 条道路的极简尺度卡片。

- 坊尺度来自联合总表 `坊功能表` 的东西宽度与南北深度字段；
- 道路宽度来自 `道路分级表`，有史料原始尺度时保留原单位，其余显示米制宽度；
- 表内没有宽度记录的道路明确显示“尺度暂无”，不生成推测值；
- 使用顶部按钮可筛选全部、里坊或道路。

## Godot 接入

远景点击坊或道路显示同源 V3 极简尺度卡片；中景、近景及图鉴保留原卡片。
Godot 通过 `DataManager` 加载 `data/far_scale_cards.json`，优先按实体编号匹配，地图合成实体按名称匹配。
未匹配尺度时显示“尺度暂无”，不从地图绘制尺寸推算。

更新网页数据后运行 `python tools/sync_far_scale_cards.py` 同步游戏 JSON。
可运行 `godot --headless --path . --script tools/test_far_scale_cards.gd` 检查数据与视角分流（测试禁用 API 调用）。

重新导出数据：

```powershell
python tools/export_far_view_scale_cards.py <联合总表.xlsx> prototypes/far-view-scale-cards-v3/cards-data.js
```
