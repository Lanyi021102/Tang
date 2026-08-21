# Tang — 唐长安城知识图谱科普

基于 Godot 4.7 开发的唐长安城知识图谱科普项目。

- **引擎版本**：Godot 4.7 stable（标准版，非 .NET）
- **主场景**：`res://scenes/MainMenu.tscn`
- **渲染**：Mobile 渲染器，Jolt Physics

---

## 一、环境要求

| 工具 | 用途 | 下载 |
|------|------|------|
| Godot 4.7 | 游戏引擎 | https://godotengine.org/download |
| Git | 版本控制 | macOS 自带；Windows：https://git-scm.com |
| Node.js | （可选）AI 辅助开发用 | https://nodejs.org |

> ⚠️ 请务必安装 **4.7** 版本，版本不一致打开项目可能报兼容错误。

---

## 二、快速开始

### 1. 配置 SSH 密钥（首次使用）

```bash
ssh-keygen -t ed25519 -C "你的邮箱"   # 一路回车
cat ~/.ssh/id_ed25519.pub            # 复制输出内容
```

把公钥粘贴到 GitHub → **Settings → SSH and GPG keys → New SSH key**。

### 2. 克隆项目

```bash
git clone git@github.com:Lanyi021102/Tang.git
cd Tang
```

### 3. 打开项目

启动 Godot → **Import** → 选择项目文件夹中的 `project.godot`。

### 4. 配置 LLM 密钥（必做）

游戏运行时需要调用大模型，密钥不会提交到仓库：

```bash
cp config/llm_config.json.example config/llm_config.json
```

然后编辑 `config/llm_config.json`，把 `api_key` 替换成你自己的 Key。

---

## 三、可选：AI 辅助开发

本项目已集成 `godot_mcp` 插件，可用 AI 直接读写场景、脚本和节点。

1. Godot 中打开 `项目 → 项目设置 → 插件`，勾选 **Godot MCP Native**
2. 安装 AI 编码工具：

```bash
npm install -g opencode-ai
```

3. 在项目目录启动：

```bash
opencode
```

启动后 AI 会自动连接 Godot MCP，即可用自然语言修改项目。

---

## 四、协作规范（Feature Branch 工作流）

`main` 分支已开启保护，**不能直接推送**，必须通过 Pull Request 合并。

### 每次开发的流程

```bash
# 1. 开工前同步
git checkout main
git pull

# 2. 开自己的分支（按分工命名）
git checkout -b feature/你的功能

# 3. 开发、测试...

# 4. 提交并推送
git add -A
git commit -m "说明这次改了什么"
git push -u origin feature/你的功能
```

然后在 GitHub 发 **Pull Request**，经至少 **1 人批准** 后合并回 `main`。

### 分支命名规范

| 类型 | 前缀 | 示例 |
|------|------|------|
| 新功能 | `feature/` | `feature/玩家移动` |
| 修 Bug | `fix/` | `fix/存档读取` |
| 美术资源 | `art/` | `art/西市贴图` |
| 策划数据 | `data/` | `data/科普词条` |

### 关键约定

- **别直接 push `main`**（已受保护，推不上去）
- **别多人同时改同一个 `.tscn`**，场景按模块拆分
- 提交时**保留 `.uid` 文件**（脚本关联用）
- `.godot/` 和 `config/llm_config.json` 已被 gitignore，不会进仓库

---

## 五、目录结构

```
Tang/
├── assets/          # 图片、贴图、着色器
├── scenes/          # 场景（.tscn）与脚本（.gd）
├── data/            # 知识库数据（JSON）
├── config/          # 本地配置（密钥，不入库）
├── addons/          # 插件（godot_mcp）
└── project.godot    # 项目入口
```
