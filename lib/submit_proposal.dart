// lib/student/submit_proposal_screen.dart

import 'package:flutter/material.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:provider/provider.dart';
import '../api services/api_services.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(); // We can instantiate API service here
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  // --- 🚀 Submission Logic ---
  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    
    // 1. Get the JWT token from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      _showError('Authentication failed. Please log in again.');
      setState(() { _isLoading = false; });
      return;
    }

    try {
      // 2. Call the API service, passing the token for authorization
      await _apiService.submitProposal(title, description, token);

      _showSuccess('Proposal submitted successfully!');
      // Navigate back to the dashboard upon success
      Navigator.of(context).pop(); 

    } catch (e) {
      // Handle API errors (e.g., failed validation, server error)
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit New Proposal'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Project Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: _buildInputDecoration('Proposal Title', Icons.subject),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title.' : null,
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration('Detailed Description', Icons.description),
                maxLines: 8,
                minLines: 4,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description.' : null,
              ),
              const SizedBox(height: 30),

              // Submission Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitProposal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Submit Proposal',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Common input decoration style
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      prefixIcon: Icon(icon, color: Colors.green),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }
}