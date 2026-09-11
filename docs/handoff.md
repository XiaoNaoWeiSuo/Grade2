# 交接文档（handoff）

> 供后续开发者/维护者在接手时快速上手：环境、结构速览、运行与验证、常见陷阱、可替换项。

## 1. 先读这几份

按顺序：
1. [architect.md](architect.md) —— 架构、分层、平台标识、环境要求
2. [lib/core/crawler/README.md](../lib/core/crawler/README.md) —— 内核函数签名全集
3. [dev-guidelines.md](dev-guidelines.md) —— 开发规范与已踩坑清单
4. [process.md](process.md) —— 进度与后续方向

## 2. 环境准备（第一步必做）

```bash
# 确认用官方 SDK，而不是 PATH 里的鸿蒙 SDK
/Users/lin/develop/flutter/bin/flutter --version   # Flutter 3.44.1 / Dart 3.12.1
/Users/lin/develop/flutter/bin/flutter pub get
```

> ⚠ HTTP 环境变量若指向内部服务，联网实网脚本可能失败；确认 `HTTP(S)_PROXY`。
> 本机统一用 `flutter-switch official|harmony` 切换官方/鸿蒙 SDK，**写入构建命令前先确认**。

## 3. 项目井字图一眼见

```text
Grade2/
├── lib/
│   ├── main.dart              入口 / 路由
│   ├── core/
│   │   ├── crawler/           爬虫内核（23 文件，零依赖，已冻结）
│   │   └── storage/local_cache.dart  业务 KV 缓存
│   ├── viewmodels/            Riverpod 状态层（组装根在 providers.dart）
│   └── views/                 UI（可整体替换）
├── grabber/                   Python 原版爬虫（参考 & golden 基准）
├── test/                      8 个单测文件
├── tool/                      实网验证/诊断脚本（dart run）
└── docs/                      本目录文档
```

## 4. 运行与验证

```bash
# 单元测试（离线）
/Users/lin/develop/flutter/bin/flutter test

# 静态分析
/Users/lin/develop/flutter/bin/flutter analyze

# 内核自检（AES 向量 / 表格 golden / 域 golden，需先 python3 /tmp/gen_domain_golden.py）
/Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart
/Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart golden
/Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart domain

# 实网验证入口（登录/API 冒烟/学期/短信，需真实账号与手机号）
/Users/lin/develop/flutter/bin/dart run tool/login_diag.dart
/Users/lin/develop/flutter/bin/dart run tool/api_smoke.dart
/Users/lin/develop/flutter/bin/dart run tool/sms_flow_dart.dart send    # 短信全流程
/Users/lin/develop/flutter/bin/dart run tool/dart_sms_smoke.dart

# 打 Debug APK（需 JAVA_HOME=Android Studio jbr）
flutter-switch official
JAVA_HOME=<Android Studio>/jbr /Users/lin/develop/flutter/bin/flutter build apk --debug
```

## 5. 核心工作流速览

### 加一个业务调用
1. 读 [models/data_models.dart](../lib/core/crawler/models/data_models.dart) 确认返回形状；
   若内核无对应方法，需先在 `eams_api.dart` 加方法 + 解析器 + 单测（这是核心改动，需谨慎）。
2. 在 viewmodel 用静态类型会话调 `session.withApi((api) => api.xxx(...))`；
3. 结果写 LocalCache（缓存优先），页面绑定 Provider。

### 处理会话失效 / 风控
- `SessionLost` → `withApi` 已自动重建，业务无需处理；
- `CredentialError`/`NeedCaptchaError`/`NeedSecondaryAuthError` → 提示用户，**永不自动重试**。

### 新增缓存命名空间
在 [local_cache.dart](../lib/core/storage/local_cache.dart) 约定范围内新增 `<ns>`，
路径由组装层注入，VM 不直接拼路径。

## 6. 已知陷阱与红线（务必先看开发规范）

- **禁止 dynamic 接收者调 `withApi`**：会话参数必须静态类型 `CrawlerSession`，
  否则闭包被推断 `(dynamic)→dynamic`，运行时签名检查失败（曾致 App 端课表全挂）。
- **构建/分析只用官方 SDK**；直接 `./gradlew` 前设 `JAVA_HOME` 为 Android Studio jbr。
- **IDE 缓冲区回退陷阱**：IDE 打开过的文件（pubspec.yaml、gradle.kts、pbxproj 等）
  外部编辑后可能被旧缓冲区写回。对策：外部大改后用 `python3` 原子写入 + 该命令内立即 grep 验证。
- **防封号红线**：每会话最多 1 次密码 POST；SSO 期内全走免密；凭据被拒不重试；
  短信二次认证绝不自动重试。
- **敏感文件**：`assets/*.har` 含抓包 token/cookie，已 gitignore，**勿重新提交**。
  `lib/core/config/app_secrets.dart` 为本地密钥占位（勿泄露）。

## 7. 可整体替换 / 临时项

| 项 | 性质 | 说明 |
|---|---|---|
| `api_explorer_vm.dart` + more_page API 调试 | 工程期调试 | 正式 UI 落地后可删除 |
| 账号簿密码 base64 存储 | 工程期 | 正式版换 secure storage |
| `grabber/` Python 源 | 参考基准 | 保留作 golden 与行为参照 |
| `tool/*.dart` 实网脚本 | 开发验证 | 保留作回归入口 |

## 8. 常见问题（FAQ）

- **Q：进不了登录/报"启动失败"？**
  A：确认 `ensureApi()` 抛错类型——纯网络异常且历史会话在会离线降级进入；
   凭据被拒/需验证码则回到登录页属正常。
- **Q：为什么构建要用 `/Users/lin/develop/flutter`？**
  A：PATH 里的 flutter 是鸿蒙 SDK（Dart 3.9.2），不支持本项目 pubspec（需 Dart ≥3.11）。
- **Q：课表/成绩缓存从哪来？**
  A：LocalCache `timetable/table_std_<semesterId>` 与 `meta/current_semester`；
   离线/未登录仍可渲染（缓存优先）。
- **Q：改了内核代码后怎么验证？**
  A：`flutter test` + `kernel_check.dart`（golden 比对 Python），任何保真偏差都要先回归。