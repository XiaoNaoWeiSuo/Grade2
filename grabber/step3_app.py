# -*- coding: utf-8 -*-
"""第③步: 教务应用授权(sdp_user_token + verify JWT)

链路(抓包实测):
    GET  {EAMS}/eams/localLogin.action?sdpAppCode=<app>&unitId=<unit>
         → 网关下发 sdp_user_token Cookie(值 == 门户 sid)
         → 若未授权,返回中转页 HTML,内嵌 var locationUrl="{PORTAL}/controller/v1/public/verify?t=<JWT>"
    GET  verify?t=<JWT>   (JWT 自包含, timeout=600s) → 302 回应用入口
         → CAS 免密接力(CASTGC)→ ST → URP localLogin.action?ticket=ST
         → 302 ...;jsessionid=... → 302 /eams/home.action

自愈设计:本步骤可重复执行;任何一次被网关拦回中转页,都会自动重走 verify。
"""
import re
import urllib.parse

import config
from http_client import HttpClient


class AppAuthError(Exception):
    pass


APP_ENTRY = f"{config.EAMS_BASE}/eams/localLogin.action"
ENTRY_WITH_PARAMS = f"{APP_ENTRY}?sdpAppCode={config.SDP_APP_CODE}&unitId={config.UNIT_ID}"
INTERSTITIAL = re.compile(r'var\s+locationUrl\s*=\s*"([^"]+)"')


def enter(http: HttpClient, log) -> None:
    url = ENTRY_WITH_PARAMS
    resp = None
    verify_hits = 0
    no_param_hits = 0

    for _ in range(config.MAX_HOPS):
        referer = f"{config.PORTAL_BASE}/portal/" if resp is None else resp.url
        resp = http.get(url, headers={"Referer": referer})

        # 手动跟随 3xx(302 后转 GET)
        hops = 0
        while resp.status_code in (301, 302, 303, 307) and resp.headers.get("Location"):
            nxt = urllib.parse.urljoin(resp.url, resp.headers["Location"])
            resp = http.get(nxt, headers={"Referer": resp.url})
            hops += 1
            if hops > config.MAX_HOPS:
                raise AppAuthError(f"重定向跳数超限: {resp.url}")

        path = urllib.parse.urlparse(resp.url).path.split(";")[0]

        if path == "/eams/home.action":
            if not http.has_cookie("JSESSIONID"):
                raise AppAuthError("已到 home.action 但缺少 JSESSIONID")
            log("教务会话建立(JSESSIONID/GSESSIONID + sdp_user_token)")
            return

        if resp.status_code == 200:
            m = INTERSTITIAL.search(resp.text or "")
            if m and "/controller/v1/public/verify" in m.group(1):
                verify_hits += 1
                if verify_hits > 5:
                    raise AppAuthError("verify 中转页循环超过 5 次")
                log(f"命中网关中转页 → verify?t=<JWT 第 {verify_hits} 次")
                url = m.group(1)
                continue
            if path == "/eams/localLogin.action":
                # 模拟浏览器第二击:无参入口,触发 CAS 免密接力
                no_param_hits += 1
                if no_param_hits > 3:
                    break
                url = APP_ENTRY
                continue
            break  # 其他页面(多为 CAS 登录页,CASTGC 已失效)

        break

    tail = (resp.text or "")[:150].replace("\n", " ")
    raise AppAuthError(f"未能进入 /eams/home.action,落点: {resp.url} | 页面片段: {tail}")
