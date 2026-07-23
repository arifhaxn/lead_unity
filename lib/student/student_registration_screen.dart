import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:link_unity/widgets/animated_dialog.dart';
import 'package:link_unity/widgets/animated_submit_button.dart';
import 'package:link_unity/widgets/web_constrain.dart'; 
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'student_dash.dart';
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

  // 🟢 Added a controller to read the first password for comparison
  final _passwordController = TextEditingController();

  SubmitState _submitState = SubmitState.idle;

  bool _obscurePassword = true;
  // 🟢 Added state for the confirm password visibility toggle
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initiateRegistration() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Change state to loading
      setState(() => _submitState = SubmitState.loading);

      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .sendOtp(context, _formData['email']);

        if (!mounted) return;

        // Show the green success checkmark briefly!
        setState(() => _submitState = SubmitState.success);
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        // Reset the button back to normal in the background
        setState(() => _submitState = SubmitState.idle);

        // Now open the dialog
        _showOTPDialog();
      } catch (e) {
        // Reset on error
        setState(() => _submitState = SubmitState.idle);
      }
    }
  }

  void _showOTPDialog() {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showAnimatedDialog(
      context: context,
      barrierDismissible: false,
      dialog: StatefulBuilder(builder: (context, setDialogState) {
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
                onPressed: () => Navigator.pop(context),
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
                        setDialogState(() => isVerifying = true);
                        _finalizeRegistration(otpController.text, context);
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
        context,
        _formData['name'],
        _formData['email'],
        _formData['password'],
        _formData['studentId'],
        _formData['batch'],
        _formData['section'],
        otp,
      );

      if (!mounted) return;

      Navigator.pop(dialogContext);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(dialogContext);
    }
  }

  void _showInstructions() {
    showAnimatedDialog(
      context: context,
      dialog: AlertDialog(
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
          "• You MUST input your exact Student ID (must be at least 10 digits).\n\n"
          "• Provide your current Batch and Section.\n\n"
          "• Passwords must be 8+ characters and contain at least one uppercase, one lowercase, one number, and one special character.\n\n"
          "• After clicking Register, an OTP will be sent to your email (Also check spam folder).",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        title: const Text('Create Account'),
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
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: WebConstraint(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 400),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 40.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    const Text(
                      'Join the Community',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in your details to get started with your research journey.',
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 30),
                    
                    _buildLabel('Personal Info', theme),
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
                    _buildLabel('Academic Info', theme),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Student ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => _formData['studentId'] = v,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
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
                    _buildLabel('Security', theme),
                    
                    // 🟢 Attached _passwordController here
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
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
                          border: const OutlineInputBorder()),
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
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 🟢 Added Confirm Password Field
                    TextFormField(
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      height: 54, 
                      width: double.infinity,
                      child: AnimatedSubmitButton(
                        state: _submitState,
                        title: "Register",
                        onPressed: _initiateRegistration,
                        backgroundColor: theme.colorScheme.primary, // 🟢 Synced with theme
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary)), // 🟢 Synced with theme
    );
  }
}