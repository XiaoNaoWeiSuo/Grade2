# -*- coding: utf-8 -*-
"""HTTP 会话封装

- 关闭 requests 自动重定向,手动逐跳跟踪,保证与真实浏览器一致的跳转语义
- Cookie 连同作用域(域/路径/有效期)持久化到 .session/state.json
  (含 CASTGC / sid / sdp_user_token / JSESSIONID 等敏感令牌,勿外传)
- GET 类请求有限重试;登录 POST 绝不自动重试(防触发账号锁定)
"""
import json
import os
import time
import urllib.parse

import requests
import requests.cookies

import config


class HttpError(Exception):
    """网络层/链路层错误。"""


class HttpClient:
    def __init__(self):
        self.s = requests.Session()
        self.s.headers.update({
            "User-Agent": config.UA,
            "Accept-Language": config.ACCEPT_LANG,
        })

    # ---------- 基础请求 ----------
    def request(self, method, url, retries=0, allow_retry=True, **kw):
        kw.setdefault("timeout", config.TIMEOUT)
        kw.setdefault("allow_redirects", False)
        last = None
        for attempt in range(retries + 1):
            try:
                return self.s.request(method, url, **kw)
            except requests.RequestException as exc:
                last = exc
                if not allow_retry or attempt == retries:
                    break
                time.sleep(1 + attempt)
        raise HttpError(f"{method} {url} 失败: {last}")

    def get(self, url, **kw):
        kw.setdefault("retries", config.GET_RETRIES)
        return self.request("GET", url, **kw)

    def post(self, url, **kw):
        # POST 不做网络重试(避免重复提交登录表单)
        return self.request("POST", url, retries=0, allow_retry=False, **kw)

    # ---------- 手动重定向跟踪 ----------
    def follow(self, resp, on_hop=None, max_hops=None):
        """从当前响应开始跟踪 3xx(302 后一律转 GET,与浏览器一致),返回最终响应。"""
        max_hops = max_hops or config.MAX_HOPS
        for _ in range(max_hops):
            if resp.status_code not in (301, 302, 303, 307, 308):
                return resp
            loc = resp.headers.get("Location", "")
            if not loc:
                return resp
            nxt = urllib.parse.urljoin(resp.url, loc)
            if on_hop:
                on_hop(resp.url, resp.status_code, nxt)
            resp = self.get(nxt, headers={"Referer": resp.url})
        raise HttpError(f"重定向跳数超限,最后落点: {resp.url}")

    # ---------- 会话持久化 ----------
    def save_state(self, extra):
        os.makedirs(os.path.dirname(config.STATE_PATH), exist_ok=True)
        cookies = []
        for c in self.s.cookies:
            cookies.append({
                "name": c.name, "value": c.value, "domain": c.domain,
                "path": c.path, "secure": bool(c.secure),
                "expires": c.expires,
            })
        data = {"saved_at": time.time(), "cookies": cookies, "extra": extra}
        tmp = config.STATE_PATH + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        os.replace(tmp, config.STATE_PATH)  # 原子替换

    def load_state(self):
        """恢复 Cookie 与附加状态;文件缺失/损坏返回 None。"""
        if not os.path.exists(config.STATE_PATH):
            return None
        try:
            with open(config.STATE_PATH, encoding="utf-8") as f:
                data = json.load(f)
            self.s.cookies.clear()
            for c in data.get("cookies", []):
                ck = requests.cookies.create_cookie(
                    name=c["name"], value=c["value"], domain=c.get("domain") or "",
                    path=c.get("path") or "/", secure=bool(c.get("secure")),
                    expires=c.get("expires"),
                )
                self.s.cookies.set_cookie(ck)
            return data
        except (OSError, ValueError, KeyError):
            return None

    # ---------- 小工具 ----------
    def has_cookie(self, name, domain_suffix=None):
        for c in self.s.cookies:
            if c.name == name and (
                domain_suffix is None or (c.domain or "").endswith(domain_suffix)
            ):
                return True
        return False
