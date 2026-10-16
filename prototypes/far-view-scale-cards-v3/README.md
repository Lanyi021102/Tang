# 远景极简尺度卡片 V3

打开 `index.html` 可浏览唐长安城全部 108 坊与 40 条道路的极简尺度卡片。

- 坊尺度来自联合总表 `坊功能表` 的东西宽度与南北深度字段；
- 道路宽度来自 `道路分级表`，有史料原始尺度时保留原单位，其余显示米制宽度；
- 表内没有宽度记录的道路明确显示“尺度暂无”，不生成推测值；
- 使用顶部按钮可筛选全部、里坊或道路。

重新导出数据：

```powershell
python tools/export_far_view_scale_cards.py <联合总表.xlsx> prototypes/far-view-scale-cards-v3/cards-data.js
```
