import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../api services/api_services.dart';
import '../widgets/animated_submit_button.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/custom_page_route.dart';
import 'reset_password_screen.dart'; // We will create this next

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _api = ApiService();
  SubmitState _submitState = SubmitState.idle;

  void _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      CustomSnackBar.showError("Please enter a valid email address");
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    try {
      await _api.sendForgotPasswordOtp(email);
      setState(() => _submitState = SubmitState.success);
      
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      // Navigate to Reset Screen
      Navigator.push(
        context,
        FadeScaleRoute(page: ResetPasswordScreen(email: email)),
      );
    } catch (e) {
      CustomSnackBar.showError(e.toString());
      setState(() => _submitState = SubmitState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 40.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                const Text(
                  "Forgot Password",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter your registered email to receive a 6-digit recovery code.",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: themeColor),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: AnimatedSubmitButton(
                    state: _submitState,
                    title: "Send OTP",
                    onPressed: _handleSendOtp,
                    backgroundColor: themeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}