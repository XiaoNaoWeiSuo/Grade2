import 'package:dio/dio.dart';
import 'package:enough_mail/enough_mail.dart';

import '../config/app_secrets.dart';
import 'version_utils.dart';

/// 邮件服务：用户反馈上报 / 登录日志匿名上报。
class MailService {
  MailService._();

  /// [isFeedback] 为 true 时发送用户反馈邮件，否则先向服务端上报一条登录日志。
  static Future<void> send(String name, String campus, String content,
      bool isFeedback, String account) async {
    Dio dio = Dio();

    final client = SmtpClient('neverouo.bug', isLogEnabled: true);
    try {
      await client.connectToServer('smtp.163.com', 465, isSecure: true);
      await client.ehlo();
      if (client.serverInfo.supportsAuth(AuthMechanism.plain)) {
        await client.authenticate(
            AppSecrets.smtpUser, AppSecrets.smtpPassword, AuthMechanism.plain);
      } else if (client.serverInfo.supportsAuth(AuthMechanism.login)) {
        await client.authenticate(
            AppSecrets.smtpUser, AppSecrets.smtpPassword, AuthMechanism.login);
      } else {
        return;
      }
      String version = await getVersionapp();
      if (!isFeedback) {
        try {
          await dio
              .get("http://49.235.106.67:5000/api/log/$account/$campus/$name/$version/");
        } catch (e) {
          Null;
        }
      }
      final builder = MessageBuilder.prepareMultipartAlternativeMessage();
      builder.from = [
        MailAddress(
            (isFeedback ? 'Grade用户反馈' : "Grade用户登录"), AppSecrets.smtpUser)
      ];
      builder.to = [const MailAddress('小脑萎缩', 'xiaonaoweisu@qq.com')];
      builder.subject = "$campus:$name";
      builder.addTextPlain("版本：$version\n$content");
      final mimeMessage = builder.buildMimeMessage();
      await client.sendMessage(mimeMessage);
    } on SmtpException {
      Null;
    }
  }
}
