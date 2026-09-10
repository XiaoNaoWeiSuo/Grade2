# -*- coding: utf-8 -*-
"""课程表接口(数据清洗:完整捕获每门课全部字段)

抓包链路:
    GET  /eams/courseTableForStd.action                 页面内嵌 ids(学生id/班级id)
    POST /eams/courseTableForStd!courseTable.action     ignoreHead=1&setting.kind=std|class
                                                        &startWeek=&semester.id=X&ids=N

课表数据在 JS 里,每个课程块结构(宁重复勿缺,全部捕获):
    var teachers  = [{id,name,lab}];           任课教师
    var actTeachers = [{id,name,lab}];         实际授课教师
    var assistantName = "";                    助教
    activity = new TaskActivity(教师ids, 教师names, "教学班号(课程代码)",
                "课程名(课程代码)", roomId, roomName, 周次位串, null, null,
                assistantName, "", 实验标记);
    index = D*unitCount+U;                     星期D(1起) 第U节(1起)
"""
import re

from api.base import EamsBase
from api.clean import week_parse, clean_ws

_DAY_NAMES = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]


def _js_teachers(part: str, var: str) -> list:
    """解析 'var teachers = [{id:..,name:"..",lab:false}]' → Python 列表。"""
    m = re.search(r"var\s+%s\s*=\s*(\[[^\]]*\])" % var, part, re.S)
    if not m:
        return []
    out = []
    for tid, name, lab in re.findall(
            r'\{[^{}]*?id\s*:\s*(\d+)[^{}]*?name\s*:\s*"([^"]*)"[^{}]*?lab\s*:\s*(true|false)[^{}]*?\}',
            m.group(1)):
        out.append({"id": int(tid), "name": name, "lab": lab == "true"})
    return out


def _split_label(s: str) -> dict:
    """"115251(752764)" → {"no": "115251", "code": "752764", "raw": …}"""
    m = re.match(r"^(.*?)\(([\w-]+)\)\s*$", s or "")
    if m:
        return {"no": m.group(1), "code": m.group(2), "raw": s}
    return {"no": s or "", "code": "", "raw": s or ""}


def parse_course_html(html: str) -> dict:
    """课表 HTML/JS → 完整结构化数据(模块级纯函数,支持离线自检)。

    返回 {unit_count, table_meta, course_count, courses, merged}
    courses 每条含:教师(id/名称/助教)、教学班号/课程代码/课程名、
    roomId/roomName、周次(位串+摘要+列表+数量)、星期/节次、实验标记、
    TaskActivity 原始参数(params_raw)。
    merged 按课程名聚合各上课时段。
    """
    unit_m = re.search(r"var\s+unitCount\s*=\s*(\d+)", html)
    unit_count = int(unit_m.group(1)) if unit_m else None
    table_meta = {}
    tm = re.search(r"new\s+CourseTable\((\d+)\s*,\s*(\d+)\)", html)
    if tm:
        table_meta = {"year": int(tm.group(1)), "slots": int(tm.group(2))}

    courses = []
    # 每个课程块以 "var teachers" 开始,块内含 TaskActivity 与 index
    for part in re.split(r"(?=var\s+teachers\s*=)", html)[1:]:
        act_m = re.search(r"new\s+TaskActivity\s*\((.*?)\)\s*;", part, re.S)
        idx_m = re.search(r"index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+)\s*;", part)
        if not act_m or not idx_m:
            continue
        args = EamsBase.split_js_args(act_m.group(1))

        def lit(i):
            s = args[i].strip() if i < len(args) else ""
            return s[1:-1] if s and s[0] in "\"'" and s[-1] == s[0] else ""

        teachers = _js_teachers(part, "teachers")
        act_teachers = _js_teachers(part, "actTeachers")
        assistant_m = re.search(r'assistantName\s*=\s*"([^"]*)"', part)
        assistant = assistant_m.group(1) if assistant_m else ""
        task = _split_label(lit(2))
        name = _split_label(lit(3))
        week = week_parse(lit(6))
        idx = int(idx_m.group(1)) * (unit_count or 0) + int(idx_m.group(2))
        day = idx // unit_count + 1 if unit_count else None
        unit = idx % unit_count + 1 if unit_count else None
        courses.append({
            # 教师
            "teachers": teachers,
            "teacher_names": ",".join(t["name"] for t in act_teachers or teachers),
            "act_teachers": act_teachers,
            "assistant": assistant,
            # 课程标识
            "task_no": task["no"], "course_code": task["code"],
            "clazz": task["raw"],
            "name": name["no"], "name_raw": name["raw"],
            "course_code2": name["code"],
            # 地点
            "room_id": lit(4), "room": lit(5),
            # 时间
            "day": day,
            "day_name": _DAY_NAMES[day - 1] if day and day <= 7 else None,
            "unit": unit,
            "weeks": week,          # {raw, digest, list, count, total}
            # 其它标记(第 12 参:实验/实践课标记;全部参数原样保留)
            "flag": lit(11),
            "params_raw": args,
        })

    # 按课程名聚合(同一课程多时段)
    merged = {}
    for c in courses:
        m = merged.setdefault(c["name"], {
            "name": c["name"], "course_code": c["course_code"] or c["course_code2"],
            "clazz": c["clazz"], "teachers": c["teacher_names"],
            "assistant": c["assistant"],
            "rooms": [], "times": [], "weeks": [], "units": 0})
        if c["room"] and c["room"] not in m["rooms"]:
            m["rooms"].append(c["room"])
        if c["day"] and c["unit"]:
            m["times"].append(f"{c['day_name']}{c['unit']}节")
        if c["weeks"]["digest"] and c["weeks"]["digest"] not in m["weeks"]:
            m["weeks"].append(c["weeks"]["digest"])
        m["units"] += 1
    return {"unit_count": unit_count, "table_meta": table_meta,
            "course_count": len(courses), "courses": courses,
            "merged": list(merged.values())}


class TimetableMixin(EamsBase):
    def _course_table_ids(self) -> dict:
        """从课表入口页解析 学生id(std) 与 班级id(class)"""
        html = self.get_ajax("/eams/courseTableForStd.action")
        ids = re.findall(r'addInput\(form,"ids","(\d+)"\)', html)
        return {
            "std": ids[0] if ids else None,
            "class": ids[1] if len(ids) > 1 else None,
        }

    def course_table(self, kind: str = "std", semester_id=None, start_week=None) -> dict:
        """课表(完整清洗:教师/课程代码/周次/节次/教室/实验标记等全部字段)。

        kind:        "std"=学生课表 / "class"=班级课表
        semester_id: 学期 id(如 409),None=服务器默认学期
        start_week:  起始教学周(如 "5"),None=全部周
        """
        if kind not in ("std", "class"):
            raise ValueError('kind 必须是 "std" 或 "class"')
        ids = self._course_table_ids()
        sid = ids.get(kind)
        if not sid:
            raise RuntimeError(f"课表入口页未解析到 {kind} ids")
        data = {
            "ignoreHead": "1",
            "setting.kind": kind,
            "startWeek": str(start_week) if start_week else "",
            "semester.id": str(semester_id) if semester_id else "",
            "ids": sid,
        }
        html = self.post_ajax("/eams/courseTableForStd!courseTable.action", data)
        file = self.save(f"courseTable_{kind}_{semester_id or 'default'}.html", html)
        result = parse_course_html(html)
        return {"kind": kind, "ids": sid, "semester_id": semester_id,
                "start_week": start_week, "file": file, **result}
