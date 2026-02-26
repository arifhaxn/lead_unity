import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateToStudentLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(role: 'student'),
      ),
    );
  }

  void _navigateToAdminLogin(BuildContext context) {
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
            color: theme.colorScheme.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[

                    Center(
                      child: Image.asset(
                        'assets/logo/logo.png',
                        height: 120,
                        fit: BoxFit.contain,

                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.image_not_supported_rounded, size: 40, color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'LeadUnity',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
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
                      bgColor: const Color(0xFF475569),
                      onTap: () => _navigateToStudentLogin(context),
                    ),
                    const SizedBox(height: 24),
                    _buildLoginOptionCard(
                      context: context,
                      title: 'Supervisor',
                      subtitle:
                          'Log in to view, approve, and assign student projects.',
                      icon: Icons.security,
                      bgColor: const Color(0xFF1E3A8A),
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

  Widget _buildLoginOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}