// 更新与反馈（关于页 / 登录页更新流程共用）：
// 替代旧 AutherPage 与 LoginPage._startUpdate 中各自为政的版本检查、
// APK 下载安装与反馈邮件逻辑。

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/network/server_api.dart';
import '../core/utils/mail_service.dart';
import '../core/utils/version_utils.dart';

class AboutState {
  final String remoteVersion;
  final String localVersion;
  final List<dynamic> updateLog;
  final double downloadProgress;
  final bool downloading;

  const AboutState({
    this.remoteVersion = "2.0.0",
    this.localVersion = "2.0.0",
    this.updateLog = const [],
    this.downloadProgress = 0.0,
    this.downloading = false,
  });

  bool get needUpdate => isVersionGreaterThan(remoteVersion, localVersion);

  AboutState copyWith({
    String? remoteVersion,
    String? localVersion,
    List<dynamic>? updateLog,
    double? downloadProgress,
    bool? downloading,
  }) {
    return AboutState(
      remoteVersion: remoteVersion ?? this.remoteVersion,
      localVersion: localVersion ?? this.localVersion,
      updateLog: updateLog ?? this.updateLog,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloading: downloading ?? this.downloading,
    );
  }
}

class AboutNotifier extends Notifier<AboutState> {
  static const String _apkUrl = "http://49.235.106.67/arm64-v8a.apk";

  @override
  AboutState build() => const AboutState();

  /// 检查远端版本，返回是否需要更新（永不抛异常，与旧 getversion 兜底一致）
  Future<bool> checkUpdate() async {
    final remote = await ServerApi.getRemoteVersion();
    final local = await getVersionapp();
    state = state.copyWith(remoteVersion: remote, localVersion: local);
    return state.needUpdate;
  }

  /// 加载远端更新日志（旧 getlog）
  Future<void> loadUpdateLog() async {
    state = state.copyWith(updateLog: await ServerApi.getUpdateLog());
  }

  /// 下载 APK 并调起安装（旧 LoginPage._startUpdate / AutherPage 更新逻辑）。
  /// 返回安装结果描述。
  Future<String> downloadAndInstallApk() async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = "${appDocDir.path}/new_version.apk";

    state = state.copyWith(downloading: true, downloadProgress: 0.0);
    await Dio().download(_apkUrl, savePath,
        onReceiveProgress: (count, total) {
      state = state.copyWith(downloadProgress: count / total);
    });

    final res = await OpenFilex.open(savePath);
    state = state.copyWith(downloading: false);
    return "Install apk ${res.type == ResultType.done ? 'success' : 'fail:${res.message}'}";
  }

  /// 用户反馈邮件（旧 AutherPage 的 SenMail(state=true)）
  Future<void> sendFeedback({
    required String name,
    required String campus,
    required String content,
    required String account,
  }) async {
    await MailService.send(name, campus, content, true, account);
  }
}

final aboutProvider = NotifierProvider<AboutNotifier, AboutState>(AboutNotifier.new);

/// 平台辅助：仅 Android 提供 APK 安装流程
bool get canInstallApk => Platform.isAndroid;
