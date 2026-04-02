import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_unity/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart'; 
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart'; 
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/network_overlay.dart'; 
import 'widgets/custom_snackbar.dart';

void main() async { // 🟢 2. ADDED 'async' HERE
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 3. INITIALIZE FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LeadUnity Portal',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // 🟢 5. ATTACH THE OBSERVER HERE TO TRACK SCREENS AUTOMATICALLY
          navigatorObservers: <NavigatorObserver>[observer],
          
          // This allows you to call CustomSnackBar.showError() from literally anywhere!
          scaffoldMessengerKey: CustomSnackBar.messengerKey,
          
          // This wraps EVERY screen in your app with the NetworkOverlay automatically
          builder: (context, child) {
            return NetworkOverlay(child: child!);
          },
          
          home: const SplashScreen(), 
        );
      },
    );
  }
}