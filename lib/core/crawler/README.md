# 爬虫内核（lib/core/crawler）函数签名文档

Python 爬虫草稿（`grabber/`）的纯 Dart 翻译。零第三方依赖（仅 `dart:io`/`dart:convert`/`dart:math`/`dart:typed_data`/`dart:async`），
业务数据全部为原生 `Map<String, Object?>` / `List`（与 Python dict/list 输出 1:1，已过 golden 逐字段比对）。

## 目录结构（模型 / 解析清洗器 / 爬虫 / cookie&token&会话鉴权）

```text
lib/core/crawler/
├── crawler_exceptions.dart        异常体系（sealed，层级见下）
├── models/
│   ├── config_models.dart         GrabberConfig（全局配置）+ CrawlerCredentials（凭据）
│   └── data_models.dart           全部返回结构的 typedef 形状约定（原生 Map/List）
├── crypto/
│   ├── aes_cbc.dart               纯 Dart AES-128-CBC（FIPS-197/SP800-38A 向量验证）
│   └── cas_crypto.dart            CAS 密码加密（encrypt.js 1:1）+ randomString/randomHex
├── session/
│   ├── cookie_jar.dart            CookieJar：RFC6265 域/路径作用域 + 过期 + JSON 持久化
│   ├── http_client.dart           SessionHttpClient：dart:io 手动逐跳重定向 + Set-Cookie 摄取
│   ├── state_store.dart           SessionStateStore 接口（File 原子写 / Memory 两实现）
│   ├── step1_cas.dart             第①步 CAS 统一身份认证（SSO 优先 / 密码 AES）
│   ├── step2_portal.dart          第②步 aTrust 门户会话（sid + csrfToken + authCheck）
│   ├── step3_app.dart             第③步 教务应用授权（sdp_user_token + verify JWT 自愈）
│   └── crawler_session.dart       CrawlerSession：生命周期编排（本内核唯一入口）
├── parsers/
│   ├── html_sax.dart              SAX 式 HTML 解析器（纯 Dart，容错）
│   ├── clean.dart                 cleanWs/stripAll/stripTags/toNum/weekParse/splitBefore…
│   ├── js_literal.dart            splitJsArgs/extractBalanced/jsLiteralToDart（JS 字面量→原生对象）
│   ├── table_miner.dart           parseTables/pickTable/tableRecords/kvTables（表格挖掘）
│   ├── timetable_parser.dart      parseCourseHtml/parseCourseTableIds
│   ├── grade_parser.dart          parseGradesHtml
│   ├── exam_parser.dart           parseExamHtml/parseOtherExamsHtml/parseExamBatchesHtml
│   ├── plan_parser.dart           parsePlanCompletionHtml/parsePlanTablesHtml/parseStdApplyHtml
│   ├── elective_parser.dart       parseProfilesHtml/parseElectiveContextHtml/parseLessonsHtml/
│   │                              parseCountsHtml/parseOperateResultHtml
│   └── misc_parser.dart           parseStdDetailHtml/parseMessagesHtml/parseWelcomeHtml/
│                                  parseSemestersHtml/parseMidtermHtml/parseEvaluateHtml
└── api/
    └── eams_api.dart              第④步 EamsApi：全部教务接口 + RawSink（原始响应留存）
```

---

## 1. 生命周期（状态机）

```text
构造 CrawlerSession
   │
   ▼
loadState()                     ← 恢复持久化 cookie + extra（幂等，ensureApi 自动调用）
   │
   ▼
ensureApi() ──── 缓存新鲜？(app_at 距今 < sessionTtl 且有 JSESSIONID)
   │  ├─ 是 ──────────────► 直接返回 EamsApi（零网络请求）
   │  └─ 否 ─► ①CAS登录 ─► ②门户会话 ─► ③应用授权 ─► EamsApi
   │            (每步成功后 saveState() 持久化)
   │
   ▼
EamsApi.*() 业务调用
   │
   ├─ SessionLost ──► withApi 自动重建（最多 maxRebuilds 次）或手动再 ensureApi()
   ├─ CredentialError / NeedCaptchaError ──► 禁止自动重试，须人工干预
   │
   ▼
reset()（登出/换号：清 cookie + 状态）  dispose()（Riverpod onDispose：关连接）
```

防封号硬约束：
- 每个 `CrawlerSession` 实例最多 1 次密码登录 POST（`maxLoginPostsPerRun`），失败立即终止；
- CASTGC（14 天）有效期内全部走 SSO 免密，不消耗登录次数；
- `CredentialError`/`NeedCaptchaError` 绝不自动重试。

---

## 2. Riverpod 对接（推荐姿势）

```dart
final crawlerProvider = Provider<CrawlerSession>((ref) {
  final s = CrawlerSession(
    config: const GrabberConfig(),            // 默认值即抓包实测，可覆写
    credentials: CrawlerCredentials(username: '...', password: '...'),
    stateStore: FileSessionStateStore('$appDocDir/crawler_state.json'),
    onLog: (msg) => debugPrint('[crawler] $msg'),   // 可选链路日志
  );
  ref.onDispose(s.dispose);
  return s;
});

// 业务调用（会话失效自动重建重试一次）
final grades = await ref.read(crawlerProvider).withApi(
    (api) => api.grades(349));
```

---

## 3. 输入模型（config_models.dart）

```dart
class GrabberConfig {
  const GrabberConfig({
    this.casBase,      // String：CAS 统一身份认证域名
    this.portalBase,   // String：aTrust 门户域名
    this.eamsBase,     // String：教务系统网关代理域名
    this.sdpAppCode,   // String：教务应用静态标识
    this.unitId,       // String：租户 id
    this.userAgent,    // String：UA（伪装 SDP 内置浏览器）
    this.acceptLanguage,
    this.timeout = 20,          // int 秒：单请求超时
    this.maxHops = 24,          // int：单链路最大重定向跳数
    this.getRetries = 2,        // int：GET 网络错误重试（POST 永不重试）
    this.sessionTtl = 720,      // int 秒：会话缓存新鲜期（实测 15min，留余量）
    this.maxLoginPostsPerRun = 1, // int：防封号硬约束
  });
  String get casService;          // CAS service 回跳地址
  Map<String, String> get clientQuery; // 门户 API 公共 query
  String get appEntry;            // 教务授权入口
  String get appEntryWithParams;  // 带静态标识的授权入口
  String get portalHost / eamsHost;
}

class CrawlerCredentials {
  const CrawlerCredentials({required this.username, required this.password});
  // password 仅在第①步内存中使用，绝不持久化
}
```

---

## 4. CrawlerSession（会话生命周期管理）

```dart
CrawlerSession({
  required GrabberConfig config,
  required CrawlerCredentials credentials,
  SessionStateStore? stateStore,              // null → MemorySessionStateStore
  void Function(String message)? onLog,       // 可选链路日志回调
})

Future<EamsApi> ensureApi({bool forceRelogin = false})
// 输入：forceRelogin=true 跳过缓存强制重走链路
// 输出：第④步 API 对象（缓存复用时零网络请求）
// 抛出：CasError/NeedCaptchaError/CredentialError/PortalError/AppAuthError/HttpError

Future<T> withApi<T>(Future<T> Function(EamsApi api) action, {int maxRebuilds = 2})
// 输入：以 api 为参的异步闭包
// 输出：闭包返回值；SessionLost 时自动重建链路重试（超上限 rethrow）

Future<void> loadState()      // 恢复持久化状态（幂等）
Future<void> saveState()      // 持久化 cookie + extra（原子写）
Future<void> reset()          // 登出/换号：清 cookie/内存/持久化状态
void dispose()                // 释放连接（Riverpod onDispose）
bool hasCookie(String name, {String? domainSuffix})
Map<String, Object?> extra    // 附加状态：device_id/cas_at/portal_at/app_at/display_name
```

---

## 5. 四步鉴权（内部步骤类，均由 ensureApi 编排）

| 步骤 | 类 | 关键方法 | 产出 |
|---|---|---|---|
| ① CAS 统一身份认证 | `Step1Cas` | `Future<CasLoginResult> login()` | 带 `ticket=ST-xxx` 的回跳 URL（SSO 优先，免密） |
| ② aTrust 门户会话 | `Step2Portal` | `Future<PortalInfo> establish(String casRedirectUrl, String deviceId)` | sid/online cookie + `username/displayName` |
| ③ 教务应用授权 | `Step3App` | `Future<void> enter()` | JSESSIONID/GSESSIONID + sdp_user_token |
| ④ API 接口封装 | `EamsApi` | 见下文全部方法 | 结构化原生 Map/List |

### 短信二次认证（网关风控，2026-09 实测补充）

同账号高频登录等风险场景下，authCheck 会以 [NeedSecondaryAuthError] 拒绝
（`type:enhanced` + `nextService:auth/sms`）。此时在**同一会话**上：

```dart
try {
  await session.ensureApi(forceRelogin: true);
} on NeedSecondaryAuthError {
  // 风控：发短信 → 用户输码 → 提交（可循环重试验证码，不消耗登录 POST 次数）
  final challenge = await session.startSmsVerification();
  // challenge.maskedPhone = '193****0952', challenge.intervalSeconds = 60
  final api = await session.completeSmsVerification(userInputCode);
}
```

端点（已实网验证）：`GET /passport/v1/auth/sms?action=sendsms`（附 taskId/authId）
→ `POST /passport/v1/auth/sms?action=checkcode`（form `code=…`）→ authCheck 复查在线。
认证记忆绑定"存活的门户会话"：新 sid 会重新评估策略，故认证后的 cookie 必须
落盘复用（`CrawlerSession` 已内置）。

底层基础设施：

```dart
// session/http_client.dart
class SessionHttpClient {
  Future<HttpTextResponse> get(Uri url, {Map<String, String>? headers});   // GET 有限重试
  Future<HttpTextResponse> post(Uri url, {headers, form, json});           // POST 永不重试
  Future<HttpTextResponse> follow(HttpTextResponse resp, {onHop, maxHops}); // 手动逐跳 3xx
  final CookieJar cookies;   // RFC6265 域/路径作用域 + 过期 + JSON 序列化
  void close();
}

// session/cookie_jar.dart
class CookieJar {
  void ingest(String requestHost, List<String> setCookieHeaders); // 摄取 Set-Cookie
  String? headerFor(Uri uri);            // 按作用域计算 Cookie 请求头
  void set(String name, String value, {required String domain, String path = '/'});
  bool has(String name, {String? domainSuffix});
  String? value(String name, {String? domainSuffix});
  void delete(String name, {String? domain});  void clear();
  List<Map<String, Object?>> toJson();   void loadJson(List<Object?> json);
}

// session/state_store.dart
abstract class SessionStateStore {
  Future<Map<String, Object?>?> load();   // 缺失/损坏返回 null → 走全链路登录
  Future<void> save(Map<String, Object?> state);  // {saved_at, cookies, extra}
  Future<void> clear();
}
class FileSessionStateStore implements SessionStateStore {...}  // tmp+rename 原子写
class MemorySessionStateStore implements SessionStateStore {...}
```

---

## 6. EamsApi（第④步接口签名全集）

构造：`EamsApi({required SessionHttpClient http, required GrabberConfig config, RawSink? rawSink})`
——由 `CrawlerSession.ensureApi()` 产出，勿自行构造。`rawSink` 留存原始响应
（`DirectoryRawSink(dir)` 写文件 / `MemoryRawSink({capacity})` 内存 / null 生产默认）。

所有方法：会话失效抛 `SessionLost`（用 `withApi` 自动重建）；URP 过频保护自动等待 2.5s 重试一次。

### 杂项

```dart
Future<WelcomeResult> welcome()
// → {modules: [{name, content}], welcome_text, file}

Future<StdDetailResult> stdDetail()
// → {sections: [{section, kv}], photo, kv, file}（学籍/联系/家庭多段 KV + 照片 URL）

Future<SemestersResult> semesters()
// → {semesters: [{id, schoolYear, name, label}], current: int?, year_index}
// ⚠ 内部会先 GET courseTableForStd 预热 dataQuery 组件（2026-09 实测：
//   未预热时服务端返回空表 {yearDom:"",semesters:{},semesterId:""}）

Future<JsonMap> setSemester(int semesterId)
// → {semester_id, ok: bool}（写 cookie semester.id，等价页面学期条切换）

Future<MessagesResult> messages()
// → {records: [{发件人, 主题, 时间, _links?}], count, file}

Future<EvaluateResult> evaluate({int? semesterId})
// → {records, count, file}（教学评价任务列表）
```

### 课表

```dart
Future<CourseTableResult> courseTable({String kind = 'std', int? semesterId, String? startWeek})
// 输入：kind='std'|'class'；semesterId 如 409（null=服务器默认）；startWeek 如 '5'（null=全部）
// 输出：{kind, ids, semester_id, start_week, file,
//        unit_count: int?, table_meta, course_count: int,
//        courses: [CourseRecord], merged: [MergedCourse]}
// CourseRecord：teachers/teacher_names/act_teachers/assistant/task_no/course_code/clazz/
//   name/name_raw/course_code2/room_id/room/day/day_name/unit/weeks{raw,digest,list,count,total}/
//   flag/params_raw —— 全字段捕获，形状见 data_models.dart
```

### 成绩

```dart
Future<GradesResult> grades(int semesterId)
// → {semester_id, headers: [String], records: [{列名→值, 学分/绩点等自动数值化}],
//     count, rows: [[String]], file}
```

### 考试

```dart
Future<List<ExamBatch>> examBatches()
// → [{id: int, name, selected: bool}]（含补考批次）

Future<ExamTableResult> examTable(int batchId)
// → {batch_id, headers, records: [{课程/日期/时段/考场/座位号…, exam_room_id?, _links?}], count, file}

Future<OtherExamsResult> otherExams()
// → {signups: [记录], scores: [记录], signup_count, score_count, file}（四六级等）

Future<MidtermResult> midterm({int? semesterId})
// → {message, text, file}（研究生中期考核，页面文本前 500 字）
```

### 培养计划

```dart
Future<PlanCompletionResult> planCompletion()
// → {summary: KV, sections: [{group, summary, records}], records: 平铺, count, file}

Future<PlanByMajorResult> planByMajor()
// → {tables: [{class, title, headers, header_rows, records}], file}

Future<MajorPlanResult> majorPlan()
// → {tables, file} 或 {error, file}（部分账号无权限）

Future<StdApplyResult> stdApply()
// → {message, menus: [{text, href}], text, file}（转专业申请页）
```

### 选课

```dart
Future<List<ElectiveProfile>> electiveProfiles()
// → [{id, name, round: int?, elect_open, withdraw_open, limits: [String], notice, link}]

Future<ElectiveContext> electiveContext(int profileId)
// → {profile_id, project_id, semester_id: int?}

Future<List<ElectiveLesson>> electiveLessons(int profileId)
// → lessonJSONs 课程列表（id/name/credits/teachers/campusName/… 全字段）

Future<ElectiveCounts> electiveCounts({int projectId = 1, int? semesterId})
// → {lessonId字符串: {sc: 已选, lc: 上限}}

Future<ElectiveOperateResult> electiveOperate({required int profileId, required int lessonId, required bool elect})
// ⚠ 写操作（elect=true 选课 / false 退课），调用方需自行确认
// → {success: bool, message, lesson_id}
```

---

## 7. 异常体系（crawler_exceptions.dart）

```text
CrawlerException                内核基础异常（message 可直接展示用户）
├── HttpError                   网络层/链路层错误（连接失败、超时、跳数超限）
├── CasError                    ① CAS 失败
│   ├── NeedCaptchaError        需要验证码（主动放弃，不硬闯）
│   └── CredentialError         凭据被拒 —— 严禁自动重试（防账号锁定）
├── PortalError                 ② aTrust 门户失败
│   └── NeedSecondaryAuthError  网关风控要求二次认证（短信等，绝不自动重试）
├── AppAuthError                ③ 应用授权失败
└── SessionLost                 ④ 会话失效 —— 可重建后重试（withApi 自动处理）
```

UI 层处理建议：`SessionLost` → 静默重建；`CredentialError`/`NeedCaptchaError` → 提示用户；
`HttpError` → 提示网络问题可手动重试；其余 → 展示 message。

---

## 8. 数据约定

- 全部返回值为原生 `Map<String, Object?>` / `List`，值类型 `String/int/double/bool/null`，
  可直接 `jsonEncode` 持久化（Riverpod 层无需转换）。
- 每个返回结构在 `models/data_models.dart` 有 typedef 形状注释（CourseRecord、GradeRecord、
  ExamBatch、ElectiveProfile…），IDE 悬停即可见字段说明。
- 强类型类仅两处（输入端）：`GrabberConfig` / `CrawlerCredentials`，编译期约束 UI 注入。

## 9. 离线自检（开发期）

```bash
# AES 向量 + pycryptodome 交叉验证
/Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart
# 表格解析 golden（20 样本 vs Python）
/Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart golden
# 域解析器 golden（22 键 vs Python；先 python3 /tmp/gen_domain_golden.py）
/Users/lin/develop/flutter/bin/dart run tool/kernel_check.dart domain
```

三项当前全部 PASS（解析输出与 Python 逐字符一致）。
