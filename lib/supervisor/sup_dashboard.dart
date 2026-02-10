import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🟢 Core Imports
import '../auth_provider.dart';
import '../home_page.dart';

// 🟢 Screen Imports (Ensure these files exist in lib/supervisor/)
import 'team_list_screen.dart';
import 'marking_selection_screen.dart';
import 'sup_list_screen.dart'; // Renamed from supervisor_list_screen based on your file tree
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // 🟢 Logic: Listen to the provider to get the latest User object
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
            icon:
                const Icon(Icons.logout_rounded, color: AppColors.accentCoral),
            tooltip: "Logout",
            onPressed: () {
              // 🟢 Logic: Secure Logout & Navigation Clearing
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

            // 🟢 Data: Display the name dynamically from the User model
            Text(
              user?.name ?? 'Supervisor',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 30),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                // 🟢 Navigation: Passing arguments matches his logic (e.g., onlyMyTeams)
                _buildCard(
                    context,
                    "My Teams",
                    "Assigned Groups",
                    Icons.groups,
                    AppColors.primary,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamListScreen(onlyMyTeams: true)))),

                _buildCard(
                    context,
                    "All Teams",
                    "Global List",
                    Icons.format_list_bulleted,
                    AppColors.accentTeal,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamListScreen(onlyMyTeams: false)))),

                _buildCard(
                    context,
                    "Marking",
                    "Evaluation",
                    Icons.verified_user_outlined,
                    AppColors.accentLime,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MarkingSelectionScreen()))),

                _buildCard(
                    context,
                    "Supervisors",
                    "Colleagues",
                    Icons.person_pin_circle_outlined,
                    AppColors.accentCoral,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SupervisorListScreen()))),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 🟢 UI Helper: Kept your teammate's card design as requested, but simplified slightly
  Widget _buildCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.card,
      child: Container(
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
          child: Column(
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
