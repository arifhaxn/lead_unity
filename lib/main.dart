import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_unity/widgets/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'services/api_services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/network_overlay.dart';
import 'widgets/custom_snackbar.dart'; // 🟢 1. Imported the CustomSnackBar

// 🟢 2. Created the Master Key for global context
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

/// Single shared plugin instance for the UI isolate. The background isolate
/// runs in a separate memory space and initializes its own copy.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// The channel every LeadUnity notification is posted to.
///
/// The id MUST stay in sync with two other places:
///   • `default_notification_channel_id` in android/app/src/main/AndroidManifest.xml
///   • `android.notification.channelId` on the backend's FCM payload
/// If the channel is never created, Android silently routes notifications to a
/// low-importance fallback channel — no heads-up banner and no sound.
const AndroidNotificationChannel kLeadUnityChannel = AndroidNotificationChannel(
  'leadunity_channel',
  'LeadUnity Notifications',
  description: 'Proposal updates, supervisor assignments and defense schedules.',
  importance: Importance.high,
);

const AndroidInitializationSettings kAndroidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

/// Draws a real notification in the system tray.
///
/// Android only auto-draws FCM notifications while the app is in the
/// background or terminated. In the foreground nothing appears unless the app
/// posts it itself — which is why push "didn't work" with the app open.
Future<void> showLocalNotification(RemoteMessage message) async {
  if (kIsWeb) return; // web is handled by firebase-messaging-sw.js

  final String? title =
      message.notification?.title ?? message.data['title']?.toString();
  final String? body =
      message.notification?.body ?? message.data['body']?.toString();
  if (title == null && body == null) return;

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        kLeadUnityChannel.id,
        kLeadUnityChannel.name,
        channelDescription: kLeadUnityChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The backend sends a `notification` block, which Android has already drawn
  // by the time this isolate runs. Drawing it again produces two notifications.
  // Only data-only payloads need to be rendered manually here.
  if (message.notification != null) return;

  // Re-initialize Firebase because this runs in a separate isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: kAndroidInitSettings),
  );

  await showLocalNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🟢 Create the notification channel BEFORE any message can arrive.
  // AndroidManifest.xml points FCM at 'leadunity_channel'; if that channel does
  // not exist, Android drops the notification onto an unconfigured fallback.
  if (!kIsWeb) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: kAndroidInitSettings),
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(kLeadUnityChannel);
  }

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🟢 3. Listen for notifications arriving WHILE the app is OPEN
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Post it to the system tray — Android will not do this for us in the
    // foreground. This is what makes push visible in the notification panel.
    await showLocalNotification(message);

    // Grab the current active screen's context using our master key
    final context = globalNavigatorKey.currentContext;

    if (context != null && context.mounted) {
      // Trigger the beautiful top-sliding pill!
      CustomSnackBar.showPushNotification(
        context,
        message.notification?.title ??
            message.data['title']?.toString() ??
            "New Notification",
      );

      // Auto-refresh the notification data so the unread badge (red dot) updates instantly
      Provider.of<DataProvider>(context, listen: false)
          .fetchNotificationsIfNeeded(forceRefresh: true);
    }
  });

  // 🟢 Tapping a tray notification brings the app forward — refresh the badge
  // so the unread count is correct by the time the user sees the UI.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final context = globalNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      Provider.of<DataProvider>(context, listen: false)
          .fetchNotificationsIfNeeded(forceRefresh: true);
    }
  });

  // 🟢 Global session-expiry handler. When any protected request returns 401
  // (the token has expired or was rejected), log the user out cleanly and
  // send them to login — instead of leaving them stuck on a dashboard that
  // silently fails to load. Reacts to a response the backend already sends; no
  // backend change involved.
  ApiService.onUnauthorized = () {
    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      // Navigator not ready yet — let a later 401 retry.
      ApiService.resetUnauthorizedGuard();
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ApiService.resetUnauthorizedGuard();
      return; // already logged out
    }

    auth.logout();

    globalNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );

    if (context.mounted) {
      CustomSnackBar.showInfo(
          context, 'Your session expired. Please sign in again.');
    }
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const LeadUnityApp(),
    ),
  );
}

class LeadUnityApp extends StatelessWidget {
  const LeadUnityApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          // 🟢 4. Attach the master key to your app!
          navigatorKey: globalNavigatorKey,

          debugShowCheckedModeBanner: false,
          title: 'LeadUnity',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Attach the observer to track screens automatically
          navigatorObservers: <NavigatorObserver>[observer],

          // Wraps every screen with the NetworkOverlay
          builder: (context, child) {
            return NetworkOverlay(child: child!);
          },

          home: const SplashScreen(),
        );
      },
    );
  }
}
