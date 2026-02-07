import 'package:flutter/material.dart';
// 🟢 No need for Provider or AuthProvider here anymore because ApiService handles the token
import '../api services/api_services.dart';

class SupervisorFirstLoginScreen extends StatefulWidget {
  const SupervisorFirstLoginScreen({Key? key}) : super(key: key);

  @override
  _SupervisorFirstLoginScreenState createState() => _SupervisorFirstLoginScreenState();
}

class _SupervisorFirstLoginScreenState extends State<SupervisorFirstLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _tempPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  
  // 🟢 Use the shared API Service
  final ApiService _apiService = ApiService(); 
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 🟢 FIXED: Call API directly. The token is auto-injected by the Service.
        await _apiService.changePasswordFirstLogin(
          _emailCtrl.text.trim(), // Good practice to trim emails
          _tempPassCtrl.text, 
          _newPassCtrl.text
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated! Please Login."), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to login screen
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Activate Account", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Security Update", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 10),
              Text("Please enter the temporary credentials provided by the admin and set a new secure password.", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _emailCtrl, 
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()), 
                validator: (v) => v!.isEmpty ? "Required" : null
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _tempPassCtrl, 
                decoration: const InputDecoration(labelText: "Temporary Password", prefixIcon: Icon(Icons.lock_open), border: OutlineInputBorder()), 
                obscureText: true, 
                validator: (v) => v!.isEmpty ? "Required" : null
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPassCtrl, 
                decoration: const InputDecoration(labelText: "New Password", prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()), 
                obscureText: true, 
                validator: (v) => v!.length < 6 ? "Min 6 chars" : null
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E), // Supervisor Theme Color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Update & Activate", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}