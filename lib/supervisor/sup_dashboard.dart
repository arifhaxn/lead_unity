import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🟢 Core Imports
import '../auth_provider.dart';
import '../home_page.dart';

// 🟢 Screen Imports (Ensure these files exist in lib/supervisor/)
import 'team_list_screen.dart';
import 'marking_selection_screen.dart';
import 'sup_list_screen.dart'; // Renamed from supervisor_list_screen based on your file tree

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 Logic: Listen to the provider to get the latest User object
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Supervisor Portal',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
            Text('Welcome back,', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            
            // 🟢 Data: Display the name dynamically from the User model
            Text(
              user?.name ?? 'Supervisor', 
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                  "My Teams", "Assigned Groups", Icons.groups, const Color(0xFF0F766E), 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamListScreen(onlyMyTeams: true)))
                ),
                
                _buildCard(
                  context, 
                  "All Teams", "Global List", Icons.format_list_bulleted, const Color(0xFF3B82F6), 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamListScreen(onlyMyTeams: false)))
                ),
                
                _buildCard(
                  context, 
                  "Marking", "Evaluation", Icons.verified_user_outlined, const Color(0xFFF59E0B), 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarkingSelectionScreen()))
                ),
                
                _buildCard(
                  context, 
                  "Supervisors", "Colleagues", Icons.person_pin_circle_outlined, const Color(0xFF8B5CF6), 
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupervisorListScreen()))
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 🟢 UI Helper: Kept your teammate's card design as requested, but simplified slightly
  Widget _buildCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, size: 28, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}