import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Needed for Navigator
import 'package:link_unity/widgets/custom_snackbar.dart';
import 'package:link_unity/widgets/top_notification.dart'; // Your snackbar!

class NotificationService {
  static bool _hasRequested = false;

  // We need the context here to navigate when a user taps a notification
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
          ? await messaging.getToken(vapidKey: "YOUR_VAPID_KEY")
          : await messaging.getToken();

      print("🔥 INITIAL DEVICE TOKEN: $token");
      if (token != null) _sendTokenToBackend(token, userAuthToken);

      // ==========================================
      // TASK 3: LISTEN FOR TOKEN REFRESHES
      // ==========================================
      messaging.onTokenRefresh.listen((newToken) {
        print("🔄 Token refreshed by Google!");
        _sendTokenToBackend(newToken, userAuthToken);
      });

      // ==========================================
      // TASK 1: FOREGROUND NOTIFICATIONS
      // ==========================================
      // ==========================================
      // TASK 1: FOREGROUND NOTIFICATIONS
      // ==========================================
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📥 Received a message while app is open!");
        
        // 🟢 Say goodbye to the boring blue box!
        TopNotification.show(
          context,
          title: message.notification?.title ?? "LeadUnity Alert",
          message: message.notification?.body ?? "You have a new update.",
        );
      });

      // ==========================================
      // TASK 2: BACKGROUND TAPS & NAVIGATION
      // ==========================================
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("👆 User tapped the notification banner!");

        // Check if there is hidden routing data attached
        if (message.data.containsKey('route')) {
          String routeName = message.data['route'];
          // Example: If the backend sends { "route": "/leads" }
          Navigator.pushNamed(context, routeName);
        }
      });
    }
  }

  // API Call Helper
  static Future<void> _sendTokenToBackend(
      String fcmToken, String userAuthToken) async {
    final url =
        Uri.parse('https://your-api-url.com/api/users/update-fcm-token');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userAuthToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode == 200) print("✅ Token synced!");
    } catch (e) {
      print("❌ Network error syncing token: $e");
    }
  }
}
