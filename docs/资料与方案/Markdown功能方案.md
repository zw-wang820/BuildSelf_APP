# Markdown 功能方案（方案 B：自研渲染器）

> 2026-09-12 确认通过。分支：`feature/markdown`（从 main `daea678` 切出）。

## 一、背景与目标

在所有涉及长文字编辑的场景（工作笔记、生活 moments、阅读笔记、目标描述、review 四象限、murmur）支持 Markdown 语法，让记录更结构化。

- 坚持零三方依赖：不引入 `markdown_widget` / `flutter_markdown` 等三方包
- Dart SDK 约束 `>=2.17.0 <3.0.0`：不支持 switch expressions / wildcard `_` patterns
- 数据库 schema **零迁移**：存原始 Markdown 字符串，存量纯文本天然兼容

## 二、渲染范围（V1 子集）

| 语法 | 支持 | 说明 |
|---|---|---|
| 标题 `#` ~ `######` | ✅ | 六级，字号递减 |
| 粗体 `**x**` / 斜体 `*x*` | ✅ | 行内解析 |
| 无序列表 `-` / `*` | ✅ | 支持嵌套一层（缩进 2 空格） |
| 有序列表 `1.` | ✅ | 保留原始序号 |
| 引用 `>` | ✅ | 左侧色条样式 |
| 行内代码 `` `x` `` | ✅ | 等宽字体 + 底色 |
| 代码块 ``` ``` ``` | ✅ | 无语法高亮 |
| 分隔线 `---` | ✅ | |
| 链接 `[t](url)` | ✅ V1 | 显示为文字+下划线，不做点击跳转 |
| 表格 / 图片 / 脚注 / 任务列表 | ❌ | non-goals，需要时再评估 |

## 三、组件设计

新增 2 个共享组件，位置 `lib/shared/widgets/`：

1. **`MarkdownText`** — 渲染组件（只读）。parser（`lib/core/utils/markdown_parser.dart`）输出 block 模型列表 → 映射为 Flutter Widget。列表页/详情页均可直接使用。
2. **`MarkdownEditor`** — 编辑组件。封装 TextField + 底部工具栏（**B** / *I* / H / 列表 / 引用 / 代码 / 预览切换），沿用项目双模式表单惯例：编辑模式 ↔ 预览模式 Tab 切换。

工具栏行为：在光标处包裹/插入对应语法（如选中文字点 B → `**选中**`），无选中则插入占位符。

## 四、分期接入

| 期 | 内容 | 状态 |
|---|---|---|
| Phase 1 | 核心组件（parser + MarkdownText + MarkdownEditor）+ 工作笔记接入 | 本期 |
| Phase 2 | 阅读笔记、目标描述 | 待开始 |
| Phase 3 | review 四象限、murmur、生活 moments | 待开始 |

接入原则：
- 只接**长文本内容字段**；标题/名称类字段不接
- 列表页摘要显示纯文本（剥离 `#`/`*`/`` ` `` 等符号），避免符号噪音

## 五、数据层

- 不改 schema，不写迁移脚本，原始字符串直存直取
- 旧数据（纯文本）= 不含语法标记的合法 Markdown，显示效果不变

## 六、门禁

每期：真机验证 → `dart analyze lib` 0 error / 0 new warning → `git status` 干净 → 等用户明确指令后 commit → commit 后校验 ref 落盘。
