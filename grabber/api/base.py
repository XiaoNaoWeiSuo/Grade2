# -*- coding: utf-8 -*-
"""URP 教务接口基类:统一请求、会话守卫、保存与解析工具

约定:
    - 所有请求 1:1 复刻抓包(ajax 参数 + X-Requested-With 头 + Referer)
    - 每个接口方法:保存原始响应到 output/ 并返回结构化数据
    - 会话失效(被踢回登录)统一抛 SessionLost,由调用方重建链路
"""
import json
import os
import re
import time

import config
from http_client import HttpClient


class SessionLost(Exception):
    pass


class EamsBase:
    def __init__(self, http: HttpClient):
        self.http = http

    # ---------------- 请求 ----------------
    @staticmethod
    def _ts() -> int:
        return int(time.time() * 1000)

    def _ajax_headers(self, referer: str = None) -> dict:
        return {
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "text/html, */*; q=0.01",
            "Referer": referer or f"{config.EAMS_BASE}/eams/home.action",
        }

    def _guard(self, resp) -> None:
        path = ""
        m = re.match(r"https?://[^/]+(/[^;?]*)", resp.url)
        if m:
            path = m.group(1)
        if resp.status_code in (301, 302, 303, 307):
            raise SessionLost(f"被重定向: {resp.headers.get('Location', '')[:100]}")
        if resp.status_code != 200:
            raise SessionLost(f"HTTP {resp.status_code}: {resp.url}")
        if not path.startswith("/eams/") or "authserver" in resp.url:
            raise SessionLost(f"落点不在教务系统: {resp.url}")

    def get_ajax(self, path: str, **params) -> str:
        params.setdefault("_", self._ts())
        params.setdefault("sf_request_type", "ajax")
        for attempt in range(2):
            resp = self.http.get(f"{config.EAMS_BASE}{path}", params=params,
                                 headers=self._ajax_headers())
            self._guard(resp)
            if "请不要过快点击" not in resp.text or attempt:
                return resp.text
            time.sleep(2.5)  # URP 点击频率保护,稍候重试一次
        return resp.text

    def post_ajax(self, path: str, data: dict, **params) -> str:
        params.setdefault("sf_request_type", "ajax")
        for attempt in range(2):
            resp = self.http.post(f"{config.EAMS_BASE}{path}", params=params, data=data,
                                  headers=self._ajax_headers())
            self._guard(resp)
            if "请不要过快点击" not in resp.text or attempt:
                return resp.text
            time.sleep(2.5)
        return resp.text

    # ---------------- 保存 ----------------
    @staticmethod
    def save(name: str, content: str) -> str:
        os.makedirs(config.OUTPUT_DIR, exist_ok=True)
        path = os.path.join(config.OUTPUT_DIR, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        return path

    # ---------------- 解析工具 ----------------
    @staticmethod
    def strip_tags(s: str) -> str:
        s = re.sub(r"<[^>]+>", " ", s)
        return re.sub(r"\s+", " ", s.replace("&nbsp;", " ")).strip()

    @staticmethod
    def parse_grid(html: str) -> dict:
        """解析第一个 gridtable 表格 → {headers, rows}"""
        grids = EamsBase.parse_grids(html)
        return grids[0] if grids else {"headers": [], "rows": []}

    @staticmethod
    def parse_grids(html: str) -> list:
        """解析页面全部数据表格(gridtable/infoTable/formTable/planTable...)
        → [{headers, rows}, ...]。headers 取 <th>,无 <th> 时为空列表。"""
        out = []
        for m in re.finditer(r"<table[^>]*>(.*?)</table>", html, re.S):
            tbl = m.group(1)
            if "<td" not in tbl and "<th" not in tbl:
                continue
            headers = [EamsBase.strip_tags(c) for c in re.findall(r"<th[^>]*>(.*?)</th>", tbl, re.S)]
            rows = []
            for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", tbl, re.S):
                cells = [EamsBase.strip_tags(c) for c in re.findall(r"<td[^>]*>(.*?)</td>", tr, re.S)]
                if any(cells):
                    rows.append(cells)
            if rows:
                out.append({"headers": headers, "rows": rows})
        return out

    @staticmethod
    def parse_kv(html: str) -> dict:
        """解析页面第一张表中的 label:value 型信息(如 学号:/姓名:)→ dict"""
        m = re.search(r"<table[^>]*>(.*?)</table>", html, re.S)
        if not m:
            return {}
        cells = [EamsBase.strip_tags(c) for c in re.findall(r"<td[^>]*>(.*?)</td>", m.group(1), re.S)]
        kv, i = {}, 0
        while i < len(cells) - 1:
            if cells[i].rstrip().endswith((":", "：")):
                kv[cells[i].rstrip(":： ").strip()] = cells[i + 1].strip()
                i += 2
            else:
                i += 1
        return kv

    @staticmethod
    def week_digest(state: str) -> str:
        """'000011110000...' → '5-8' 形式的上课周次。"""
        runs, i = [], 0
        while i < len(state):
            if state[i] == "1":
                j = i
                while j < len(state) and state[j] == "1":
                    j += 1
                runs.append(f"{i + 1}-{j}" if j > i + 1 else str(i + 1))
                i = j
            else:
                i += 1
        return ",".join(runs)

    @staticmethod
    def split_js_args(s: str) -> list:
        """按顶层逗号拆分 JS 实参(尊重引号与括号)。"""
        args, buf, depth, in_str = [], [], 0, None
        for ch in s:
            if in_str:
                buf.append(ch)
                if ch == in_str:
                    in_str = None
                continue
            if ch in ("'", '"'):
                in_str = ch
                buf.append(ch)
            elif ch in "([{":
                depth += 1
                buf.append(ch)
            elif ch in ")]}":
                depth -= 1
                buf.append(ch)
            elif ch == "," and depth == 0:
                args.append("".join(buf).strip())
                buf = []
            else:
                buf.append(ch)
        if buf:
            args.append("".join(buf).strip())
        return args

    @staticmethod
    def _extract_balanced(text: str, open_ch: str) -> str:
        """从 text 开头提取首个配平的 {...} 或 [...] 字面量"""
        close_ch = "]" if open_ch == "[" else "}"
        start = text.find(open_ch)
        if start < 0:
            raise ValueError("未找到起始符")
        depth, in_str = 0, None
        for i in range(start, len(text)):
            ch = text[i]
            if in_str:
                if ch == in_str:
                    in_str = None
                continue
            if ch in ("'", '"'):
                in_str = ch
            elif ch == open_ch:
                depth += 1
            elif ch == close_ch:
                depth -= 1
                if depth == 0:
                    return text[start:i + 1]
        raise ValueError("括号不配平")

    @staticmethod
    def js_to_py(s: str):
        """URP 页面 JS 字面量(单引号/无引号键)→ Python 对象"""
        s = re.sub(r"([{,\[]\s*)([A-Za-z_$][\w$]*)\s*:", r'\1"\2":', s)
        s = s.replace("'", '"')
        return json.loads(s)
