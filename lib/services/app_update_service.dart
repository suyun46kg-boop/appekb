import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/supabase/supabase.dart';

const _dismissedVersionKey = 'app_update_dismissed_version';
const _localeStorageKey = '__locale_key__';

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.forceUpdate,
    required this.softUpdate,
    required this.message,
    required this.storeUrl,
    required this.latestVersion,
    required this.currentVersion,
  });

  final bool forceUpdate;
  final bool softUpdate;
  final String message;
  final String storeUrl;
  final String latestVersion;
  final String currentVersion;
}

class AppUpdateService {
  AppUpdateService._();

  static Future<AppUpdateCheckResult?> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final rows = await AppConfigTable().queryRows(
        queryFn: (q) => q.eq('id', 'default'),
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }

      final config = rows.first;
      final message = await _localizedMessage(config);
      final storeUrl = _storeUrl(config);

      if (compareVersions(currentVersion, config.minVersion) < 0) {
        return AppUpdateCheckResult(
          forceUpdate: true,
          softUpdate: false,
          message: message,
          storeUrl: storeUrl,
          latestVersion: config.latestVersion,
          currentVersion: currentVersion,
        );
      }

      if (compareVersions(currentVersion, config.latestVersion) < 0) {
        final prefs = await SharedPreferences.getInstance();
        final dismissedVersion = prefs.getString(_dismissedVersionKey);
        if (dismissedVersion == config.latestVersion) {
          return null;
        }

        return AppUpdateCheckResult(
          forceUpdate: false,
          softUpdate: true,
          message: message,
          storeUrl: storeUrl,
          latestVersion: config.latestVersion,
          currentVersion: currentVersion,
        );
      }

      return null;
    } catch (e) {
      debugPrint('App update check failed: $e');
      return null;
    }
  }

  static Future<void> dismissSoftUpdate(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, latestVersion);
  }

  static int compareVersions(String a, String b) {
    final partsA = a.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final partsB = b.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final length = partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < length; i++) {
      final valueA = i < partsA.length ? partsA[i] : 0;
      final valueB = i < partsB.length ? partsB[i] : 0;
      if (valueA != valueB) {
        return valueA.compareTo(valueB);
      }
    }
    return 0;
  }

  static Future<String> _localizedMessage(AppConfigRow config) async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString(_localeStorageKey) ?? 'ru';
    return locale == 'ky' ? config.messageKy : config.messageRu;
  }

  static String _storeUrl(AppConfigRow config) {
    if (!kIsWeb && Platform.isIOS && config.iosUrl.isNotEmpty) {
      return config.iosUrl;
    }
    return config.androidUrl;
  }
}
