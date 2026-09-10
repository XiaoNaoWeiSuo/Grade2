/// 爬虫内核输入模型：全局配置 + 账号凭据。
///
/// 这两类是内核中仅有的"万不得已"使用强类型类的数据——它们是
/// 参数传递闭环的输入端，强类型可以在编译期约束 UI 层的注入。
/// 其余全部业务数据均为原生 Map/List（见 data_models.dart）。
library;

/// aTrust 零信任网关 + 教务系统(URP)爬虫全局配置。
///
/// 默认值 1:1 对应 grabber/config.py（抓包实测）。所有字段均可覆写，
/// 便于测试注入或未来域名变更。
class GrabberConfig {
  const GrabberConfig({
    this.casBase = _casBase,
    this.portalBase = _portalBase,
    this.eamsBase = _eamsBase,
    this.sdpAppCode = _sdpAppCode,
    this.unitId = _unitId,
    this.userAgent = _userAgent,
    this.acceptLanguage = _acceptLanguage,
    this.timeout = 20,
    this.maxHops = 24,
    this.getRetries = 2,
    this.sessionTtl = 12 * 60,
    this.maxLoginPostsPerRun = 1,
  });

  // ===== aTrust 零信任网关三个域名（抓包实测） =====
  static const _casBase = 'https://cas-yangtzeu-edu-cn.atrust.yangtzeu.edu.cn';
  static const _portalBase = 'https://atrust.yangtzeu.edu.cn:4443';
  static const _eamsBase = 'https://jwc3-yangtzeu-edu-cn-s.atrust.yangtzeu.edu.cn';

  // 教务应用在网关上的静态标识（抓包实测，长期不变）
  static const _sdpAppCode = '172f31db-be9b-4b53-a6b4-c3c9a5324854';
  static const _unitId = '22b2c333-05b0-432c-845e-152f6f883b5e';

  // ===== 请求模拟（伪装 SDP 内置浏览器） =====
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 '
      'cpdaily/9.9.22 wisedu/9.9.22';
  static const _acceptLanguage = 'zh-SG,zh-CN;q=0.9,zh-Hans;q=0.8';

  /// CAS 统一身份认证（经网关域名映射）。
  final String casBase;

  /// aTrust 门户/控制器。
  final String portalBase;

  /// 教务系统(URP /eams/)的网关代理域名。
  final String eamsBase;

  /// 教务应用在网关上的静态标识。
  final String sdpAppCode;

  /// 租户 unitId。
  final String unitId;

  /// 全局 User-Agent。
  final String userAgent;

  /// 全局 Accept-Language。
  final String acceptLanguage;

  /// 单请求超时（秒）。
  final int timeout;

  /// 单条链路最大重定向跳数。
  final int maxHops;

  /// GET 类请求网络错误重试次数（POST 永不重试）。
  final int getRetries;

  /// 授权会话有效期实测 15min，缓存 12min 内视为新鲜，留 3min 余量（秒）。
  final int sessionTtl;

  /// 防封号硬约束：单次 [CrawlerSession] 生命周期内最多 1 次密码登录 POST，
  /// 失败立即终止、绝不自动重试。
  final int maxLoginPostsPerRun;

  /// CAS service：登录成功后跳回 aTrust 换取门户会话 sid。
  String get casService => '$portalBase/passport/v1/auth/cas?sfDomain=CAS';

  /// 门户 API 公共 query 参数（clientType 等）。
  Map<String, String> get clientQuery => const {
        'clientType': 'SDPBrowserClient',
        'platform': 'iOS',
        'lang': 'en-US',
      };

  /// 教务应用授权入口（第③步 GET 目标）。
  String get appEntry => '$eamsBase/eams/localLogin.action';

  /// 带静态标识的应用授权入口。
  String get appEntryWithParams =>
      '$appEntry?sdpAppCode=$sdpAppCode&unitId=$unitId';

  /// 门户域名主机（设置 online cookie 等用途）。
  String get portalHost => Uri.parse(portalBase).host;

  /// 教务域名主机（设置 semester.id cookie 等用途）。
  String get eamsHost => Uri.parse(eamsBase).host;
}

/// 账号凭据（CAS 用户名/密码）。由 UI 层安全存储注入，内核不落盘明文。
class CrawlerCredentials {
  const CrawlerCredentials({required this.username, required this.password});

  /// 学号/工号。
  final String username;

  /// CAS 密码明文（仅在第①步内存中使用，绝不持久化）。
  final String password;
}
