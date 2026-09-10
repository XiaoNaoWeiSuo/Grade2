# -*- coding: utf-8 -*-
"""全局配置:域名、常量、账号(仅本地测试,勿提交/外传)"""

import os

# ===== 测试账号 =====
USERNAME = "2022007923"
PASSWORD = "changjiangdaxue@923"

# ===== aTrust 零信任网关三个域名(抓包实测) =====
# CAS 统一身份认证(经网关域名映射)
CAS_BASE = "https://cas-yangtzeu-edu-cn.atrust.yangtzeu.edu.cn"
# aTrust 门户/控制器
PORTAL_BASE = "https://atrust.yangtzeu.edu.cn:4443"
# 教务系统(URP /eams/)的网关代理域名
EAMS_BASE = "https://jwc3-yangtzeu-edu-cn-s.atrust.yangtzeu.edu.cn"

# CAS service:登录成功后跳回 aTrust 换取门户会话 sid
CAS_SERVICE = PORTAL_BASE + "/passport/v1/auth/cas?sfDomain=CAS"

# 教务应用在网关上的静态标识(抓包实测,长期不变)
SDP_APP_CODE = "172f31db-be9b-4b53-a6b4-c3c9a5324854"
UNIT_ID = "22b2c333-05b0-432c-845e-152f6f883b5e"

# ===== 请求模拟 =====
UA = (
    "Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 "
    "cpdaily/9.9.22 wisedu/9.9.22"
)
ACCEPT_LANG = "zh-SG,zh-CN;q=0.9,zh-Hans;q=0.8"
CLIENT_QUERY = {"clientType": "SDPBrowserClient", "platform": "iOS", "lang": "en-US"}

# ===== 稳定性参数 =====
TIMEOUT = 20                 # 单请求超时(秒)
MAX_HOPS = 24                # 单条链路最大跳数
GET_RETRIES = 2              # GET 网络错误重试次数(POST 永不重试)
# 授权会话有效期实测 15min,缓存 12min 内视为新鲜,留 3min 余量
SESSION_TTL = 12 * 60
# 防封号硬约束:单次运行最多 1 次密码登录 POST,失败立即终止、绝不自动重试
MAX_LOGIN_POSTS_PER_RUN = 1

_BASE = os.path.dirname(os.path.abspath(__file__))
STATE_PATH = os.path.join(_BASE, ".session", "state.json")
OUTPUT_DIR = os.path.join(_BASE, "output")
