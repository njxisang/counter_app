# 计数统计 App

一款基于 Flutter + Riverpod 的轻量级多项目计数应用，支持本地 SQLite 持久化、自定义增减量、统计图表与日期筛选。

---

## 功能特性

### 核心功能

| 功能 | 说明 |
|------|------|
| 多项目管理 | 创建、编辑、删除计数项目，支持自定义颜色标签 |
| 快速计数 | 主页一键 +1/-1，带触觉反馈（HapticFeedback） |
| 自定义增减 | 支持任意整数自定义增减量 |
| 批量撤销 | 本会话内连续操作可一键全部撤销；跨会话支持撤销最近一条记录 |
| 会话感知撤销 | 应用跟踪当前会话内的操作次数，点击撤销回退全部会话内操作 |
| 双击快捷 | 连击同一按钮（500ms 内）触发 ±5 快速增减，带强触觉反馈 |
| 两步删除确认 | 首次确认 + 输入项目名前两字二次验证，防止误删 |
| 日期筛选 | 按「今日 / 本周 / 本月 / 自定义范围」筛选记录 |

### 统计图表

| 功能 | 说明 |
|------|------|
| 折线图 / 柱状图切换 | 折线图展示累计值走势，柱状图展示单次变化量 |
| 日期范围筛选 | 通过 ChoiceChip 快速切换时间范围，支持自定义日期区间 |
| 空数据友好 | 无数据时显示引导提示，而非空白或报错 |

### UX 细节

- **数字动画**：累计总数变化时播放 `AnimatedSwitcher` + `ScaleTransition` 缩放动画
- **操作反馈 SnackBar**：每次计数操作后显示浮动提示，800ms 自动消失
- **项目颜色系统**：8 套预设色（靛蓝 / 翠绿 / 琥珀 / 玫红 / 紫罗兰 / 青色 / 橙色 / 青柠），卡片左侧显示彩色条
- **长按上下文菜单**：`ProjectCard` 长按弹出 BottomSheet，提供「编辑项目」与「查看统计」快捷入口
- **FittedBox 数字自适应**：计数数字自动缩放，防止溢出

---

## 技术架构

```
lib/
├── main.dart                          # 应用入口
├── app.dart                           # MaterialApp + GoRouter 路由配置
├── models/
│   ├── project.dart                   # CounterProject 数据模型
│   └── record.dart                    # CounterRecord 数据模型
├── database/
│   ├── database_helper.dart           # SQLite 数据库初始化（DB version = 1）
│   └── repositories/
│       ├── project_repository.dart    # 项目 CRUD
│       └── record_repository.dart     # 记录 CRUD
├── providers/
│   ├── projects_provider.dart         # 项目列表 StateNotifier + 排序/搜索
│   ├── records_provider.dart          # 记录列表 Provider
│   └── date_filter_provider.dart      # 日期筛选状态
├── pages/
│   ├── home_page.dart                 # 项目列表首页
│   ├── project_detail_page.dart       # 计数详情（StatefulWidget，支持会话撤销）
│   ├── project_edit_page.dart         # 新建/编辑项目 + 两步删除确认 + 颜色选择器
│   └── stats_page.dart                # 统计图表页（折线/柱状切换）
└── widgets/
    ├── project_card.dart              # 项目卡片（左侧彩色条 + 长按菜单）
    ├── counter_buttons.dart           # 计数按钮（双击快捷 + 触觉反馈）
    ├── record_list_tile.dart          # 记录列表项
    └── stats_chart.dart               # FL Chart 图表组件
```

### 技术栈

| 类别 | 技术 |
|------|------|
| Framework | Flutter SDK `^3.11.5` |
| State Management | flutter_riverpod `^2.4.10` |
| Routing | go_router `^14.1.1` |
| Local Database | sqflite `^2.3.2` + path |
| Charts | fl_chart `^0.66.2` |
| Equality | equatable `^2.0.5` |
| Date Formatting | intl `^0.19.0` |

### 数据模型

**CounterProject（项目）**
```dart
id          int?      // 自增主键
name        String    // 项目名称（必填）
createdAt   DateTime  // 创建时间
note        String?   // 备注（可选）
colorIndex  int       // 颜色索引（0-7），默认 0
```

**CounterRecord（记录）**
```dart
id          int?      // 自增主键
projectId   int       // 所属项目 ID
delta       int       // 变化量（正/负整数）
totalAfter  int       // 变化后的累计值
createdAt   DateTime  // 记录时间
```

### 数据库表

```sql
CREATE TABLE projects (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  created_at  TEXT    NOT NULL,
  note        TEXT,
  color_index INTEGER DEFAULT 0
);

CREATE TABLE records (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  project_id  INTEGER NOT NULL,
  delta       INTEGER NOT NULL,
  total_after INTEGER NOT NULL,
  created_at  TEXT    NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
```

---

## 构建与运行

### 环境要求

- Flutter SDK `^3.11.5`
- Dart SDK `^3.11.5`
- Android SDK（用于 Android 构建）

### 安装步骤

```bash
# 克隆项目
git clone git@github.com:njxisang/counter_app.git
cd counter_app

# 使用 FVM 管理 Flutter 版本（可选）
fvm install 3.41.9
fvm flutter pub get

# 安装依赖
flutter pub get

# 运行 Debug 构建
flutter build apk --debug

# 或使用 FVM
fvm flutter build apk --debug
```

> **注意**：本项目使用 FVM（Flutter Version Management）管理 Flutter 版本。全局编译命令为：
> ```bash
> JAVA_HOME=/home/xisang/miniconda3 fvm flutter build apk --debug
> ```
> APK 输出路径：`build/app/outputs/flutter-apk/app-debug.apk`

---

## 项目截图功能说明

| 界面 | 关键交互 |
|------|----------|
| 首页项目列表 | 卡片左侧彩色条 → 项目颜色；右上角编辑图标 / 长按 BottomSheet |
| 计数详情页 | 顶部大字累计数（带缩放动画）；±1 大按钮（120×72）；双击 ±5 |
| 统计图表页 | 右上角切换折线/柱状；ChoiceChip 切换日期范围 |
| 编辑项目页 | 颜色选择器（圆形色块）；删除触发两步确认 |

---

## 开发规范

- 所有页面状态使用 `flutter_riverpod` 管理，无 `setState` 滥用
- `StatelessWidget` 仅用于纯展示组件；需要本地状态或 `initState` 的页面使用 `ConsumerStatefulWidget`
- 数据库操作通过 Repository 模式封装，不在 UI 层直接操作 DB
- 表单验证统一使用 `GlobalKey<FormState>`
- 删除操作必须经过用户确认，不提供静默删除
- 所有外部操作结果（保存/删除/撤销）通过 `SnackBar` 反馈用户

---

## 更新日志

### v1.0.1（2026-05-11）

**UX/UI 优化**

- ✅ 计数数字变化动画（AnimatedSwitcher + ScaleTransition，200ms）
- ✅ 操作 SnackBar 提示（增加/减少 + 撤销反馈）
- ✅ 详情页 AppBar 动态显示项目名称
- ✅ 编辑入口优化（ProjectCard 长按 BottomSheet + 卡内编辑按钮）
- ✅ 两步删除确认（警告弹窗 → 输入项目名前两字验证）
- ✅ 批量撤销（会话内操作一键撤销，跨会话撤销最近一条）
- ✅ 项目颜色主题（8 套预设色，左侧卡片彩条 + 编辑页选色器）
- ✅ 按钮尺寸优化（100×64 → 120×72）
- ✅ 双击快捷增减（连击 ±5，强触觉反馈）
- ✅ 修复无效 `recentCount` 排序枚举

---

## License

Private project. All rights reserved.
