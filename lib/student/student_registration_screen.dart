import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import 'student_dash.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({Key? key}) : super(key: key);

  @override
  _StudentRegistrationScreenState createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      try {
        // 🟢 Logic Merge: Using individual fields to match your AuthProvider's 
        // register function while keeping your form structure.
        await Provider.of<AuthProvider>(context, listen: false).register(
          _formData['name'],
          _formData['email'],
          _formData['password'],
          _formData['studentId'],
          _formData['batch'],
          _formData['section'],
        );
        
        if (!mounted) return;
        
        // Navigate to Dashboard on success
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
          (route) => false,
        );
      } catch (e) {
        // Cleaning up the error message for the UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')), 
            backgroundColor: Colors.red
          )
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🟢 Keeping your white UI
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 Your specific headers and typography
              const Text(
                'Join the Community',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in your details to get started with your research journey.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              _buildLabel('Personal Info'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name', 
                  prefixIcon: Icon(Icons.person_outline), 
                  border: OutlineInputBorder()
                ),
                onSaved: (v) => _formData['name'] = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address', 
                  prefixIcon: Icon(Icons.email_outlined), 
                  border: OutlineInputBorder()
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _formData['email'] = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              _buildLabel('Academic Info'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Student ID', 
                  prefixIcon: Icon(Icons.badge_outlined), 
                  border: OutlineInputBorder()
                ),
                onSaved: (v) => _formData['studentId'] = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Batch', 
                        prefixIcon: Icon(Icons.calendar_today_outlined), 
                        border: OutlineInputBorder()
                      ),
                      onSaved: (v) => _formData['batch'] = v,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Section', 
                        prefixIcon: Icon(Icons.class_outlined), 
                        border: OutlineInputBorder()
                      ),
                      onSaved: (v) => _formData['section'] = v,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildLabel('Security'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password', 
                  prefixIcon: Icon(Icons.lock_outline), 
                  border: OutlineInputBorder()
                ),
                obscureText: true,
                onSaved: (v) => _formData['password'] = v,
                validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
              ),

              const SizedBox(height: 40),
              // 🟢 Your custom-styled button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text, 
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F766E))
      ),
    );
  }
}