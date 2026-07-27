import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_services.dart';

/// Registers this device with FCM and keeps the backend's token list in sync.
///
/// Display of incoming messages is NOT handled here — that lives in main.dart
/// (`showLocalNotification` + the `onMessage` listener). Keeping a second
/// listener in this class caused every foreground push to render twice.
class NotificationService {
  static bool _initialized = false;
  static void reset() => _initialized = false;

  static final ApiService _api = ApiService();

  // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  static const String _vapidKey =
      'BDu0B1pCcMaF8BlK_kB74Ja0oGWvVWGnrxWiq3tFtRo9aa4ARMEx27VbZFDigYEqs0ODyeD7tGNYSdGHaauAyEQ';

  /// Requests notification permission and registers the device token.
  ///
  /// [userAuthToken] is used only as a "is there a live session?" guard — the
  /// Authorization header itself is attached by ApiService's Dio interceptor.
  static Future<void> setupPushNotifications(String userAuthToken) async {
    if (_initialized) return;

    // No session yet. Return WITHOUT latching so the next dashboard mount
    // retries once the JWT is available.
    if (userAuthToken.isEmpty) {
      debugPrint('🔕 Skipping FCM setup: no auth token yet.');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    // Leave _initialized false so enabling notifications later in system
    // settings still gets a chance to register on the next mount.
    if (!granted) {
      debugPrint(
          '🔕 Notification permission not granted: ${settings.authorizationStatus}');
      return;
    }

    _initialized = true;

    try {
      final token = kIsWeb
          ? await messaging.getToken(vapidKey: _vapidKey)
          : await messaging.getToken();

      if (token == null) {
        debugPrint('❌ FCM returned a null token.');
        _initialized = false;
        return;
      }

      // Print the FULL token on debug builds so it can be copied straight into
      // tools/send-test-push.js or the Firebase Console test sender. Release
      // builds log only a prefix, to keep the token out of production logs.
      if (kDebugMode) {
        debugPrint('🔥 FCM DEVICE TOKEN (copy this):\n$token');
      } else {
        debugPrint('🔥 FCM token: ${token.substring(0, 20)}...');
      }

      await _api.saveFcmToken(token);
      debugPrint('✅ FCM token registered with backend.');
    } catch (e) {
      // Registration failed — un-latch so a later attempt can retry. Without
      // this the device stays silently unregistered for the whole session.
      debugPrint('❌ FCM token registration failed: $e');
      _initialized = false;
      return;
    }

    // Google rotates tokens periodically; push the new one straight through.
    messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _api.saveFcmToken(newToken);
        debugPrint('🔄 Refreshed FCM token synced.');
      } catch (e) {
        debugPrint('❌ Failed to sync refreshed FCM token: $e');
      }
    });
  }

  /// Returns the current device token so it can be un-registered on logout.
  static Future<String?> currentToken() async {
    try {
      return kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: _vapidKey)
          : await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Could not read FCM token: $e');
      return null;
    }
  }
}
