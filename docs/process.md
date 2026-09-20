# 开发进度（process）

> 按时间线记录重大项目节点、已完成能力、验证结论与待办。进度见表内"状态"。

## 1. 时间线

| 时间 | 阶段 | 内容 |
|---|---|---|
| 2024-02 ~ 2024-08 | 旧版 | Python + 早期 Flutter 立项、多轮功能迭代（历史 commit） |
| 2026-09-09 | ①   | 重写为严格 MVVM + Riverpod 2.6，依赖裁剪到最小 |
| 2026-09-10 | ②   | 爬虫内核 1.0 beta：Python `grabber/` → 纯 Dart 翻译 + 封装闭环 |
| 2026-09-10 | ③   | 登录联调实测：四步鉴权、短信二次认证、SSO 免密、离线降级 |
| 2026-09-10 | ④   | 学期编号本地表、全局学期切换、离线审计与提速 |
| 2026-09-11 | ⑤   | 正式 UI 全量落地：Cupertino 单栈 + 国际化（5 语言）+ 主题（4 模式）+ 密码安全存储 |

## 2. 各阶段状态

### ① MVVM + Riverpod 重构（已完成）
- 清除旧 `lib/data`/`lib/viewmodels`/`lib/views` 冗余业务层。
- pubspec 依赖裁至 `flutter_riverpod` + `path_provider`。
- 建立 `viewmodels/providers.dart` 组装根与单向依赖规则。

### ② 爬虫内核 1.0 beta（已完成）
- `lib/core/crawler/` 23 文件，模型/解析清洗器/爬虫/会话鉴权架构。
- 业务数据全原生 `Map`/`List`，与 Python 输出 1:1（已过 golden 逐字段比对）。
- 生命周期状态机 + Riverpod 对接示例齐备。

### ③ 登录联调实测（已完成，实网验证）
- **功能**：四步鉴权、CAS 密码 AES、SSO(CASTGC) 免密恢复、离线降级。
- **短信二次认证**（aTrust 网关风控）：`sendSmsCode`/`verifySmsCode`/`resendSms`/
  `submitSmsCode` 全链路实网验证通过；"认证记忆绑定存活的门户会话"已确认。
- **会话状态跨语言互通**：`grabber/.session/state.json` 与 Dart `FileSessionStateStore`
  同构，Dart 可载入 Python 会话并复用 CASTGC（实测）。
- **关键坑修复**：
  - `'$config.portalBase$path'` → `${config.portalBase}`（多级成员插值）；
  - `Random.nextInt` 2^32 上限 → 拆位生成；`on (A,B)` 记录类型 → `on Exception`；
  - dataQuery 需先 GET 预热；sendsms `interval` 为字符串"60"；`step2` 懒加载 getter。

### ④ 学期体系 + 审计提速（已完成）
- **学期编号本地表** `models/semester_table.dart`：63 条常量，锚点 `409=2026-2027-1`，
  步进 +20/学期外推；`currentSemesterId`（按日期）、`byId`、`labelFor`、`allAsMaps`。
- **全局学期切换** `semester_vm.dart`：选择 > 网络校正 > 本地推算；切换即失效课表。
- **离线内核审计**（冻结期）：修 `_restore` cookie 判定、charset 嗅探、HTML SAX 提速、
  eams_api 会话级缓存、正则提 top-level；`_uri` 用"合并而非替换"query 等。
- **验证**：test/ 8 文件全部通过；`kernel_check.dart`（AES 向量、表格 golden、域 golden）PASS
  （golden 采样已持续比对 Python，结果逐字符一致）。

### ⑤ 正式 UI 全量落地（已完成，2026-09-11）

- **信息架构**：放弃底部 TabBar，改为 **iOS 单栈**——课表即首页（常驻），其余能力经
  『更多』中枢（hub_page）与『账户』页（account_page）下钻；设计基准见
  [design-spec.md](design-spec.md)。
- **业务页面全量落地**（Cupertino 风格）：选课（轮次→课程列表→选/退，跨接口编排余量合并、
  myElect 本地记录 + 课表课程号交叉判定"已选"、多标签筛选 + SliverList.builder 懒加载）、
  考试（批次/安排/四六级/中期考核）、成绩（表格 + 全局学期联动）、培养计划、学籍、
  欢迎公告、消息、教学评价、账号簿多账号管理（accounts_page）。
- **国际化** `lib/l10n/app_strings.dart`：简体中文 / 繁體中文 / English / 日本語 / اردو
  共 5 语言，`context.l10n` 全量替换硬编码文案。
- **主题** `lib/l10n/app_theme.dart`：跟随系统 / 亮色 / 暗色 / 护眼四模式；
  `AppPalette` 语义色板经 `AppThemeScope` 下发，页面统一 `AppThemeScope.of(context)` 取色。
- **语言/主题持久化** `lib/l10n/app_settings.dart`：LocalCache ns=`meta` 落盘，启动恢复。
- **密码安全存储**：账号簿密码迁至 `flutter_secure_storage`（Keychain / Android Keystore），
  不再 base64 落盘；LocalCache 仅存账号簿元数据。
- **工程期调试能力移除**：api_explorer_vm / cache_vm / cache_page / more_page / kit.dart 删除，
  由正式页面 + `cupertino_kit.dart` 共享组件取代。
- **修复**：Cupertino 图标方框（补 `cupertino_icons` 正文字体依赖）；成绩页 Table 渲染断言
  `_elements.contains(element): is not true`（空表头兜底 + `KeyedSubtree` 稳定 key 整表重建）。
- **选课实现核对**：对照 `assets/教务系统抓包.har` 与 `grabber/api/elective.py` 逐参数核对，
  Dart 端轮次/上下文/课程/余量/选退接口与抓包链路一致（无需修改内核）。

## 3. 质量验证现状

| 项 | 结果 |
|---|---|
| `dart analyze` | 零 issues（官方 SDK 下） |
| test/（8 文件） | 全部通过 |
| 内核 golden（AES/表格/域） | PASS（与 Python 逐字符一致） |
| 短信全链路实网 | 通过（send/check/resume，check 阶段从落盘恢复会话） |
| 选课实现与抓包核对 | 一致（HAR vs `grabber/api/elective.py` vs Dart eams_api） |

## 4. 环境约束备忘（重要）

- 分析/测试/**构建必须用官方 SDK** `/Users/lin/develop/flutter/bin/flutter`
  （PATH 里的是鸿蒙 SDK，Dart 3.9.2，解析不了本项目 pubspec）。
- 官方 SDK 当前：Flutter 3.44.1 / Dart 3.12.1。

## 5. 待办 / 后续方向

- ~~密码存储升级为安全存储~~（⑤已完成：`flutter_secure_storage`）。
- ~~正式 UI 重写 / API 调试页替换~~（⑤已完成：见 [design-spec.md](design-spec.md)）。
- 线上补推/产物打包（参见仓库 README 打包命令，按需更新到官方 SDK）。
- Android/iOS 平台目录、原生插件 namespace（AGP 9 约束）在重建模板后需回归验证。
- UI 打磨延续：动画细节、平板/大屏适配、RTL（乌尔都语）布局复查。
- 长尾能力（如有需要）：学期列表网络校正入口下沉、缓存管理页可视化回归。