// 第②步门户会话单元测试：authCheck 风控判定 + 短信增强认证响应解析。
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/core/crawler/crawler_exceptions.dart';
import 'package:grade2/core/crawler/session/step2_portal.dart';

void main() {
  group('Step2Portal.buildPortalUri', () {
    test('path 自带 action query 必须保留（sendsms 400 回归）', () {
      final u = Step2Portal.buildPortalUri(
        'https://portal.example:4443',
        '/passport/v1/auth/sms?action=sendsms',
        {'clientType': 'SDPBrowserClient', 'platform': 'iOS', 'lang': 'en-US'},
        {'taskId': 'ACL:1', 'authId': 'a1'},
      );
      expect(u.queryParameters['action'], 'sendsms');
      expect(u.queryParameters['taskId'], 'ACL:1');
      expect(u.queryParameters['clientType'], 'SDPBrowserClient');
      expect(u.host, 'portal.example');
      expect(u.port, 4443);
    });

    test('无自带 query 的路径不受影响', () {
      final u = Step2Portal.buildPortalUri(
          'https://portal.example:4443',
          '/passport/v1/auth/authCheck',
          {'clientType': 'x'},
          {'mod': '1'});
      expect(u.queryParameters['mod'], '1');
      expect(u.queryParameters.containsKey('action'), false);
    });
  });

  group('Step2Portal.parseSmsSendResponse', () {
    test('实测发送成功响应 → 掩码手机号 + 60s 间隔（interval 为字符串）', () {
      // 2026-09-10 实测捕获：interval 服务端返回字符串 "60"
      final c = Step2Portal.parseSmsSendResponse({
        'code': 0,
        'message': 'SMS message sent successfully',
        'data': {
          'tips': '验证码已发送到您的手机：193****0952, 请查收！',
          'interval': '60',
          'currentService': 'auth/sms',
          'type': 'enhanced',
        },
      });
      expect(c.maskedPhone, '193****0952');
      expect(c.intervalSeconds, 60);
    });

    test('interval 为 int 时同样兼容', () {
      final c = Step2Portal.parseSmsSendResponse({
        'code': 0,
        'data': {'tips': '已发送 193****0952', 'interval': 60},
      });
      expect(c.intervalSeconds, 60);
    });

    test('发送失败（非 0 code）→ PortalError', () {
      expect(
        () => Step2Portal.parseSmsSendResponse({
          'code': 75500001,
          'message': 'sending too frequently',
        }),
        throwsA(isA<PortalError>()),
      );
    });
  });

  group('Step2Portal.isSecondaryAuthRequired', () {
    test('风控响应（enhanced + 短信二次认证）→ true', () {
      // 2026-09-10 实测捕获的完整形状（节选）
      const riskResponse = {
        'code': 10000006,
        'message':
            'Operation failed. The current page is not found or has been opened in another tab of the browser.',
        'data': {
          'currentService': 'auth/authCheck',
          'nextService': 'auth/sms',
          'type': 'enhanced',
          'message':
              'Potential risks exist for the current login. Please perform enhanced authentication',
          'skipSecondaryAuthStatus': 0,
          'nextServiceList': [
            {
              'authId': '5b717940-4009-11ed-ab5d-0fcee6455c3b',
              'authType': 'auth/sms',
              'authName': '二次认证',
              'description': '玄武科技短信认证平台-辅',
              'subType': 'https',
            }
          ],
        },
        'traceId': '320ebdab',
      };
      expect(Step2Portal.isSecondaryAuthRequired(riskResponse), true);
    });

    test('仅 type=enhanced（无 nextServiceList）→ true', () {
      expect(
        Step2Portal.isSecondaryAuthRequired({
          'code': 10000006,
          'type': 'enhanced',
          'data': <String, Object?>{},
        }),
        true,
      );
    });

    test('code=0 但 data 内嵌 ACL 增强认证指令（PolicyDisobeyed）→ true', () {
      // 2026-09-10 实测第二种形状：code=0 + data 内嵌增强认证要求
      const aclResponse = {
        'code': 0,
        'message': "acl check not passed('L000002'): PolicyDisobeyed",
        'data': {
          'actionType': 'prevEffect',
          'action': 'auth/sms',
          'reason': 'PolicyDisobeyed',
          'type': 'enhanced',
          'message':
              'Potential risks exist for the current login. Please perform enhanced authentication',
          'nextService': 'auth/sms',
          'nextServiceList': [
            {'authType': 'auth/sms', 'authName': '二次认证'}
          ],
        },
      };
      expect(Step2Portal.isSecondaryAuthRequired(aclResponse), true);
    });

    test('仅 nextService=auth/sms → true', () {
      expect(
        Step2Portal.isSecondaryAuthRequired({
          'code': 1,
          'data': {'nextService': 'auth/sms'},
        }),
        true,
      );
    });

    test('普通业务失败（无风控特征）→ false', () {
      expect(
        Step2Portal.isSecondaryAuthRequired({
          'code': 1,
          'message': 'token expired',
          'data': <String, Object?>{},
        }),
        false,
      );
      expect(
        Step2Portal.isSecondaryAuthRequired(<String, Object?>{}),
        false,
      );
    });
  });
}
