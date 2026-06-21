import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../../widgets/animated_submit_button.dart';
import '../../widgets/custom_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _api = ApiService();
  SubmitState _submitState = SubmitState.idle;
  bool _obscure = true;

  void _handleReset() async {
    if (_otpController.text.length < 6) {
      CustomSnackBar.showError(context, "Enter the 6-digit OTP");
      return;
    }
    if (_newPassController.text.length < 6) {
      CustomSnackBar.showError(context, "Password must be at least 6 characters");
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    try {
      await _api.resetPassword(
        widget.email,
        _otpController.text.trim(),
        _newPassController.text,
      );
      setState(() => _submitState = SubmitState.success);
      
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      CustomSnackBar.showSuccess(context, "Password updated! Please login.");
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      CustomSnackBar.showError(context, e.toString());
      setState(() => _submitState = SubmitState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "OTP Code",
                prefixIcon: Icon(Icons.vibration),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPassController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: AnimatedSubmitButton(
                state: _submitState,
                title: "Update Password",
                onPressed: _handleReset,
                backgroundColor: themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}