import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:link_unity/student/student_login.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:link_unity/student/team_info.dart';
import 'package:link_unity/view_template.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String? _currentTeamId;

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
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const StudentLoginScreen()));
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String actualStudentName = authProvider.user?.name ?? 'Student';
    _currentTeamId = "ABC-001"; // Placeholder
    final bool hasTeam = _currentTeamId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Welcome Section ---
            Text(
              'Hello, $actualStudentName',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // --- Status Banner ---
            _buildStatusBanner(hasTeam, _currentTeamId),

            const Divider(height: 30),

            // --- Dashboard Cards Layout ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ROW 1: Submit Proposal (Prominent Size, Standard Color)
                _buildSlickCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Submit Proposal',
                  action: 'Upload your team project proposal',
                  color: Colors.green,
                  onTap: _navigateToSubmitProposal,
                  isProminent:
                      true, // Keeps it bigger, but colors will now match others
                ),

                // ROW 2: Team Info & Request Team (Side by Side & Equal Height)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSlickCard(
                          icon: Icons.groups_2_outlined,
                          title: 'Team Info',
                          action: 'View Submitted Info',
                          color: Colors.blueAccent,
                          onTap: _navigateToTeamInfo,
                          isCompact: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSlickCard(
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'Request Team',
                          action: 'If You Don\'t Have a Team',
                          color: Colors.orange,
                          onTap: _navigateToRequestTeam,
                          isCompact: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // ROW 3: Get Template
                _buildSlickCard(
                  icon: Icons.download_for_offline_outlined,
                  title: 'Get Template',
                  action: 'Preview and Download',
                  color: Colors.purple,
                  onTap: _downloadTemplate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Status Banner Widget ---
  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final Color bannerColor =
        hasTeam ? Colors.green.shade50 : Colors.red.shade50;
    final Color textColor =
        hasTeam ? Colors.green.shade800 : Colors.red.shade800;
    final String statusText = hasTeam
        ? 'You are part of Team $teamId.'
        : 'Action required: You are not yet on a team.';

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

  // --- Slicker Card Widget (Updated for Consistent Color Design) ---
  Widget _buildSlickCard({
    required IconData icon,
    required String title,
    required String action,
    required Color color,
    required VoidCallback onTap,
    bool isProminent = false,
    bool isCompact = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: isProminent
            ? 6
            : 4, // Still slightly higher elevation for prominent
        color: Colors.white, // 🟢 FIX: Always white background now
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            // Keep padding larger if prominent
            padding: EdgeInsets.all(isProminent ? 25.0 : 20.0),
            child: isCompact
                ? Column(
                    // Compact Mode
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 30, color: color),
                      ),
                      const SizedBox(height: 12),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(action,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                : Row(
                    // Standard/Prominent Mode
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          // 🟢 FIX: Always use light opacity background for icon
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // 🟢 FIX: Always use the accent color for icon
                        child: Icon(icon, size: 30, color: color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                style: TextStyle(
                                    fontSize: isProminent
                                        ? 22
                                        : 18, // Font is still bigger if prominent
                                    fontWeight: FontWeight.bold,
                                    color: Colors
                                        .black87 // 🟢 FIX: Always black text
                                    )),
                            const SizedBox(height: 2),
                            Text(action,
                                style: TextStyle(
                                    fontSize: isProminent ? 16 : 14,
                                    color:
                                        color, // 🟢 FIX: Always accent color text
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
