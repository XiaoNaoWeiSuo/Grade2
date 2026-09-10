/// 纯 Dart 实现的 AES-128-CBC 加密（仅加密方向）+ PKCS7 填充。
///
/// 依据 FIPS-197 标准实现，已用 NIST SP 800-38A 测试向量验证：
/// - FIPS-197 附录 C.1 单块向量
/// - SP 800-38A F.2.1 CBC-AES128 向量
///
/// 不引入任何第三方库（pubspec 的 crypto 包只提供哈希，无 AES）。
/// 内核仅在第①步 CAS 密码加密时使用（见 cas_crypto.dart）。
library;

import 'dart:convert';
import 'dart:typed_data';

/// AES-128（密钥 16 字节）分组密码，仅支持加密。
class Aes128 {
  /// 以 16 字节密钥构造。密钥长度必须为 16。
  Aes128(Uint8List key) {
    if (key.length != 16) {
      throw ArgumentError('AES-128 密钥必须 16 字节, 收到 ${key.length}');
    }
    _expandKey(key);
  }

  /// AES S 盒（FIPS-197 图 7）。
  static const List<int> _sbox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, //
    0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
    0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7, 0xfd, 0x93, 0x26,
    0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2,
    0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
    0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed,
    0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f,
    0x50, 0x3c, 0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
    0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec,
    0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14,
    0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 0xe7, 0xc8, 0x37, 0x6d,
    0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f,
    0x4b, 0xbd, 0x8b, 0x8a, 0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
    0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11,
    0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f,
    0xb0, 0x54, 0xbb, 0x16,
  ];

  /// 轮常量 Rcon（AES-128 共 10 轮）。
  static const List<int> _rcon = [
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36,
  ];

  /// GF(2^8) 乘 2 / 乘 3 查表（MixColumns 用）。
  static final List<int> _mul2 = List<int>.generate(256, _xtime);
  static final List<int> _mul3 =
      List<int>.generate(256, (i) => _xtime(i) ^ i);

  static int _xtime(int x) => ((x << 1) ^ (x & 0x80 != 0 ? 0x1b : 0)) & 0xff;

  /// 11 个轮密钥（每个 16 字节，按列展开为 44 个 32 位字）。
  late final Uint32List _roundKeys = Uint32List(44);

  void _expandKey(Uint8List key) {
    for (var i = 0; i < 4; i++) {
      _roundKeys[i] = (key[4 * i] << 24) |
          (key[4 * i + 1] << 16) |
          (key[4 * i + 2] << 8) |
          key[4 * i + 3];
    }
    for (var i = 4; i < 44; i++) {
      var t = _roundKeys[i - 1];
      if (i % 4 == 0) {
        // RotWord + SubWord + Rcon
        t = ((t << 8) | (t >>> 24)) & 0xffffffff; // 循环左移 1 字节
        t = (_sbox[(t >>> 24) & 0xff] << 24) |
            (_sbox[(t >>> 16) & 0xff] << 16) |
            (_sbox[(t >>> 8) & 0xff] << 8) |
            _sbox[t & 0xff];
        t ^= _rcon[i ~/ 4 - 1] << 24;
      }
      _roundKeys[i] = _roundKeys[i - 4] ^ t;
    }
  }

  /// 加密单个 16 字节块（原地语义：返回新数组）。
  Uint8List encryptBlock(Uint8List input) {
    if (input.length != 16) {
      throw ArgumentError('AES 块必须 16 字节');
    }
    // 状态按列映射：s[r][c] = input[r + 4c]，用 16 字节数组直接表示。
    final s = Uint8List.fromList(input);

    void addRoundKey(int round) {
      final w = _roundKeys;
      for (var c = 0; c < 4; c++) {
        final k = w[round * 4 + c];
        s[0 + c * 4] ^= (k >>> 24) & 0xff;
        s[1 + c * 4] ^= (k >>> 16) & 0xff;
        s[2 + c * 4] ^= (k >>> 8) & 0xff;
        s[3 + c * 4] ^= k & 0xff;
      }
    }

    addRoundKey(0);
    for (var round = 1; round <= 10; round++) {
      // SubBytes
      for (var i = 0; i < 16; i++) {
        s[i] = _sbox[s[i]];
      }
      // ShiftRows：行 r 左移 r（列主序布局 s[r + 4c]）
      _shiftRows(s);
      // MixColumns（末轮省略）
      if (round != 10) _mixColumns(s);
      addRoundKey(round);
    }
    return s;
  }

  static void _shiftRows(Uint8List s) {
    // 行 1 左移 1
    var t = s[1];
    s[1] = s[5];
    s[5] = s[9];
    s[9] = s[13];
    s[13] = t;
    // 行 2 左移 2（对换两次）
    t = s[2];
    s[2] = s[10];
    s[10] = t;
    t = s[6];
    s[6] = s[14];
    s[14] = t;
    // 行 3 左移 3（等价右移 1）
    t = s[15];
    s[15] = s[11];
    s[11] = s[7];
    s[7] = s[3];
    s[3] = t;
  }

  static void _mixColumns(Uint8List s) {
    for (var c = 0; c < 4; c++) {
      final i = c * 4;
      final a0 = s[i], a1 = s[i + 1], a2 = s[i + 2], a3 = s[i + 3];
      s[i] = _mul2[a0] ^ _mul3[a1] ^ a2 ^ a3;
      s[i + 1] = a0 ^ _mul2[a1] ^ _mul3[a2] ^ a3;
      s[i + 2] = a0 ^ a1 ^ _mul2[a2] ^ _mul3[a3];
      s[i + 3] = _mul3[a0] ^ a1 ^ a2 ^ _mul2[a3];
    }
  }
}

/// PKCS7 填充（块大小 16）。
Uint8List pkcs7Pad(Uint8List data, {int blockSize = 16}) {
  final n = blockSize - data.length % blockSize;
  return Uint8List.fromList([...data, ...List<int>.filled(n, n)]);
}

/// AES-128-CBC 加密：明文自动 PKCS7 填充，返回密文字节。
///
/// [key]/[iv] 长度必须为 16。
Uint8List aes128CbcEncrypt(Uint8List key, Uint8List iv, Uint8List plaintext) {
  if (key.length != 16) throw ArgumentError('key 必须 16 字节');
  if (iv.length != 16) throw ArgumentError('iv 必须 16 字节');
  final cipher = Aes128(key);
  final padded = pkcs7Pad(plaintext);
  final out = Uint8List(padded.length);
  var prev = iv;
  for (var off = 0; off < padded.length; off += 16) {
    final block = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      block[i] = padded[off + i] ^ prev[i];
    }
    final enc = cipher.encryptBlock(block);
    out.setRange(off, off + 16, enc);
    prev = enc;
  }
  return out;
}

/// 便捷方法：UTF-8 明文 → AES-128-CBC → base64 密文。
String aes128CbcEncryptToBase64(String key, String iv, String plaintext) {
  final cipher = aes128CbcEncrypt(
    Uint8List.fromList(utf8.encode(key)),
    Uint8List.fromList(utf8.encode(iv)),
    Uint8List.fromList(utf8.encode(plaintext)),
  );
  return base64.encode(cipher);
}
