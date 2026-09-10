# -*- coding: utf-8 -*-
"""第②步: aTrust 门户会话建立

链路(抓包实测,顺序保持一致):
    1. GET  {PORTAL}/passport/v1/auth/cas?sfDomain=CAS&ticket=ST-xxx
           → 302 /portal/shortcut.html?...&data={"ticket":"<unitId_uuid>",...}
           → 该 302 响应下发门户会话 Cookie: sid / sid.sig(tag=secondary_auth)
    2. GET  shortcut.html(落地,后续请求的 Referer)
    3. GET  /passport/v1/public/authConfig?...&mod=1
           → 响应 JSON 含 security.csrfToken —— 后续门户 API 必须带 x-csrf-token 头
    4. POST /controller/v1/public/reportEnv
           (x-csrf-token + x-sdp-traceid;body = data 里的 ticket + deviceId)
    5. GET  /passport/v1/auth/authCheck → code:0 + isOnline:true
           → 刷新 sid(tag=online),授权会话正式生效(实测有效期 15min)
"""
import json
import os
import re
import urllib.parse

import config
from http_client import HttpClient


class PortalError(Exception):
    pass


def _trace_id() -> str:
    return os.urandom(4).hex()


def _api_headers(csrf: str, referer: str, origin: bool = False) -> dict:
    h = {
        "Accept": "*/*",
        "x-csrf-token": csrf,
        "x-sdp-traceid": _trace_id(),
        "Referer": referer,
    }
    if origin:
        h["Origin"] = config.PORTAL_BASE
    return h


def _login_ticket_from(loc: str) -> str:
    m = re.search(r'"ticket"\s*:\s*"([^"]+)"', urllib.parse.unquote(loc))
    return m.group(1) if m else ""


def establish(http: HttpClient, cas_redirect_url: str, device_id: str, log) -> dict:
    # 1) 用 ST 换门户会话(302 响应头下发 sid Cookie)
    resp = http.get(cas_redirect_url, headers={
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Referer": f"{config.CAS_BASE}/",
    })
    if resp.status_code not in (301, 302, 303, 307):
        raise PortalError(f"auth/cas 未按预期 302: HTTP {resp.status_code}")
    shortcut_loc = resp.headers.get("Location", "")
    login_ticket = _login_ticket_from(shortcut_loc)
    if not login_ticket:
        raise PortalError("shortcut 跳转中未找到 login ticket")

    # 2) shortcut.html 落地(参照浏览器行为)
    shortcut_url = urllib.parse.urljoin(resp.url, shortcut_loc)
    http.get(shortcut_url, headers={"Referer": resp.url})
    # SPA 维护的在线状态 cookie(保真)
    http.s.cookies.set("online", "0", domain="atrust.yangtzeu.edu.cn", path="/")
    log(f"门户会话建立(sid),login_ticket={login_ticket[:13]}****")

    q = dict(config.CLIENT_QUERY)

    # 3) authConfig:取 csrfToken
    resp = http.get(f"{config.PORTAL_BASE}/passport/v1/public/authConfig",
                    params={**q, "mod": "1"},
                    headers={"Accept": "*/*", "Referer": shortcut_url})
    try:
        csrf = ((resp.json().get("data") or {}).get("security") or {}).get("csrfToken", "")
    except ValueError:
        raise PortalError(f"authConfig 响应非 JSON: HTTP {resp.status_code}")
    if not csrf:
        raise PortalError("authConfig 未下发 csrfToken")
    log(f"csrfToken 获取: {csrf[:8]}****")

    # 4) reportEnv 环境上报(body 结构 1:1 复刻抓包)
    env_body = {
        "ticket": login_ticket,
        "deviceId": device_id,
        "env": {"endpoint": {"device_id": device_id, "device": {"type": "browser"}}},
    }
    resp = http.post(f"{config.PORTAL_BASE}/controller/v1/public/reportEnv",
                     params=q, json=env_body,
                     headers=_api_headers(csrf, shortcut_url, origin=True))
    try:
        rcode = resp.json().get("code")
    except ValueError:
        raise PortalError(f"reportEnv 响应异常: HTTP {resp.status_code} {resp.text[:100]}")
    if rcode != 0:
        raise PortalError(f"reportEnv 失败: code={rcode} {resp.text[:120]}")

    # 5) authCheck —— 在线状态确认(硬校验)
    resp = http.get(f"{config.PORTAL_BASE}/passport/v1/auth/authCheck",
                    params=q, headers=_api_headers(csrf, shortcut_url))
    try:
        data = resp.json()
    except ValueError:
        raise PortalError(f"authCheck 响应非 JSON: HTTP {resp.status_code} {resp.text[:100]}")
    if data.get("code") != 0:
        raise PortalError(f"authCheck 失败: {data.get('message')}")
    info = (data.get("data") or {}).get("onlineInfo") or {}
    if not info.get("isOnline"):
        raise PortalError("authCheck 报告未在线")
    http.s.cookies.set("online", "1", domain="atrust.yangtzeu.edu.cn", path="/")
    log(f"authCheck 通过: {info.get('displayName')}({info.get('username')}) 在线")
    return {"username": info.get("username"), "display_name": info.get("displayName"),
            "sid_ticket": (data.get("data") or {}).get("sidTicket", "")}
