import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:link_unity/supervisor/sup_dashboard.dart';
import 'package:provider/provider.dart';

// 🟢 Correct Imports for your project
import 'auth_provider.dart';
import 'home_page.dart';
import 'student/student_dash.dart';

void main() {
  // 🟢 Fix 1: Ensure bindings are initialized for Secure Storage/SystemChrome
  WidgetsFlutterBinding.ensureInitialized();

  // 🟢 Fix 2: Add his professional Status Bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        // 🟢 Fix 3: Initialize AuthProvider and try auto-login immediately
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: const LeadUnityApp(),
    ),
  );
}

class LeadUnityApp extends StatelessWidget {
  const LeadUnityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LeadUnity Portal',
      // 🟢 Fix 4: Use his professional Theme logic but keep it in the main file for simplicity
      theme: _buildTheme(),
      // 🟢 Fix 5: Use your Consumer logic to route the user automatically
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            // Check roles to send user to the right place
            if (auth.user?.role.toLowerCase() == 'student') {
              return const StudentDashboard();
            } else if (auth.user?.role.toLowerCase() == 'supervisor') {
              return  const SupervisorDashboard();
            }
          }
          // If not authenticated, show the choice screen
          return const HomePage();
        },
      ),
    );
  }

  // 🟢 His Professional UI Theme (Teal & Slate colors)
  ThemeData _buildTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: const Color(0xFF0F766E),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: const Color(0xFF0F766E),
        secondary: const Color(0xFFF59E0B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}