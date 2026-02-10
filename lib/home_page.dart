import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart'; // 🟢 Points to the unified LoginScreen we merged earlier
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- Logic Merge: Use the role-based navigation from his logic ---
  void _navigateToStudentLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(role: 'student'),
      ),
    );
  }

  void _navigateToAdminLogin(BuildContext context) {
    // 🟢 Fixed: Removed the placeholder SnackBar and connected to logic
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(role: 'supervisor'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // --- Logo & Title ---
                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppShadows.level1,
                      ),
                      child: const Icon(Icons.lightbulb_outline,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'LeadUnity',
                      style: theme.textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The link between students and supervisors',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 56),

                    _buildLoginOptionCard(
                      context: context,
                      title: 'Student',
                      subtitle:
                          'Register or log in to manage your project team and proposals.',
                      icon: Icons.school,
                      color: AppColors.primary,
                      onTap: () => _navigateToStudentLogin(context),
                    ),
                    const SizedBox(height: 24),
                    _buildLoginOptionCard(
                      context: context,
                      title: 'Supervisor',
                      subtitle:
                          'Log in to view, approve, and assign student projects.',
                      icon: Icons.security,
                      color: AppColors.accentTeal,
                      onTap: () => _navigateToAdminLogin(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
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
            ),
          ),
        ],
      ),
    );
  }

  // --- Your Original Card Design Helper ---
  Widget _buildLoginOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            boxShadow: AppShadows.level1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
