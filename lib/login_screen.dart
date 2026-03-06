import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:link_unity/supervisor/sup_dashboard.dart';
import 'package:link_unity/supervisor/sup_login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'api services/api_services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'student/student_dash.dart';
import 'student/student_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({Key? key, required this.role}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passController = TextEditingController();
  final _api = ApiService();

  bool _isRegOpen = true;
  bool _isLoading = false;
  
  // 🟢 NEW: State variable to track password visibility
  bool _obscurePassword = true; 

  @override
  void initState() {
    super.initState();
    _checkRegStatus();
  }

  _checkRegStatus() async {
    bool status = await _api.isRegistrationOpen();
    if (mounted) setState(() => _isRegOpen = status);
  }

  void _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter both ID/Abbreviation and Password"),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(identifier, password, role: widget.role);

      //Save the login Abbreviation or Student ID
      const storage = FlutterSecureStorage();
      await storage.write(key: 'login_identifier', value: identifier);

      if (!mounted) return;

      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final userRole = user?.role.toLowerCase();

      // Navigation Logic
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
    final themeColor = theme.colorScheme.primary;

    final isStudent = widget.role == 'student';
    final labelText = isStudent ? 'Student ID' : 'Abbreviation';
    final prefixIcon = isStudent ? Icons.badge_outlined : Icons.short_text;
    final keyboardType = isStudent ? TextInputType.number : TextInputType.text;

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2), 
        height: 1.0,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor, 
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          bottom: appBarBottomLine, 
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
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    isStudent ? 'Student Login' : 'Supervisor Login',
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back! Please sign in to continue.',
                    style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _identifierController,
                    keyboardType: keyboardType,
                    decoration: InputDecoration(
                        labelText: labelText,
                        prefixIcon: Icon(prefixIcon),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeColor))),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePassword, // 🟢 Links to state
                    decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        // 🟢 NEW: Added Visibility Toggle Icon
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
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
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
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
                          child: const Text(
                              "First time login? Activate Account",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
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
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
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
                                  color:
                                      theme.colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text("Registration Closed",
                                  style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold)),
                            ),
                    ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isStudent
                                ? "Note: New registrations can only be processed while the portal is explicitly opened by the department admin. Otherwise, it will show 'Registration Closed'."
                                : "Note: Use your exact capitalized Abbreviation (e.g., EBH). Your initial temporary password will be provided by the department admin.",
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}