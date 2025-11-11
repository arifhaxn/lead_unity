// lib/main.dart (REVISED AND FINALIZED)

import 'package:flutter/material.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:link_unity/student/student_dash.dart';
import 'package:provider/provider.dart'; // 🟢 ADDED for state management

// Import all entry-point screens
import 'home_page.dart'; // The screen showing Login/Admin options

// Import the provider and models
// import 'models/user_model.dart'; // UserModel is only needed in AuthProvider

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🟢 WRAP the app in ChangeNotifierProvider and immediately try to auto-login
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider()..tryAutoLogin(),
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
      title: 'LinkUnity Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 🟢 Use Consumer to route the user based on the AuthProvider state
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // If the provider has a token, the user is authenticated
          if (auth.isAuthenticated) {
            // Check the user's role to determine the dashboard
            if (auth.user?.isStudent == true) {
              return const StudentDashboard(); 
            } else {
              // TODO: return const AdminDashboardScreen();
              // For now, if logged in but not student, send to student dashboard
              return const StudentDashboard(); 
            }
          } else {
            // User is not logged in, show the initial choice screen
            return const HomePage(); 
          }
        },
      ),
    );
  }
}