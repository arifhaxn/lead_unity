import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api services/api_services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Team & Proposal'),
        backgroundColor: theme.colorScheme.surface,
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
        // 🟢 Using his API method which automatically attaches the token
        future: _apiService.getUserProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diversity_3_outlined,
                      size: 80,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No Team Found",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text("Submit a proposal to form a team.",
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          // 🟢 Logic: Display the first active proposal (similar to his logic)
          final proposal = snapshot.data![0];
          final members = proposal['teamMembers'] as List? ?? [];
          final course = proposal['course'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Your Card UI for the Project Info
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF245E63),
                    borderRadius: AppRadii.card,
                    boxShadow: AppShadows.level1,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(course['courseCode'] ?? 'N/A'),
                              backgroundColor: Colors.white.withOpacity(0.15),
                              labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: _getStatusColor(proposal['status']),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                (proposal['status'] ?? 'PENDING')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text("Project Title",
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70)),
                        Text(proposal['title'] ?? 'Untitled Project',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildInfoRow('Description/Link',
                            proposal['description'] ?? 'No link provided'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text("Team Members", style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),

                // 🟢 Your List-based UI for members
                ...members
                    .map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF245E63),
                            borderRadius: AppRadii.card,
                            boxShadow: AppShadows.level1,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              child: Text(
                                (m['name']?[0] ?? 'U').toString().toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(m['name'] ?? 'Unknown',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 16, color: Colors.white)),
                            subtitle: Text(m['studentId'] ?? 'No ID',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("CGPA",
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.white70)),
                                Text(m['cgpa'] ?? 'N/A',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.accentTeal;
      case 'rejected':
        return AppColors.accentCoral;
      default:
        return AppColors.accentLime;
    }
  }
}
