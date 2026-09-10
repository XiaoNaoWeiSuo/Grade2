# -*- coding: utf-8 -*-
"""第①步: CAS 统一身份认证

链路(抓包实测):
    GET  /authserver/login?service=<aTrust 回跳地址>
         ├─ CASTGC 有效 → 302 直接下发 ST(SSO 免密,不消耗登录次数)
         └─ 否则返回登录表单(含 pwdEncryptSalt)
    POST /authserver/login (密码 AES 加密) → 302 带 ticket=ST-xxx

安全约束:
    - 密码 POST 每次运行最多 1 次(config.MAX_LOGIN_POSTS_PER_RUN),失败立即终止
    - POST 前先查 checkNeedCaptcha,需要验证码则直接放弃(不硬闯)
"""
import re
import time
import urllib.parse

import config
from crypto import encrypt_password
from http_client import HttpClient, HttpError

SERVICE_ENC = urllib.parse.quote(config.CAS_SERVICE, safe="")
LOGIN_URL = f"{config.CAS_BASE}/authserver/login?service={SERVICE_ENC}"

_login_posts_used = 0


class CasError(Exception):
    pass


class NeedCaptchaError(CasError):
    pass


class CredentialError(CasError):
    """凭据错误——严禁自动重试。"""


def check_need_captcha(http: HttpClient, username: str) -> bool:
    resp = http.get(
        f"{config.CAS_BASE}/authserver/checkNeedCaptcha.htl",
        params={"username": username, "_": int(time.time() * 1000),
                "sf_request_type": "ajax"},
        headers={"X-Requested-With": "XMLHttpRequest"},
    )
    try:
        return bool(resp.json().get("isNeed"))
    except ValueError:
        return False


def _parse_login_form(html: str) -> dict:
    def field(*patterns):
        for pat in patterns:
            m = re.search(pat, html)
            if m:
                return m.group(1)
        return ""

    return {
        "execution": field(r'name="execution" value="([^"]*)"',
                           r'id="execution"[^>]*value="([^"]*)"'),
        "lt": field(r'name="lt"[^>]*value="([^"]*)"',
                    r'id="lt"[^>]*value="([^"]*)"'),
        "salt": field(r'id="pwdEncryptSalt" value="([^"]*)"'),
    }


def _extract_error(html: str) -> str:
    m = (re.search(r'id="msg"[^>]*>([^<]+)<', html)
         or re.search(r'class="auth_error"[^>]*>([^<]+)<', html)
         or re.search(r'class="errors?[" >][^>]*>([^<]{2,80})<', html))
    return m.group(1).strip() if m else "未知原因"


def cas_login(http: HttpClient, log) -> str:
    """返回带 ST ticket 的 aTrust 回跳 URL;失败抛 CasError。"""
    global _login_posts_used

    # 1) 先试 SSO:CASTGC 有效时,登录页直接 302 下发新 ST(零风险、不占登录次数)
    resp = http.get(LOGIN_URL, headers={
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Referer": f"{config.PORTAL_BASE}/portal/",
    })
    if resp.status_code in (301, 302, 303, 307):
        loc = resp.headers.get("Location", "")
        if "ticket=ST-" in loc:
            log("CAS SSO 命中(CASTGC 有效),免密获得新 ticket")
            return loc
        raise CasError(f"登录页异常跳转(无 ticket): {loc[:120]}")

    # 2) 走密码登录
    if _login_posts_used >= config.MAX_LOGIN_POSTS_PER_RUN:
        raise CasError("本次运行密码登录 POST 次数已达上限,拒绝继续(防封号)")

    form = _parse_login_form(resp.text)
    if not form["execution"]:
        raise CasError("登录页解析失败(未找到 execution 字段)")

    if check_need_captcha(http, config.USERNAME):
        raise NeedCaptchaError("该账号本次需要验证码,已主动放弃(请稍后再试或人工登录)")

    payload = {
        "username": config.USERNAME,
        "password": encrypt_password(config.PASSWORD, form["salt"]),
        "captcha": "",
        "rememberMe": "true",
        "_eventId": "submit",
        "lt": form["lt"],
        "cllt": "userNameLogin",
        "dllt": "generalLogin",
        "execution": form["execution"],
    }
    _login_posts_used += 1
    log(f"CAS 密码登录 POST(第 {_login_posts_used}/{config.MAX_LOGIN_POSTS_PER_RUN} 次,盐 {form['salt'][:4]}****)")
    resp = http.post(LOGIN_URL, data=payload, headers={
        "Content-Type": "application/x-www-form-urlencoded",
        "Origin": config.CAS_BASE,
        "Referer": LOGIN_URL,
    })

    if resp.status_code in (301, 302, 303, 307):
        loc = resp.headers.get("Location", "")
        if "ticket=ST-" in loc:
            log("CAS 登录成功,获得 ST ticket")
            return loc
        raise CasError(f"登录后跳转异常: {loc[:120]}")

    # 200 = 登录失败页(错误信息在页面里)。绝不重试。
    raise CredentialError(f"CAS 登录被拒绝: {_extract_error(resp.text)}")
