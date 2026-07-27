import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // 🟢 NEW IMPORT
import 'package:link_unity/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final List<Map<String, dynamic>> developers = [
      {
        "name": "Arif Hasan",
        "batch": "61st Batch",
        "department": "Dept. of CSE",
        "role": "Lead Flutter Developer",
        "image": "assets/template/crew/pfp.jpeg",
        "fb": "https://www.facebook.com/arifhaxnn",
        "linkedin": "https://www.linkedin.com/in/arif-hasan-672249358",
        "github": "https://github.com/arifhaxn",
      },
      {
        "name": "Shoumo Shahriar Araf",
        "batch": "61st Batch",
        "department": "Dept. of CSE",
        "role": "Full Stack Developer",
        "image": "assets/template/crew/araf.jpeg",
        "fb": "https://www.facebook.com/shahriar.araf.3",
        "linkedin": "https://www.linkedin.com/in/shoumo-shahriar-araf",
        "github": "https://github.com/shahriaraf",
      },
      {
        "name": "Omio Mahim",
        "batch": "61st Batch",
        "department": "Dept. of CSE",
        "role": "Frontend & AI Integrator",
        "image": "assets/template/crew/omio.jpeg",
        "fb": "https://www.facebook.com/omio.mahim.044",
        "linkedin": "https://www.linkedin.com/in/omio-mahim-79a2302a8",
        "github": "https://github.com/Omio-Mahim",
      },
    ];

    final Map<String, String> supervisor = {
      "name": "Md. Ebrahim Hossain",
      "designation": "Associate Professor",
      "department": "Dept. of Computer Science and Engineering",
      "university": "Leading University",
      "image": "assets/template/crew/sir.jpeg",
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("About App"),
        backgroundColor: theme.scaffoldBackgroundColor, // 🟢 Tinted background
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      // 🟢 AnimationLimiter added for the entire page
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0) +
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            // 🟢 Staggered List conversion for Column children
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // 🟢 Animated Logo (Pulses like the Home Page)
                const _AnimatedAppLogo(),
                
                const SizedBox(height: 16),
                Text(
                  "LeadUnity",
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("Version 1.0.0",
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),

                const Text(
                  "LeadUnity is a comprehensive project and proposal management system designed to seamlessly connect students and supervisors, streamlining the academic evaluation process.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 40),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Meet the Developers",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Card items are included in the staggered mapping
                ...developers.map((dev) => _buildDeveloperCard(theme, dev)),

                const SizedBox(height: 30),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Supervised By",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSupervisorCard(theme, supervisor),

                const SizedBox(height: 40),

                const Divider(),
                const SizedBox(height: 16),
                Text(
                  "Inspired by the previous \"LU Dissertation\" app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          CircleAvatar(
            radius: 45,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: dev["image"].startsWith('http')
                ? NetworkImage(dev["image"]) as ImageProvider
                : AssetImage(dev["image"]),
          ),
          const SizedBox(height: 16),
          Text(
            dev["name"],
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            "${dev["batch"]} • ${dev["department"]}",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            dev["role"],
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dev.containsKey("fb") && dev["fb"].toString().isNotEmpty)
                IconButton(
                  onPressed: () => _launchUrl(dev["fb"]),
                  icon: const FaIcon(FontAwesomeIcons.facebook,
                      color: Color(0xFF1877F2)),
                  tooltip: "Facebook",
                ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _launchUrl(dev["github"]),
                icon: FaIcon(FontAwesomeIcons.github,
                    color: theme.colorScheme.onSurface),
                tooltip: "GitHub",
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _launchUrl(dev["linkedin"]),
                icon: const FaIcon(FontAwesomeIcons.linkedin,
                    color: Color(0xFF0A66C2)),
                tooltip: "LinkedIn",
              ),
            ],
          )
        ],
      ),
    );
  }

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
              backgroundImage: supervisor["image"]!.startsWith('http')
                  ? NetworkImage(supervisor["image"]!) as ImageProvider
                  : AssetImage(supervisor["image"]!),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            supervisor["name"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            supervisor["designation"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            supervisor["department"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            supervisor["university"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// --- 🟢 ANIMATED LOGO WIDGET FOR CONSISTENCY ---
class _AnimatedAppLogo extends StatefulWidget {
  const _AnimatedAppLogo({Key? key}) : super(key: key);

  @override
  State<_AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<_AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        height: 100,
        width: 100,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}