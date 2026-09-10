# -*- coding: utf-8 -*-
"""URP 教务系统接口封装(第④步的完整形态)

EamsApi = TimetableMixin(课表) + ExamMixin(考试/补考/课外考试/中期考核)
        + GradeMixin(成绩) + ElectiveMixin(选课/退课)
        + PlanMixin(培养计划) + MiscMixin(学籍/学期/消息/评价)
"""
from api.base import EamsBase, SessionLost
from api.timetable import TimetableMixin
from api.exam import ExamMixin
from api.grade import GradeMixin
from api.elective import ElectiveMixin
from api.plan import PlanMixin
from api.misc import MiscMixin


class EamsApi(TimetableMixin, ExamMixin, GradeMixin,
              ElectiveMixin, PlanMixin, MiscMixin, EamsBase):
    """基于抓包链路的教务系统只读/写操作接口集合。

    用法:
        api = EamsApi(http_client)
        api.plan_completion()      # 计划完成情况
        api.course_table("std")    # 学生课表
        api.elective_profiles()    # 选课入口
        ...
    所有方法自动保存原始响应到 output/ 并返回结构化 dict/list。
    """
