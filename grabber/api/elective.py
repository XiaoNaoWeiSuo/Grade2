# -*- coding: utf-8 -*-
"""选课接口:入口(轮次)/课程列表/选课人数/选课/退课

抓包链路:
    GET  /eams/stdElectCourse.action                          选课入口(轮次列表)
    GET  /eams/stdElectCourse!defaultPage.action?electionProfile.id=P   进入轮次
         (页面含 queryStdCount.action?projectId=1&semesterId=S → 轮次所属学期)
    GET  /eams/stdElectCourse!data.action?profileId=P         lessonJSONs 选课课程列表
    GET  /eams/stdElectCourse!queryStdCount.action?projectId=1&semesterId=S
         → window.lessonId2Counts={'课程id':{sc:已选,lc:上限},...}
    POST /eams/stdElectCourse!batchOperator.action?profileId=P
         选课: optype=true & operator0=<id>:true:0 & lesson0=<id> & schLessonGroup_<id>=undefined
         退课: optype=false & operator0=<id>:false & lesson0=<id>
         结果: 红色 div=失败原因;否则 JS update({elected:true|false})

⚠ 选课/退课为写操作,调用方需自行确认。
"""
import re
from html import unescape

from api.base import EamsBase
from api.clean import clean_ws


def parse_profiles_html(html: str) -> list:
    """选课入口页 → 轮次列表(名称/轮次号/开放时间/退课时间/限制/注意事项)。"""
    out = []
    for block in re.split(r"(?=<h2)", html):
        m = re.search(r"electionProfile\.id=(\d+)", block)
        if not m:
            continue
        h2 = re.search(r"<h2[^>]*>(.*?)</h2>", block, re.S)
        text = clean_ws(unescape(re.sub(r"<[^>]+>", " ", block)))
        round_m = re.search(r"选课轮次\s*(\d+)", text)
        # 范围分隔符为 " - "(两侧空格),与日期内部的 "-" 区分
        open_m = re.search(r"选课开放时间[:：]?\s*([\d\-: ]+?)\s+-\s+([\d\-: ]+)", text)
        wd_m = re.search(r"退课开放时间[:：]?\s*([\d\-: ]+?)\s+-\s+([\d\-: ]+)", text)
        limits, notice = [], ""
        lim_m = re.search(r"选课限制(.*?)注意事项", text)
        if lim_m:
            limits = [x.strip(" ,、") for x in lim_m.group(1).split(",") if x.strip(" ,、")]
        nt_m = re.search(r"注意事项(.*?)(?:进入选课|$)", text)
        if nt_m:
            notice = nt_m.group(1).strip()
        out.append({
            "id": int(m.group(1)),
            "name": clean_ws(h2.group(1)) if h2 else "",
            "round": int(round_m.group(1)) if round_m else None,
            "elect_open": f"{open_m.group(1).strip()} ~ {open_m.group(2).strip()}" if open_m else "",
            "withdraw_open": f"{wd_m.group(1).strip()} ~ {wd_m.group(2).strip()}" if wd_m else "",
            "limits": limits,
            "notice": notice,
            "link": m.group(0),
        })
    return out


class ElectiveMixin(EamsBase):
    def elective_profiles(self) -> list:
        """选课入口:当前开放的选课轮次(完整:名称/轮次/时间/限制/注意事项)。"""
        html = self.get_ajax("/eams/stdElectCourse.action")
        self.save("electiveProfiles.html", html)
        return parse_profiles_html(html)

    def elective_context(self, profile_id: int) -> dict:
        """进入选课轮次,返回 {profile_id, project_id, semester_id}"""
        html = self.get_ajax("/eams/stdElectCourse!defaultPage.action",
                             **{"electionProfile.id": profile_id})
        self.save(f"electiveDefaultPage_{profile_id}.html", html)
        m = re.search(r"queryStdCount\.action\?projectId=(\d+)&semesterId=(\d+)", html)
        return {"profile_id": profile_id,
                "project_id": int(m.group(1)) if m else 1,
                "semester_id": int(m.group(2)) if m else None}

    def elective_lessons(self, profile_id: int) -> list:
        """选课课程列表(lessonJSONs:课程名/教师/学分/时间/地点/可退性)。"""
        html = self.get_ajax("/eams/stdElectCourse!data.action", profileId=profile_id)
        lessons = None
        key = re.search(r"var\s+lessonJSONs\s*=", html)
        if key:
            try:
                arr = self._extract_balanced(html[key.end():], "[")
                lessons = self.js_to_py(arr)
            except ValueError:
                lessons = None
        self.save(f"electiveLessons_{profile_id}.json",
                  __import__("json").dumps(lessons, ensure_ascii=False, indent=2)
                  if lessons is not None else html)
        return lessons or []

    def elective_counts(self, project_id: int = 1, semester_id: int = None) -> dict:
        """选课人数余量。返回 {lesson_id: {"sc": 已选人数, "lc": 人数上限}}"""
        params = {"projectId": project_id}
        if semester_id:
            params["semesterId"] = semester_id
        html = self.get_ajax("/eams/stdElectCourse!queryStdCount.action", **params)
        key = re.search(r"lessonId2Counts\s*=\s*", html)
        if not key:
            return {}
        try:
            return self.js_to_py(self._extract_balanced(html[key.end():], "{"))
        except ValueError:
            return {}

    def elective_operate(self, profile_id: int, lesson_id: int, elect: bool = True) -> dict:
        """选课(elect=True)/退课(elect=False)。写操作!

        返回 {success, message, lesson_id}
        """
        if elect:
            data = {"optype": "true",
                    "operator0": f"{lesson_id}:true:0",
                    "lesson0": str(lesson_id),
                    f"schLessonGroup_{lesson_id}": "undefined"}
        else:
            data = {"optype": "false",
                    "operator0": f"{lesson_id}:false",
                    "lesson0": str(lesson_id)}
        html = self.post_ajax("/eams/stdElectCourse!batchOperator.action", data,
                              profileId=profile_id)
        self.save(f"electiveOp_{('elect' if elect else 'withdraw')}_{lesson_id}.html", html)
        red = re.search(r'color:\s*red;[^"]*">(.*?)</div>', html, re.S)
        if red:
            return {"success": False, "message": self.strip_tags(red.group(1)),
                    "lesson_id": lesson_id}
        m = re.search(r"elected\s*:\s*(true|false)", html)
        elected = bool(m and m.group(1) == "true")
        if elect:
            ok, msg = elected, ("选课成功" if elected else "选课未生效(结果未确认)")
        else:
            ok, msg = not elected, ("退课成功" if not elected else "退课未生效(结果未确认)")
        return {"success": ok, "message": msg, "lesson_id": lesson_id}
