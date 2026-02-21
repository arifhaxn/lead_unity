import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  // 🟢 Helper function to open websites
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ==========================================
    // 🟢 ENTER YOUR DEVELOPER DETAILS HERE
    // ==========================================
    final List<Map<String, dynamic>> developers = [
      {
        "name": "Arif Hasan",
        "batch": "61th Batch",
        "department": "Dept. of CSE",
        "role": "Lead Flutter Developer",
        "image": "assets/template/crew/arif.jpg",
        "fb": "https://www.facebook.com/arifhaxnn",
        "ig": "https://www.instagram.com/arifhaxn",
        "linkedin": "https://www.linkedin.com/in/arif-hasan-672249358",
      },
      {
        "name": "Shoumo Shahriar Araf",
        "batch": "61th Batch",
        "department": "Dept. of CSE",
        "role": "Backend NestJS Developer",
        "image": "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png",
        "fb": "https://facebook.com",
        "ig": "https://instagram.com",
        "linkedin": "https://linkedin.com",
      },
      {
        "name": "Omio Mahim",
        "batch": "61th Batch",
        "department": "Dept. of CSE",
        "role": "Frontend & AI Integrator",
        "image": "assets/template/crew/omio.jpeg",
        "fb": "https://facebook.com",
        "ig": "https://instagram.com",
        "linkedin": "https://linkedin.com",
      },
    ];

    // ==========================================
    // 🟢 ENTER YOUR SUPERVISOR DETAILS HERE
    // ==========================================
    final Map<String, String> supervisor = {
      "name": "Md. Ebrahim Hossain",
      "designation": "Associate Professor",
      "department": "Dept. of Computer Science and Engineering",
      "university": "Leading University",
      "image": "assets/template/crew/sir.jpeg", // 🟢 Local asset
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("About App"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. App Logo & Summary ---
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.school_rounded, size: 45, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              "LeadUnity",
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Version 1.0.0", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            
            const Text(
              "LeadUnity is a comprehensive project and proposal management system designed to seamlessly connect students and supervisors, streamlining the academic evaluation process.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 40),

            // --- 2. Developers Section ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Meet the Developers",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // Loop through the 3 developers and build cards
            ...developers.map((dev) => _buildDeveloperCard(theme, dev)),

            const SizedBox(height: 30),

            // --- 3. Supervisor Section ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Supervised By",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildSupervisorCard(theme, supervisor),

            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  // 🟢 Developer Card UI
  Widget _buildDeveloperCard(ThemeData theme, Map<String, dynamic> dev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Developer Picture
          CircleAvatar(
            radius: 45,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            // 🟢 Smart check for local vs network image
            backgroundImage: dev["image"].startsWith('http')
                ? NetworkImage(dev["image"]) as ImageProvider
                : AssetImage(dev["image"]),
          ),
          const SizedBox(height: 16),
          
          // Name 
          Text(
            dev["name"],
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          
          // 🟢 Batch & Department
          Text(
            "${dev["batch"]} • ${dev["department"]}",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),

          // Role
          Text(
            dev["role"],
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          
          // Social Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _launchUrl(dev["fb"]),
                icon: const Icon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
                tooltip: "Facebook",
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _launchUrl(dev["ig"]),
                icon: const Icon(FontAwesomeIcons.instagram, color: Color(0xFFE4405F)),
                tooltip: "Instagram",
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _launchUrl(dev["linkedin"]),
                icon: const Icon(FontAwesomeIcons.linkedin, color: Color(0xFF0A66C2)),
                tooltip: "LinkedIn",
              ),
            ],
          )
        ],
      ),
    );
  }

  // 🟢 Supervisor Card UI
  Widget _buildSupervisorCard(ThemeData theme, Map<String, String> supervisor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              // 🟢 Smart check for local vs network image
              backgroundImage: supervisor["image"]!.startsWith('http')
                  ? NetworkImage(supervisor["image"]!) as ImageProvider
                  : AssetImage(supervisor["image"]!),
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            supervisor["name"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 6),
          
          // Designation
          Text(
            supervisor["designation"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),

          // Department
          Text(
            supervisor["department"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),

          // University
          Text(
            supervisor["university"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}