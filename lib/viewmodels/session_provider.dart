// 会话状态：替代旧 main.dart 的全局变量 netdata（[Dio, statusCode]）与 enterkey。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/session_client.dart';

/// 登录会话。statusCode 语义与旧代码一致：302=登录成功，400=账号或密码错误。
class SessionState {
  final SessionClient? client;
  final int statusCode;
  final String account;

  const SessionState({this.client, this.statusCode = 0, this.account = ""});

  bool get isOnline => client != null && statusCode == 302;
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  /// 登录成功后写入会话（替代旧 `netdata = await iTing.Login(...)`）
  void signIn(SessionClient client, int statusCode, String account) {
    state = SessionState(client: client, statusCode: statusCode, account: account);
  }

  /// 退出会话
  void signOut() {
    state = const SessionState();
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

/// 当前学期（替代旧全局变量 enterkey）
final currentSemesterProvider = StateProvider<String>((ref) => "");
