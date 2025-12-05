import 'package:flutter/material.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:provider/provider.dart'; 

class StudentDashboard extends StatefulWidget { 
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String? _currentTeamId; 

  @override
  void initState() {
    super.initState();
  }

  // --- Navigation Handlers (Unchanged) ---
  void _navigateToTeamInfo() => print('Navigating to Team Info for $_currentTeamId');
  
  void _navigateToSubmitProposal() => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SubmitProposalScreen()),
  );
  
  void _navigateToRequestTeam() => print('Navigating to Request Team/Invite Screen');
  
  void _downloadTemplate() {
    print('Downloading Project Template...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading Project Template... (Functionality to be added)')),
    );
  }

  void _logout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout(); 
    print('User logged out via Provider.');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String actualStudentName = authProvider.user?.name ?? 'Student';
    _currentTeamId = "ABC-001"; 
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
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 10),
            
            // --- Status Banner ---
            _buildStatusBanner(hasTeam, _currentTeamId),
            
            const Divider(height: 40),

            // --- Single-column (4-row) card layout ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- Row 1: Team Info / Request Team (Conditional) ---
                _buildSlickCard(
                    icon: hasTeam ? Icons.groups_2_outlined : Icons.person_add_alt_1_outlined,
                    title: hasTeam ? 'Team Info' : 'Request Team',
                    action: hasTeam ? 'View Members' : 'Form / Join',
                    color: hasTeam ? Colors.blueAccent : Colors.orange,
                    onTap: hasTeam ? _navigateToTeamInfo : _navigateToRequestTeam,
                ),
                
                // --- Row 2: Submit Proposal ---
                _buildSlickCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Submit Proposal',
                  action: 'Start Draft',
                  color: Colors.green,
                  onTap: _navigateToSubmitProposal,
                ),

                // --- Row 3: Get Template ---
                _buildSlickCard(
                  icon: Icons.download_for_offline_outlined,
                  title: 'Get Template',
                  action: 'Download Now',
                  color: Colors.purple,
                  onTap: _downloadTemplate,
                ),

                // --- Row 4: Request Team (Always available) ---
                _buildSlickCard(
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Request Team',
                    action: 'Form / Join',
                    color: Colors.redAccent, 
                    onTap: _navigateToRequestTeam,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // --- Status Banner Widget (Unchanged) ---
  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final Color bannerColor = hasTeam ? Colors.green.shade50 : Colors.red.shade50;
    final Color textColor = hasTeam ? Colors.green.shade800 : Colors.red.shade800;
    final String statusText = hasTeam ? 'You are part of Team $teamId.' : 'Action required: You are not yet on a team.';

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
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  // --- Slicker Card Widget (Logo on Left Fix) ---
  Widget _buildSlickCard({
    required IconData icon,
    required String title,
    required String action,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            // 🟢 FIX: Changed the main structure to a Row to place icon and text horizontally
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Centers items vertically
              children: <Widget>[
                // 1. Icon (Logo) Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                
                // 2. Horizontal Spacing
                const SizedBox(width: 16),
                
                // 3. Title and Action (Expanded to take remaining space)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action,
                        style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
                      ),
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