import 'package:flutter/material.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../providers/data_provider.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  @override
  void initState() {
    super.initState();
    // 🟢 Trigger the background cache sync instantly upon opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchMyProposalsIfNeeded();
      dp.fetchSupervisorsIfNeeded(); // 🟢 Fetch supervisors for the name lookup!
      dp.fetchNotificationsIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dp = Provider.of<DataProvider>(context);

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2),
        height: 1.0,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Team & Proposal'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
        actions: [
          const NotificationBell(), // 🟢 ADDED: The Notification Bell widget
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
      floatingActionButton: const BreathingChatbotFab(),
      body: Builder(
        builder: (context) {
          // 1. Show Shimmer ONLY if cache is completely empty
          if (dp.isLoadingMyProposals && dp.myProposals == null) {
            return _buildSkeletonLoader(theme);
          }

          // 2. Empty State (No proposals)
          if (dp.myProposals == null || dp.myProposals!.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  dp.fetchMyProposalsIfNeeded(forceRefresh: true),
                  dp.fetchSupervisorsIfNeeded(forceRefresh: true),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(Icons.diversity_3_outlined,
                      size: 80,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text("No Team Found",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text("Submit a proposal to form a team.",
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            );
          }

          // 3. Success State (Scrollable list of all proposals)
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                dp.fetchMyProposalsIfNeeded(forceRefresh: true),
                dp.fetchSupervisorsIfNeeded(forceRefresh: true),
              ]);
            },
            color: theme.colorScheme.primary,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: dp.myProposals!.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Divider(
                  thickness: 2,
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              itemBuilder: (context, index) {
                final proposal = dp.myProposals![index];
                final members = proposal['teamMembers'] as List? ?? [];
                final course = proposal['course'] ?? {};

                // 🟢 ID-to-Name Lookup Logic for Supervisor
                final dynamic supervisor = proposal['assignedSupervisor'];
                String supName = 'Not Assigned';

                if (supervisor is Map) {
                  supName = supervisor['abbreviation'] ??
                      supervisor['name'] ??
                      'Not Assigned';
                } else if (supervisor != null && dp.allSupervisors != null) {
                  final foundSup = dp.allSupervisors!.firstWhere(
                      (s) => s['_id']?.toString() == supervisor.toString(),
                      orElse: () => null);
                  if (foundSup != null) {
                    supName = (foundSup['name'] ??
                            foundSup['abbreviation'] ??
                            'Not Assigned')
                        .toString();
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  backgroundColor: const Color(0xFF1A4A4F),
                                  labelStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  side: BorderSide.none,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                      color:
                                          _getStatusColor(proposal['status']),
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
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                            Text(proposal['title'] ?? 'Untitled Project',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white)),
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),

                            // 🟢 DISPLAY THE SUPERVISOR HERE
                            _buildInfoRow('Assigned Supervisor', supName),
                            const SizedBox(height: 12),

                            _buildInfoRow('Description/Link',
                                proposal['description'] ?? 'No link provided'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Team Members", style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...members.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF245E63),
                            borderRadius: AppRadii.card,
                            boxShadow: AppShadows.level1,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.15),
                                child: Text(
                                  (m['name']?[0] ?? 'U')
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const SizedBox(height: 6),
                                    _memberDetailRow(Icons.badge_outlined, 'ID',
                                        m['studentId'] ?? 'N/A'),
                                    const SizedBox(height: 4),
                                    _memberDetailRow(Icons.email_outlined,
                                        'Email', m['email'] ?? 'N/A'),
                                    const SizedBox(height: 4),
                                    _memberDetailRow(Icons.phone_outlined,
                                        'Mobile', m['mobile'] ?? 'N/A'),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("CGPA",
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white70)),
                                  Text(
                                      m['cgpa'] != null
                                          ? double.tryParse(
                                                      m['cgpa'].toString())
                                                  ?.toStringAsFixed(2) ??
                                              m['cgpa'].toString()
                                          : 'N/A',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 🟢 Skeleton Loader Method
  Widget _buildSkeletonLoader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 24,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
                3,
                (index) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _memberDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ),
      ],
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
