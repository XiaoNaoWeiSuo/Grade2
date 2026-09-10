# -*- coding: utf-8 -*-
"""培养计划接口(数据清洗:头部 KV + 分组课程明细 + 嵌套方案表)

抓包链路:
    GET /eams/myPlanCompl.action    培养计划完成情况(头部 KV + 课程完成 formTable)
    GET /eams/myPlanByMajor.action  按专业的培养计划(嵌套表:分类/课程/8学期建议)
    GET /eams/stdMajorPlan.action   专业培养方案
    GET /eams/stdApply.action       转专业申请
"""
import re

from api.base import EamsBase
from api.clean import (parse_tables, pick_table, table_records, kv_tables,
                       clean_ws)


def _sections_from_records(records: list) -> list:
    """平铺记录(含 _group 行)→ [{group, records}] 分组结构。"""
    sections, cur = [], None
    for r in records:
        if "_group" in r:
            cur = {"group": r.pop("_group"), "summary": {k: v for k, v in r.items()},
                   "records": []}
            sections.append(cur)
        else:
            if cur is None:
                cur = {"group": "(未分组)", "summary": {}, "records": []}
                sections.append(cur)
            cur["records"].append(r)
    return sections


def parse_plan_completion_html(html: str) -> dict:
    """计划完成情况 HTML → {summary(KV), sections(分组课程明细), records(平铺)。"""
    kvs = kv_tables(html)
    tables = parse_tables(html)
    form = pick_table(tables, "formTable")
    records = table_records(form, header_row=0) if form else []
    sections = _sections_from_records(records)
    flat = []
    for s in sections:
        for r in s["records"]:
            flat.append({"group": s["group"], **r})
    return {"summary": kvs[0]["kv"] if kvs else {},
            "sections": sections, "records": flat, "count": len(flat)}


def parse_plan_tables_html(html: str) -> list:
    """培养方案/专业计划页 → 全部表格(嵌套内层表独立,含表头与记录)。"""
    out = []
    for t in parse_tables(html):
        if t["n_rows"] == 0 and not t["header_rows"]:
            continue
        out.append({"class": t["class"], "title": t["title"] or t["caption"],
                    "headers": t["headers"], "header_rows": t["n_rows"],
                    "records": table_records(t)})
    return out


class PlanMixin(EamsBase):
    def plan_completion(self) -> dict:
        """培养计划完成情况:要求/实修学分、GPA、审核结果 + 分组课程明细。"""
        html = self.get_ajax("/eams/myPlanCompl.action")
        file = self.save("myPlanCompl.html", html)
        return {**parse_plan_completion_html(html), "file": file}

    def plan_by_major(self) -> dict:
        """我的专业培养计划(嵌套表:分类/课程代码/学分/建议修读学期/院系)。"""
        html = self.get_ajax("/eams/myPlanByMajor.action")
        file = self.save("myPlanByMajor.html", html)
        return {"tables": parse_plan_tables_html(html), "file": file}

    def major_plan(self) -> dict:
        """专业培养方案(部分账号无权限,返回 {"error": ...})。"""
        html = self.get_ajax("/eams/stdMajorPlan.action")
        file = self.save("stdMajorPlan.html", html)
        m = re.search(r"color:\s*red[^>]*>([^<]+)<", html)
        if m:
            return {"error": m.group(1).strip(), "file": file}
        return {"tables": parse_plan_tables_html(html), "file": file}

    def std_apply(self) -> dict:
        """转专业申请页(完整:提示语 + 导航菜单链接)。"""
        html = self.get_ajax("/eams/stdApply.action")
        file = self.save("stdApply.html", html)
        msg = re.search(r"<h[2-4][^>]*>([^<]+)</h[2-4]>", html)
        menus = [{"text": clean_ws(t), "href": h} for h, t in re.findall(
            r'<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>', html, re.S)]
        return {"message": clean_ws(msg.group(1)) if msg else "",
                "menus": menus,
                "text": clean_ws(re.sub(r"<[^>]+>", " ", html))[:300],
                "file": file}
