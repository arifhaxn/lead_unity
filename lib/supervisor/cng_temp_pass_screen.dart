import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // 🟢 Added for animations
import 'package:link_unity/widgets/web_constrain.dart';
import '../services/api_services.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/animated_submit_button.dart';

class SupervisorFirstLoginScreen extends StatefulWidget {
  const SupervisorFirstLoginScreen({Key? key}) : super(key: key);

  @override
  _SupervisorFirstLoginScreenState createState() =>
      _SupervisorFirstLoginScreenState();
}

class _SupervisorFirstLoginScreenState
    extends State<SupervisorFirstLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _abbrevCtrl = TextEditingController();
  final _tempPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  final ApiService _apiService = ApiService();
  SubmitState _submitState = SubmitState.idle;

  // 🟢 Added visibility toggles for the password fields
  bool _obscureTempPass = true;
  bool _obscureNewPass = true;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitState = SubmitState.loading);

      try {
        await _apiService.changePasswordFirstLogin(
            _abbrevCtrl.text.trim(), _tempPassCtrl.text, _newPassCtrl.text);

        if (!mounted) return;

        setState(() => _submitState = SubmitState.success);

        CustomSnackBar.showSuccess(context, "Password Updated! Please Login.");

        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        setState(() => _submitState = SubmitState.idle);

        CustomSnackBar.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeColor = theme.colorScheme.primary;

    // 🟢 Added bottom line for consistent app bar design
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
        title: const Text("Activate Account"),
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
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: WebConstraint(
              child: AnimationLimiter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0) +
                      EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // 🟢 Added Staggered Animations
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 400),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 40.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Security Update",
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please enter your Supervisor Abbreviation (e.g. MRA) and the temporary password provided by the admin.",
                            style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 40),

                          TextFormField(
                            controller: _abbrevCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: "Abbreviation",
                              prefixIcon: const Icon(Icons.badge_outlined),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeColor),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _tempPassCtrl,
                            obscureText: _obscureTempPass,
                            decoration: InputDecoration(
                              labelText: "Temporary Password",
                              prefixIcon: const Icon(Icons.lock_open_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureTempPass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureTempPass = !_obscureTempPass;
                                  });
                                },
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeColor),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _newPassCtrl,
                            obscureText: _obscureNewPass,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPass = !_obscureNewPass;
                                  });
                                },
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: themeColor),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v!.length < 6 ? "Min 6 chars" : null,
                          ),
                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: AnimatedSubmitButton(
                              state: _submitState,
                              title: "Update & Activate",
                              onPressed: _submit,
                              backgroundColor: themeColor,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // 🟢 Added the semantic info box at the bottom
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Note: This action will permanently replace your temporary password. Ensure your new password is secure.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
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
          ),
        ],
      ),
    );
  }
}