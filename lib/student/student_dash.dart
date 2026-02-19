import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:provider/provider.dart';

// 🟢 Correct Imports
import '../auth_provider.dart';
import '../view_template.dart';
import '../chatbot_screen.dart';
import 'team_info.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart'; // 🟢 Added Drawer Import

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

  void _openChatbot() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // 🟢 Extract First Name Logic
    final String fullName = user?.name ?? 'Student';
    final String firstName = fullName.split(' ').first;
    
    // Logic placeholder: In a real app, you'd check if user.teamId is not null
    final bool hasTeam = false;
    final String? currentTeamId = null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // 🟢 Implement the Drawer here
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        // 🟢 Actions removed because the drawer now handles them
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Welcome Section ---
            Text(
              'Hello, $firstName', // 🟢 Using firstName here
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 10),

            // --- Status Banner ---
            _buildStatusBanner(hasTeam, currentTeamId),

            const SizedBox(height: 30),

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
                  color: AppColors.accentCoral,
                  onTap: _navigateToSubmitProposal,
                  isProminent: true,
                  darkBgColor: const Color(0xFF1E3A8A),
                  lightBgColor: const Color(0xFFD6E4FF),
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
                          color: AppColors.accentGreen,
                          onTap: _navigateToTeamInfo,
                          isCompact: true,
                          darkBgColor: const Color(0xFF6B7280),
                          lightBgColor: const Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSlickCard(
                          context: context,
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'Request Team',
                          action: 'Find a group',
                          color: AppColors.accentPink,
                          onTap: _navigateToRequestTeam,
                          isCompact: true,
                          darkBgColor: const Color(0xFF0E7490),
                          lightBgColor: const Color(0xFFCFFAFE),
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
                  color: AppColors.accentLime,
                  onTap: _downloadTemplate,
                  darkBgColor: const Color(0xFF4338CA),
                  lightBgColor: const Color(0xFFDDD6FE),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        backgroundColor: accent,
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ),
    );
  }

  // --- Status Banner Widget ---
  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final theme = Theme.of(context);
    final Color bannerColor = hasTeam
        ? theme.colorScheme.primary.withOpacity(0.08)
        : theme.colorScheme.surfaceVariant;
    final Color textColor = hasTeam
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
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
    Color? darkBgColor,
    Color? lightBgColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          decoration: BoxDecoration(
            color: darkBgColor ?? const Color(0xFF10B981),
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(action,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                  ],
                )
              : Row(
                  // Standard/Prominent Layout (Horizontal)
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 30, color: Colors.white),
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
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(action,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: Colors.white70),
                  ],
                ),
        ),
      ),
    );
  }
}