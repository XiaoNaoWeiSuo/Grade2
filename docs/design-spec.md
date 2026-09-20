# 正式 UI 设计规格（design-spec）

> 目标：以 **Cupertino（iOS 原生）风格**完整封装爬虫内核全部能力，
> 按"课表常驻 + 窗期高频 + 低频查询"的使用模型组织信息架构。
> 本文档是正式 UI 重写阶段的**唯一设计基准**；与 [architect.md](architect.md)/
> [handoff.md](handoff.md)/[dev-guidelines.md](dev-guidelines.md) 配套。

## 0. 一句话定位

课表是**常驻主界面**；选课/考试仅在窗期数天内高频，历史成绩/计划/消息等为偶发低频。
故**不采用底部 TabBar**，改为 **iOS 单栈**：课表即首页，其余能力经『更多』中枢与『账户』下钻。

## 1. 设计原则

- **Cupertino 原生质感**：`CupertinoApp`、`CupertinoPageScaffold`、`CupertinoSliverNavigationBar`、
  `CupertinoListSection`、`CupertinoTextField`、`CupertinoButton`；页面下钻用 `CupertinoPageRoute`。
- **完整封装内核**：杂项/课表/成绩/考试/培养计划/选课全部落页；跨接口联动在 **viewmodel 层编排**。
- **缓存优先 + 离线可用**：只读数据 Cache-first，离线可渲染；写操作严格联网 + 二次确认。
- **防封号红线不变**：会话失效静默重建；凭据/风控/验证码错误永不自动重试；每会话 1 次密码 POST。
- **工程期调试能力全部移除**（见 §8），内核与学期/课表 VM 保留不动。

## 2. 全局导航 IA（无底部栏）

```text
根路由 = 课表(CupertinoPageScaffold，常驻；进其他页压栈，返回不丢滚动/周状态)
   │
   ├─ 点击课程格 ──────────► 课程详情（下钻）
   ├─ 点导航栏标题[当前学期] ─► 学期切换弹层
   ├─ leading 头像 ────────► 【账户】页
   │                          ├ 账号信息(学号/显示名/离线态)
   │                          ├ 学期网络同步(校正 semesterSelection)
   │                          ├ 清除缓存 / 关于
   │                          └ 登出
   └─ trailing「更多/┅」──── ► 【功能中枢】页（全部业务模块）
```

## 3. 功能中枢（『更多』页）

CupertinoListSection 分组（与使用频率/性质对齐）：

| 分组 | 条目 | 下钻 |
|---|---|---|
| 窗期高频 | 选课 | 轮次 → 课程+余量 → 选/退（§5.1） |
| 窗期高频 | 考试 | 批次 → 安排；四六级、中期考核（§5.2） |
| 数据查询 | 成绩 | 表格 + 全局学期联动（§5.3） |
| 数据查询 | 培养计划 | 完成度 → 我的计划 / 培养方案 / 转专业（§5.4） |
| 数据查询 | 学籍 | 分段 KV + 头像 |
| 事务 | 消息 | 系统消息列表 |
| 事务 | 教学评价 | 评价任务列表 |

每项进入即压栈；数据页统一数据生命周期（§6.3）。

## 4. 账户页

- 账号信息：显示名、学号/工号、离线状态徽标。
- 学期网络同步：调 `semesterSelectionProvider.refreshFromNetwork()`（权威校正，写回 meta 缓存）。
- 清除本地缓存：LocalCache 清理（课表/成绩等重建）。
- 关于：版本/平台标识。
- 登出：二次确认 → `authProvider.logout()`（清会话令牌，保留账号簿）。

（P2 可选：账号簿多账号管理入口 + 密码存储升级 flutter_secure_storage。）

## 5. 各模块交互与跨接口联动

### 5.1 选课（核心跨接口编排，viewmodel 串联）
```text
electiveProfiles() ─► 轮次列表(卡片: 期数/开/退状态/限额/公告，仅 开/退 可操作)
   └─ 进入一轮次
       ├─ electiveContext(id)       → project_id + semester_id
       ├─ electiveLessons(id)       → 课程列表(名称/学分/教师/校区)
       ├─ electiveCounts(proj,sem)  → 每课 {sc已选,lc上限} → 余量徽标(满员置灰)
       └─ 操作: electiveOperate(id, lesson, elect)
            ├─ Elect=true  选课  ⚠二次确认
            ├─ Elect=false 退课  ⚠二次确认(danger 强调)
            └─ 成功后: 重建 Counts+Lessons 刷新余量
```
- `counts` 键为 lessonId 字符串，需与 `lessons[].id` 对齐；失败恢复按钮态并展示 `message`。

### 5.2 考试
```text
examBatches() → 批次(正考/补考 分段) → examTable(bid) → 安排列表(课程/时间/考场/座位)
otherExams()  → 四六级 报名+成绩 两段
midterm()     → 中期考核文本
```

### 5.3 成绩 × 全局学期
```text
成绩页 ─(读 semesterSelection)─► grades(semesterId) ─► 表格(headers+records)
                                   缓存: grades/grades_<semesterId>
页内学期切换器 / 复用全局学期弹层，切换即重取
```

### 5.4 培养计划 / 学籍 / 消息 / 评价
- 培养计划：`planCompletion`（完成度摘要+分组）→ `planByMajor` / `majorPlan`（无权限提示）/ `stdApply`。
- 学籍：`stdDetail` → sections 分段 KV + 头像。
- 消息：`messages` 列表；评价：`evaluate` 任务列表。

## 6. 全局生命周期

### 6.1 认证状态机（复用 `authProvider`，Cupertino 呈现）
```text
boot ─(loadState+ensureApi)─►
  ├─ SSO 在线(cookie 存活)        ─► authed
  ├─ 无凭据且无 cookie            ─► needsLogin
  ├─ CredentialError/NeedCaptcha  ─► needsLogin(展示错误,不重试)
  ├─ NeedSecondaryAuthError(风控) ─► needsSms(输码) ─► authed
  └─ 纯网络失败但有历史会话       ─► authed + offline(只读可用,写禁用)
```

### 6.2 会话失效
业务调用走 `withApi`；`SessionLost` 自动重建（≤2 次）。UI 无感。

### 6.3 页面数据生命周期（统一范式）
```
首次: loading ─► 数据 | 空态 | 错误态(带重试)
再次: Cache-first 即时渲染 → CupertinoSliverRefreshControl 下拉刷新 → 写缓存
写缓存前剔除 file/敏感字段；不落令牌。
```

## 7. 功能基准与优先级

**P0（首版必须）**
- Cupertino 骨架 + 课表即首页；学期/周翻页/课程详情
- 『账户』页（账号信息/学期同步/清除缓存/登出）
- 『更多』中枢页
- 成绩（表格 + 学期联动）
- 选课全流程（§5.1）
- 认证/短信/SSO/离线降级（复用，改呈现）

**P1**
- 考试（批次+安排+四六级+中期）
- 培养计划（4 项）
- 消息、教学评价

**P2（可延后）**
- 账号簿多账号管理；密码存储升级 secure_storage

## 8. 工程期移除清单（正式 UI 落地时删除）

| 文件/能力 | 处理 |
|---|---|
| `lib/viewmodels/api_explorer_vm.dart` | 删除 |
| `lib/viewmodels/cache_vm.dart` | 删除 |
| `lib/views/pages/cache_page.dart`、`more_page.dart` | 删除（more 职责由『中枢』替代） |
| `home_page.dart` 三 Tab 骨架 | 重写为课表根页 |

**保留不动**：`lib/core/crawler/`（23 文件）、`local_cache.dart`、`auth_vm.dart`、
`timetable_vm.dart`、`semester_vm.dart`、`providers.dart`、`semester_table.dart`。

## 9. 验证

- 每模块：`/Users/lin/develop/flutter/bin/flutter analyze` + `flutter test` 零新增问题。
- 内核未动则 golden 无需重跑；改动内核前跑 `tool/kernel_check.dart` golden/domain。
- 构建/分析只用官方 SDK（见 handoff §4）。