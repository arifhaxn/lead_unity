// lib/screens/student_dashboard_screen.dart (REVISED)

import 'package:flutter/material.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboard> {
  // 🟢 Placeholder for student data fetched after login.
  // Set to null to test the "No Team" flow, or to a value like "ABC-001" for "Has Team" flow.
  String? _currentTeamId = "ABC-001"; // Change to null to test 'Request Team' in the first slot
  String _studentName = "Alice Johnson"; // Example name

  @override
  void initState() {
    super.initState();
    // TODO: Fetch the student's status (teamID, proposals) here.
  }

  // --- Navigation Handlers (Placeholders) ---
  void _navigateToTeamInfo() => print('Navigating to Team Info for $_currentTeamId');
  void _navigateToSubmitProposal() => print('Navigating to Submit Proposal');
  void _navigateToRequestTeam() => print('Navigating to Request Team/Invite Screen');
  void _downloadTemplate() {
    print('Downloading Project Template...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading Project Template... (Functionality to be added)')),
    );
  }

  void _logout() {
    // TODO: Clear the JWT token and navigate to the HomePage.
    print('User logged out.');
    Navigator.of(context).popUntil((route) => route.isFirst); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
              'Hello, $_studentName',
              style: const TextStyle(
                fontSize: 30, 
                fontWeight: FontWeight.bold, 
                color: Colors.black87
              ),
            ),
            const SizedBox(height: 10),
            
            // --- Status Banner ---
            _buildStatusBanner(),
            
            const Divider(height: 40),

            // --- Main Features Grid ---
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                // 1. Team Management Card (Conditional: Info OR Request)
                _currentTeamId != null
                    ? _buildSlickCard(
                        icon: Icons.groups_2_outlined,
                        title: 'Team Info',
                        action: 'View Members',
                        color: Colors.blueAccent,
                        onTap: _navigateToTeamInfo,
                      )
                    : _buildSlickCard(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Request Team',
                        action: 'Form / Join',
                        color: Colors.orange,
                        onTap: _navigateToRequestTeam,
                      ),
                
                // 2. Submit Proposal Card (Fixed)
                _buildSlickCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Submit Proposal',
                  action: 'Start Draft',
                  color: Colors.green,
                  onTap: _navigateToSubmitProposal,
                ),

                // 3. Get Template Card (Fixed)
                _buildSlickCard(
                  icon: Icons.download_for_offline_outlined,
                  title: 'Get Template',
                  action: 'Download Now',
                  color: Colors.purple,
                  onTap: _downloadTemplate,
                ),

                // 4. Request Team Card (Fixed in this slot - consistent placement)
                _buildSlickCard(
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'Request Team',
                    action: 'Form / Join',
                    color: Colors.redAccent, // Use a distinct color for the separate action
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
  Widget _buildStatusBanner() {
    final bool hasTeam = _currentTeamId != null;
    final Color bannerColor = hasTeam ? Colors.green.shade50 : Colors.red.shade50;
    final Color textColor = hasTeam ? Colors.green.shade800 : Colors.red.shade800;
    final String statusText = hasTeam ? 'You are part of Team $_currentTeamId.' : 'Action required: You are not yet on a team.';

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
  
  // --- Slicker Card Widget (Unchanged) ---
  Widget _buildSlickCard({
    required IconData icon,
    required String title,
    required String action,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Top Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              
              // Title and Action
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
            ],
          ),
        ),
      ),
    );
  }
}