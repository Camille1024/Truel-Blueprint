# LeanArchitect Blueprint 项目搭建指南

> 本文档记录了 Truel-Blueprint 项目从零搭建到 GitHub Pages 部署的完整流程，以及遇到的所有 CI 问题和修复方案。适用于任何基于 LeanArchitect + leanblueprint 的 Lean 4 项目。

## 一、整体架构

```
Lean 源码 (.lean)
  │  @[blueprint] 标注（由 LeanArchitect 提供）
  ▼
LeanArchitect (lake build :blueprint)
  │  提取 LaTeX 片段 (.tex) + JSON 依赖数据
  │  输出到 .lake/build/blueprint/
  ▼
blueprint/src/content.tex
  │  通过 \input 引用 LeanArchitect 的提取结果
  ▼
leanblueprint web
  │  plasTeX 渲染引擎，生成 HTML 网站
  ▼
blueprint/web/          ← 可浏览的静态网站
  ├── index.html        ← 首页
  ├── sect0001.html     ← 正文（定义/定理卡片）
  └── dep_graph_document.html  ← 可交互的依赖图
```

### 两个工具的分工

| 工具 | 类型 | 作用 | 输入 | 输出 |
|------|------|------|------|------|
| **LeanArchitect** | Lean 4 包（Lake 依赖） | 从 Lean 源码提取 blueprint 数据 | `@[blueprint]` 标注 | `.tex` 节点文件 + `.json` |
| **leanblueprint** | Python 包（pip 安装） | 将 LaTeX 渲染成网站/PDF | `blueprint/src/` + 提取的 `.tex` | `blueprint/web/` HTML 网站 |

## 二、项目文件结构

对标 [LeanArchitect-example](https://github.com/hanwenzhu/LeanArchitect-example)，一个完整项目需要以下文件：

```
项目根目录/
├── .github/workflows/blueprint.yml   ← CI: 编译 + 部署 GitHub Pages
├── .gitignore
├── README.md
├── YourProject.lean                   ← Lean 源码 + @[blueprint] 标注
├── lakefile.toml                      ← 项目配置（必须用 .toml 格式！）
├── lean-toolchain                     ← Lean 版本锁定
├── lake-manifest.json                 ← 依赖版本锁定
├── blueprint/src/                     ← blueprint 模板源文件
│   ├── content.tex                    ← 内容入口
│   ├── web.tex                        ← 网页版主文档
│   ├── print.tex                      ← PDF 版主文档
│   ├── plastex.cfg                    ← plasTeX 配置
│   ├── blueprint.sty                  ← LaTeX 占位包（2行）
│   ├── latexmkrc                      ← latexmk 编译配置
│   ├── extra_styles.css               ← 自定义样式
│   └── macros/
│       ├── common.tex                 ← 通用 LaTeX 宏（theorem 环境等）
│       ├── web.tex                    ← 网页版专用宏（通常为空）
│       └── print.tex                  ← PDF版宏（含 \lean 等占位定义！）
└── home_page/                         ← Jekyll 首页（GitHub Pages 入口）
    ├── _config.yml
    └── index.md
```

## 三、搭建步骤

### Step 1: Lean 源码标注

在 `.lean` 文件顶部添加 `import Architect`，给关键声明打 `@[blueprint]` 标注：

```lean
import Architect

-- 定义：自动识别为 definition 环境
@[blueprint "def:my-definition"
  (statement := /-- 人类可读的描述，支持 $LaTeX$ 公式。 -/)]
def myDef : ... := ...

-- 定理：自动识别为 theorem 环境
@[blueprint
  (statement := /-- 定理的描述。 -/)
  (uses := [myDef])]  -- 手动声明依赖（unfold/norm_num 证明必须手动声明）
theorem myThm : ... := by ...
```

**关键点：**
- `statement` 参数提供网页上显示的描述文字，**每个节点都应该有**
- `uses` 参数声明依赖关系，LeanArchitect 会自动推断，但 `unfold` + `norm_num` 类证明**必须手动声明**
- 无 `sorry` 的声明自动标记为 `\leanok`（网页上显示 ✓）

### Step 2: lakefile.toml 配置

```toml
name = "YourProject"
defaultTargets = ["YourProject"]

[[require]]
name = "LeanArchitect"
git = "https://github.com/hanwenzhu/LeanArchitect.git"
rev = "main"

[[require]]
name = "checkdecls"
scope = "PatrickMassot"

# 如果需要 mathlib：
[[require]]
name = "mathlib"
git = "https://github.com/leanprover-community/mathlib4.git"
rev = "v4.30.0-rc1"

[[lean_lib]]
name = "YourProject"
```

### Step 3: blueprint/src/ 模板文件

#### content.tex
```latex
\input{../../.lake/build/blueprint/library/YourProject}
\chapter{章节名}
\inputleanmodule{YourProject}
```

#### web.tex
```latex
\documentclass{report}
\usepackage{amssymb, amsthm, amsmath}
\usepackage{hyperref}
\usepackage[showmore, dep_graph]{blueprint}
\input{macros/common}
\input{macros/web}
\home{https://YOUR_USERNAME.github.io/YOUR_REPO}
\github{https://github.com/YOUR_USERNAME/YOUR_REPO}
\title{项目标题}
\author{作者}
\begin{document}
\maketitle
\input{content}
\end{document}
```

#### print.tex
```latex
\documentclass[a4paper]{report}
\usepackage{geometry}
\usepackage{expl3}
\usepackage{amssymb, amsthm, mathtools}
\usepackage[unicode,colorlinks=true]{hyperref}
\input{macros/common}
\input{macros/print}
\title{项目标题}  % 注意：不要用中文！CI 环境没有 CJK 字体
\author{作者}
\begin{document}
\maketitle
\input{content}
\end{document}
```

#### blueprint.sty（2行占位文件，必须有）
```latex
\DeclareOption*{}
\ProcessOptions
```

#### latexmkrc
```
$pdf_mode = 1;
$pdflatex = 'xelatex -interaction=nonstopmode -synctex=1';
@default_files = ('print.tex');
```

#### macros/common.tex
```latex
\usepackage{cleveref}
\newtheorem{theorem}{Theorem}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{corollary}[theorem]{Corollary}
\theoremstyle{definition}
\newtheorem{definition}[theorem]{Definition}
```

#### macros/print.tex（关键！必须定义 leanblueprint 宏的占位版本）
```latex
\newcommand{\lean}[1]{}
\newcommand{\discussion}[1]{}
\newcommand{\leanok}{}
\newcommand{\mathlibok}{}
\newcommand{\notready}{}
\ExplSyntaxOn
\NewDocumentCommand{\uses}{m}
{\clist_map_inline:nn{#1}{\vphantom{\ref{##1}}}%
\ignorespaces}
\NewDocumentCommand{\proves}{m}
{\clist_map_inline:nn{#1}{\vphantom{\ref{##1}}}%
\ignorespaces}
\ExplSyntaxOff
```

#### macros/web.tex
（通常为空文件）

### Step 4: GitHub Actions workflow

```yaml
name: Compile blueprint

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  pages: write
  id-token: write
  issues: write
  pull-requests: write

jobs:
  build_project:
    runs-on: ubuntu-latest
    steps:
      - uses: jlumbroso/free-disk-space@54081f138730dfa15788a46383842cd2f914a1be
        with:
          tool-cache: false
          android: true
      - uses: actions/checkout@08c6903cd8c0fde910a37f88322edcfb5dd907a8
        with:
          fetch-depth: 0
      - uses: leanprover/lean-action@434f25c2f80ded67bba02502ad3a86f25db50709
        with:
          build: true
          build-args: :blueprint
      - uses: leanprover-community/docgen-action@deed0cdc44dd8e5de07a300773eb751d33e32fc8
        with:
          blueprint: true
          homepage: home_page
```

### Step 5: 本地验证

```bash
# 编译 Lean 项目
lake build

# 提取 blueprint 数据（LeanArchitect）
lake build :blueprint
lake build :blueprintJson

# leanblueprint 要求项目在 git 根目录
# 如果是 monorepo 子目录，需要临时 git init
git init && git add -A && git commit -m "temp"

# 生成网页（leanblueprint）
leanblueprint web

# 预览
python3 -m http.server 8080 --directory blueprint/web

# 清理临时 git
rm -rf .git
```

### Step 6: 推送并部署

```bash
# 创建 GitHub 仓库
gh repo create YOUR_USERNAME/YOUR_REPO --public

# 推送
git push -u origin main

# 启用 GitHub Pages（source: GitHub Actions）
gh api repos/YOUR_USERNAME/YOUR_REPO/pages -X POST -f "build_type=workflow"
```

## 四、CI 踩坑记录

以下是 Truel-Blueprint 部署过程中遇到的所有 CI 失败及修复方案：

### Bug 1: docgen-action 找不到 lakefile

**错误信息：**
```
Error parsing Lake package description: Could not find `lakefile.toml`.
```

**原因：** `leanprover-community/docgen-action` 只解析 `lakefile.toml` 格式，不支持 `lakefile.lean`。

**修复：** 将 `lakefile.lean` 转换为 `lakefile.toml` 格式。格式对应关系：

| lakefile.lean | lakefile.toml |
|--------------|---------------|
| `package «Truel»` | `name = "Truel"` |
| `require X from git "url" @ "rev"` | `[[require]]` + `name`/`git`/`rev` |
| `lean_lib «Truel»` | `[[lean_lib]]` + `name` |

### Bug 2: blueprint.sty 找不到

**错误信息：**
```
! LaTeX Error: File `blueprint.sty' not found.
```

**原因：** `web.tex` 中 `\usepackage[showmore, dep_graph]{blueprint}` 在 PDF 编译（latexmk）时需要一个 `blueprint.sty` 文件。但 `blueprint` 实际上是 leanblueprint 的 plasTeX 插件，不是标准 LaTeX 包。

**修复：** 创建 `blueprint/src/blueprint.sty` 占位文件（2行）：
```latex
\DeclareOption*{}
\ProcessOptions
```

### Bug 3: \lean 未定义

**错误信息：**
```
! Undefined control sequence.
l.3 \lean
         {Truel.duelFirstWins}
```

**原因：** LeanArchitect 生成的 `.tex` 文件包含 `\lean{}`、`\leanok`、`\uses{}` 等命令。这些是 leanblueprint plasTeX 插件定义的，标准 LaTeX 不认识。PDF 编译时（latexmk 调用 xelatex）会报错。

**修复：** 在 `blueprint/src/macros/print.tex` 中定义这些宏的占位版本：
```latex
\newcommand{\lean}[1]{}
\newcommand{\leanok}{}
\newcommand{\uses}{...}  % 用 expl3 实现
```

### Bug 4: 中文字体缺失

**错误信息：**
```
Missing character: There is no 三 (U+4E09) in font [lmroman17-regular]
```

**原因：** CI 环境（ubuntu-latest）没有 CJK 中文字体，Latin Modern 字体不支持中文。`content.tex` 和 `print.tex` 中的中文标题导致 PDF 编译失败。

**修复：** PDF 版本（`print.tex`、`content.tex`）中**不使用中文字符**。中文标题只放在 `web.tex` 中（plasTeX 支持 Unicode，不受字体限制）。

### Bug 5: checkdecls 可执行文件不存在

**错误信息：**
```
error: unknown executable checkdecls
```

**原因：** `docgen-action` 最后一步会运行 `lake exe checkdecls` 来验证 blueprint 中声明的 Lean 名称是否有效。需要在 lakefile 中添加 `checkdecls` 依赖。

**修复：** 在 `lakefile.toml` 中添加：
```toml
[[require]]
name = "checkdecls"
scope = "PatrickMassot"
```
同时在 `lake-manifest.json` 中添加对应条目（rev: `3d425859e73fcfbef85b9638c2a91708ef4a22d4`）。

## 五、CI 时间预估

| 项目类型 | 首次 CI | 后续 CI（有缓存） |
|---------|---------|------------------|
| 不依赖 mathlib | ~12 分钟 | ~5 分钟 |
| 依赖 mathlib | ~60-90 分钟 | ~15-25 分钟 |

慢的主要原因是 `docgen4`（API 文档生成）需要加载 mathlib 的所有声明。如果不需要 API 文档，可以在 workflow 中设置 `api-docs: false` 来跳过。

## 六、常见注意事项

1. **lakefile 必须用 .toml 格式** — docgen-action 不支持 .lean 格式
2. **blueprint.sty 占位文件不能少** — 虽然只有 2 行，但 PDF 编译依赖它
3. **macros/print.tex 必须定义所有 leanblueprint 宏** — `\lean`、`\leanok`、`\uses`、`\proves` 等
4. **PDF 版本不能有中文** — 除非配置 xeCJK + 安装中文字体
5. **checkdecls 依赖不能忘** — docgen-action 最后会跑 `lake exe checkdecls`
6. **leanblueprint 要求项目在 git 根目录** — monorepo 子目录需要临时 `git init`
7. **`uses` 参数对 unfold+norm_num 证明是必须的** — LeanArchitect 无法自动推断这类依赖
8. **home_page/ 目录必须有 Gemfile** — docgen-action 用 Jekyll 构建首页，需要 Gemfile 声明 `github-pages` gem 依赖

## 附录：CI Bug 完整时间线

| # | 错误 | 原因 | 修复 | CI 时间 |
|---|------|------|------|---------|
| 1 | `Could not find lakefile.toml` | docgen-action 只支持 .toml | 转换 lakefile.lean → lakefile.toml | 4min |
| 2 | `File blueprint.sty not found` | PDF 编译需要占位包 | 创建 2 行 blueprint.sty | 4min |
| 3 | `Undefined control sequence \lean` + CJK 缺字体 | print.tex 缺宏定义 + 中文字体 | macros/print.tex 加宏定义，去中文 | 5min |
| 4 | `unknown executable checkdecls` | 缺 checkdecls 依赖 | lakefile.toml + manifest 加 checkdecls | 被取消 |
| 5 | `Could not locate Gemfile` | Jekyll 构建主页需要 Gemfile | home_page/ 加 Gemfile | 2h5min |
