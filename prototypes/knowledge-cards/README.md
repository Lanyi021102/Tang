# 长安城知识卡片设计原型

打开 `gallery.html` 可查看数据驱动的多实体知识卡片，支持城门、里坊、道路、水渠和建筑五类实体，并可点击卡片查看正反面。

## 文件结构

- `gallery.html`：多实体知识卡片页面；
- `cards-data.js`：卡片示例数据，后续可替换为知识卡片 API 返回值；
- `assets/`：卡片视觉素材。

## 本地预览

可直接用浏览器打开 `gallery.html`。如需通过本地 HTTP 服务预览，可在此目录运行：

```bash
python -m http.server 8000
```

然后访问 `http://localhost:8000/gallery.html`。

## 数据对接

- `entity_key` → 收藏编号；
- `name`、`entity_type`、`period` → 正面基本信息；
- `summary` → 正面一句话介绍；
- `relations` → 背面的知识关系；
- `evidence.original_text` → 史料原文；
- `evidence.source` → 来源信息。

视觉素材中的形制参考和场景示意不代表唐长安对应实体的直接复原证据，页面中已逐项标注。
