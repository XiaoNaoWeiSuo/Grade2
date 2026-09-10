# -*- coding: utf-8 -*-
"""教务爬虫测试入口 —— 四步链路登录 + 全功能测试菜单

用法:
    python3 main.py             # 智能模式:缓存新鲜则免登录
    python3 main.py --relogin   # 强制重新密码登录

防封号:密码 POST 单次运行最多 1 次,失败即停;CASTGC(14天)内全部 SSO 免密。
"""
import json
import sys
import time

import config
from http_client import HttpClient, HttpError
from api import EamsApi, SessionLost
import step1_cas
import step2_portal
import step3_app


def log(msg: str) -> None:
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def _fresh(ts) -> bool:
    return ts and (time.time() - ts) < config.SESSION_TTL


def build_api(http: HttpClient, state: dict) -> EamsApi:
    """走/复用 ①→③ 链路,返回第④步 API 对象。"""
    extra = state.get("extra") or {}
    device_id = extra.get("device_id") or __import__("os").urandom(32).hex()

    # 缓存复用:12min 内直接返回,失效由主循环 SessionLost 自动重建
    if _fresh(extra.get("app_at")) and http.has_cookie("JSESSIONID"):
        log("缓存会话有效,免登录复用")
        return EamsApi(http)

    # ① CAS
    cas_redirect = step1_cas.cas_login(http, log)
    extra.setdefault("device_id", device_id)
    extra["cas_at"] = time.time()
    http.save_state(extra)
    # ② 门户
    portal_info = step2_portal.establish(http, cas_redirect, device_id, log)
    extra.update({"portal_at": time.time(), "display_name": portal_info.get("display_name", "")})
    http.save_state(extra)
    # ③ 应用授权
    step3_app.enter(http, log)
    extra["app_at"] = time.time()
    http.save_state(extra)
    return EamsApi(http)


def p(title, data):
    print(f"\n----- {title} -----")
    print(json.dumps(data, ensure_ascii=False, indent=2, default=str)[:2200])


def ask_int(prompt) -> int:
    return int(input(prompt).strip())


def ask_semester(api: EamsApi) -> int:
    """输入学期 id,空车取当前学期。"""
    raw = input("学期 id(回车=当前学期): ").strip()
    if raw:
        return int(raw)
    cur = api.semesters().get("current")
    print(f"  → 当前学期 id: {cur}")
    return int(cur)


MENU = """
======== 教务系统功能测试 ========
  1) 欢迎页                2) 学籍信息
  3) 学期列表              4) 切换学期
  5) 学生课表              6) 班级课表
  7) 成绩查询(按学期)
  8) 考试批次列表          9) 考试安排/补考表
 10) 计划完成情况         11) 按专业培养计划
 12) 专业培养方案         13) 转专业申请页
 14) 选课入口(轮次列表)   15) 选课课程列表
 16) 选课人数余量         17) 选课(写操作)
 18) 退课(写操作)
 19) 课外资格考试记录     20) 教学评价
 21) 中期考核             22) 系统消息
 23) 清洗层离线自检(不登录,直接解析 output/ 样本)
  0) 退出
================================"""


def handle(api: EamsApi, choice: str) -> None:
    if choice == "1":
        r = api.welcome()
        p(f"欢迎页(模块 {len(r['modules'])} 个)", r["modules"])
    elif choice == "2":
        r = api.std_detail()
        p(f"学籍信息({len(r['sections'])} 段,照片 {r['photo'] or '无'})",
          {"sections": r["sections"], "photo": r["photo"]})
    elif choice == "3":
        s = api.semesters()
        p(f"学期列表(当前 {s['current']})",
          [x for x in s["semesters"] if x["id"] >= 289][-12:])
    elif choice == "4":
        sid = ask_int("目标学期 id: ")
        p("切换学期", api.set_semester(sid))
    elif choice in ("5", "6"):
        kind = "std" if choice == "5" else "class"
        raw = input("学期 id(回车=默认): ").strip()
        r = api.course_table(kind, semester_id=int(raw) if raw else None)
        p(f"{r['kind']} 课表(ids={r['ids']},{r['course_count']} 门,每天{r['unit_count']}节)",
          {"courses": [{k: v for k, v in c.items() if k != "params_raw"}
                       for c in r["courses"]],
           "merged": r["merged"], "file": r["file"]})
    elif choice == "7":
        sid = ask_semester(api)
        g = api.grades(sid)
        p(f"成绩(学期 {sid},{g['count']} 门)", g["records"])
    elif choice == "8":
        p("考试批次", api.exam_batches())
    elif choice == "9":
        bid = ask_int("批次 id(见 8): ")
        r = api.exam_table(bid)
        p(f"考试安排(批次 {bid},{r['count']} 场)", r["records"])
    elif choice == "10":
        r = api.plan_completion()
        p("计划完成情况(头部)", r["summary"])
        print(f"课程明细 {r['count']} 门,分组 {len(r['sections'])} 组:")
        for s in r["sections"]:
            print(f"  [ {s['group']} ] {len(s['records'])} 门"
                  + (f" | 小计: {s['summary']}" if s["summary"] else ""))
        p("明细前 3 门", r["records"][:3])
    elif choice == "11":
        r = api.plan_by_major()
        for t in r["tables"]:
            print(f"  表[{t['class']}] {t['title'] or '(无标题)'}: "
                  f"{len(t['records'])} 行,表头 {t['headers'][:4]}…")
        p("首表前 2 行", r["tables"][0]["records"][:2] if r["tables"] else [])
    elif choice == "12":
        r = api.major_plan()
        if "error" in r:
            p("专业培养方案(无权限)", r["error"])
        else:
            p(f"专业培养方案({sum(len(t['records']) for t in r['tables'])} 行)",
              [{"class": t["class"], "rows": len(t["records"])} for t in r["tables"]])
    elif choice == "13":
        p("转专业申请", api.std_apply())
    elif choice == "14":
        p("选课轮次", api.elective_profiles())
    elif choice == "15":
        pid = ask_int("轮次 profileId(见 14): ")
        ctx = api.elective_context(pid)
        print(f"  轮次上下文: {ctx}")
        lessons = api.elective_lessons(pid)
        print(f"  共 {len(lessons)} 门可选课程:")
        for l in lessons[:30]:
            print(f"   [{l['id']}] {l['name']} | {l.get('courseTypeName')} {l.get('credits')}学分"
                  f" | {l.get('teachers')} | {l.get('campusName')}")
    elif choice == "16":
        pid = ask_int("轮次 profileId: ")
        ctx = api.elective_context(pid)
        c = api.elective_counts(ctx["project_id"], ctx["semester_id"])
        p(f"选课人数余量(学期 {ctx['semester_id']},{len(c)} 门)", c)
    elif choice == "17":
        pid = ask_int("轮次 profileId: ")
        lid = ask_int("课程 lessonId: ")
        if input(f"确认选课 {lid}? 输入 yes 继续: ").strip().lower() != "yes":
            print("已取消"); return
        p("选课结果", api.elective_operate(pid, lid, elect=True))
    elif choice == "18":
        pid = ask_int("轮次 profileId: ")
        lid = ask_int("课程 lessonId: ")
        if input(f"确认退课 {lid}? 输入 yes 继续: ").strip().lower() != "yes":
            print("已取消"); return
        p("退课结果", api.elective_operate(pid, lid, elect=False))
    elif choice == "19":
        r = api.other_exams()
        p(f"课外资格考试(报名 {r['signup_count']} 条 / 成绩 {r['score_count']} 条)",
          {"signups": r["signups"], "scores": r["scores"]})
    elif choice == "20":
        sid = ask_semester(api)
        r = api.evaluate(sid)
        p(f"教学评价({r['count']} 条)", r["records"])
    elif choice == "21":
        sid = ask_semester(api)
        p("中期考核", api.midterm(sid))
    elif choice == "22":
        r = api.messages()
        p(f"系统消息({r['count']} 条)", r["records"])
    elif choice == "23":
        clean_selfcheck()


# ----------------------------------------------------------------------------
# 清洗层离线自检:直接解析 output/ 已保存样本,不联网不登录,零封号风险
# ----------------------------------------------------------------------------
def clean_selfcheck() -> None:
    import os
    from api.timetable import parse_course_html
    from api.grade import parse_grades_html
    from api.exam import parse_exam_html, parse_other_exams_html
    from api.plan import (parse_plan_completion_html, parse_plan_tables_html)
    from api.misc import (parse_std_detail_html, parse_messages_html,
                          parse_welcome_html)
    from api.elective import parse_profiles_html

    def load(name):
        path = os.path.join(config.OUTPUT_DIR, name)
        if not os.path.exists(path):
            return None
        with open(path, encoding="utf-8") as f:
            return f.read()

    def show(title, data):
        print(f"\n  ◆ {title}")
        print("   ", json.dumps(data, ensure_ascii=False, default=str)[:800])

    print("\n===== 清洗层离线自检(仅解析本地样本) =====")
    for name, fn, field in [
        ("courseTable_std_369.html", parse_course_html, None),
        ("grades_349.html", parse_grades_html, "records"),
        ("examTable_1523.html", parse_exam_html, "records"),
        ("otherExamSignUp.html", parse_other_exams_html, None),
        ("myPlanCompl.html", parse_plan_completion_html, None),
        ("myPlanByMajor.html", parse_plan_tables_html, None),
        ("stdDetail.html", parse_std_detail_html, None),
        ("systemMessages.html", parse_messages_html, None),
        ("welcome.html", parse_welcome_html, None),
        ("electiveProfiles.html", parse_profiles_html, None),
    ]:
        html = load(name)
        if html is None:
            print(f"\n  ◆ {name}: 样本缺失,跳过(先跑一次在线功能生成)")
            continue
        try:
            r = fn(html)
            if name == "courseTable_std_369.html":
                show(f"{name} → {r['course_count']} 门课",
                     {"首门": {k: v for k, v in r["courses"][0].items()
                               if k != "params_raw"},
                      "聚合": r["merged"][:2]})
            elif name == "myPlanCompl.html":
                show(f"{name} → {r['count']} 门课 {len(r['sections'])} 组",
                     {"头部": r["summary"],
                      "分组": [s["group"] for s in r["sections"]],
                      "首门": r["records"][0]})
            elif name == "myPlanByMajor.html":
                show(f"{name} → {len(r)} 张表",
                     [{"class": t["class"], "行数": len(t["records"]),
                       "表头": t["headers"][:5]} for t in r])
            elif name == "stdDetail.html":
                show(f"{name} → {len(r['sections'])} 段",
                     {"sections": r["sections"], "photo": r["photo"]})
            elif name == "electiveProfiles.html":
                show(f"{name} → {len(r)} 个轮次", r)
            else:
                data = r.get(field) if field else r
                if isinstance(data, list) and data and isinstance(data[0], dict):
                    show(f"{name} → {len(data)} 条", data[:2])
                else:
                    show(name, data)
        except Exception as exc:  # 自检不中断
            print(f"\n  ◆ {name}: 解析异常 {exc!r}")


def run(force_login: bool) -> int:
    http = HttpClient()
    state = http.load_state() or {}
    api = build_api(http, state)
    while True:
        print(MENU)
        choice = input("选择功能: ").strip()
        if choice == "0":
            return 0
        try:
            handle(api, choice)
        except SessionLost as exc:
            log(f"会话失效({exc}),尝试自动重建…")
            api = build_api(http, http.load_state() or {})
        except KeyboardInterrupt:
            print()


def main() -> int:
    force_login = "--relogin" in sys.argv
    try:
        return run(force_login)
    except step1_cas.CredentialError as exc:
        log(f"账号凭据被拒,已终止且不会自动重试: {exc}")
        return 2
    except step1_cas.NeedCaptchaError as exc:
        log(f"需要验证码,已主动放弃: {exc}")
        return 3
    except (step1_cas.CasError, step2_portal.PortalError,
            step3_app.AppAuthError, SessionLost, HttpError) as exc:
        log(f"链路失败: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
