import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/keys/global_keys.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  final String currentVersion = '1.0.0'; // Elle tanımladığın app versiyonu

  Future<void> checkForUpdate() async {
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));

      await remoteConfig.fetchAndActivate();

      final requiredVersion = remoteConfig.getString('minimum_version_code');
      debugPrint(
          'Gereken sürüm: $requiredVersion / Kullanıcı: $currentVersion');

      if (_isOlderThan(currentVersion, requiredVersion)) {
        _showUpdateDialog(
          'Yeni sürüm çıktı! Lütfen güncelleyin.',
          Platform.isAndroid
              ? 'https://play.google.com/store/apps/details?id=com.orderbros.palse'
              : 'https://apps.apple.com/app/id6502776249',
        );
      }
    } catch (e) {
      debugPrint('Update kontrolü başarısız: $e');
    }
  }

  bool _isOlderThan(String current, String required) {
    final currentParts = current.split('.').map(int.parse).toList();
    final requiredParts = required.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < requiredParts[i]) return true;
      if (currentParts[i] > requiredParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(String message, String url) {
    final BuildContext? context =
        GlobalKeys.instance.navigatorKey.currentContext;
    if (context == null) {
      debugPrint("Navigator context is null, can't show update dialog.");
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Yeni Güncelleme"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication),
              child: const Text("Güncelle"),
            ),
          ],
        ),
      );
    });
  }
}
