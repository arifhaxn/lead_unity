import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:provider/provider.dart';

// 🟢 Correct Imports
import '../auth_provider.dart';
import '../home_page.dart';
import '../view_template.dart';
import '../chatbot_screen.dart';
import 'team_info.dart'; 

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // --- Navigation Handlers ---
  void _navigateToTeamInfo() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  }

  void _navigateToSubmitProposal() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SubmitProposalScreen()));
  }

  void _navigateToRequestTeam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request Team feature coming soon!')),
    );
  }

  void _downloadTemplate() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));
  }

  void _logout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();
    
    // 🟢 Use pushAndRemoveUntil to clear stack so user can't go back
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false
    );
  }

  void _openChatbot() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Logic Fix: Listen to AuthProvider updates to keep name/status fresh
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // Safely access properties from your User model
    final String studentName = user?.name ?? 'Student';
    // Logic placeholder: In a real app, you'd check if user.teamId is not null
    final bool hasTeam = false; 
    final String? currentTeamId = null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // 🟢 Keeping his clean background color
      appBar: AppBar(
        title: const Text('Student Dashboard', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0, // Flat modern look
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // 🟢 Increased padding for modern feel
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Welcome Section ---
            Text(
              'Hello, $studentName',
              style: const TextStyle(
                  fontSize: 28, // Slightly smaller than 30 for better fit
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)), // Slate 800
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
                  icon: Icons.upload_file_outlined,
                  title: 'Submit Proposal',
                  action: 'Upload your team project proposal',
                  color: Colors.green,
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
                          action: 'Find a group',
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        backgroundColor: const Color(0xFF0F766E), // Teal to match theme
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ),
    );
  }

  // --- Status Banner Widget ---
  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final Color bannerColor = hasTeam ? Colors.green.shade50 : Colors.red.shade50;
    final Color textColor = hasTeam ? Colors.green.shade800 : Colors.red.shade800;
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
              hasTeam ? Icons.check_circle_outline : Icons.warning_amber_outlined,
              color: textColor
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(statusText,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // --- Slicker Card Widget ---
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05), 
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          padding: EdgeInsets.all(isProminent ? 24.0 : 20.0),
          child: isCompact
              ? Column( // Compact Layout (Vertical)
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
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(action,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500)),
                  ],
                )
              : Row( // Standard/Prominent Layout (Horizontal)
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
                                  color: const Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text(action,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
                  ],
                ),
        ),
      ),
    );
  }
}