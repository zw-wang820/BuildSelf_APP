# Buildself — Code Wiki 文档

> 本文档为 `buildself_app` 项目的完整结构化代码百科，涵盖架构设计、模块职责、核心类/函数说明、依赖关系及运行方式。

---

## 1. 项目概述

**Buildself** 是一款面向个人成长记录的跨平台移动应用，基于 **Flutter** 框架构建，支持 Android、iOS、Web、Windows、macOS、Linux 六大平台。

应用围绕「工作记录、生活记录、目标管理、阅读笔记、碎碎念」五大核心场景，帮助用户沉淀成长轨迹，形成可回顾、可统计的个人知识库。

| 属性 | 说明 |
|------|------|
| 项目名称 | buildself |
| 应用名称 | Buildself |
| 版本 | 1.0.0+1 |
| SDK 范围 | `>=2.17.0 <3.0.0` |
| 架构模式 | 分层架构（Layered Architecture）+ Repository 模式 |
| 状态管理 | Provider（ChangeNotifier） |
| 本地存储 | SQLite（sqflite）+ SharedPreferences |

---

## 2. 技术栈与依赖

### 2.1 核心框架

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter`（SDK）| 3.x | UI 框架 |
| `cupertino_icons` | ^1.0.2 | iOS 风格图标 |

### 2.2 数据库与存储

| 依赖 | 版本 | 用途 |
|------|------|------|
| `sqflite` | ^2.0.3 | SQLite 数据库访问 |
| `path` | ^1.8.1 | 路径拼接 |
| `path_provider` | ^2.0.14 | 获取系统文档目录 |
| `shared_preferences` | ^2.0.20 | 轻量键值存储（登录态、配置） |

### 2.3 状态管理与工具

| 依赖 | 版本 | 用途 |
|------|------|------|
| `provider` | ^6.0.5 | 跨组件状态共享 |
| `uuid` | ^3.0.7 | 生成全局唯一 ID |

### 2.4 开发依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter_test` | SDK | 单元/Widget 测试 |
| `flutter_lints` | ^2.0.0 | 静态代码检查 |

---

## 3. 项目架构

Buildself 采用**经典分层架构**，自上而下分为 **Presentation → Domain → Data** 三层，配合** Repository 模式**实现数据访问抽象。

```
┌─────────────────────────────────────────┐
│  Presentation Layer（表现层）            │
│  ├─ features/   — 页面（Screen）         │
│  ├─ shared/     — 共享布局与组件          │
│  └─ core/       — 主题、路由、常量        │
├─────────────────────────────────────────┤
│  Domain Layer（领域层）                  │
│  ├─ data/models/      — 实体模型         │
│  └─ data/repositories/— 业务仓库接口      │
├─────────────────────────────────────────┤
│  Data Layer（数据层）                    │
│  ├─ data/database/    — SQLite 实现      │
│  └─ providers/        — 全局状态          │
└─────────────────────────────────────────┘
```

### 3.1 架构原则

1. **单一职责**：每个 Screen 只负责一个业务场景；每个 Repository 只操作一种实体。
2. **数据向下流动**：UI → Provider → Repository → DatabaseProvider → SQLite。
3. **状态集中管理**：使用 `ChangeNotifier` + `Provider` 实现跨页面状态同步。
4. **软删除与回收站**：所有用户内容表均支持 `deleted_at` 软删除，并配备自动清理机制。

---

## 4. 目录结构

```
buildself/
├── android/                    # Android 原生工程
├── ios/                        # iOS 原生工程
├── linux/                      # Linux 原生工程
├── macos/                      # macOS 原生工程
├── windows/                    # Windows 原生工程
├── web/                        # Web 入口与 manifest
├── test/                       # 测试目录
│
├── lib/                        # Dart 业务代码
│   ├── main.dart               # 应用入口
│   │
│   ├── core/                   # 核心基础设施
│   │   ├── constants/          # 常量（颜色、字符串、配置）
│   │   ├── router/             # 路由定义与路由生成器
│   │   ├── theme/              # 亮色/暗色主题
│   │   └── utils/              # 通用工具类
│   │
│   ├── data/                   # 数据层
│   │   ├── database/           # 数据库连接与表结构
│   │   ├── models/             # 数据模型与枚举
│   │   └── repositories/       # 数据仓库（CRUD 封装）
│   │
│   ├── features/               # 业务功能模块（按领域划分）
│   │   ├── auth/               # 认证（登录、欢迎页）
│   │   ├── home/               # 首页（成长概览）
│   │   ├── work/               # 工作记录
│   │   ├── life/               # 生活记录
│   │   ├── goal/               # 目标管理
│   │   ├── reading/            # 阅读与书架
│   │   ├── murmur/             # 碎碎念
│   │   └── settings/           # 设置与关于
│   │
│   └── shared/                 # 共享资源
│       ├── layouts/            # 布局框架（MainScaffold）
│       └── widgets/            # 通用组件（卡片、空状态、心情选择器）
│
├── pubspec.yaml                # 依赖与资源声明
└── analysis_options.yaml       # 静态分析配置
```

---

## 5. 核心模块详解

### 5.1 入口与启动流程（`lib/main.dart`）

**类**：`BuildselfApp`（`StatefulWidget`）

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | `WidgetsFlutterBinding.ensureInitialized()` | 确保 Flutter 绑定初始化 |
| 2 | 设置系统 UI 样式 | 透明状态栏、仅竖屏 |
| 3 | 初始化数据库 | `DatabaseProvider.instance.database` |
| 4 | 清理过期回收站 | `purgeExpiredTrash()` |
| 5 | 恢复登录态 | `AppProvider.init()` |
| 6 | 构建 `MaterialApp` | 根据 `isLoggedIn` 决定展示 `WelcomeScreen` 或 `MainScaffold` |

### 5.2 路由系统（`lib/core/router/`）

#### 路由常量（`routes.dart`）

类 `AppRoutes` 集中定义所有命名路由，避免页面间硬编码字符串：

| 路由常量 | 路径 | 对应页面 |
|----------|------|----------|
| `welcome` | `/welcome` | `WelcomeScreen` |
| `login` | `/login` | `LoginScreen` |
| `main` | `/main` | `MainScaffold` |
| `workList` | `/work` | `WorkListScreen` |
| `workDetail` | `/work/detail` | `WorkDetailScreen` |
| `workEdit` | `/work/edit` | `WorkEditScreen` |
| `lifeList` | `/life` | `LifeListScreen` |
| `lifeEdit` | `/life/edit` | `LifeEditScreen` |
| `goalBoard` | `/goal` | `GoalBoardScreen` |
| `goalDetail` | `/goal/detail` | `GoalDetailScreen` |
| `goalEdit` | `/goal/edit` | `GoalEditScreen` |
| `achievementWall` | `/goal/achievements` | `AchievementWallScreen` |
| `bookshelf` | `/reading` | `BookshelfScreen` |
| `bookDetail` | `/reading/book` | `BookDetailScreen` |
| `bookAdd` | `/reading/book/add` | `BookAddScreen` |
| `noteEdit` | `/reading/note/edit` | `NoteEditScreen` |
| `murmur` | `/murmur` | `MurmurScreen` |
| `settings` | `/settings` | `SettingsScreen` |
| `about` | `/settings/about` | `AboutScreen` |

#### 路由生成器（`app_router.dart`）

类 `AppRouter` 提供 `onGenerateRoute` 静态方法，根据 `RouteSettings.name` 匹配对应页面，支持通过 `arguments` 传递参数（如 `noteId`、`WorkNote` 实例等）。

### 5.3 数据库层（`lib/data/database/`）

#### DatabaseProvider（`database_provider.dart`）

单例模式管理 SQLite 数据库连接，封装通用 CRUD 接口。

| 方法 | 签名 | 职责 |
|------|------|------|
| `instance` | 单例 getter | 全局唯一访问点 |
| `database` | `Future<Database>` | 延迟初始化并返回数据库实例 |
| `insert` | `Future<int>` | 插入单条记录 |
| `batchInsert` | `Future<void>` | 批量插入（事务内） |
| `queryOne` | `Future<Map?>` | 查询单条记录 |
| `queryAll` | `Future<List<Map>>` | 条件查询多条记录 |
| `update` | `Future<int>` | 更新记录 |
| `delete` | `Future<int>` | 物理删除 |
| `softDelete` | `Future<int>` | 软删除（设置 `deleted_at`） |
| `restore` | `Future<int>` | 恢复软删除记录 |
| `rawQuery` / `rawUpdate` / `rawDelete` | — | 执行原始 SQL |
| `transaction` | `Future<T>` | 在事务中执行自定义逻辑 |
| `purgeExpiredTrash` | `Future<void>` | 清理超过 30 天的回收站数据 |
| `close` | `Future<void>` | 关闭数据库连接 |

#### 表结构（`tables.dart`）

共 **10 张表**，涵盖用户、内容、标签、回收站：

| 表名 | 实体 | 关键字段 |
|------|------|----------|
| `users` | `UserModel` | `user_id`, `login_type`, `nickname`, `phone`, `wechat_open_id` |
| `work_notes` | `WorkNote` | `id`, `user_id`, `title`, `content`, `record_type`, `tags`, `mood`, `attachments` |
| `life_records` | `LifeRecord` | `id`, `user_id`, `title`, `content`, `record_type`, `mood`, `weather`, `location`, `images` |
| `goals` | `Goal` | `id`, `user_id`, `title`, `description`, `goal_type`, `progress_type`, `milestones`, `checklist`, `reward`, `status` |
| `goal_logs` | `GoalLog` | `id`, `goal_id`, `progress_before`, `progress_after`, `note` |
| `books` | `Book` | `id`, `user_id`, `title`, `author`, `status`, `rating` |
| `reading_notes` | `ReadingNote` | `id`, `book_id`, `note_type`, `chapter`, `content` |
| `murmurs` | `Murmur` | `id`, `user_id`, `content`, `mood`, `tags`, `images` |
| `tags` | — | `id`, `name`, `module`, `color`, `usage_count` |
| `trash_items` | — | `id`, `module_type`, `record_data`, `deleted_at`, `auto_purge_at` |

**索引**：在 `user_id`、`deleted_at`、`status`、`goal_id`、`book_id` 等高频率查询字段上建立了索引。

### 5.4 数据模型（`lib/data/models/`）

所有模型均遵循 **Map ↔ 对象双向转换** 约定，提供 `toMap()` 和 `fromMap()` 工厂方法；复合字段（如 `List<Milestone>`、`List<ImageRef>`）使用 JSON 字符串序列化存储。

#### 核心模型一览

| 模型 | 文件 | 说明 |
|------|------|------|
| `UserModel` | `user_model.dart` | 用户实体，支持微信/手机号两种登录方式 |
| `WorkNote` | `work_note_model.dart` | 工作记录，含心情、附件、标签 |
| `LifeRecord` | `life_record_model.dart` | 生活记录，额外支持天气、地点 |
| `Goal` | `goal_model.dart` | 目标实体，含里程碑、清单、奖励子模型 |
| `Milestone` | `goal_model.dart` | 里程碑子项 |
| `ChecklistItem` | `goal_model.dart` | 清单子项 |
| `Reward` | `goal_model.dart` | 奖励子项，支持图片与预估花费 |
| `GoalLog` | `reading_models.dart` | 目标推进日志 |
| `Book` | `reading_models.dart` | 书籍实体 |
| `ReadingNote` | `reading_models.dart` | 读书笔记，绑定书籍 |
| `Murmur` | `murmur_model.dart` | 碎碎念（短内容） |
| `ImageRef` | `image_ref_model.dart` | 图片引用（本地路径 + 缩略图） |

#### 枚举定义（`enums.dart`）

| 枚举 | 用途 |
|------|------|
| `LoginType` | `wechat` / `phone` |
| `Mood` | `happy` / `neutral` / `angry` / `sad` / `think`（含 emoji 与中文标签） |
| `Weather` | `sunny` / `cloudy` / `rainy` / `snowy` / `foggy` |
| `WorkRecordType` | `experience` / `insight` / `reflection` |
| `LifeRecordType` | `beauty` / `insight` / `reflection` |
| `GoalType` | `shortTerm` / `midTerm` / `longTerm` |
| `GoalCategory` | `health` / `career` / `learning` / `life` / `finance` / `other` |
| `ProgressType` | `manual` / `milestone` / `checklist` |
| `GoalStatus` | `active` / `completed` / `abandoned` |
| `RewardType` | `food` / `travel` / `shopping` / `experience` / `other` |
| `BookStatus` | `reading` / `finished` / `paused` / `planned` |
| `NoteType` | `excerpt` / `insight` / `thought` / `change` |

### 5.5 数据仓库（`lib/data/repositories/`）

每个 Repository 对应一种业务实体，封装对 `DatabaseProvider` 的调用，屏蔽底层 SQL 细节。

| 仓库 | 文件 | 核心能力 |
|------|------|----------|
| `AuthRepository` | `auth_repository.dart` | 微信登录、手机号登录、获取/更新当前用户 |
| `WorkRepository` | `work_repository.dart` | 工作记录的增删改查、软删除/恢复、按标签筛选、搜索 |
| `LifeRepository` | `life_repository.dart` | 生活记录的增删改查、往日今日查询 |
| `GoalRepository` | `goal_repository.dart` | 目标 CRUD、进度更新（含日志记录）、完成/放弃、成就墙查询 |
| `ReadingRepository` | `reading_repository.dart` | 书籍与笔记的 CRUD、阅读统计（已读/在读/笔记数） |
| `MurmurRepository` | `murmur_repository.dart` | 碎碎念的 CRUD、字数统计 |

**设计模式**：所有 Repository 均为**无状态类**，内部持有 `DatabaseProvider.instance` 单例引用，不维护自身状态，可在 UI 层直接实例化使用。

### 5.6 状态管理（`lib/features/auth/providers/`）

#### AppProvider（`app_provider.dart`）

继承自 `ChangeNotifier`，是应用唯一的**全局状态源**。

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `currentUser` | `UserModel?` | 当前登录用户 |
| `isLoggedIn` | `bool` | 是否已登录 |
| `initialized` | `bool` | 是否完成启动初始化 |
| `userId` | `String` | 当前用户 ID（空字符串表示未登录） |
| `init()` | `Future<void>` | 从 `SharedPreferences` 恢复登录态 |
| `loginWithWechat(...)` | `Future<void>` | 微信登录并持久化 |
| `loginWithPhone(...)` | `Future<void>` | 手机号登录并持久化 |
| `updateUser(...)` | `Future<void>` | 更新用户信息并通知监听者 |
| `logout()` | `Future<void>` | 清除登录态并通知监听者 |

**持久化键值**：
- `is_logged_in` → `bool`
- `user_id` → `String`

### 5.7 主题系统（`lib/core/theme/`）

| 文件 | 职责 |
|------|------|
| `app_theme.dart` | 主题入口，提供 `light`、`dark` 两个 getter，以及按 `Brightness` 自适应方法 |
| `light_theme.dart` | 构建 Material 3 亮色主题，定义颜色方案、AppBar、卡片、按钮、输入框、底部导航、文字样式等 |
| `dark_theme.dart` | 构建暗色主题（结构与亮色对称） |

**设计 Token**：
- 主色：`#5B8C5A`（草木绿）
- 辅色：`#E8A87C`（暖橙）
- 模块色：`work` 商务蓝、`life` 生活橙、`goal` 活力绿、`reading` 书卷棕、`murmur` 柔粉

### 5.8 常量与工具（`lib/core/constants/`、`lib/core/utils/`）

| 文件 | 说明 |
|------|------|
| `app_constants.dart` | 应用信息、数据库名、本地存储 Key、分页大小、图片限制、回收站清理天数等 |
| `colors.dart` | 完整的颜色定义（品牌色、模块色、中性色、功能色、心情色） |
| `strings.dart` | 所有用户可见文案集中管理，便于国际化扩展 |
| `date_utils.dart` | 日期格式化、友好时间（"刚刚"/"5分钟前"）、问候语生成 |

### 5.9 共享组件（`lib/shared/`）

#### 布局（`layouts/`）

| 组件 | 文件 | 说明 |
|------|------|------|
| `MainScaffold` | `main_scaffold.dart` | 底部 Tab 导航主框架，包含 `HomeScreen`、`WorkListScreen`、`GoalBoardScreen`、`BookshelfScreen`、`SettingsScreen` 五个页面，使用 `IndexedStack` 保持页面状态 |

#### 通用组件（`widgets/`）

| 组件 | 文件 | 说明 |
|------|------|------|
| `AppCard` | `app_card.dart` | 统一卡片容器，带圆角、边框、点击效果 |
| `EmptyState` | `empty_state.dart` | 空状态占位组件 |
| `MoodSelector` | `mood_selector.dart` | 心情选择器（emoji 网格） |
| `TagChip` | `tag_chip.dart` | 标签小 chip |

---

## 6. 功能模块（Features）

### 6.1 认证模块（`features/auth/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `WelcomeScreen` | `welcome_screen.dart` | 欢迎页，展示应用 Slogan，引导登录 |
| `LoginScreen` | `login_screen.dart` | 登录页，支持微信与手机号两种方式（本地模拟） |
| `AppProvider` | `providers/app_provider.dart` | 全局登录态管理 |

**登录逻辑**：
1. 微信登录：传入 `openId` + `nickname`，本地创建/更新用户记录。
2. 手机号登录：传入 `phone`，本地创建/更新用户记录（验证码为模拟）。
3. 登录成功后写入 `SharedPreferences`，触发 `notifyListeners()`，UI 自动跳转 `MainScaffold`。

### 6.2 首页模块（`features/home/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `HomeScreen` | `home_screen.dart` | 成长概览，聚合展示：进行中的目标、近期阅读改变、往日今日 |

**数据加载**：并发请求三个仓库（`GoalRepository`、`ReadingRepository`、`LifeRepository`），使用 `Future.wait` 减少等待时间。

### 6.3 工作模块（`features/work/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `WorkListScreen` | `work_list_screen.dart` | 工作记录列表，支持按类型筛选 |
| `WorkDetailScreen` | `work_detail_screen.dart` | 记录详情展示 |
| `WorkEditScreen` | `work_edit_screen.dart` | 新建/编辑工作记录 |

**记录类型**：经验（`experience`）、心得（`insight`）、反思（`reflection`）。

### 6.4 生活模块（`features/life/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `LifeListScreen` | `life_list_screen.dart` | 生活记录列表 |
| `LifeEditScreen` | `life_edit_screen.dart` | 新建/编辑生活记录 |

**特色功能**：支持记录天气、地点、图片（最多 9 张），并提供「往日今日」回忆功能（查询历年同月同日记录）。

### 6.5 目标模块（`features/goal/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `GoalBoardScreen` | `goal_board_screen.dart` | 目标看板，展示进行中的目标 |
| `GoalDetailScreen` | `goal_detail_screen.dart` | 目标详情、进度历史、里程碑/清单管理 |
| `GoalEditScreen` | `goal_edit_screen.dart` | 新建/编辑目标 |
| `AchievementWallScreen` | `achievement_wall_screen.dart` | 成就墙，展示已完成目标 |

**进度计算**：
- `manual`：用户手动输入百分比。
- `milestone`：自动计算已完成里程碑占比。
- `checklist`：自动计算已完成清单项占比。

### 6.6 阅读模块（`features/reading/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `BookshelfScreen` | `bookshelf_screen.dart` | 书架，展示所有书籍（在读/已读/想读/暂停） |
| `BookDetailScreen` | `book_detail_screen.dart` | 书籍详情与关联笔记列表 |
| `BookAddScreen` | `book_add_screen.dart` | 添加新书 |
| `NoteEditScreen` | `note_edit_screen.dart` | 新建/编辑读书笔记 |

**笔记类型**：摘抄（`excerpt`）、心得（`insight`）、思考（`thought`）、改变（`change`）。其中「改变」类笔记会在首页「近期改变」卡片中展示。

### 6.7 碎碎念模块（`features/murmur/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `MurmurScreen` | `murmur_screen.dart` | 碎碎念时间线，支持快速记录短内容与心情 |

### 6.8 设置模块（`features/settings/`）

| 页面 | 文件 | 职责 |
|------|------|------|
| `SettingsScreen` | `settings_screen.dart` | 设置主页（备份、主题、应用锁、关于入口） |
| `AboutScreen` | `about_screen.dart` | 关于页面，展示版本信息与 Slogan |

---

## 7. 数据流与依赖关系

### 7.1 单向数据流

```
UI (Screen/Widget)
    │ ① 用户交互（点击、输入）
    ▼
Provider (AppProvider)  —— 仅管理登录态
    │ ② 读取/提交数据
    ▼
Repository (XxxRepository)
    │ ③ 调用底层 CRUD
    ▼
DatabaseProvider (单例)
    │ ④ 执行 SQL
    ▼
SQLite (本地文件)
```

### 7.2 关键依赖图

```
main.dart
 ├── BuildselfApp
 │    ├── AppProvider (ChangeNotifierProvider)
 │    ├── AppTheme (light/dark)
 │    ├── AppRouter (onGenerateRoute)
 │    └── _buildHome() → WelcomeScreen / MainScaffold
 │
MainScaffold
 ├── HomeScreen
 │    ├── GoalRepository
 │    ├── ReadingRepository
 │    └── LifeRepository
 ├── WorkListScreen → WorkRepository
 ├── GoalBoardScreen → GoalRepository
 ├── BookshelfScreen → ReadingRepository
 └── SettingsScreen

所有 Repository
 └── DatabaseProvider.instance
      ├── database (SQLite)
      └── AppSql (建表语句)
```

### 7.3 跨模块依赖说明

- **无循环依赖**：`core/` 不依赖 `features/`；`shared/` 只依赖 `core/`；`features/` 之间通过路由跳转，无直接导入依赖。
- **模型共享**：`data/models/` 被所有上层模块共用，是唯一的公共契约。
- **主题下沉**：`core/theme/` 与 `core/constants/` 提供最底层的 UI Token，所有页面均可安全引用。

---

## 8. 项目运行方式

### 8.1 环境要求

- **Flutter SDK**：`>=3.0.0`（推荐稳定版）
- **Dart SDK**：`>=2.17.0 <3.0.0`
- **Android**：Android Studio + Android SDK（API 21+）
- **iOS**：Xcode + CocoaPods（macOS 环境）

### 8.2 首次运行

```bash
# 1. 进入项目目录
cd buildself_app

# 2. 获取依赖
flutter pub get

# 3. 运行到已连接设备或模拟器
flutter run

# 4. 指定平台运行
flutter run -d android
flutter run -d ios
flutter run -d chrome
```

### 8.3 构建 release 包

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### 8.4 代码检查与测试

```bash
# 静态分析
flutter analyze

# 运行测试
flutter test
```

---

## 9. 关键设计决策

| 决策 | 选型 | 理由 |
|------|------|------|
| 状态管理 | Provider | 官方推荐，学习成本低，满足本应用复杂度 |
| 本地数据库 | sqflite | 成熟稳定，支持复杂查询与事务 |
| 数据删除策略 | 软删除 + 自动清理 | 保护用户误删数据，同时避免存储无限增长 |
| 图片存储 | 本地文件路径 | 无需网络依赖，配合 `ImageRef` 模型统一管理 |
| 主题方案 | Material 3 + ColorScheme.fromSeed | 自适应亮色/暗色，未来可扩展动态取色 |
| 用户认证 | 本地模拟 | 纯本地应用，无需后端服务，降低部署成本 |

---

## 10. 扩展建议

1. **数据同步**：可引入 `drift` 或 `hive` + 云端备份，实现多端同步。
2. **搜索增强**：当前为 SQL `LIKE` 模糊查询，可接入 `fts5` 全文索引。
3. **图表统计**：引入 `fl_chart` 展示目标完成趋势、阅读时长等可视化数据。
4. **通知提醒**：接入 `flutter_local_notifications`，为目标截止日期设置提醒。
5. **国际化**：当前字符串集中在 `AppStrings`，可迁移至 `flutter_gen` + ARB 文件实现多语言。

---

*文档版本：v1.0.0*  
*生成日期：2026-07-30*  
*对应代码版本：1.0.0+1*
