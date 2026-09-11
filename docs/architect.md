# 架构与项目结构（architect）

> 统一记录：应用整体架构、分层依赖、核心模块职责、平台标识与环境要求。
> 本文件以 2026-09 第二次重建（爬虫内核驱动）为准，适用于 `2.5.31+1`。

## 1. 一句话定位

本项目是**长江大学教务系统课程表 App**：通过爬虫内核模拟登录学校教务/CAS/aTrust 系统，
抓取并解析 HTML 页面获取课表/成绩/考试/培养计划/选课等数据，本地持久化支持离线查看。

> 仅供学习与研究，勿作商业用途或违规使用（见仓库 README 免责声明）。

## 2. 技术栈

| 层 | 选型 |
|---|---|
| 语言/平台 | Dart + Flutter（`sdk: >=3.11.0 <4.0.0`） |
| 架构 | 严格 MVVM + Riverpod 2.6 |
| 依赖 | 仅 `flutter_riverpod` + `path_provider`（**内核零第三方依赖**） |
| 内核实现 | 纯 Dart 标准库（`dart:io`/`dart:convert`/`dart:math`/`dart:typed_data`/`dart:async`） |
| 数据形态 | 原生 `Map<String, Object?>` / `List`（与 Python 爬虫输出 1:1） |

依赖最小化原则见 [pubspec.yaml](../pubspec.yaml)：内核零第三方，UI 层仅保留状态管理
与文件路径定位，其余（intl/dio/html/crypto/email/url_launcher 等）已全部裁除。

## 3. 分层总览

```text
lib/
├── main.dart                    入口：状态栏样式 + ProviderScope + 按认证状态路由
├── core/                        内核层（零 Flutter 依赖）
│   ├── crawler/                 爬虫内核（模型/解析清洗器/会话鉴权/接口，详见 §4）
│   └── storage/local_cache.dart 业务 KV 缓存工具（命名空间=单JSON文件，原子写）
├── viewmodels/                  状态层（Riverpod Provider / Notifier）—— 组装根 + 各业务 VM
└── views/                     表现层（页面 + 共享组件，可整体替换不影响内核）
```

分层依赖规则（**单向依赖**）：

```text
views ──► viewmodels ──► core（crawler / storage）
                             ▲
                             │
                             └ 零依赖（仅 Dart 标准库）
```

- **views 依赖 viewmodels，viewmodels 依赖 core**；反向引用禁止。
- **core 不 import flutter**（`package:flutter` 不进内核），可被单测/命令行脚本复用。
- 文件路径只在组装层（`viewmodels/providers.dart`）通过 `path_provider` 注入，
  内核与业务 VM 只接收字符串路径。

## 4. 爬虫内核（lib/core/crawler）

采用 **模型 / 解析清洗器 / 爬虫 / cookie&token&会话鉴权** 架构，共 23 个文件。

```text
lib/core/crawler/
├── crawler_exceptions.dart      异常体系（sealed）
├── models/
│   ├── config_models.dart       GrabberConfig（全局配置）+ CrawlerCredentials（凭据）
│   └── data_models.dart         全部返回结构的 typedef 形状约定
├── crypto/
│   ├── aes_cbc.dart             纯 Dart AES-128-CBC
│   └── cas_crypto.dart          CAS 密码加密 + randomString/randomHex
├── session/
│   ├── cookie_jar.dart          CookieJar：RFC6265 域/路径作用域 + JSON 持久化
│   ├── http_client.dart         SessionHttpClient：手动逐跳重定向 + Set-Cookie 摄取
│   ├── state_store.dart         SessionStateStore 接口（File 原子写 / Memory 两实现）
│   ├── step1_cas.dart           CAS 统一身份认证（SSO 优先 / 密码 AES）
│   ├── step2_portal.dart        aTrust 门户会话（sid + csrfToken + authCheck + 短信二次认证）
│   ├── step3_app.dart           教务应用授权（sdp_user_token + verify JWT 自愈）
│   └── crawler_session.dart     CrawlerSession：生命周期编排（内核唯一对外入口）
├── parsers/
│   ├── html_sax.dart            SAX 式 HTML 解析器
│   ├── clean.dart               cleanWs/stripAll/stripTags/toNum/weekParse…
│   ├── js_literal.dart          JS 字面量 → 原生对象
│   ├── table_miner.dart         表格挖掘（parseTables/pickTable/tableRecords/kvTables）
│   ├── timetable_parser.dart    课表
│   ├── grade_parser.dart        成绩
│   ├── exam_parser.dart         考试
│   ├── plan_parser.dart         培养计划
│   ├── elective_parser.dart     选课
│   └── misc_parser.dart         学籍/消息/欢迎/学期/中期考核/教学评价
└── api/eams_api.dart            第④步 EamsApi：全部教务接口 + RawSink
```

### 四步鉴权链路

```text
① CAS 统一认证 ──► ② aTrust 门户会话 ──► ③ 教务应用授权 ──► ④ EamsApi 业务接口
  Step1Cas          Step2Portal          Step3App            EamsApi
  ticket=ST-xxx     sid/online cookie    JSESSIONID +         courseTable/grades/
                                          sdp_user_token       examBatches/… (20+)
```

网关风控（二次认证）：`Step2Portal` 支持 `sendSmsCode`/`verifySmsCode`/`SmsChallenge`，
`CrawlerSession` 暴露 `startSmsVerification`/`completeSmsVerification`。

### 会话生命周期状态机

```text
构造 CrawlerSession
   ▼
loadState()  ← 恢复 cookie + extra（幂等，ensureApi 自动调用）
   ▼
ensureApi()     缓存新鲜且 JSESSIONID 在 → 零网络直接用；否则走①→②→③→④
   ▼
EamsApi.*()     业务调用；SessionLost → withApi 自动重建（≤ maxRebuilds 次）
   ▼
reset()（登出/换号）  dispose()（Riverpod onDispose）
```

防封号硬约束：每实例最多 1 次密码登录 POST；CASTGC 14 天内全走 SSO 免密；
`CredentialError`/`NeedCaptchaError`/`NeedSecondaryAuthError` 绝不自动重试。

完整函数签名见 [lib/core/crawler/README.md](../lib/core/crawler/README.md)。

## 5. 状态层（viewmodels）

| Provider | 类型 | 职责 |
|---|---|---|
| `localCacheProvider` | FutureProvider | LocalCache 单例（组装注入路径） |
| `sessionStatePathProvider` | FutureProvider | 会话状态落盘路径 |
| `crawlerSessionProvider` | Provider | 从 auth 状态提取当前 CrawlerSession |
| `grabberConfigProvider` | Provider | 全局爬虫配置（默认值即抓包实测） |
| `authProvider` | AsyncNotifier | 登录/会话恢复/短信二次认证/账号簿/登出 |
| `timetableProvider` | AsyncNotifier | 课程表（缓存优先 + 强制刷新 + 周次翻页） |
| `semesterSelectionProvider` | AsyncNotifier | 全局学期选择单一数据源 |
| `cacheProvider` | AsyncNotifier | LocalCache 可视化/运维 |
| `apiExplorerProvider` | Notifier | API 调试探索（工程期逐接口触发） |
| `weekIndexProvider` | StateProvider | 当前教学周（翻页不触发网络） |

关键数据流：
```text
authProvider.build → _restore()（读账号簿+会话 cookie，走 ensureApi；失败区分降级）
timetableProvider.build → 学期=semesterSelection → LocalCache 命中渲染 / 在线拉取写缓存
semesterSelectionProvider → 用户选择(meta) > 网络校正 > SemesterTable 本地推算(锚点409 +20/学期)
```

依赖注入约定：
- 业务 VM **不直接 new 内核对象**，一律读取本文件组装好的 Provider。
- 会话参数必须**静态类型 `CrawlerSession`**：dynamic 接收者调用泛型 `withApi`
  时闭包被推断为 `(dynamic)→dynamic`，运行时签名检查失败（已踩坑，详见开发规范）。

## 6. 表现层（views）

```text
lib/views/
├── widgets/kit.dart      共享组件 + snack/确认/JSON 弹窗
└── pages/
    ├── load_page.dart    Splash
    ├── login_page.dart   登录页 + 账号簿 double-tab + 短信二次认证面板
    ├── home_page.dart    NavigationBar 三 tab 容器
    ├── timetable_page.dart  课表 Table 网格 + 周翻页 + 学期选择底部弹层
    ├── cache_page.dart   缓存工具（LocalCache 可视化）
    └── more_page.dart    更多（API 调试 + 学期列表权威校正）
```

路由（[main.dart](../lib/main.dart)）：
```text
authProvider.when
  loading ──► Splash
  status:
    boot            ──► Splash
    busy/needsLogin/needsSms ──► LoginPage
    authed          ──► HomePage
```

## 7. 本地持久化

| 用途 | 位置 | 结构 |
|---|---|---|
| 业务缓存 | `{documents}/grade2_cache/<ns>.json`（LocalCache） | `{key: {v, exp}}`，原子写 |
| 会话状态 | `{support}/crawler_state.json`（FileSessionStateStore） | `{saved_at, cookies, extra}` |

LocalCache 命名空间约定：`auth`（账号簿/最后登录）、`timetable`（`table_std_<semesterId>`）、
`meta`（`current_semester`/`semester_list`）、以及导入的 demo 等。
> 会话状态与业务缓存**严格分离**：只存令牌 vs 只存业务数据。

## 8. 平台标识与环境要求（勿丢）

| 项目 | 值 |
|---|---|
| Android applicationId | `ink.xiaonaoweisuo.grade` |
| Android label | `Stable Grade` |
| Android compileSdk | 36（Flutter 默认） |
| iOS bundle id | `com.example.xiaonaoweisuo.grade2.grade2` |
| iOS 团队 | `7V6DGXJ642` |
| iOS target | 13.0 |
| iOS 显示名 | Grade2 |

**构建环境（重要）**：
- 本机 PATH 的 flutter 是**鸿蒙 SDK**（Dart 3.9.2），解析不了本项目的 pubspec（要求 Dart ≥3.11）。
  构建/分析**必须**用官方 SDK：`/Users/lin/develop/flutter/bin/flutter`（3.44.1 / Dart 3.12.1）。
  切换脚本：`flutter-switch official|harmony`。
- 直接 `./gradlew` 时需 `JAVA_HOME` 指向 Android Studio 自带 jbr（DevEco JBR 缺 jlink 会失败）。
- 平台目录为 2026-09 重建的新模板：Gradle 9.1 + AGP 9.0.1 + Kotlin DSL(.kts)。

## 9. 相关文档索引

| 文档 | 内容 |
|---|---|
| [architect.md](architect.md) | 本文件：架构与项目结构 |
| [process.md](process.md) | 开发进度与里程碑 |
| [handoff.md](handoff.md) | 交接文档与上手指引 |
| [dev-guidelines.md](dev-guidelines.md) | 开发规范 |
| [lib/core/crawler/README.md](../lib/core/crawler/README.md) | 爬虫内核函数签名 |