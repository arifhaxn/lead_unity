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
    // 1. Get Logged-in User ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.id;
    final ApiService apiService = ApiService();
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Helper to extract ID
    String getId(dynamic obj) {
      if (obj is Map) return obj['_id']?.toString() ?? '';
      return obj?.toString() ?? '';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Select Team to Evaluate"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          var teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return const Center(child: Text("No proposals found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];

              // --- LOGIC: Determine Relationship ---
              final sups = team['supervisors'] as List? ?? [];
              final assigned = team['assignedSupervisor'];
              
              // Check if I am involved (Assigned or Preferred)
              bool isMyTeam = false;
              if (myId != null) {
                bool isAssigned = getId(assigned) == myId;
                bool isPreferred = sups.any((s) => getId(s) == myId);
                isMyTeam = isAssigned || isPreferred;
              }

              // --- UI Elements ---
              final courseCode = (team['course'] is Map)
                  ? team['course']['courseCode']
                  : '${team['course'] ?? 'N/A'}';
              final title = team['title'] ?? 'Untitled';
              final studentName = team['student']?['name'] ?? 'Unknown Leader';

              // Dynamic Styling based on Type
              final cardColor = isMyTeam ? Colors.teal[50] : theme.colorScheme.surface;
              final btnColor = isMyTeam ? Colors.teal : Colors.deepPurple;
              final btnText = isMyTeam ? "Internal Evaluation" : "Defense Evaluation";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppRadii.card,
                  boxShadow: AppShadows.level1,
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(courseCode,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary)),
                          ),
                          if (isMyTeam) 
                            const Icon(Icons.star, size: 18, color: Colors.amber) // Indicator
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Leader: $studentName', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
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
                            backgroundColor: btnColor,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
                          ),
                          child: Text(btnText),
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
}