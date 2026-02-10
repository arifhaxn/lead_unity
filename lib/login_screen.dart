import 'package:flutter/material.dart';
import 'package:link_unity/student/student_registration_screen.dart';
import 'package:link_unity/supervisor/sup_dashboard.dart';
import 'package:link_unity/supervisor/sup_login_screen.dart';
import 'package:provider/provider.dart';

// 🟢 Correct Imports for your project structure
import 'auth_provider.dart';
import 'api services/api_services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

// Dashboard Imports
import 'student/student_dash.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'student' or 'supervisor'
  const LoginScreen({Key? key, required this.role}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _api = ApiService();
  bool _isRegOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRegStatus();
  }

  _checkRegStatus() async {
    // 🟢 Uses the new helper method in your ApiService
    bool status = await _api.isRegistrationOpen();
    if (mounted) setState(() => _isRegOpen = status);
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // 🟢 Trim email to prevent space errors
    final email = _emailController.text.trim();
    final password = _passController.text;

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(email, password);

      if (!mounted) return;

      // 🟢 Access User Object correctly
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final userRole =
          user?.role.toLowerCase(); // handle 'Student' vs 'student'

      if (widget.role == 'student' && userRole == 'student') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StudentDashboard()),
            (route) => false);
      } else if (widget.role == 'supervisor' && userRole == 'supervisor') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
            (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Role mismatch or invalid credentials"),
            backgroundColor: Colors.red));
        // Optional: Logout if role mismatch to clean state
        Provider.of<AuthProvider>(context, listen: false).logout();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Define theme color based on role
    final themeColor =
        widget.role == 'student' ? AppColors.primary : AppColors.accentTeal;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: themeProvider.toggleTheme,
              tooltip: themeProvider.isDarkMode
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
            )
          ]),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let\'s Sign You In.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! You\'ve been missed.',
                style: TextStyle(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: themeColor))),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: themeColor))),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.button),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Login',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              // --- Supervisor Specific: Activate Account Link ---
              if (widget.role == 'supervisor')
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SupervisorFirstLoginScreen())),
                      child: const Text("First time login? Activate Account",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // --- Student Specific: Registration Link ---
              if (widget.role == 'student')
                Center(
                  child: _isRegOpen
                      ? TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentRegistrationScreen())),
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant),
                              children: [
                                TextSpan(
                                    text: 'Register Now',
                                    style: TextStyle(
                                        color: themeColor,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppColors.accentCoral.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text("Registration Closed",
                              style: TextStyle(
                                  color: AppColors.accentCoral,
                                  fontWeight: FontWeight.bold)),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
