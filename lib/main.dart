import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_unity/supervisor/sup_dashboard.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'home_page.dart';
import 'student/student_dash.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle( //for transparent status bar
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                // Check roles to send user to the right place
                if (auth.user?.role.toLowerCase() == 'student') {
                  return const StudentDashboard();
                } else if (auth.user?.role.toLowerCase() == 'supervisor') {
                  return const SupervisorDashboard();
                }
              }
              return const HomePage();
            },
          ),
        );
      },
    );
  }
}
