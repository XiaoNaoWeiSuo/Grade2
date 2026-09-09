# Grade2 严格 MVVM 架构重构计划（Riverpod）

## Context

项目是大学生教务成绩查询 Flutter 应用（Flutter 3.35.8 / Dart ≥3.11），现有 10 个 dart 文件共 10711 行，无任何分层：页面直连网络（Requests）、直读文件（CounterStorage）、全局可变变量（main.dart L33-35 的 `netdata`/`enterkey`）传状态，topbar↔pages 循环依赖，多个数千行大文件。

用户要求：重构为严格 MVVM（状态管理选用 **Riverpod**）；拆分大文件；删除死代码（FakeWechat、Servies、widgetshow、ContributionGraph/ActivityTile、CircularProgressBar、CicleloadPage、~250 行注释块）以及 **AI 聊天（tree/chat.dart）和 高仿青年大学习功能（DaxuexiPage + TeenStudy/getdaxuexi/getpass + daxuexi.png + updatePage 相关入口）**；SMTP 凭据挪到本地配置。LOVEPage 保留。行为保持不变（除删除功能），导航继续用 Navigator.push。

## 目标目录结构与旧→新映射

```
lib/
├── main.dart                          # 仅 main()+ProviderScope+MyApp (~60行)  ← main.dart L37-67
├── core/
│   ├── config/app_secrets.dart(.example)  # SMTP 账号/密码 ← function.dart L120-124（.dart 进 gitignore）
│   ├── network/session_client.dart    # Dio+CookieJar 会话封装 ← login.dart Requests 构造部分 L691-710
│   ├── storage/json_store.dart        # CounterStorage 改名，逻辑不变 ← function.dart L78-108
│   └── utils/
│       ├── version_utils.dart         # 版本比较/年份工具 ← function.dart L31-63,151-170、login.dart L26-33
│       └── mail_service.dart          # SenMail，改读 AppSecrets ← function.dart L110-149
├── data/
│   ├── models/                        # 纯数据 fromJson/toJson，零依赖
│   │   ├── student.dart               # Student ← login L74-163
│   │   ├── course.dart                # Course + Coursesis + CourseDataModel ← login L165-370
│   │   ├── task_activity.dart         # TaskActivity ← login L282-300
│   │   ├── evaluate.dart              # Evaluate ← login L372-387
│   │   ├── grade.dart                 # GradeAverange + CourseTotal ← login L389-553
│   │   ├── exam_data.dart             # ExamData ← login L429-491
│   │   └── app_settings.dart          # ResultObject 改造为类型化设置模型 ← function L66-75
│   ├── parsers/                       # 纯解析（从 Requests 抽出，无 IO）
│   │   ├── student_parser.dart        # HTML→Student/Course ← login parseStudentTable 等
│   │   ├── timetable_parser.dart      # SourceAnalysis 课表 JS 解析 ← login L554-690
│   │   ├── grade_parser.dart          # 成绩表格解析
│   │   └── exam_parser.dart
│   └── repositories/                  # 唯一允许 IO/网络的地方
│       ├── auth_repository.dart       # Login/GetData ← login L711-770
│       ├── schedule_repository.dart   # GetSchedule ← login L840-866,1465+
│       ├── grade_repository.dart      # Getgrade/GetAllGrade ← login L772-838,1188-1210
│       ├── exam_repository.dart       # GetExam ← login L868-900
│       └── evaluate_repository.dart   # GetEvaluate/GetSEvaluatePush/backyearid ← login L1130-1290
├── viewmodels/                        # 禁 import flutter/material
│   ├── session_provider.dart          # 替代全局 netdata（见下表）
│   ├── settings_provider.dart         # AppSettings Notifier，变更写 setting.json
│   ├── auth_provider.dart             # 登录流程编排 + 账号管理(data.json)
│   ├── offline_provider.dart          # 合并 Loadpage.load() 与 handleTimeout() 的 root.json 解析
│   ├── schedule_provider.dart         # 课表 + 当前学期(替代 enterkey)
│   ├── grade_provider.dart            # 学期成绩/历年总览
│   ├── exam_provider.dart             # 考试
│   ├── evaluate_provider.dart         # 评教列表+提交刷新
│   └── about_provider.dart            # 版本检查/APK 下载/反馈邮件（Login 与 About 共用 update 逻辑）
└── views/
    ├── widgets/                       # 纯 UI，业务经回调上移
    │   ├── form_widgets.dart          # PresetSelectionCard/DateTimePickerButton/CustomTextField ← topbar L18-173,570-614
    │   ├── info_widgets.dart          # AnimatedStrip/SubjectCreditsList/进度环 ← topbar L616-800
    │   ├── calendar_grid.dart         # CalendarPage 纯渲染化(消除 build 副作用) ← topbar L261-569
    │   ├── exam_list.dart             # ExamList，导航改 VoidCallback 注入 ← topbar L802-1027
    │   ├── loading_animation.dart     # loadanimation+MyPainter→ScheduleGridPainter ← topbar L1155-1321
    │   └── shared_ui.dart             # Polygonal/AnimCard/CardItem/RandomGeometricShapes/SizeTransitionRe ← rewidget L234-580
    └── pages/                         # 每页一个 ConsumerWidget/ConsumerStatefulWidget
        ├── load_page.dart             # Loadpage ← main L69-259
        ├── login_page.dart            # LoginPage ← main L260-1332
        ├── main_page.dart             # MainPage 壳(底部导航) ← main L1333-2625
        ├── tools_page.dart            # updatePage（删大学习/密码入口后）← main L2626-3638
        ├── evaluate_page.dart         # EvaluatePage 改读 provider ← main L3639-3783
        ├── appearance_page.dart       # MyImagePicker+ColorPickerDialog ← pages L23-531
        ├── about_page.dart            # AutherPage ← pages L532-1013
        ├── vacation_page.dart         # vacationPage ← pages L1014-1769
        ├── grade_overview_page.dart   # HomoPage（删 ~250 行注释块）← pages L1909-2668
        └── love_page.dart             # LOVEPage ← pages L2669-2689
```

删除文件：`lib/tree/`（chat.dart、Wechat.dart、serives.dart、pages.dart）、`lib/Common/`、旧 main.dart/login.dart/topbar.dart/rewidget.dart/function.dart 残余。

## Riverpod Provider 设计（替代全局状态）

| Provider | 类型 | 职责 |
|---|---|---|
| `sessionClientProvider` | Provider | Dio+CookieJar 会话对象（原 `netdata[0]`） |
| `sessionProvider` | NotifierProvider\<SessionNotifier, SessionState\> | {client, statusCode, account}（原 `netdata[1]` 判断 302/400） |
| `currentSemesterProvider` | StateProvider\<String\> | 原 `enterkey` |
| `settingsProvider` | NotifierProvider\<AppSettings\> | 主题色/背景图/blur/classstate，set 时持久化 setting.json（原 ResultObject 回传+MyImagePicker 直写） |
| `authProvider` | AsyncNotifierProvider | Loginact 流程：调 AuthRepository → 写 session/semester → 缓存 root.json |
| `offlineRestoreProvider` | FutureProvider | root.json 离线恢复（合并 Loadpage/handleTimeout 两份重复逻辑为一份） |
| `scheduleProvider` / `gradeProvider` / `examProvider` / `allGradeProvider` | AsyncNotifier/FutureProvider | 各业务数据，依赖 session |
| `evaluateProvider` | AsyncNotifierProvider | 评教列表；提交后 notifier 内刷新（替代 EvaluatePage 直改 widget.evaluatedata） |
| `aboutProvider` | NotifierProvider | 版本检查、APK 下载进度、在线模式开关 |

命名规范：`xxxProvider` 全局变量 + `XxxNotifier` 类。Repository 由 Provider 惰性创建，仅通过构造注入 sessionClientProvider。

## 分层铁律

- View：禁止 import dio/dart:io/parsing；数据一律 `ref.watch`，动作 `ref.read(xxx.notifier)`。
- ViewModel：禁止 import `package:flutter/material.dart`（仅 foundation）。
- Model：纯数据 + fromJson/toJson。
- IO/网络/解析只存在于 core/ 与 data/repositories/。
- ExamList 导航、CalendarPage 课程弹窗经回调/在上层处理；CalendarPage build 内修改 `widget.iteh`（L383-388 副作用）改为 initState/didChangeDependencies 计算。

## pubspec 变更

- 新增 `flutter_riverpod: ^3.0.0`
- 删除依赖（已 Grep 验证）：`http`、`flutter_markdown`（仅 chat.dart 与 topbar 未用 import）、`qr_flutter`（仅注释代码）
- 删除 asset：`assets/data/daxuexi.png`；删除 `assets/data/daxuexi.png` 文件
- `.gitignore` 增加 `lib/core/config/app_secrets.dart`；提交 `app_secrets.dart.example`（空默认值，保证新克隆可编译）

## 实施顺序（每阶段结束跑 `flutter analyze`，须零 error）

1. **基础设施**：pubspec + core/ 四文件 + app_secrets(.example) + .gitignore
2. **Model 层**：data/models/ 7 文件、data/parsers/ 4 文件（从 login.dart 抽出，纯拷贝+类型化）
3. **Repository 层**：5 个 repository（Requests 的网络与 IO 逻辑迁入，SourceAnalysis 归入 parsers）
4. **ViewModel 层**：viewmodels/ 9 个 provider 文件
5. **View 迁移**：views/widgets → views/pages，逐页迁移；每迁完一页即从旧文件删除对应类；全局 netdata/enterkey 的 23 处读写点随页替换为 ref
6. **删除与清理**：chat/Wechat/serives/Notifications/DaxuexiPage/TeenStudy/getdaxuexi/getpass、updatePage 大学习入口（main L2691-2715、L2846-2854）、死组件、注释块、`ignore_for_file` 行、旧文件清空删除

## 风险与对策

- **循环依赖 topbar↔pages**：ExamList 跳 AutherPage 回调化后 widgets 层不再 import pages，自然解除。
- **两个 MyPainter 同名**：rewidget 的改名 `ShapesPainter`（shared_ui.dart），topbar 的改名 `ScheduleGridPainter`（loading_animation/calendar 侧）。
- **netdata 替换**：23 处集中在 main.dart（L336/679-693/757-787/809/3369/3675-3680/3761-3766），随页面迁移逐点替换。
- **Loadpage 与 handleTimeout 重复**：以 Loadpage 版本为准合并进 offlineProvider。
- **use_build_context_synchronously** 等 lint：迁移时就地修复（`context.mounted` 判断），不把 `ignore_for_file` 带入新文件。
- **updatePage 体量大**（删功能后仍 ~800 行）：动画控制器逻辑保持原样搬运，只替换数据读写为 provider，不额外重构动画。

## 验证

1. 每阶段：`flutter analyze` 零 error。
2. 最终：`flutter build apk --debug`（或 ios --no-codesign）编译通过。
3. 人工冒烟清单：启动路由分发 → 离线进入 → 登录 → 课表渲染+课程弹窗 → 成绩/历年总览 → 考试列表"关于"跳转 → 外观页换背景重启保持 → 关于页检查更新/反馈邮件 → 请假条生成保存 → 评教提交后列表刷新 → 退出换号。
