import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api services/api_services.dart';
import '../../chatbot_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SupervisorListScreen extends StatelessWidget {
  const SupervisorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 No Provider needed here anymore
    final ApiService apiService = ApiService();
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("All Supervisors"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 FIXED: Call API directly without token argument
        // The Service handles the filtering ('role' == 'supervisor') and the token automatically.
        future: apiService.getSupervisors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sups = snapshot.data ?? [];

          if (sups.isEmpty) {
            return const Center(child: Text("No other supervisors found."));
          }

          return ListView.builder(
            itemCount: sups.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final s = sups[index];
              final name = s['name'] ?? 'Unknown';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF245E63),
                  borderRadius: AppRadii.card,
                  boxShadow: AppShadows.level1,
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F6F55),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Text(name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontSize: 16, color: Colors.white)),
                  subtitle: Text(s['email'] ?? '',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Chat with Assistant',
      ),
    );
  }
}
