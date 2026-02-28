import 'package:flutter/material.dart';
import '../api services/api_services.dart';
import '../chatbot_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';

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
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {

        await _apiService.changePasswordFirstLogin(
            _abbrevCtrl.text.trim(), 
            _tempPassCtrl.text,
            _newPassCtrl.text);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password Updated! Please Login."),
            backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to login screen
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Activate Account"),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Security Update",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Text(
                  "Please enter your Supervisor Abbreviation (e.g. MRA) and the temporary password provided by the admin.",
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
              const SizedBox(height: 30),

              TextFormField(
                  controller: _abbrevCtrl,
                  decoration: const InputDecoration(
                      labelText: "Abbreviation",
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 15),
              
              TextFormField(
                  controller: _tempPassCtrl,
                  decoration: const InputDecoration(
                      labelText: "Temporary Password",
                      prefixIcon: Icon(Icons.lock_open),
                      border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? "Required" : null),
              const SizedBox(height: 15),
              
              TextFormField(
                  controller: _newPassCtrl,
                  decoration: const InputDecoration(
                      labelText: "New Password",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? "Min 6 chars" : null),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.button),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Update & Activate",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ),
    );
  }
}