import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'push_notification_service.dart';

/// Root category ids the user wants push notifications for.
///
/// Stored locally and mirrored to `device_tokens.category_ids`, which the
/// `notify-new-listing` function uses to pick recipients.
abstract final class CategorySubscriptions {
  static const _prefsKey = 'category_subscriptions';

  static Future<Set<int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_prefsKey) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  static Future<void> save(Set<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKey,
        (ids.toList()..sort()).map((id) => '$id').toList(),
      );
    } catch (_) {
      return;
    }
    unawaited(PushNotificationService.syncDeviceToken());
  }

  static Future<void> toggle(int id, {required bool subscribed}) async {
    final ids = await load();
    subscribed ? ids.add(id) : ids.remove(id);
    await save(ids);
  }
}
