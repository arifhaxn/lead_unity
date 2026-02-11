import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:provider/provider.dart';

// 🟢 Correct Imports
import '../auth_provider.dart';
import '../home_page.dart';
import '../view_template.dart';
import '../chatbot_screen.dart';
import 'team_info.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // --- Navigation Handlers ---
  void _navigateToTeamInfo() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  }

  void _navigateToSubmitProposal() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SubmitProposalScreen()));
  }

  void _navigateToRequestTeam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request Team feature coming soon!')),
    );
  }

  void _downloadTemplate() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));
  }

  void _logout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();

    // 🟢 Use pushAndRemoveUntil to clear stack so user can't go back
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false);
  }

  void _openChatbot() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // 🟢 Logic Fix: Listen to AuthProvider updates to keep name/status fresh
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Safely access properties from your User model
    final String studentName = user?.name ?? 'Student';
    // Logic placeholder: In a real app, you'd check if user.teamId is not null
    final bool hasTeam = false;
    final String? currentTeamId = null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
            icon: Icon(Icons.logout, color: theme.colorScheme.onSurfaceVariant),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Welcome Section ---
            Text(
              'Hello, $studentName',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 10),

            // --- Status Banner ---
            _buildStatusBanner(hasTeam, currentTeamId),

            const SizedBox(height: 30), // Replaced Divider with clean space

            // --- Dashboard Cards Layout ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ROW 1: Submit Proposal
                _buildSlickCard(
                  context: context,
                  icon: Icons.upload_file_outlined,
                  title: 'Submit Proposal',
                  action: 'Upload your team project proposal',
                  color: AppColors.accentTeal,
                  onTap: _navigateToSubmitProposal,
                  isProminent: true,
                ),

                // ROW 2: Team Info & Request Team
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSlickCard(
                          context: context,
                          icon: Icons.groups_2_outlined,
                          title: 'Team Info',
                          action: 'View Submitted Info',
                          color: AppColors.primary,
                          onTap: _navigateToTeamInfo,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSlickCard(
                          context: context,
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'Request Team',
                          action: 'Find a group',
                          color: AppColors.accentLime,
                          onTap: _navigateToRequestTeam,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // ROW 3: Get Template
                _buildSlickCard(
                  context: context,
                  icon: Icons.download_for_offline_outlined,
                  title: 'Get Template',
                  action: 'Preview and Download',
                  color: AppColors.accentCoral,
                  onTap: _downloadTemplate,
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ),
    );
  }

  // --- Status Banner Widget ---
  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final Color bannerColor = hasTeam
        ? AppColors.accentTeal.withOpacity(0.12)
        : AppColors.accentCoral.withOpacity(0.12);
    final Color textColor =
        hasTeam ? AppColors.accentTeal : AppColors.accentCoral;
    final String statusText = hasTeam
        ? 'You are part of Team $teamId.'
        : 'You are not yet on a team.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
              hasTeam
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: textColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(statusText,
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // --- Slicker Card Widget ---
  Widget _buildSlickCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String action,
    required Color color,
    required VoidCallback onTap,
    bool isProminent = false,
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadii.card,
            boxShadow: AppShadows.level1,
          ),
          padding: EdgeInsets.all(isProminent ? 24.0 : 20.0),
          child: isCompact
              ? Column(
                  // Compact Layout (Vertical)
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 28, color: color),
                    ),
                    const SizedBox(height: 16),
                    Text(title,
                        style:
                            theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(action,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ],
                )
              : Row(
                  // Standard/Prominent Layout (Horizontal)
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 30, color: color),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: isProminent ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text(action,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: theme.colorScheme.outline),
                  ],
                ),
        ),
      ),
    );
  }
}
