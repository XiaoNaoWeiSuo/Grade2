/// CAS 密码加密 —— 1:1 复刻服务端 /authserver/.../encrypt.js
/// （对应 grabber/crypto.py，已在线下用抓包密文解密验证）。
///
/// 服务端逻辑：
/// ```text
/// encryptPassword(pwd, salt) -> encryptAES(pwd, salt)
///   salt 为空: 返回明文
///   salt 非空: AES-128-CBC(key=salt, iv=randomString(16),
///                           plaintext=randomString(64) + pwd, PKCS7) -> base64
/// ```
/// 盐值来源：登录页 `<input id="pwdEncryptSalt" value="...">`（每次会话动态下发）。
library;

import 'dart:math';

import 'aes_cbc.dart';

/// 随机串字符集（与服务端 encrypt.js 一致，不含 I/L/O 等易混字符）。
const String aesChars =
    'ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678';

final Random _rng = Random.secure();

/// 生成 n 位随机串（字符集与服务端 randomString 一致）。
String randomString(int n) => List.generate(
      n,
      (_) => aesChars[_rng.nextInt(aesChars.length)],
    ).join();

/// 生成 n 字节随机数据的十六进制串（对标 os.urandom(n).hex()）。
String randomHex(int n) => List.generate(
      n,
      (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

/// 与 encrypt.js 的 encryptPassword 等价。
///
/// [salt] 为空时直接返回明文；否则 AES-128-CBC 加密并 base64。
String encryptPassword(String password, String salt) {
  if (salt.isEmpty) return password;
  final key = salt.trim(); // getAesString 里 trim 过
  final iv = randomString(16);
  final plain = randomString(64) + password;
  return aes128CbcEncryptToBase64(key, iv, plain);
}
