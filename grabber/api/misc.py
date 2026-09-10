# -*- coding: utf-8 -*-
"""其他接口(数据清洗:学籍多 section KV + 照片 + 消息/评价全字段)

抓包链路:
    GET  /eams/home!welcome.action          欢迎信息
    GET  /eams/stdDetail.action             学籍信息
    POST /eams/dataQuery.action             dataType=projectId / semesterCalendar(学期全表+当前学期)
    GET  /eams/systemMessageForStd!search.action   系统消息
    GET  /eams/quality/stdEvaluate.action   教学评价
"""
import random
import re

import config
from api.base import EamsBase
from api.clean import (parse_tables, pick_table, table_records, kv_tables,
                       clean_ws)


def parse_std_detail_html(html: str) -> dict:
    """学籍 HTML → {sections: [{section, kv}], photo, kv(首段)}。"""
    sections = kv_tables(html)
    photo = ""
    for s in sections:
        photo = s["kv"].get("照片") or photo
    return {"sections": sections, "photo": photo,
            "kv": sections[0]["kv"] if sections else {}}


def parse_messages_html(html: str) -> dict:
    """系统消息 HTML → {records: [{发件人, 主题, 时间, _links}]}。"""
    grid = pick_table(parse_tables(html), "gridtable")
    records = table_records(grid) if grid else []
    return {"records": records, "count": len(records)}


def parse_welcome_html(html: str) -> dict:
    """欢迎页 → 各模块标题 + 正文(完整文本)。"""
    from html import unescape
    modules = []
    for m in re.finditer(
            r'<h2 class="header">\s*<a[^>]*>([^<]+)</a>\s*</h2>\s*'
            r'<div class="modulebody">(.*?)</div>', html, re.S):
        body = clean_ws(unescape(re.sub(r"<[^>]+>", " ", m.group(2))))
        modules.append({"name": m.group(1).strip(), "content": body})
    return {"modules": modules, "welcome_text": modules[0]["content"] if modules else ""}


class MiscMixin(EamsBase):
    def welcome(self) -> dict:
        """首页欢迎信息(各模块完整文本,含今天日期)。"""
        html = self.get_ajax("/eams/home!welcome.action")
        file = self.save("welcome.html", html)
        return {**parse_welcome_html(html), "file": file}

    def std_detail(self) -> dict:
        """学籍信息(学籍/联系信息/家庭联系信息 等多 section + 照片 URL)。"""
        html = self.get_ajax("/eams/stdDetail.action")
        file = self.save("stdDetail.html", html)
        return {**parse_std_detail_html(html), "file": file}

    def semesters(self) -> dict:
        """全部学期列表 + 当前学期。

        通过 dataQuery(semesterCalendar) 拿到全量学期表:
            [{id, schoolYear, name(1/2)}, ...] + semesterId(当前)
        """
        # projectId(与抓包一致的预备查询)
        self.post_ajax("/eams/dataQuery.action", {"dataType": "projectId"})
        tag_id = f"semesterBar{random.randint(10 ** 9, 10 ** 10 - 1)}Semester"
        html = self.post_ajax("/eams/dataQuery.action", {
            "tagId": tag_id, "dataType": "semesterCalendar",
            "value": "", "empty": "false",
        })
        self.save("semesters_raw.txt", html)
        # 响应为 JS 字面量且 yearDom 内嵌 HTML,通用转换不适用,改用定向正则
        sems = [{"id": int(i), "schoolYear": y, "name": n,
                 "label": f"{y}学年 {n} 学期"}
                for i, y, n in re.findall(
                    r'\{id:(\d+),schoolYear:"([^"]+)",name:"([^"]+)"\}', html)]
        sems.sort(key=lambda s: s["id"])
        cur = re.search(r'semesterId:"(\d+)"', html)
        yi = re.search(r'yearIndex:"(\d+)"', html)
        return {"semesters": sems,
                # value 为空时响应不含 semesterId,回退为列表中最新学期
                "current": int(cur.group(1)) if cur else (sems[-1]["id"] if sems else None),
                "year_index": yi.group(1) if yi else None}

    def set_semester(self, semester_id: int) -> dict:
        """切换当前学期(写 cookie semester.id,等价于页面学期条选择)。"""
        tag_id = f"semesterBar{random.randint(10 ** 9, 10 ** 10 - 1)}Semester"
        html = self.post_ajax("/eams/dataQuery.action", {
            "tagId": tag_id, "dataType": "semesterCalendar",
            "value": str(semester_id), "empty": "false",
        })
        self.http.s.cookies.set("semester.id", str(semester_id),
                                domain=config.EAMS_BASE.split("//", 1)[1], path="/")
        self.save("setSemester_raw.txt", html)
        return {"semester_id": semester_id, "ok": bool(html.strip())}

    def messages(self) -> dict:
        """学生系统消息列表(发件人/主题/时间全字段)。"""
        html = self.get_ajax("/eams/systemMessageForStd!search.action")
        file = self.save("systemMessages.html", html)
        return {**parse_messages_html(html), "file": file}

    def evaluate(self, semester_id: int = None) -> dict:
        """教学评价页(评价任务列表:课程/类别/教师/问卷全字段)。"""
        if semester_id:
            self.post_ajax("/eams/quality/stdEvaluate.action", {"semester.id": semester_id})
        html = self.get_ajax("/eams/quality/stdEvaluate.action")
        file = self.save("stdEvaluate.html", html)
        grid = pick_table(parse_tables(html), "gridtable")
        records = table_records(grid) if grid else []
        return {"records": records, "count": len(records), "file": file}
