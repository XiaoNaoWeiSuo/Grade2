# 开发规范（dev-guidelines）

> 约定分层、命名、错误处理与**已踩坑清单**。新增/修改代码前必读。

## 1. 分层与依赖（架构红线）

- **单向依赖**：`views → viewmodels → core`，禁止反向引用、禁止跨层跳级。
- **core 零 Flutter 零第三方**：`lib/core/**` 不得 `import 'package:flutter/...'`，
  只能 import Dart 标准库与其他 core 文件。违反即破坏内核可复用性。
- **viewmodels 不 new 内核对象**：一律从 [providers.dart](../lib/viewmodels/providers.dart)
  组装根读取 Provider；路径（path_provider）只在组装层定位并注入字符串。
- **业务数据原生化**：跨层传值用 `Map<String, Object?>`/`List`/`String`/`int`/`double`/`bool`/`null`，
  可直接 `jsonEncode`。强类型类仅限输入端（`GrabberConfig`/`CrawlerCredentials`）与 UI 展示 DTO。
- **会话只作静态类型接收**：任何使用 `CrawlerSession` 的参数/变量都必须是静态类型，
  **禁止用 `dynamic` 接收会话**（见陷阱 T1）。

## 2. 命名与目录

- 层目录固定：`core/`、`viewmodels/`、`views/`。
- Kernel 内核文件按模块归类：`models/`、`crypto/`、`session/`、`parsers/`、`api/`。
- ViewModel 文件后缀 `_vm.dart`；Provider 顶层定义于每个文件底部；根组装放 `providers.dart`。
- 常量命名 `_lowerCamel`；类 `PascalCase`；Provider 名通常以 Provider 结尾（`authProvider`）。
- 私有成员以 `_` 开头；文件顶部写 `library;` + 模块注释（职责/数据流/注意点，参见现有 VM）。

## 3. 认证与会话（防封号红线）

- 每个 `CrawlerSession` 实例最多 **1 次密码登录 POST**（`maxLoginPostsPerRun`）。
- CASTGC（14 天）有效期内全走 SSO 免密，**不消耗登录次数**。
- `CredentialError` / `NeedCaptchaError` / `NeedSecondaryAuthError` **绝不自动重试**，
  必须提示用户人工介入。
- 短信二次认证须在同一会话上进行，认证记忆绑定"存活的门户会话"；
  认证后的 cookie 必须落盘复用（`CrawlerSession` 已内置），新 sid 会重新触发风控。
- 启动恢复：必须先 `loadState()` 载入持久化 cookie 再判定（幂等）；勿在未载入时直接判"未记住密码"。

## 4. 异常处理

- 继承体系见 [crawler_exceptions.dart](../lib/core/crawler/parsers/../crawler_exceptions.dart)（sealed）。
- 捕获**具体异常类型**，生产路径不写 `catch (e)`（调试临时除外）。
- 网络 GET 有限重试、POST 永不重试（`http_client.dart` 已内置，勿在业务层加循环重试）。
- UI 呈现用 `e.message`（可读）；展示错误后复位状态，避免 UI 卡在 busy。
- 幂等操作（loadState、写缓存）收到 IO/格式异常应宽容处理（视为空），不崩状态机。

## 5. LocalCache 使用规范

- 命名空间按业务域划分（`auth`/`timetable`/`meta`…），一个 ns 一个文件。
- 会话令牌走 `FileSessionStateStore(crawler_state.json)`，**与业务缓存严格分离**。
- 写缓存前剔除不可序列化字段（如原始 `file` 路径）、不落敏感凭据。
- 缓存优先策略：读取在驱动网络前命中即渲染（离线可用）；`refresh()` 才强制在线。

## 6. 测试

- 新增解析器/加解密/会话逻辑必须有 `test/*_test.dart` 覆盖；改动内核后跑全量单元测试。
- 域名解析器/golden 基准以 `grabber/`（Python）为对照，改动后跑 `kernel_check.dart` 的
  golden/domain 比对，**任何保真偏差先定位**。
- 公用 golden 采样脚本在 /tmp（如 `/tmp/gen_domain_golden.py`），改动采样需同步。

## 7. 已踩坑清单（新坑请回填）

- **T1 dynamic 调泛型 `withApi`**：`dynamic session.withApi((api)=>…)` 闭包推断为
  `(dynamic)→dynamic`，运行时签名检查失败（`type '(dynamic) => dynamic' is not a subtype of
  'Future<T> Function(EamsApi)'`），曾致 App 端课表全挂。→ 必须静态类型化会话。
- **T2 `'$config.portalBase$path'` 插值陷阱**：`$config` 后 `.portalBase` 被当字面量，
  产出 `Instance of 'GrabberConfig'.portalBase/...`。→ 多级成员用 `${config.portalBase}`。
- **T3 `Random.nextInt(n)` 上限 2^32**：`nextInt(9000000000)` 抛 RangeError。→ 大范围拆位生成。
- **T4 `on (A, B)` 是记录类型永不匹配**：Dart 无 catch 联合类型语法，会静默失效。
  → 用 `on Exception` 或分别 `on A`/`on B`。
- **T5 raw string 转义**：`r'\s'` 是字面反斜杠 + s；拼 `RegExp` 用普通字符串 `'\\s'`。
- **T6 顶层不能 `final` 修饰函数**。
- **T7 dataQuery 需预热**：未先 GET 一次含 semesterBar 的页面，`semesters()` 返回空表。
  → `semesters()`/`setSemester()` 已内置预热。
- **T8 sendsms `interval` 是字符串 "60" 非 int**：解析须宽容。
- **T9 `step2` 跨进程空指针**：`completeSmsVerification` 用 `_step2!` 会因重建为 null，
  → 用 step2 懒加载 getter。
- **T10 UUID/相对路径拼 `Uri` 替换 query 陷阱**：`Uri.replace(queryParameters:)` 整串替换，
  曾丢 `action=sendsms`。→ 用"合并而非替换"（见 `eams_api._uri`）。
- **T11 IDE 缓冲区回退**：IDE 打开过的文件外部编辑后被旧缓冲区写回。
  → 外部改后 `python3` 原子写入 + 同命令内 grep 验证。
- **T12 构建 SDK 混淆**：PATH 是鸿蒙 SDK（Dart 3.9.2）解析不了本项目。
  → 一律 `/Users/lin/develop/flutter/bin/flutter`。

## 8. 提交与安全

- **不提交敏感数据**：`assets/*.har`（抓包含 token/cookie）已进 `.gitignore`，勿重新 add；
  `lib/core/config/app_secrets.dart` 是本地密钥占位，勿泄露。
- 提交信息风格参考现有历史（简洁、中英皆可，聚焦"为什么"）。

## 9. 环境命令速查

```bash
export SDK=/Users/lin/develop/flutter/bin/flutter
$SDK pub get
$SDK test
$SDK analyze
$SDK dart run tool/kernel_check.dart            # golden 自检
flutter-switch official                          # 切换官方 SDK（构建前确认）
JAVA_HOME=<Android Studio>/jbr $SDK build apk --debug   # 直接 gradlew 时必设 JAVA_HOME
```