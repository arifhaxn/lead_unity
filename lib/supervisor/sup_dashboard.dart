import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🟢 Core Imports
import '../auth_provider.dart';
import '../home_page.dart';

// 🟢 Screen Imports
import 'team_list_screen.dart';
import 'sup_list_screen.dart'; // Renamed from supervisor_list_screen
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Supervisor Portal'),
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
            icon: const Icon(Icons.logout_rounded, color: AppColors.accentCoral),
            tooltip: "Logout",
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,',
                style: TextStyle(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),

            Text(
              user?.name ?? 'Supervisor',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 30),

            // 🟢 Row 1: My Teams (Full Width)
            _buildCard(
              context,
              "My Teams",
              "Assigned Groups",
              Icons.groups,
              AppColors.primary,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TeamListScreen(onlyMyTeams: true))),
              isFullWidth: true, // Special flag for wide card
            ),

            const SizedBox(height: 16),

            // 🟢 Row 2: All Teams & Supervisors (Side by Side)
            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    "All Teams",
                    "Global List",
                    Icons.format_list_bulleted,
                    AppColors.accentTeal,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamListScreen(onlyMyTeams: false))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    context,
                    "Supervisors",
                    "Colleagues",
                    Icons.person_pin_circle_outlined,
                    AppColors.accentCoral,
                    () => Navigator.push(
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
    );
  }

  // 🟢 Helper: Added isFullWidth to adjust height/padding for the top card
  Widget _buildCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap,
      {bool isFullWidth = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.card,
      child: Container(
        // Adjust height based on layout role (Full width vs Grid item)
        height: isFullWidth ? 140 : 180, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.12),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.card,
          boxShadow: AppShadows.level1,
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: isFullWidth
              ? Row( // Horizontal layout for full-width card
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.level1),
                      child: Icon(icon, size: 32, color: color),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title, style: theme.textTheme.headlineSmall), // Bigger text
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, 
                         color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), 
                         size: 20)
                  ],
                )
              : Column( // Vertical layout for smaller cards
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.level1),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}