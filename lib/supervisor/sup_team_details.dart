import 'package:flutter/material.dart';
// 🟢 Import your Theme
import '../theme/app_theme.dart';

class SupervisorTeamDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> team;

  const SupervisorTeamDetailsScreen({Key? key, required this.team})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safe Data Extraction
    final title = team['title'] ?? 'Untitled Project';
    final courseCode =
        team['course'] is Map ? team['course']['courseCode'] ?? 'N/A' : 'N/A';
    final courseTitle =
        team['course'] is Map ? team['course']['courseTitle'] ?? '' : '';
    final description = team['description'] ?? 'No description provided';
    final status = team['status']?.toString().toUpperCase() ?? 'PENDING';

    // Logic: Show only teamMembers, first one as leader (hide student account)
    final members = team['teamMembers'] as List? ?? [];
    final leader = members.isNotEmpty ? members.first : {};
    final restMembers = members.length > 1 ? members.sublist(1) : [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Project Details"),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F766E),
                    Color(0xFF115E59)
                  ], // Supervisor Green
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.level1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(courseCode,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          status,
                          style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(courseTitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- DRIVE LINK / DESCRIPTION ---
            Text("Submission Link / Description",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2)),
                boxShadow: AppShadows.level1,
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      description,
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- TEAM ROSTER ---
            Text("Team Roster",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Leader Card (first of teamMembers)
            if (leader.isNotEmpty)
              _buildMemberCard(context,
                  name: leader['name'] ?? 'Unknown',
                  id: leader['studentId'] ?? leader['_id'],
                  email: leader['email'],
                  role: "Leader",
                  color: const Color(0xFFF59E0B) // Amber for Leader
                  ),

            // Rest of team members
            ...restMembers
                .map((m) => _buildMemberCard(context,
                    name: m['name'] ?? 'Unknown',
                    id: m['studentId'] ?? m['_id'],
                    email: m['email'],
                    role: "Member",
                    color: Colors.grey))
                .toList(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context,
      {required String name,
      required String? id,
      required String? email,
      required String role,
      required Color color}) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.level1,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(Icons.person, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (role == "Leader")
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text("LEADER",
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2410C))),
                      )
                  ],
                ),
                Text(id ?? 'N/A',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
