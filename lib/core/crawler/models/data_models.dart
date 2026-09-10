/// 爬虫内核数据模型（原生数据结构形状约定）。
///
/// 设计原则：业务数据一律使用原生 `Map<String, Object?>` / `List`，
/// 不引入强类型类——与 Python 版 dict/list 输出保持 1:1，
/// 便于 Riverpod 层直接 jsonEncode 持久化与调试打印。
///
/// 本文件通过 typedef + 文档注释固化每个返回结构的形状（模型层）。
/// 值类型约定：`String` / `int` / `double` / `bool` / `null` / 嵌套 Map/List。
library;

/// 通用 JSON 对象。
typedef JsonMap = Map<String, Object?>;

// ============================================================
// 课表（courseTable）
// ============================================================

/// 周次信息：`{raw, digest, list: [int], count: int, total: int}`。
/// - raw: 位串原文 '0111100…'
/// - digest: 摘要 '5-8,10'
typedef WeekInfo = JsonMap;

/// 教师：`{id: int, name: String, lab: bool}`。
typedef CourseTeacher = JsonMap;

/// 单个课程时段记录（parseCourseHtml 的 courses 元素）：
/// ```text
/// teachers: [CourseTeacher]         任课教师
/// teacher_names: String             实际授课教师名(逗号分隔)
/// act_teachers: [CourseTeacher]     实际授课教师
/// assistant: String                 助教
/// task_no: String                   教学班号
/// course_code: String               课程代码(教学班)
/// clazz: String                     教学班原文 '115251(752764)'
/// name: String                      课程名
/// name_raw: String                  课程名原文
/// course_code2: String              课程代码(课程名处)
/// room_id: String                   教室 id
/// room: String                      教室名
/// day: int?                         星期(1=周一…7=周日)
/// day_name: String?                 '周x'
/// unit: int?                        节次(1起)
/// weeks: WeekInfo                   周次
/// flag: String                      实验/实践课标记(第12参)
/// params_raw: [String]              TaskActivity 原始参数
/// ```
typedef CourseRecord = JsonMap;

/// 按课程名聚合（merged 元素）：
/// `{name, course_code, clazz, teachers, assistant, rooms: [String], times: [String], weeks: [String], units: int}`
typedef MergedCourse = JsonMap;

/// 课表结果（EamsApi.courseTable 返回）：
/// `{kind, ids, semester_id, start_week, file, unit_count, table_meta, course_count, courses: [CourseRecord], merged: [MergedCourse]}`
typedef CourseTableResult = JsonMap;

// ============================================================
// 成绩（grades）
// ============================================================

/// 成绩记录：列名 → 值（学分/绩点/成绩等自动数值化），
/// 常见键：`学年学期/课程代码/课程序号/课程名称/课程类别/学分/补考成绩/总评成绩/最终/绩点`。
typedef GradeRecord = JsonMap;

/// 成绩结果：`{semester_id, headers: [String], records: [GradeRecord], count, rows: [[String]], file}`。
typedef GradesResult = JsonMap;

// ============================================================
// 考试（exam）
// ============================================================

/// 考试批次：`{id: int, name: String, selected: bool}`。
typedef ExamBatch = JsonMap;

/// 考试安排记录：`{课程名称/考试时间/考场/座位号/…, exam_room_id?: int, _links?: [{col,href,text}]}`。
typedef ExamRecord = JsonMap;

/// 考试安排结果：`{batch_id, headers: [String], records: [ExamRecord], count, file}`。
typedef ExamTableResult = JsonMap;

/// 课外资格考试结果：`{signups: [JsonMap], scores: [JsonMap], signup_count, score_count, file}`。
typedef OtherExamsResult = JsonMap;

/// 中期考核结果：`{message, text, file}`。
typedef MidtermResult = JsonMap;

// ============================================================
// 培养计划（plan）
// ============================================================

/// 计划分组：`{group: String, summary: JsonMap, records: [JsonMap]}`。
typedef PlanSection = JsonMap;

/// 计划完成情况结果：
/// `{summary: JsonMap, sections: [PlanSection], records: [JsonMap], count, file}`。
typedef PlanCompletionResult = JsonMap;

/// 培养方案单表：`{class, title, headers: [String], header_rows: int, records: [JsonMap]}`。
typedef PlanTable = JsonMap;

/// 按专业培养计划结果：`{tables: [PlanTable], file}`。
typedef PlanByMajorResult = JsonMap;

/// 专业培养方案结果：`{tables: [PlanTable], file}` 或 `{error: String, file}`（无权限）。
typedef MajorPlanResult = JsonMap;

/// 转专业申请页结果：`{message, menus: [{text, href}], text, file}`。
typedef StdApplyResult = JsonMap;

// ============================================================
// 选课（elective）
// ============================================================

/// 选课轮次：`{id: int, name, round: int?, elect_open, withdraw_open, limits: [String], notice, link}`。
typedef ElectiveProfile = JsonMap;

/// 选课轮次上下文：`{profile_id: int, project_id: int, semester_id: int?}`。
typedef ElectiveContext = JsonMap;

/// 可选课程（lessonJSONs 元素）：`{id, name, courseTypeName, credits, teachers, campusName, …}`。
typedef ElectiveLesson = JsonMap;

/// 选课人数余量：`{lessonId: {sc: int 已选, lc: int 上限}}`。
typedef ElectiveCounts = JsonMap;

/// 选课/退课操作结果：`{success: bool, message: String, lesson_id: int}`。
typedef ElectiveOperateResult = JsonMap;

// ============================================================
// 杂项（misc）
// ============================================================

/// KV 信息段：`{section: String, kv: {键: 值}}`。
typedef KvSection = JsonMap;

/// 学籍信息结果：`{sections: [KvSection], photo: String, kv: JsonMap, file}`。
typedef StdDetailResult = JsonMap;

/// 学期：`{id: int, schoolYear: String, name: String, label: String}`。
typedef SemesterInfo = JsonMap;

/// 学期列表结果：`{semesters: [SemesterInfo], current: int?, year_index: String?}`。
typedef SemestersResult = JsonMap;

/// 欢迎页结果：`{modules: [{name, content}], welcome_text, file}`。
typedef WelcomeResult = JsonMap;

/// 系统消息结果：`{records: [JsonMap], count, file}`。
typedef MessagesResult = JsonMap;

/// 教学评价结果：`{records: [JsonMap], count, file}`。
typedef EvaluateResult = JsonMap;
