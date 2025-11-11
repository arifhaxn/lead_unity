// lib/screens/student_login_screen.dart

import 'package:flutter/material.dart';
import 'package:link_unity/api%20services/api_services.dart';
import 'package:link_unity/student/student_dash.dart';
import 'package:link_unity/student/student_registration_screen.dart';
// Note: You may also need to import your registration screen to navigate back
// import 'student_registration_screen.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(); // Instantiate the API service

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Utility Functions (Same as registration screen) ---
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // --- 🔑 Login Logic ---
  Future<void> _loginStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String studentId = _studentIdController.text.trim();
    final String password = _passwordController.text;

    // 🔑 Construct the unique email alias used for login authentication
    final String emailAlias = '${studentId.toLowerCase()}@leadunity.edu';

    try {
      // Call the API service's login method
      final responseBody = await _apiService.login(
        emailAlias,
        password,
      );

      // On Success: Check the user role (though this is the student login screen)
      final String role = responseBody['role'];
      final String token = responseBody['token'];

      // TODO: Store the token and user data securely (e.g., SharedPreferences)
      print("Login Successful. Role: $role, Token: $token");

      _showSuccess('Login successful! Welcome $role!');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StudentDashboard()));
    } catch (e) {
      // Handle API errors (e.g., Invalid email or password)
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Student Portal Login',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Student ID Field
                _buildFormField(
                  controller: _studentIdController,
                  label: 'Student ID',
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your Student ID.'
                      : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildPasswordField(
                  controller: _passwordController,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your password.'
                      : null,
                ),
                const SizedBox(height: 30),

                // Login Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _loginStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Log In',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                const SizedBox(height: 15),

                // Link to Registration
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const StudentRegistrationScreen()));
                    print('Navigate to Registration');
                  },
                  child: const Text("Don't have an account? Register here.",
                      style: TextStyle(color: Colors.blueGrey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildFormField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label, icon),
      validator: validator,
    );
  }

  Widget _buildPasswordField(
      {required TextEditingController controller,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: _buildInputDecoration('Password', Icons.lock),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }
}
