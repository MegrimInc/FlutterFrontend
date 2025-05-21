import 'dart:io';

import 'package:barzzy/Backend/database.dart';
import 'package:barzzy/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum Environment { test, live }

class AppConfig {
  static Environment environment = Environment.test;

  // ---------- STRIPE ----------
   static String get stripePublishableKey {
    switch (environment) {
      case Environment.test:
        return 'pk_test_51QIHPQALmk8hqurjW70pr2kLZg1lr0bXN9K6uMdf9oDPwn3olIIPRd2kJncr8rGMKjVgSUsZztTtIcPwDlLfchgu00dprIZKma'; 
      case Environment.live:
        return 'pk_live_51QIHPQALmk8hqurj9QQVsCMabyzQ3hCJrxk1PhLNJFXDHfbmQqkJzEdOIrXlGd27hBEJchOuLBjIrb6WKxKiUKoo00tOVyaRdA'; 
    }
  }

  // ---------- POSTGRES ----------
  static String get postgresHttpBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'https://www.barzzy.site/postgres-test-http';
      case Environment.live:
        return 'https://www.barzzy.site/postgres-live-http';
    }
  }

  static String get postgresWsBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'wss://www.barzzy.site/postgres-test-ws';
      case Environment.live:
        return 'wss://www.barzzy.site/postgres-live-ws';
    }
  }

  // ---------- REDIS ----------
  static String get redisHttpBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'https://www.barzzy.site/redis-test-http';
      case Environment.live:
        return 'https://www.barzzy.site/redis-live-http';
    }
  }

  static String get redisWsBaseUrl {
    switch (environment) {
      case Environment.test:
        return 'wss://www.barzzy.site/redis-test-ws';
      case Environment.live:
        return 'wss://www.barzzy.site/redis-live-ws';
    }
  }

  Future<void> enforceVersionPolicy(BuildContext context) async {
  final deviceInfo = DeviceInfoPlugin();
  final config = LocalDatabase().config;

  if (config == null) return;

  String currentVersion = '';
  String minVersion = '';
  List<String> blockedVersions = [];

  if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    final model = iosInfo.utsname.machine.toLowerCase();

    final isTablet = model.contains('ipad');
    currentVersion = isTablet ? currentIOSTabletVersion : currentIOSMobileVersion;

    if (isTablet) {
      minVersion = config.iosTabletMinSupportedVersion;
      blockedVersions = config.iosTabletBlockedVersions;
    } else {
      minVersion = config.iosMobileMinSupportedVersion;
      blockedVersions = config.iosMobileBlockedVersions;
    }
  } else if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    final isTablet = androidInfo.systemFeatures.contains("android.hardware.screen.landscape") &&
        !androidInfo.systemFeatures.contains("android.hardware.telephony");
    currentVersion = '1.0.0'; // Your current Android version

    if (isTablet) {
      minVersion = config.androidTabletMinSupportedVersion;
      blockedVersions = config.androidTabletBlockedVersions;
    } else {
      minVersion = config.androidMobileMinSupportedVersion;
      blockedVersions = config.androidMobileBlockedVersions;
    }
  }

  bool isBlocked = blockedVersions.contains(currentVersion);
  bool isBelowMin = _compareVersions(currentVersion, minVersion) < 0;

  if (isBlocked || isBelowMin) {
    // ignore: use_build_context_synchronously
    await _showForceUpdateDialog(context);
    exit(0);
  }
}

int _compareVersions(String v1, String v2) {
  final parts1 = v1.split('.').map(int.parse).toList();
  final parts2 = v2.split('.').map(int.parse).toList();

  for (int i = 0; i < 3; i++) {
    final p1 = i < parts1.length ? parts1[i] : 0;
    final p2 = i < parts2.length ? parts2[i] : 0;
    if (p1 != p2) return p1.compareTo(p2);
  }
  return 0;
}

Future<void> _showForceUpdateDialog(BuildContext context) async {
  final safeContext = navigatorKey.currentContext;

  if (safeContext == null) return;

  HapticFeedback.heavyImpact();

  await showDialog(
    context: safeContext,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.system_update, color: Colors.black),
            SizedBox(width: 8),
            Text(
              'Update Required',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: const Text(
          "We've made important upgrades to improve your experience and security.\n\nPlease update the Megrim app to continue using it.",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
          textAlign: TextAlign.center,
          
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK',
            style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold
          ),),
          ),
        ],
      );
    },
  );
}
}