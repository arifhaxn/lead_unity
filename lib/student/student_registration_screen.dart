import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'student_dash.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({Key? key}) : super(key: key);

  @override
  _StudentRegistrationScreenState createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isLoading = false;

  Future<void> _initiateRegistration() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .sendOtp(_formData['email']);

        if (!mounted) return;

        setState(() => _isLoading = false);
        _showOTPDialog(); // Only show dialog if API succeeds
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red));
      }
    }
  }

  //Show Dialog to Enter Code
  void _showOTPDialog() {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Verify Email"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "We have sent a verification code to ${_formData['email']}. It expires in 5 minutes."),
              const SizedBox(height: 20),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Enter 6-digit Code",
                    border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            if (!isVerifying)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: isVerifying
                  ? null
                  : () {
                      if (otpController.text.isNotEmpty) {
                        setDialogState(
                            () => isVerifying = true); // Show loading in dialog
                        // Call final registration with OTP
                        _finalizeRegistration(otpController.text, ctx);
                      }
                    },
              child: isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Verify & Register"),
            )
          ],
        );
      }),
    );
  }

  void _finalizeRegistration(String otp, BuildContext dialogContext) async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _formData['name'],
        _formData['email'],
        _formData['password'],
        _formData['studentId'],
        _formData['batch'],
        _formData['section'],
        otp, //Pass OTP
      );

      if (!mounted) return;

      Navigator.pop(dialogContext);

      // Go to Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(dialogContext);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Registration Failed: ${e.toString().replaceAll('Exception: ', '')}"),
          backgroundColor: Colors.red));
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text("How to Register"),
          ],
        ),
        content: const Text(
          "• Enter your full name and valid email address.\n\n"
          // 🟢 Updated Instructions
          "• You MUST input your exact Student ID (must be at least 10 digits).\n\n"
          "• Provide your current Batch and Section.\n\n"
          "• Passwords must be 8+ characters and contain at least one uppercase, one lowercase, one number, and one special character.\n\n"
          "• After clicking Register, an OTP will be sent to your email.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // 🟢 NEW: A reusable 1-pixel subtle border line for the bottom of the AppBar
    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2), // Subtle separation
        height: 1.0,
      ),
    );

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // 🟢 Matched background color
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor:
            theme.scaffoldBackgroundColor, // 🟢 Matched background color
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine, // 🟢 Added bottom line
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
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showInstructions,
            tooltip: 'Registration Instructions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join the Community',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in your details to get started with your research journey.',
                style: TextStyle(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 30),

              _buildLabel('Personal Info'),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder()),
                onSaved: (v) => _formData['name'] = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => _formData['email'] = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              _buildLabel('Academic Info'),
              TextFormField(
                decoration: const InputDecoration(
                    // 🟢 Updated Label
                    labelText: 'Student ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onSaved: (v) => _formData['studentId'] = v,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  // 🟢 Updated Validation Check
                  if (v.length < 10) return 'ID must be at least 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Batch',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder()),
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
                          border: OutlineInputBorder()),
                      onSaved: (v) => _formData['section'] = v,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLabel('Security'),

              //Regex
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder()),
                obscureText: true,
                onSaved: (v) => _formData['password'] = v,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Must be at least 8 characters long';
                  }
                  if (!RegExp(r'(?=.*?[A-Z])').hasMatch(value)) {
                    return 'Must contain at least one uppercase letter';
                  }
                  if (!RegExp(r'(?=.*?[a-z])').hasMatch(value)) {
                    return 'Must contain at least one lowercase letter';
                  }
                  if (!RegExp(r'(?=.*?[0-9])').hasMatch(value)) {
                    return 'Must contain at least one number';
                  }
                  if (!RegExp(r'(?=.*?[!@#\$&*~])').hasMatch(value)) {
                    return 'Must contain at least one special character (!@#\$&*~)';
                  }
                  return null; // Return null if all checks pass
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _initiateRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : const Text('Register',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}
