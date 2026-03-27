import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_unity/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart'; 
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'widgets/network_overlay.dart'; 
import 'widgets/custom_snackbar.dart'; // 🟢 1. IMPORT YOUR CUSTOM SNACKBAR HERE

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
          
          // 🟢 2. ATTACH THE GLOBAL KEY HERE
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