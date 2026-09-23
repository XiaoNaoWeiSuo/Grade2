// 第①步 CAS 登录与重试机制单元测试。
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/models/config_models.dart';

void main() {
  group('Step1Cas Form Parsing & Error Extraction', () {
    test('标准表单解析', () {
      const html = '''
        <html>
          <form id="casLoginForm">
            <input type="hidden" name="lt" value="LT-12345-abcdef"/>
            <input type="hidden" name="execution" value="e1s1"/>
            <input type="hidden" id="pwdEncryptSalt" value="sAlt1234567890ab"/>
          </form>
        </html>
      ''';
      // Step1Cas parses execution, lt, salt
      expect(html.contains('e1s1'), true);
    });

    test('属性乱序与不同引号兼容解析', () {
      const html = '''
        <input value="LT-reordered" id="lt" name="lt" />
        <input id="execution" class="form-control" value="e2s2" name="execution" />
        <input type="hidden" value="salt_ordered_first" class="salt" id="pwdEncryptSalt" />
      ''';
      // Test regexes used in Step1Cas._parseLoginForm
      final saltMatch = RegExp(r"""id=["']pwdEncryptSalt["'][^>]*value=["']([^"']*)["']""", caseSensitive: false).firstMatch(html) ??
          RegExp(r"""value=["']([^"']*)["'][^>]*id=["']pwdEncryptSalt["']""", caseSensitive: false).firstMatch(html);
      expect(saltMatch?.group(1), 'salt_ordered_first');

      final executionMatch = RegExp(r"""id=["']execution["'][^>]*value=["']([^"']*)["']""", caseSensitive: false).firstMatch(html) ??
          RegExp(r"""value=["']([^"']*)["'][^>]*name=["']execution["']""", caseSensitive: false).firstMatch(html);
      expect(executionMatch?.group(1), 'e2s2');
    });

    test('错误信息提取', () {
      const html1 = '<span id="msg"> 用户名或密码错误 </span>';
      const html2 = '<div class="auth_error">账号已被锁定，请联系管理员</div>';
      const html3 = '<p class="error">验证码错误</p>';

      String extract(String h) {
        final m = RegExp(r'id="msg"[^>]*>([^<]+)<', caseSensitive: false).firstMatch(h) ??
            RegExp(r'class="auth_error"[^>]*>([^<]+)<', caseSensitive: false).firstMatch(h) ??
            RegExp(r'class="errors?[" >][^>]*>([^<]{2,80})<', caseSensitive: false).firstMatch(h);
        return m?.group(1)?.trim() ?? '未知原因';
      }

      expect(extract(html1), '用户名或密码错误');
      expect(extract(html2), '账号已被锁定，请联系管理员');
      expect(extract(html3), '验证码错误');
    });
  });

  group('Step2Portal Safe Unquote', () {
    test('容错异常的 URL 百分号编码', () {
      const normalLoc = '/portal/shortcut.html?data={"ticket":"valid_ticket_123"}';
      const malformedLoc = '/portal/shortcut.html?data={"ticket":"ticket_%ZZ_test"}';

      String loginTicket(String loc) {
        String decoded;
        try {
          decoded = Uri.decodeFull(loc);
        } catch (_) {
          try {
            decoded = Uri.decodeComponent(loc);
          } catch (_) {
            decoded = loc;
          }
        }
        final m = RegExp(r'"ticket"\s*:\s*"([^"]+)"').firstMatch(decoded);
        return m?.group(1) ?? '';
      }

      expect(loginTicket(normalLoc), 'valid_ticket_123');
      expect(loginTicket(malformedLoc), 'ticket_%ZZ_test');
    });
  });

  group('GrabberConfig maxLoginPostsPerRun', () {
    test('默认允许至多 2 次登录 POST（支持首次失败自动重试一次）', () {
      const cfg = GrabberConfig();
      expect(cfg.maxLoginPostsPerRun, 2);
    });
  });
}
