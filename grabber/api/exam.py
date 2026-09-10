# -*- coding: utf-8 -*-
"""考试相关接口(数据清洗:全字段 + 座位表链接 + 考场id)

抓包链路:
    GET /eams/stdExamTable.action                       页面含批次下拉(examBatch.id)
    GET /eams/stdExamTable!examTable.action?examBatch.id=X   考试安排表
    GET /eams/stdOtherExamSignUp.action                 资格考试报名记录(四六级等)
    GET /eams/postgraduate/midterm/stdExamine!content.action?semester.id=X
"""
import re

from api.base import EamsBase
from api.clean import (parse_tables, pick_table, table_records, clean_ws)


def parse_exam_html(html: str) -> dict:
    """考试安排 HTML → {headers, records}(含座位表下载链接与考场 id)。"""
    tables = parse_tables(html)
    grid = pick_table(tables, "gridtable") or (tables[0] if tables else None)
    records = table_records(grid) if grid else []
    for r in records:
        if "_links" not in r:
            continue
        for l in r["_links"]:
            m = re.search(r"examRoom\.id=(\d+)", l.get("href", ""))
            if m:
                r["exam_room_id"] = int(m.group(1))
    return {"headers": grid["headers"] if grid else [],
            "records": records, "count": len(records)}


def parse_other_exams_html(html: str) -> dict:
    """课外资格考试页 → {signups(报名记录), scores(成绩)}(按表格前置标题分流)。"""
    signups, scores = [], []
    for t in parse_tables(html):
        recs = table_records(t)
        title = t["title"] + t["caption"]
        if "报名" in title:
            signups += recs
        else:
            scores += recs
    return {"signups": signups, "scores": scores,
            "signup_count": len(signups), "score_count": len(scores)}


class ExamMixin(EamsBase):
    def exam_batches(self) -> list:
        """考试批次列表(含补考批次)。返回 [{id, name, selected}]"""
        html = self.get_ajax("/eams/stdExamTable.action")
        self.save("examBatches.html", html)
        m = re.search(r'<select[^>]*name="examBatch\.id"[^>]*>(.*?)</select>', html, re.S)
        if not m:
            return []
        out = []
        for opt in re.finditer(r'<option value="(\d+)"(\s+selected)?[^>]*>(.*?)</option>', m.group(1), re.S):
            out.append({"id": int(opt.group(1)),
                        "selected": bool(opt.group(2)),
                        "name": clean_ws(opt.group(3))})
        return out

    def exam_table(self, batch_id: int) -> dict:
        """某批次考试安排(含补考):课程/类别/日期/时段/地点/座位号/形式/链接。"""
        html = self.get_ajax("/eams/stdExamTable!examTable.action", **{"examBatch.id": batch_id})
        file = self.save(f"examTable_{batch_id}.html", html)
        return {"batch_id": batch_id, **parse_exam_html(html), "file": file}

    def other_exams(self) -> dict:
        """课外/资格考试报名与完成情况(四六级、计算机等级、体育测试等)。"""
        html = self.get_ajax("/eams/stdOtherExamSignUp.action")
        file = self.save("otherExamSignUp.html", html)
        return {**parse_other_exams_html(html), "file": file}

    def midterm(self, semester_id: int = None) -> dict:
        """研究生中期考核申请信息(完整页面文本)。"""
        params = {"semester.id": semester_id} if semester_id else {}
        html = self.get_ajax("/eams/postgraduate/midterm/stdExamine!content.action", **params)
        file = self.save("midterm.html", html)
        m = re.search(r"<h[1-4][^>]*>(.*?)</h[1-4]>", html, re.S)
        text = clean_ws(re.sub(r"<[^>]+>", " ", html))
        return {"message": clean_ws(m.group(1)) if m else "",
                "text": text[:500], "file": file}
