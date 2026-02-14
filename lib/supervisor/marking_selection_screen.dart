import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api services/api_services.dart';
import '../../auth_provider.dart';
import 'marking_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class MarkingSelectionScreen extends StatelessWidget {
  const MarkingSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 1. Get Logged-in User ID to filter the list
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.id;
    final ApiService apiService = ApiService();
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Evaluation"),
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
        // 🟢 2. Call API directly (Token is auto-injected)
        future: apiService.getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No proposals found."));
          }

          // 🟢 3. Filter Logic: Only show teams assigned to THIS supervisor
          var teams = snapshot.data!.where((t) {
            final sups = t['supervisors'] as List? ?? [];
            // Robust check: Handle if supervisor is an object or just an ID string
            return sups.any((s) {
              if (s is Map) return s['_id'] == myId;
              if (s is String) return s == myId;
              return false;
            });
          }).toList();

          if (teams.isEmpty) {
            return const Center(child: Text("No assigned teams to mark."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];

              // 🟢 4. Safety Check for Course Code display
              final courseCode = (team['course'] is Map)
                  ? team['course']['courseCode']
                  : 'Course: ${team['course'] ?? 'N/A'}';
              final supervisorName =
                  _extractSupervisorName(team['supervisors']);

              final isDark = theme.brightness == Brightness.dark;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: AppRadii.card,
                  boxShadow: AppShadows.level1,
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(courseCode,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary)),
                          ),
                          Icon(Icons.more_horiz,
                              color: isDark
                                  ? Colors.white70
                                  : theme.colorScheme.onSurfaceVariant)
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(team['title'] ?? 'Untitled',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: isDark ? Colors.white : null)),
                      if (supervisorName != null) ...[
                        const SizedBox(height: 6),
                        Text('Supervisor: $supervisorName',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : theme.colorScheme.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MarkingScreen(team: team)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.button),
                          ),
                          child: const Text("Start Evaluation"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String? _extractSupervisorName(dynamic supervisors) {
    if (supervisors is List && supervisors.isNotEmpty) {
      final first = supervisors.first;
      if (first is Map) {
        final name = first['name'] ?? first['fullName'];
        if (name is String && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
    }
    return null;
  }
}
