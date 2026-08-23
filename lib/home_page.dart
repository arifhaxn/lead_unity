import 'package:flutter/material.dart';
import 'package:lead_unity/features/about_app_screen.dart';
import 'package:lead_unity/widgets/web_constrain.dart';
import 'package:provider/provider.dart';
import 'authentication/login_screen.dart';
import 'theme/theme_provider.dart';
import 'providers/auth_provider.dart'; // 🟢 IMPORT ADDED
import 'student/student_dash.dart';   // 🟢 IMPORT ADDED
import 'supervisor/sup_dashboard.dart'; // 🟢 IMPORT ADDED

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
    
    // 🟢 NEW: Get Auth state to check for existing session
    final auth = Provider.of<AuthProvider>(context);

    // 🟢 REDIRECT LOGIC: If authenticated, skip the home page UI
    if (auth.isAuthenticated) {
      if (auth.user?.role.toLowerCase() == 'student') {
        return const StudentDashboard();
      } else if (auth.user?.role.toLowerCase() == 'supervisor') {
        return const SupervisorDashboard();
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0) +
                  EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
                child: WebConstraint(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Center(child: _AnimatedAppLogo()),
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
                        'Leading Innovations. Uniting Teams.',
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
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: <Widget>[
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

// --- HELPER WIDGET FOR THE FLOATING/BREATHING LOGO ---
class _AnimatedAppLogo extends StatefulWidget {
  const _AnimatedAppLogo({Key? key}) : super(key: key);

  @override
  State<_AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<_AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), 
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOutSine),
      ),
    );

    _hoverAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.04)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: 'app_logo',
      child: SlideTransition(
        position: _hoverAnimation,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Image.asset(
            'assets/logo/logo.png',
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.image_not_supported_rounded,
                  size: 40, color: theme.colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}