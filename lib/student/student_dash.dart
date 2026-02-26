import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:provider/provider.dart';

import '../../api services/api_services.dart'; // Ensure correct import
import '../auth_provider.dart';
import 'view_template.dart';
import '../chatbot_screen.dart';
import 'team_info.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ApiService _api = ApiService();
  bool _isSubmissionOpen = true; // Default to true until checked
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkSubmissionStatus();
  }

  void _checkSubmissionStatus() async {
    bool status = await _api.isSubmissionOpen();
    if (mounted) {
      setState(() {
        _isSubmissionOpen = status;
        _isLoadingStatus = false;
      });
    }
  }

  void _navigateToSubmitProposal() {
    if (!_isSubmissionOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project submissions are currently closed.'), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SubmitProposalScreen()));
  }

  // ... (other navigation methods same as before) ...
  void _navigateToTeamInfo() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  }
  void _navigateToRequestTeam() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Team feature coming soon!')));
  }
  void _downloadTemplate() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));
  }
  void _openChatbot() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String fullName = user?.name ?? 'Student';
    final String firstName = fullName.split(' ').first;
    final bool hasTeam = false; 
    final String? currentTeamId = null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Hello, $firstName', style: theme.textTheme.displaySmall),
            const SizedBox(height: 10),
            _buildStatusBanner(hasTeam, currentTeamId),
            const SizedBox(height: 30),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ROW 1: Submit Proposal (With Disabled State)
                _buildSlickCard(
                  context: context,
                  icon: _isSubmissionOpen ? Icons.upload_file_outlined : Icons.lock_outline,
                  title: _isSubmissionOpen ? 'Submit Proposal' : 'Submissions Closed',
                  action: _isSubmissionOpen ? 'Upload your team project proposal' : 'Please contact admin.',
                  color: _isSubmissionOpen ? AppColors.accentCoral : Colors.grey,
                  onTap: _isSubmissionOpen ? _navigateToSubmitProposal : () {}, // No-op if closed
                  isProminent: true,
                  isDisabled: !_isSubmissionOpen, // Pass flag for visual styling
                  darkBgColor: _isSubmissionOpen ? const Color(0xFF1E3A8A) : Colors.grey[800],
                  lightBgColor: _isSubmissionOpen ? const Color(0xFFD6E4FF) : Colors.grey[300],
                ),

                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSlickCard(
                          context: context,
                          icon: Icons.groups_2_outlined,
                          title: 'Team Info',
                          action: 'View Info',
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
      ),
    );
  }

  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    // ... (Keep existing implementation)
    final theme = Theme.of(context);
    final Color bannerColor = hasTeam ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surfaceVariant;
    final Color textColor = hasTeam ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(hasTeam ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: textColor),
          const SizedBox(width: 12),
          Expanded(child: Text(hasTeam ? 'You are part of Team $teamId.' : 'You are not yet on a team.', style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildSlickCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String action,
    required Color color,
    required VoidCallback onTap,
    bool isProminent = false,
    bool isCompact = false,
    bool isDisabled = false, // New Prop
    Color? darkBgColor,
    Color? lightBgColor,
  }) {
    // Determine opacity based on disabled state
    final double opacity = isDisabled ? 0.6 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Opacity(
        opacity: opacity,
        child: InkWell(
          onTap: isDisabled ? null : onTap, // Disable tap
          borderRadius: AppRadii.card,
          child: Container(
            decoration: BoxDecoration(
              color: darkBgColor ?? const Color(0xFF10B981),
              borderRadius: AppRadii.card,
              boxShadow: isDisabled ? [] : AppShadows.level1, // Remove shadow if disabled
            ),
            padding: EdgeInsets.all(isProminent ? 24.0 : 20.0),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(action, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  )
                : Row(
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
                            Text(title, style: TextStyle(fontSize: isProminent ? 20 : 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(action, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      if (!isDisabled) 
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}