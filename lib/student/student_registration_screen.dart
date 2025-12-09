// lib/student/student_registration_screen.dart (FINAL)

import 'package:flutter/material.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:link_unity/student/student_dash.dart';
import 'package:provider/provider.dart'; 

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  // --- Controllers and Setup ---
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedSection;
  final List<String> _sections = ['A', 'B', 'C', 'D', 'E']; 
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // --- Utility Functions for Messaging ---
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

  // --- 🚀 Backend Integration Logic ---
  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate() || _selectedSection == null) return;
    
    // 1. Check if registration is open (via a placeholder check or a future API call)
    // NOTE: This check is currently done on your Node.js backend.

    setState(() { _isLoading = true; }); 

    final String name = _nameController.text.trim();
    final String studentId = _studentIdController.text.trim();
    final String batch = _batchController.text.trim();
    final String password = _passwordController.text;
    final String section = _selectedSection!;
    
    // 2. Construct the unique email alias as required by the backend User model
    final String emailAlias = '${studentId.toLowerCase()}@leadunity.edu'; 
    
    // 3. Access the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 4. Call the AuthProvider to handle the API request and token storage
      await authProvider.register(
        name, 
        emailAlias, 
        password,
        studentId, 
        batch,  
        section, 
      );

      // On success, the AuthProvider has stored the token and updated state.
      // main.dart will automatically route the user to the StudentDashboard.
      _showSuccess('Registration successful! You are now logged in.');
      Navigator.push(context, 
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
      
    } catch (e) {
      // Handle API errors (e.g., registration closed, user already exists)
      _showError(e.toString().replaceFirst('Exception: ', '')); 
    } finally {
      setState(() { _isLoading = false; }); 
    }
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Student Registration'),
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
                                'Student Account Setup',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // Full Name Field
                            _buildFormField(controller: _nameController, label: 'Full Name', icon: Icons.person),
                            const SizedBox(height: 16),

                            // Student ID Field
                            _buildFormField(controller: _studentIdController, label: 'Student ID', icon: Icons.badge, keyboardType: TextInputType.number),
                            const SizedBox(height: 16),

                            // Batch Field
                            _buildFormField(controller: _batchController, label: 'Batch (e.g., 61)', icon: Icons.school, keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            
                            // Section Dropdown
                            _buildSectionDropdown(),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildPasswordField(),
                            const SizedBox(height: 30),

                            // Register Button
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _registerStudent,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text(
                                        'Register Account',
                                        style: TextStyle(color: Colors.white, fontSize: 18),
                                    ),
                                ),
                        ],
                    ),
                ),
            ),
        ),
    );
  }
  
  // Helper function for text input decoration
  Widget _buildFormField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label.';
        }
        return null;
      },
    );
  }
  
  // Helper function for password field
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: _buildInputDecoration('Password (min 6 characters)', Icons.lock),
      validator: (value) {
        if (value == null || value.length < 6) {
          return 'Password must be at least 6 characters long.';
        }
        return null;
      },
    );
  }
  
  // Helper function for dropdown
  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      decoration: _buildInputDecoration('Section', Icons.group),
      hint: const Text('Select your section'),
      items: _sections.map((String section) {
        return DropdownMenuItem<String>(
          value: section,
          child: Text(section),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSection = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your section.';
        }
        return null;
      },
    );
  }

  // Common input decoration style
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }
}