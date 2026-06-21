import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_unity/widgets/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/network_overlay.dart';
import 'widgets/custom_snackbar.dart'; // 🟢 1. Imported the CustomSnackBar

// 🟢 2. Created the Master Key for global context
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-initialize Firebase because this runs in a separate isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up the local notifications plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  // Show the OS notification banner (this is what appears when the app is closed/background)
  if (message.notification != null) {
    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'leadunity_channel',       // must match the channel id in AndroidManifest.xml
          'LeadUnity Notifications', // user-visible channel name
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🟢 3. Listen for notifications arriving WHILE the app is OPEN
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      // Grab the current active screen's context using our master key
      final context = globalNavigatorKey.currentContext;
      
      if (context != null && context.mounted) {
        // Trigger the beautiful top-sliding pill!
        CustomSnackBar.showPushNotification(
          context, 
          message.notification!.title ?? "New Notification",
        );
        
        // Auto-refresh the notification data so the unread badge (red dot) updates instantly
        Provider.of<DataProvider>(context, listen: false).fetchNotificationsIfNeeded(forceRefresh: true);
      }
    }
  });

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