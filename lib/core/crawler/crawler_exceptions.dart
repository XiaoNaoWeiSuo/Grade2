/// 爬虫内核异常体系（1:1 对应 grabber 各步骤异常）。
///
/// 层级：
/// ```text
/// CrawlerException            内核基础异常
/// ├── HttpError               网络层/链路层错误（连接失败、超时、跳数超限）
/// ├── CasError                第①步 CAS 统一身份认证失败
/// │   ├── NeedCaptchaError    需要验证码（主动放弃，不硬闯）
/// │   └── CredentialError     账号凭据被拒（严禁自动重试，防封号）
/// ├── PortalError             第②步 aTrust 门户会话建立失败
/// ├── AppAuthError            第③步教务应用授权失败
/// └── SessionLost             第④步 API 调用中会话失效（可重建后重试）
/// ```
sealed class CrawlerException implements Exception {
  const CrawlerException(this.message);

  /// 人类可读的错误描述（中文，可直接展示给用户）。
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 网络层/链路层错误。
final class HttpError extends CrawlerException {
  const HttpError(super.message);
}

/// 第①步：CAS 统一身份认证失败。
class CasError extends CrawlerException {
  const CasError(super.message);
}

/// 第①步：该账号本次需要验证码，已主动放弃（不硬闯、不重试）。
final class NeedCaptchaError extends CasError {
  const NeedCaptchaError(super.message);
}

/// 第①步：账号凭据被 CAS 拒绝 —— 严禁自动重试（防触发账号锁定）。
final class CredentialError extends CasError {
  const CredentialError(super.message);
}

/// 第②步：aTrust 门户会话建立失败。
final class PortalError extends CrawlerException {
  const PortalError(super.message);
}

/// 第②步：aTrust 网关风控要求二次认证（如短信验证码）。
///
/// 触发条件（2026-09 实测）：同账号高频登录后 authCheck 返回
/// `code: 10000006, type: "enhanced", nextService: "auth/sms"`。
/// 自动化无法代替用户收短信 —— 绝不重试，提示用户：
/// 稍后重试，或先在浏览器完成一次门户登录后再用本应用。
final class NeedSecondaryAuthError extends PortalError {
  const NeedSecondaryAuthError(super.message);
}

/// 第③步：教务应用授权（sdp_user_token + verify JWT）失败。
final class AppAuthError extends CrawlerException {
  const AppAuthError(super.message);
}

/// 第④步：API 调用中会话失效（被踢回登录页/重定向出教务系统）。
///
/// 生命周期约定：调用方捕获本异常后，重新执行
/// [CrawlerSession.ensureApi]（或 [CrawlerSession.withApi] 自动处理）即可重建链路。
final class SessionLost extends CrawlerException {
  const SessionLost(super.message);
}
