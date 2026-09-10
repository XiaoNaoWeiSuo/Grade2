# -*- coding: utf-8 -*-
"""CAS 密码加密 —— 1:1 复刻服务端 /authserver/.../encrypt.js

服务端逻辑(已从线上 encrypt.js 摘录并在 2026-09-10 抓包密文上离线解密验证):
    encryptPassword(pwd, salt) -> encryptAES(pwd, salt)
      salt 为空: 返回明文
      salt 非空: AES-128-CBC(key=salt, iv=randomString(16),
                              plaintext=randomString(64) + pwd, PKCS7) -> base64
盐值来源:登录页 <input id="pwdEncryptSalt" value="...">(每次会话动态下发)
随机串字符集与服务端一致(不含 I/L/O 等易混字符):
    ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678
"""
import base64
import random

from Crypto.Cipher import AES

AES_CHARS = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678"


def random_string(n: int) -> str:
    return "".join(random.choice(AES_CHARS) for _ in range(n))


def _pkcs7_pad(data: bytes) -> bytes:
    n = 16 - len(data) % 16
    return data + bytes([n]) * n


def encrypt_password(password: str, salt: str) -> str:
    """与 encrypt.js encryptPassword 等价。"""
    if not salt:
        return password
    key = salt.strip().encode("utf-8")          # getAesString 里 trim 过
    iv = random_string(16).encode("utf-8")
    plain = _pkcs7_pad((random_string(64) + password).encode("utf-8"))
    cipher = AES.new(key, AES.MODE_CBC, iv)
    return base64.b64encode(cipher.encrypt(plain)).decode("ascii")
