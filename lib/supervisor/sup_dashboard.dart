import 'package:flutter/material.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/registration_status_badge.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'team_list_screen.dart';
import 'sup_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  @override
  void initState() {
    super.initState();
    // 🟢 Trigger the silent background check as soon as the screen loads!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).fetchDeadlineIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dp = Provider.of<DataProvider>(context); // 🟢 Listen to our provider
    final user = authProvider.user;

    final String fullName = user?.name ?? 'Supervisor';
    final String displayName = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .join(' ');

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2),
        height: 1.0,
      ),
    );

    // 🟢 WRAPPED THE ENTIRE SCAFFOLD IN THE NETWORK OVERLAY
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Supervisor Portal'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back,',
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        displayName,
                        style: theme.textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // 🟢 Only hide if we have NO data AND it's currently loading.
                // Otherwise, show the badge immediately!
                if (!(dp.deadline == null && dp.isLoadingDeadline))
                  RegistrationStatusBadge(deadline: dp.deadline),
              ],
            ),
            const SizedBox(height: 30),
            _AnimatedDashboardCard(
              title: "My Teams",
              subtitle: "Personal Markings",
              icon: Icons.groups_rounded,
              bgColor: const Color(0xFF4338CA),
              iconColor: const Color.fromARGB(255, 24, 255, 143),
              height: 120,
              horizontalLayout: true,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TeamListScreen(onlyMyTeams: true))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AnimatedDashboardCard(
                    title: "All Teams",
                    subtitle: "Board Markings",
                    icon: Icons.format_list_bulleted_rounded,
                    bgColor: const Color.fromARGB(255, 74, 65, 91),
                    iconColor: const Color.fromARGB(255, 255, 156, 252),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamListScreen(onlyMyTeams: false))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedDashboardCard(
                    title: "Supervisors",
                    subtitle: "Colleagues",
                    icon: Icons.person_pin_circle_rounded,
                    bgColor: const Color(0xFF0E7490),
                    iconColor: Colors.cyanAccent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SupervisorListScreen())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: const BreathingChatbotFab(),
    );
  }
}

// Custom Animated Card Widget
class _AnimatedDashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;
  final double height;
  final bool horizontalLayout;

  const _AnimatedDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
    this.height = 180,
    this.horizontalLayout = false,
  });

  @override
  State<_AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<_AnimatedDashboardCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: AppRadii.card,
            boxShadow: _isPressed ? [] : AppShadows.level1,
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: widget.horizontalLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAnimatedIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.subtitle,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.5), size: 18),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedIcon(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedScale(
      scale: _isPressed ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.iconColor.withOpacity(0.3)
              : widget.iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.iconColor.withOpacity(0.3)),
        ),
        child: Icon(widget.icon, size: 28, color: widget.iconColor),
      ),
    );
  }
}
