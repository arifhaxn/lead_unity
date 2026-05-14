import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb

class NotificationService {
  static bool _hasRequested = false;
  static Future<void> setupPushNotifications() async {
    if (_hasRequested) return;
    _hasRequested = true;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Ask the user for permission (Triggers popup on Web/iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission!');

      try {
        // 2. Fetch the unique device token
        String? token;
        
        if (kIsWeb) {
          // 🟢 WEB REQUIRES THE VAPID KEY FROM THE FIREBASE CONSOLE
          token = await messaging.getToken(
            vapidKey: "BDu0B1pCcMaF8BlK_kB74Ja0oGWvVWGnrxWiq3tFtRo9aa4ARMEx27VbZFDigYEqs0ODyeD7tGNYSdGHaauAyEQ", 
          );
        } else {
          // 🟢 ANDROID JUST GRABS IT DIRECTLY
          token = await messaging.getToken();
        }

        print("🔥 HERE IS THE DEVICE TOKEN: $token");
        
        // (Later, we will send this token to your backend developer!)

      } catch (e) {
        print("Error getting token: $e");
      }
    } else {
      print('User declined notifications.');
    }
  }
}