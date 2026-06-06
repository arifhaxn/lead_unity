import 'package:flutter/material.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart'; // 🟢 ADDED: Required for clicking links
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      // Use getMyTeam — works for both leaders AND absorbed members
      dp.fetchMyTeamIfNeeded();
      dp.fetchSupervisorsIfNeeded();
      dp.fetchNotificationsIfNeeded();
      // 🟢 RESTORED: Fetch user's individual proposal history
      dp.fetchMyProposalsIfNeeded(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dp = Provider.of<DataProvider>(context);

    // 🟢 Grab the proposals list to display at the bottom
    final myProposals = dp.myProposals ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Team & Proposal'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.outline.withOpacity(0.2),
            height: 1.0,
          ),
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      floatingActionButton: const BreathingChatbotFab(),
      body: Builder(
        builder: (context) {
          // Loading — only show shimmer when cache is truly empty
          if (dp.isLoadingMyTeam && dp.myTeam == null) {
            return _buildSkeletonLoader(theme);
          }

          // Empty state
          if (dp.myTeam == null) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  dp.fetchMyTeamIfNeeded(forceRefresh: true),
                  dp.fetchSupervisorsIfNeeded(forceRefresh: true),
                  // 🟢 RESTORED: Refresh proposal history
                  dp.fetchMyProposalsIfNeeded(forceRefresh: true),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Push it up slightly if they have proposals to show below
                  SizedBox(height: MediaQuery.of(context).size.height * (myProposals.isEmpty ? 0.3 : 0.1)),
                  Icon(Icons.diversity_3_outlined,
                      size: 80,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('No Active Team Found',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Submit a proposal or wait for your team to be formed.',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // 🟢 RESTORED: Show proposal list even if no active team exists yet
                  if (myProposals.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('My Submitted Proposals', style: theme.textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    ...myProposals.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildProposalCard(p, theme),
                        )),
                    const SizedBox(height: 20),
                  ]
                ],
              ),
            );
          }

          // ── Success state ────────────────────────────────────────────────
          final proposal = dp.myTeam!;
          final course = proposal['course'] ?? {};

          // Resolve supervisor name
          final dynamic supervisor = proposal['assignedSupervisor'];
          String supName = 'Not Assigned';
          
          if (supervisor is Map) {
            // FIXED: Swapped 'name' to be checked BEFORE 'abbreviation'
            supName = supervisor['name'] ?? supervisor['abbreviation'] ?? 'Not Assigned';
          } else if (supervisor != null && dp.allSupervisors != null) {
            final found = dp.allSupervisors!.firstWhere(
              (s) => s['_id']?.toString() == supervisor.toString(),
              orElse: () => null,
            );
            if (found != null) {
              supName = (found['name'] ?? found['abbreviation'] ?? 'Not Assigned').toString();
            }
          }

          // ── Build the deduplicated member list ───────────────────────────
          final leaderMap = proposal['student'];
          final String? leaderStudentId =
              leaderMap is Map ? leaderMap['studentId']?.toString() : null;

          final rawMembers = (proposal['teamMembers'] as List? ?? []);

          // Deduplicate: remove any member entry that matches the leader
          final otherMembers = rawMembers.where((m) {
            if (m is! Map) return false;
            final sid = m['studentId']?.toString();
            return sid != null && sid != leaderStudentId;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                dp.fetchMyTeamIfNeeded(forceRefresh: true),
                dp.fetchSupervisorsIfNeeded(forceRefresh: true),
                // 🟢 RESTORED: Refresh proposal history
                dp.fetchMyProposalsIfNeeded(forceRefresh: true),
              ]);
            },
            color: theme.colorScheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // ── Project header card ──────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF245E63),
                    borderRadius: AppRadii.card,
                    boxShadow: AppShadows.level1,
                  ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Project Title',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white70)),
                      Text(
                        proposal['title'] ?? 'Untitled Project',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      _buildInfoRow('Assigned Supervisor', supName),
                      const SizedBox(height: 12),
                      
                      // UPDATED: Passing isLink: true so it triggers the clickable logic
                      _buildInfoRow('Description/Link',
                          proposal['description'] ?? 'No link provided', isLink: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('Team Members', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),

                // Leader card (always first)
                if (leaderMap is Map)
                  _buildMemberCard(
                    name: leaderMap['name']?.toString() ?? 'Unknown',
                    studentId: leaderMap['studentId']?.toString() ?? 'N/A',
                    email: leaderMap['email']?.toString() ?? 'N/A',
                    mobile: _resolveField(
                      fromPopulated: leaderMap['mobile'],
                      rawMembers: rawMembers,
                      studentId: leaderStudentId,
                      field: 'mobile',
                    ),
                    cgpa: _resolveField(
                      fromPopulated: leaderMap['cgpa'],
                      rawMembers: rawMembers,
                      studentId: leaderStudentId,
                      field: 'cgpa',
                    ),
                    isLeader: true,
                  ),

                // Other members (duplicates already filtered out)
                ...otherMembers.map((m) => _buildMemberCard(
                      name: m['name']?.toString() ?? 'Unknown',
                      studentId: m['studentId']?.toString() ?? 'N/A',
                      email: m['email']?.toString() ?? 'N/A',
                      mobile: m['mobile']?.toString(),
                      cgpa: m['cgpa']?.toString(),
                      isLeader: false,
                    )),

                // 🟢 RESTORED: Proposal History Section appended at the bottom
                if (myProposals.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text('My Submitted Proposals', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...myProposals.map((p) => _buildProposalCard(p, theme)),
                  const SizedBox(height: 20),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tries `fromPopulated` first; if null/empty, looks inside the raw
  /// teamMembers list for a matching entry.
  String? _resolveField({
    required dynamic fromPopulated,
    required List rawMembers,
    required String? studentId,
    required String field,
  }) {
    if (fromPopulated != null &&
        fromPopulated.toString().isNotEmpty &&
        fromPopulated.toString() != 'null') {
      return fromPopulated.toString();
    }
    if (studentId == null) return null;
    try {
      final match = rawMembers.firstWhere(
        (m) => m is Map && m['studentId']?.toString() == studentId,
        orElse: () => null,
      );
      return match?[field]?.toString();
    } catch (_) {
      return null;
    }
  }

  Widget _buildMemberCard({
    required String name,
    required String studentId,
    required String email,
    String? mobile,
    String? cgpa,
    required bool isLeader,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF245E63),
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.level1,
        border: isLeader
            ? Border.all(color: Colors.white.withOpacity(0.25), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(
              (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    if (isLeader)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('LEADER',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _memberDetailRow(Icons.badge_outlined, 'ID', studentId),
                const SizedBox(height: 4),
                _memberDetailRow(Icons.email_outlined, 'Email', email),
                const SizedBox(height: 4),
                _memberDetailRow(
                    Icons.phone_outlined, 'Mobile', mobile ?? 'N/A'),
              ],
            ),
          ),
          // CGPA badge
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('CGPA',
                  style: TextStyle(fontSize: 10, color: Colors.white70)),
              Text(
                cgpa != null && cgpa.isNotEmpty
                    ? double.tryParse(cgpa)?.toStringAsFixed(2) ?? cgpa
                    : 'N/A',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white),
              ),
            ],
          ),
        ],
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

  // UPDATED: Now supports clickable links if isLink is passed as true
  Widget _buildInfoRow(String label, String value, {bool isLink = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        if (isLink && value != 'No link provided' && value.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(value);
              // Fallback for valid URLs that don't explicitly start with https://
              final launchUri = (uri != null && !uri.hasScheme) 
                  ? Uri.tryParse('https://$value') 
                  : uri;
                  
              if (launchUri != null && await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent, // Makes it look clickable
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.lightBlueAccent,
              ),
            ),
          )
        else
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
      ],
    );
  }

  // 🟢 RESTORED: Proposal Card Builder
  Widget _buildProposalCard(Map<String, dynamic> proposal, ThemeData theme) {
    final status = (proposal['status'] ?? 'PENDING').toString().toUpperCase();
    final statusColor = _getStatusColor(proposal['status']);
    
    // Resolve Course code safely
    final course = proposal['course'];
    String courseCode = 'N/A';
    if (course is Map) {
      courseCode = course['courseCode']?.toString() ?? 'N/A';
    } else if (course != null) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      final found = dp.allCourses?.firstWhere(
        (c) => c['_id']?.toString() == course.toString(),
        orElse: () => null,
      );
      if (found != null) courseCode = found['courseCode']?.toString() ?? 'N/A';
    }

    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.3) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.book_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(courseCode, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            proposal['title'] ?? 'Untitled Proposal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
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
                (i) => Container(
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
}