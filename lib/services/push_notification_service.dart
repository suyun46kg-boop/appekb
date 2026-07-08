import 'dart:io' show File, Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/firebase_options.dart';
import '/flutter_flow/nav/nav.dart';

const _androidChannelId = 'ekbkyrgyzdar_default';
const _androidChannelName = 'Уведомления';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || !DefaultFirebaseOptions.isConfigured) {
      return;
    }

    if (kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
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

      await SupaFlow.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'platform': platform,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
    } catch (e) {
      debugPrint('Failed to sync push token: $e');
    }
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    if (notification == null) {
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
      icon: '@mipmap/ic_launcher',
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
        icon: '@mipmap/ic_launcher',
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
