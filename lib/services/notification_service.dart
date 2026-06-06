import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:link_unity/widgets/top_notification.dart';

class NotificationService {
  static bool _hasRequested = false;

  // ✅ FIXED — use the same base URL as ApiService, not a placeholder
  static const String _baseUrl =
      'https://leading-unity-nest-backend.vercel.app/api';

  // ✅ FIXED — replace YOUR_VAPID_KEY with your real VAPID key from:
  // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
  static const String _vapidKey =
      'BDu0B1pCcMaF8BlK_kB74Ja0oGWvVWGnrxWiq3tFtRo9aa4ARMEx27VbZFDigYEqs0ODyeD7tGNYSdGHaauAyEQ'; // <-- replace this value

  static Future<void> setupPushNotifications(
      BuildContext context, String userAuthToken) async {
    if (_hasRequested) return;
    _hasRequested = true;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request Permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Fetch Initial Token
      String? token = kIsWeb
          ? await messaging.getToken(vapidKey: _vapidKey) // ✅ uses real key now
          : await messaging.getToken();

      print("🔥 INITIAL DEVICE TOKEN: $token");
      if (token != null) _sendTokenToBackend(token, userAuthToken);

      // 3. Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        print("🔄 Token refreshed by Google!");
        _sendTokenToBackend(newToken, userAuthToken);
      });

      // 4. Foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📥 Received a message while app is open!");
        TopNotification.show(
          context,
          title: message.notification?.title ?? "LeadUnity Alert",
          message: message.notification?.body ?? "You have a new update.",
        );
      });

      // 5. Background tap / navigation
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("👆 User tapped the notification banner!");
        if (message.data.containsKey('route')) {
          String routeName = message.data['route'];
          Navigator.pushNamed(context, routeName);
        }
      });
    }
  }

  // ✅ FIXED — was calling wrong URL: 'https://your-api-url.com/api/users/update-fcm-token'
  // The real backend endpoint is PATCH /api/users/fcm-token
  static Future<void> _sendTokenToBackend(
      String fcmToken, String userAuthToken) async {
    final url = Uri.parse('$_baseUrl/users/fcm-token'); // ✅ correct endpoint
    try {
      final response = await http.patch( // ✅ PATCH, not POST
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userAuthToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode == 200) {
        print("✅ Token synced!");
      } else {
        print("❌ Token sync failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Network error syncing token: $e");
    }
  }
}