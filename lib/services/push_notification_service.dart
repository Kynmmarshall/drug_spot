import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';

class PushNotificationService {
  PushNotificationService(this._api);

  final ApiService _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    _messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _api.registerDeviceToken(token, platform);
    } catch (_) {}
  }

  void _handleForeground(RemoteMessage message) {
    // Foreground messages are handled by the OS notification tray automatically
    // when notification payload is present. Custom handling can be added here.
  }

  Future<void> dispose() async {
    final token = await _messaging.getToken();
    if (token != null) {
      try {
        await _api.unregisterDeviceToken(token);
      } catch (_) {}
    }
  }
}
