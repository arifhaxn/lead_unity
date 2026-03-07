import 'package:flutter/material.dart';
import 'package:flutter/services.dart';// 🟢 Import your new splash screen
import 'package:link_unity/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart'; 
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

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
          // 🟢 Initial entry point is now the SplashScreen
          home: const SplashScreen(), 
        );
      },
    );
  }
}