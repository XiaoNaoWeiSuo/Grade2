/// 第③步：教务应用授权（sdp_user_token + verify JWT）
/// （对应 grabber/step3_app.py）。
///
/// 链路（抓包实测）：
/// ```text
/// GET  {EAMS}/eams/localLogin.action?sdpAppCode=<app>&unitId=<unit>
///      → 网关下发 sdp_user_token Cookie(值 == 门户 sid)
///      → 若未授权,返回中转页 HTML,内嵌 var locationUrl="{PORTAL}/controller/v1/public/verify?t=<JWT>"
/// GET  verify?t=<JWT>   (JWT 自包含, timeout=600s) → 302 回应用入口
///      → CAS 免密接力(CASTGC)→ ST → URP localLogin.action?ticket=ST
///      → 302 ...;jsessionid=... → 302 /eams/home.action
/// ```
///
/// 自愈设计：本步骤可重复执行；任何一次被网关拦回中转页，都会自动重走 verify。
library;

import '../crawler_exceptions.dart';
import '../models/config_models.dart';
import 'http_client.dart';

class Step3App {
  Step3App({required this.http, required this.config, this.onLog});

  final SessionHttpClient http;
  final GrabberConfig config;
  final void Function(String message)? onLog;

  static final RegExp _interstitial =
      RegExp(r'var\s+locationUrl\s*=\s*"([^"]+)"');

  /// 进入教务系统，建立 JSESSIONID 会话。
  ///
  /// 成功条件：最终落点为 /eams/home.action 且存在 JSESSIONID cookie。
  /// 抛出：[AppAuthError]/[HttpError]。
  Future<void> enter() async {
    var url = config.appEntryWithParams;
    var resp = await http.get(Uri.parse(url),
        headers: {'Referer': '${config.portalBase}/portal/'});
    var verifyHits = 0;
    var noParamHits = 0;

    for (var i = 0; i < config.maxHops; i++) {
      // 手动跟随 3xx（302 后转 GET）
      var hops = 0;
      while (resp.isRedirect && (resp.header('location') ?? '').isNotEmpty) {
        final next = resp.url.resolve(resp.header('location')!);
        resp =
            await http.get(next, headers: {'Referer': resp.url.toString()});
        hops++;
        if (hops > config.maxHops) {
          throw AppAuthError('重定向跳数超限: ${resp.url}');
        }
      }

      final path = resp.url.path.split(';')[0];

      if (path == '/eams/home.action') {
        if (!http.hasCookie('JSESSIONID')) {
          throw const AppAuthError('已到 home.action 但缺少 JSESSIONID');
        }
        onLog?.call('教务会话建立(JSESSIONID/GSESSIONID + sdp_user_token)');
        return;
      }

      if (resp.statusCode == 200) {
        final m = _interstitial.firstMatch(resp.body);
        if (m != null && m.group(1)!.contains('/controller/v1/public/verify')) {
          // 命中网关中转页 → 重走 verify?t=<JWT>（自愈，最多 5 次）
          verifyHits++;
          if (verifyHits > 5) {
            throw const AppAuthError('verify 中转页循环超过 5 次');
          }
          url = m.group(1)!;
          onLog?.call('命中网关中转页 → verify?t=<JWT 第 $verifyHits 次>');
          resp = await http.get(Uri.parse(url),
              headers: {'Referer': resp.url.toString()});
          continue;
        }
        if (path == '/eams/localLogin.action') {
          // 模拟浏览器第二击：无参入口，触发 CAS 免密接力（最多 3 次）
          noParamHits++;
          if (noParamHits > 3) break;
          url = config.appEntry;
          resp = await http.get(Uri.parse(url),
              headers: {'Referer': resp.url.toString()});
          continue;
        }
        break; // 其他页面(多为 CAS 登录页,CASTGC 已失效)
      }
      break;
    }

    final tail = _clip(resp.body, 150).replaceAll('\n', ' ');
    throw AppAuthError('未能进入 /eams/home.action,落点: ${resp.url} | 页面片段: $tail');
  }

  static String _clip(String s, int n) =>
      s.length > n ? s.substring(0, n) : s;
}
