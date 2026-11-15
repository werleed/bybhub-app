import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';

/// Registers the FCM token with the backend after login.
/// Called once when the user authenticates.
Future<void> registerFcmToken(WidgetRef ref, {String platform = 'android'}) async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('FCM: notification permission not granted');
      return;
    }

    final token = await messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM: no token available');
      return;
    }

    final dio = ref.read(dioProvider);
    await dio.post('/devices', data: {
      'token': token,
      'platform': platform,
      'device_name': 'BYBHUB Mobile',
    });
    debugPrint('FCM: device registered with token ${token.substring(0, 20)}...');
  } catch (e) {
    debugPrint('FCM: failed to register device — $e');
  }
}

/// Listens for FCM token refresh and re-registers.
void setupFcmTokenRefresh(WidgetRef ref, {String platform = 'android'}) {
  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/devices', data: {
        'token': token,
        'platform': platform,
        'device_name': 'BYBHUB Mobile',
      });
    } catch (e) {
      debugPrint('FCM: token refresh failed — $e');
    }
  });
}

/// Handles FCM notification taps (when app is in background or terminated).
/// Returns the data payload for deep linking.
Stream<RemoteMessage> get onMessageOpenedApp =>
    FirebaseMessaging.onMessageOpenedApp;
