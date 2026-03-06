import 'package:flutter/material.dart';
import 'package:link_unity/widgets/about_app_screen.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
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
                // The smooth Entrance Animation remains!
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuart,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Center(
                        child: Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/logo/logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Icon(Icons.image_not_supported_rounded,
                                  size: 40, color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'LeadUnity',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The link between students and supervisors',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      _buildLoginOptionCard(
                        context: context,
                        title: 'Student',
                        subtitle: 'Submit proposals, build a team and connect.',
                        icon: Icons.school_rounded,
                        // 🟢 Back to your clean, flat Slate color
                        bgColor: const Color(0xFF475569),
                        onTap: () => _navigateToStudentLogin(context),
                      ),
                      const SizedBox(height: 24),
                      _buildLoginOptionCard(
                        context: context,
                        title: 'Supervisor',
                        subtitle:
                            'Evaluate, review, and track student projects.',
                        icon: Icons.security_rounded,
                        // 🟢 Back to your clean, flat Deep Blue color
                        bgColor: const Color(0xFF1E3A8A),
                        onTap: () => _navigateToAdminLogin(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutAppScreen()),
                  );
                },
                tooltip: 'About App',
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

    const Color textColor = Colors.white;
    const Color subtitleColor = Colors.white70;
    const Color iconColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // We kept the colored glow! It makes the flat color pop off the screen.
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Ink(
            decoration: BoxDecoration(
              color: bgColor, // 🟢 Flat color applied here
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: <Widget>[
                  // Glass icon background
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 30, color: iconColor),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              color: subtitleColor, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
