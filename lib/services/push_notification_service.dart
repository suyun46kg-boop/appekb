import 'dart:io' show File, Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/firebase_options.dart';
import '/components/notification_permission_sheet.dart';
import '/flutter_flow/nav/nav.dart';
import 'category_subscriptions.dart';

const _androidChannelId = 'ekbkyrgyzdar_default';
const _androidChannelName = 'Уведомления';
const _androidNotificationIcon = 'ic_notification';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) {
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _bootstrapped = false;
  static bool _initialized = false;
  static bool _dialogShowing = false;

  /// Minimal Firebase boot so the native splash can dismiss quickly.
  /// Heavy work (channels, token sync) happens in [initialize].
  static Future<void> bootstrap() async {
    if (_bootstrapped || !DefaultFirebaseOptions.isConfigured || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _bootstrapped = true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  static Future<void> initialize() async {
    if (_initialized || !DefaultFirebaseOptions.isConfigured || kIsWeb) {
      return;
    }

    await bootstrap();
    if (!_bootstrapped) {
      return;
    }

    // Системный запрос разрешения здесь не показываем: его вызывает
    // maybeAskPermission() после пояснения, в подходящий момент.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _setupLocalNotifications();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      syncDeviceToken();
    });

    SupaFlow.client.auth.onAuthStateChange.listen((_) async {
      await syncDeviceToken();
    });

    _initialized = true;
    await syncDeviceToken();
    await _handleInitialMessage();
  }

  static Future<void> syncDeviceToken() async {
    if (!_initialized) {
      return;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      final userId = currentUserUid.isEmpty ? null : currentUserUid;
      final categoryIds = (await CategorySubscriptions.load()).toList()..sort();
      final row = {
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'category_ids': categoryIds,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        await SupaFlow.client
            .from('device_tokens')
            .upsert(row, onConflict: 'fcm_token');
      } on PostgrestException catch (e) {
        // category_push.sql not applied yet — still keep the token itself.
        if (e.code != 'PGRST204') rethrow;
        row.remove('category_ids');
        await SupaFlow.client
            .from('device_tokens')
            .upsert(row, onConflict: 'fcm_token');
      }
    } catch (e) {
      debugPrint('Failed to sync push token: $e');
    }
  }

  /// True once the OS has notification permission — then we stop prompting.
  static Future<bool> isPermissionGranted() async {
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// True while the user is still on the first-run welcome screen.
  static bool isOnWelcome(BuildContext context) {
    try {
      final path =
          GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
      return path == '/welcome';
    } catch (_) {
      return false;
    }
  }

  /// Explains why notifications are needed, then shows the system prompt.
  /// Keeps asking on later visits until the user actually grants permission.
  static Future<void> maybeAskPermission(BuildContext context) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized || !context.mounted || _dialogShowing) {
      return;
    }

    try {
      if (await isPermissionGranted()) {
        await syncDeviceToken();
        return;
      }

      if (!context.mounted || isOnWelcome(context)) {
        return;
      }

      _dialogShowing = true;
      final allow = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => const NotificationPermissionSheet(),
      );

      if (allow != true || !context.mounted) {
        return;
      }

      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      } else {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (await isPermissionGranted()) {
        await syncDeviceToken();
      }
    } catch (e) {
      debugPrint('Push permission request failed: $e');
    } finally {
      _dialogShowing = false;
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings(_androidNotificationIcon);
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayloadNavigation(response.payload);
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _androidChannelId,
              _androidChannelName,
              description: 'Новости и сообщения приложения',
              importance: Importance.high,
            ),
          );
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    // На iOS баннер в открытом приложении показывает сама система
    // (setForegroundNotificationPresentationOptions), иначе будет дубль.
    if (notification == null || Platform.isIOS) {
      return;
    }

    final imageUrl = notification.android?.imageUrl ??
        notification.apple?.imageUrl ??
        message.data['image_url'];
    final payload = _encodePayload(message.data);
    final androidDetails = await _buildAndroidNotificationDetails(imageUrl);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          attachments: imageUrl != null && imageUrl.isNotEmpty
              ? [DarwinNotificationAttachment(imageUrl)]
              : null,
        ),
      ),
      payload: payload,
    );
  }

  static Future<AndroidNotificationDetails> _buildAndroidNotificationDetails(
    String? imageUrl,
  ) async {
    const baseDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Новости и сообщения приложения',
      importance: Importance.high,
      priority: Priority.high,
      icon: _androidNotificationIcon,
    );

    if (imageUrl == null || imageUrl.isEmpty || kIsWeb) {
      return baseDetails;
    }

    try {
      final imagePath = await _downloadImage(imageUrl);
      if (imagePath == null) {
        return baseDetails;
      }

      return AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Новости и сообщения приложения',
        importance: Importance.high,
        priority: Priority.high,
        icon: _androidNotificationIcon,
        styleInformation: BigPictureStyleInformation(
          FilePathAndroidBitmap(imagePath),
          largeIcon: FilePathAndroidBitmap(imagePath),
        ),
      );
    } catch (e) {
      debugPrint('Failed to load notification image: $e');
      return baseDetails;
    }
  }

  static Future<String?> _downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      return null;
    }

    final extension = imageUrl.contains('.png') ? 'png' : 'jpg';
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/push_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }

  static Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleNotificationNavigation(message);
    }
  }

  static void _handleNotificationNavigation(RemoteMessage message) {
    _handlePayloadNavigation(_encodePayload(message.data));
  }

  static void _handlePayloadNavigation(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    final data = Uri.splitQueryString(payload);
    final route = data['route'];
    if (route == null || route.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(route);
    final isExternalUrl = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (isExternalUrl) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final context = appNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    context.go(route);
  }

  static String _encodePayload(Map<String, dynamic> data) {
    return data.entries
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent('${entry.value}')}')
        .join('&');
  }
}
