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

## 3. 质量验证现状

| 项 | 结果 |
|---|---|
| `dart analyze` | 零 issues（官方 SDK 下） |
| test/（8 文件） | 全部通过 |
| 内核 golden（AES/表格/域） | PASS（与 Python 逐字符一致） |
| 短信全链路实网 | 通过（send/check/resume，check 阶段从落盘恢复会话） |

## 4. 环境约束备忘（重要）

- 分析/测试/**构建必须用官方 SDK** `/Users/lin/develop/flutter/bin/flutter`
  （PATH 里的是鸿蒙 SDK，Dart 3.9.2，解析不了本项目 pubspec）。
- 官方 SDK 当前：Flutter 3.44.1 / Dart 3.12.1。

## 5. 待办 / 后续方向

- 密码存储升级为安全存储（正式版）：`flutter_secure_storage` / Keychain / Android Keystore，
  当前账号簿密码 base64 存应用目录仅为工程期实现。
- 正式 UI 重写：`apiExplorerProvider`/`api_explorer_vm.dart` 为工程期调试能力，可整体替换/删除，
  不影响内核。
- 线上补推/产物打包（参见仓库 README 打包命令，按需更新到官方 SDK）。
- Android/iOS 平台目录、原生插件 namespace（AGP 9 约束）在重建模板后需回归验证。
- 更多业务页面（成绩/考试/培养计划/选课/学籍等）落地为正式 UI，当前以"更多页 API 调试"呈现。