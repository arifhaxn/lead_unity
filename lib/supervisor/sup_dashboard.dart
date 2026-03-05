import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../chatbot_screen.dart';
import 'team_list_screen.dart';
import 'sup_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final String fullName = user?.name ?? 'Supervisor';
    final String displayName = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .join(' ');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Supervisor Portal'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome Back,',
                style: TextStyle(
                    fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
            Text(
              displayName,
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            _buildCard(
              context,
              "My Teams",
              "Personal Markings",
              Icons.groups,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TeamListScreen(onlyMyTeams: true))),
              darkBgColor: const Color(0xFF2F2A6D),
              height: 120,
              horizontalLayout: true,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildCard(
                    context,
                    "All Teams",
                    "Global List",
                    Icons.format_list_bulleted,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamListScreen(onlyMyTeams: false))),
                    darkBgColor: const Color(0xFF245E63),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCard(
                    context,
                    "Supervisors",
                    "Colleagues",
                    Icons.person_pin_circle_outlined,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SupervisorListScreen())),
                    darkBgColor: const Color(0xFF4E2E3C),
                  ),
                ),
              ],
            ),
          ],
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

  Widget _buildCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap,
      {Color? darkBgColor,
      double height = 180,
      bool horizontalLayout = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.card,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: darkBgColor ?? const Color(0xFF10B981),
          borderRadius: AppRadii.card,
          boxShadow: AppShadows.level1,
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: horizontalLayout
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.level1),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.5), size: 18),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.level1),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
