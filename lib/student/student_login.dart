// lib/student/student_login.dart

import 'package:flutter/material.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:link_unity/student/student_dash.dart';
import 'package:link_unity/student/student_registration_screen.dart'; // 🟢 REQUIRED IMPORT
import 'package:provider/provider.dart'; 
 // 🟢 NEW: Import the AuthProvider

// NOTE: We no longer need to import api_services.dart, student_dash.dart, or student_registration_screen.dart 
// as the Provider handles the navigation via the main.dart Consumer.

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // ❌ REMOVE: We no longer instantiate ApiService directly here.
  // final ApiService _apiService = ApiService(); 

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Utility Functions (unchanged) ---
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

  // --- 🔑 Login Logic (Refactored) ---
  Future<void> _loginStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String studentId = _studentIdController.text.trim();
    final String password = _passwordController.text;

    // Construct the unique email alias (This matches your backend's expectation for login)
    final String emailAlias = '${studentId.toLowerCase()}@leadunity.edu';

    // 🟢 ACCESS THE AUTH PROVIDER
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 🟢 CALLING THE AUTH PROVIDER's login method
      await authProvider.login(
        emailAlias,
        password,
      );

      // On Success: The AuthProvider has stored the token and updated state.
      final String userName = authProvider.user?.name ?? 'User';
      _showSuccess('Login successful! Welcome, $userName!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
      
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
    // --- UI Build Method (unchanged) ---
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
                    // 🟢 FIX: Navigate to the correct registration screen
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentDashboard())); 
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

  // --- Helper Widgets (unchanged) ---
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