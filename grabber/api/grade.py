# -*- coding: utf-8 -*-
"""成绩查询接口(数据清洗:全部列 + 数值化 + 链接)

抓包链路:
    GET /eams/teach/grade/course/person!search.action?semesterId=X&projectType=
        → 个人成绩 gridtable(学年学期/课程代码/课程序号/课程名称/课程类别/
          学分/补考成绩/总评成绩/最终/绩点)
"""
from api.base import EamsBase
from api.clean import parse_tables, pick_table, table_records


def parse_grades_html(html: str) -> dict:
    """成绩 HTML → {headers, records, rows}(纯函数,支持离线自检)。"""
    tables = parse_tables(html)
    grid = pick_table(tables, "gridtable") or (tables[0] if tables else None)
    records = table_records(grid) if grid else []
    rows = [[c["text"] for c in r] for r in (grid or {}).get("rows", [])]
    return {"headers": grid["headers"] if grid else [],
            "records": records, "count": len(records), "rows": rows}


class GradeMixin(EamsBase):
    def grades(self, semester_id: int) -> dict:
        """查询某学期个人成绩(完整清洗)。

        semester_id: 学期 id(如 349 = 2024-2025-2),可用 semesters() 获取全部
        返回: {semester_id, headers, records, count, rows(原始文本行), file}
        """
        html = self.get_ajax("/eams/teach/grade/course/person!search.action",
                             semesterId=semester_id, projectType="")
        file = self.save(f"grades_{semester_id}.html", html)
        return {"semester_id": semester_id, **parse_grades_html(html), "file": file}
