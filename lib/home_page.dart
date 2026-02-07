import 'package:flutter/material.dart';
import 'login_screen.dart'; // 🟢 Points to the unified LoginScreen we merged earlier

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // --- Logic Merge: Use the role-based navigation from his logic ---
  void _navigateToStudentLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(role: 'student'),
      ),
    );
  }

  void _navigateToAdminLogin(BuildContext context) {
    // 🟢 Fixed: Removed the placeholder SnackBar and connected to logic
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(role: 'supervisor'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🟢 Keeping your clean white background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Your Original Logo & Title ---
              const Icon(
                Icons.lightbulb_outline, 
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'LeadUnity',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'The Link Between Students and Supervisors',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // --- Your Original Student Card ---
              _buildLoginOptionCard(
                context: context,
                title: 'Student',
                subtitle: 'Register or Log in to manage your project team and proposals.',
                icon: Icons.school,
                color: Colors.blueAccent,
                onTap: () => _navigateToStudentLogin(context),
              ),
              const SizedBox(height: 30),

              // --- Your Original Supervisor Card ---
              _buildLoginOptionCard(
                context: context,
                title: 'Supervisor',
                subtitle: 'Log in to view, approve, and assign student projects.',
                icon: Icons.security,
                color: Colors.deepOrange,
                onTap: () => _navigateToAdminLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Your Original Card Design Helper ---
  Widget _buildLoginOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}