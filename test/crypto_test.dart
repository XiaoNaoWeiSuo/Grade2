// AES-128-CBC 加密单元测试：标准向量 + pycryptodome 交叉验证 + CAS 口令封装。
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/crypto/aes_cbc.dart';
import 'package:grade2/core/crawler/crypto/cas_crypto.dart';

String hex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List unhex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2)
        int.parse(s.substring(i, i + 2), radix: 16)
    ]);

void main() {
  group('AES-128 单块 (FIPS-197 附录 C.1)', () {
    test('encryptBlock', () {
      final key = unhex('000102030405060708090a0b0c0d0e0f');
      final pt = unhex('00112233445566778899aabbccddeeff');
      expect(hex(Aes128(key).encryptBlock(pt)),
          '69c4e0d86a7b0430d8cdb78070b4c55a');
    });
  });

  group('CBC 模式 (NIST SP 800-38A F.2.1)', () {
    test('4 块加密', () {
      final key = unhex('2b7e151628aed2a6abf7158809cf4f3c');
      final iv = unhex('000102030405060708090a0b0c0d0e0f');
      final pt = unhex(
          '6bc1bee22e409f96e93d7e117393172a'
          'ae2d8a571e03ac9c9eb76fac45af8e51'
          '30c81c46a35ce411e5fbc1191a0a52ef'
          'f69f2445df4f9b17ad2b417be66c3710');
      final ct = aes128CbcEncrypt(key, iv, pt);
      expect(
          hex(ct).substring(0, 128),
          '7649abac8119b246cee98e9b12e9197d'
          '5086cb9b507219ee95db113a917678b2'
          '73bed6b8e3c1743b7116e69e22229516'
          '3ff1caa1681fac09120eca307586e1a7');
      // 明文恰为整块 → PKCS7 追加一整块填充 (64+16=80)
      expect(ct.length, 80);
    });
  });

  group('pycryptodome 交叉验证（golden 抓包同构）', () {
    test('AES-128-CBC/base64(中文明文)', () {
      expect(aes128CbcEncryptToBase64('abcdefghijklmnop', '0123456789abcdef',
              'hello中文'),
          '8W3uxYxszYs8L1y/U1uNGQ==');
    });
  });

  group('encryptPassword (CAS encrypt.js 语义)', () {
    test('盐为空 → 返回明文', () {
      expect(encryptPassword('pwd123', ''), 'pwd123');
    });

    test('盐非空 → base64 密文，长度为 16 字节的倍数', () {
      final out = encryptPassword('changjiangdaxue@923', '2i7HaBcDeFgHiJkL');
      // base64 解码后应为 16 字节整数倍（64 随机前缀 + 密码 17B = 81B → 96B 密文）
      final decoded = base64Decode(out);
      expect(decoded.length % 16, 0);
      expect(decoded.length, 96);
      // 每次加密 IV/前缀随机 → 两次密文不同
      expect(encryptPassword('x', '0123456789abcdef'),
          isNot(encryptPassword('x', '0123456789abcdef')));
    });

    test('盐含首尾空白被 trim（getAesString 语义）', () {
      // trim 后恰为 16 字节 → 合法 AES key，加密成功
      expect(encryptPassword('pwd', '  0123456789abcdef  ').length, greaterThan(0));
    });

    test('randomString 字符集与服务端一致', () {
      const charset =
          'ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678';
      final s = randomString(200);
      for (var i = 0; i < s.length; i++) {
        expect(charset.contains(s[i]), true, reason: '非法字符: ${s[i]}');
      }
      expect(randomString(16).length, 16);
    });

    test('randomHex 为 n 字节 hex', () {
      final h = randomHex(32);
      expect(h.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(h), true);
    });
  });
}
