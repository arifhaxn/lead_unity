import 'package:flutter/material.dart';
import 'package:link_unity/widgets/animated_dialog.dart'; // 🟢 ADDED for the instructions pop-up
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
// 🟢 REMOVED: notification_bell.dart
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
      dp.fetchMyTeamIfNeeded();
      dp.fetchSupervisorsIfNeeded();
      dp.fetchNotificationsIfNeeded();
      dp.fetchMyProposalsIfNeeded(); 
    });
  }

  // 🟢 ADDED: Instructions Dialog tailored for the Team Info screen
  void _showInstructions() {
    showAnimatedDialog(
      context: context,
      dialog: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text("Team Info Guide"),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "• Active Proposal: Displays your currently active team, assigned supervisor, and project status.\n\n"
            "• Team Members: View the details of everyone in your group. The leader is marked with a special badge.\n\n"
            "• My Submitted Proposals: Expand the cards at the bottom to view the history of past team requests you have submitted.",
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dp = Provider.of<DataProvider>(context);

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
          // 🟢 UPDATED: Notification icon removed, replaced with consistent Theme & Info buttons
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      floatingActionButton: const BreathingChatbotFab(),
      body: Builder(
        builder: (context) {
          // Loading
          if (dp.isLoadingMyTeam && dp.myTeam == null) {
            return _buildSkeletonLoader(theme);
          }

          // ── Empty state (No Active Team) ──────────────────────────────────
          if (dp.myTeam == null) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  dp.fetchMyTeamIfNeeded(forceRefresh: true),
                  dp.fetchSupervisorsIfNeeded(forceRefresh: true),
                  dp.fetchMyProposalsIfNeeded(forceRefresh: true),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
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
                  
                  // Historical Proposals (All collapsed)
                  if (myProposals.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('My Submitted Proposals', style: theme.textTheme.titleLarge),
                    ),
                    const SizedBox(height: 12),
                    ...myProposals.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _ExpandableProposalCard(
                            proposal: p,
                            theme: theme,
                            buildInfoRow: _buildInfoRow,
                            buildMemberCard: _buildMemberCard,
                            resolveField: _resolveField,
                            getStatusColor: _getStatusColor,
                          ),
                        )),
                    const SizedBox(height: 20),
                  ]
                ],
              ),
            );
          }

          // ── Success state (Has Active Team) ──────────────────────────────
          final proposal = dp.myTeam!;
          final course = proposal['course'] ?? {};

          final dynamic supervisor = proposal['assignedSupervisor'];
          String supName = 'Not Assigned';
          
          if (supervisor is Map) {
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

          final leaderMap = proposal['student'];
          final String? leaderStudentId =
              leaderMap is Map ? leaderMap['studentId']?.toString() : null;

          final rawMembers = (proposal['teamMembers'] as List? ?? []);
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
                dp.fetchMyProposalsIfNeeded(forceRefresh: true),
              ]);
            },
            color: theme.colorScheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [

                // ACTIVE PROPOSAL LABEL 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ACTIVE PROPOSAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      _buildInfoRow('Description/Link',
                          proposal['description'] ?? 'No link provided', isLink: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('Team Members', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),

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

                ...otherMembers.map((m) => _buildMemberCard(
                      name: m['name']?.toString() ?? 'Unknown',
                      studentId: m['studentId']?.toString() ?? 'N/A',
                      email: m['email']?.toString() ?? 'N/A',
                      mobile: m['mobile']?.toString(),
                      cgpa: m['cgpa']?.toString(),
                      isLeader: false,
                    )),

                // Render Historical Proposals (All collapsed)
                if (myProposals.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  Text('My Submitted Proposals', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...myProposals.map((p) => _ExpandableProposalCard(
                        proposal: p,
                        theme: theme,
                        buildInfoRow: _buildInfoRow,
                        buildMemberCard: _buildMemberCard,
                        resolveField: _resolveField,
                        getStatusColor: _getStatusColor,
                      )),
                  const SizedBox(height: 20),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

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
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 8), 
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
                    ]
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

  Widget _buildInfoRow(String label, String value, {bool isLink = false, Color? textColor, Color? labelColor}) {
    final tColor = textColor ?? Colors.white;
    final lColor = labelColor ?? Colors.white70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: lColor)),
        const SizedBox(height: 4),
        if (isLink && value != 'No link provided' && value.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final uri = Uri.tryParse(value);
              final launchUri = (uri != null && !uri.hasScheme) 
                  ? Uri.tryParse('https://$value') 
                  : uri;
                  
              if (launchUri != null) {
                try {
                  // 🟢 FIX: Directly launch the URL without checking canLaunchUrl first!
                  await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error launching link: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent, 
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.lightBlueAccent,
              ),
            ),
          )
        else
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tColor)),
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

// ── Expandable Proposal Card Widget ─────────
class _ExpandableProposalCard extends StatefulWidget {
  final Map<String, dynamic> proposal;
  final ThemeData theme;
  
  final Widget Function(String, String, {bool isLink, Color? textColor, Color? labelColor}) buildInfoRow;
  final Widget Function({required String name, required String studentId, required String email, String? mobile, String? cgpa, required bool isLeader}) buildMemberCard;
  final String? Function({required dynamic fromPopulated, required List rawMembers, required String? studentId, required String field}) resolveField;
  final Color Function(String?) getStatusColor;

  const _ExpandableProposalCard({
    required this.proposal,
    required this.theme,
    required this.buildInfoRow,
    required this.buildMemberCard,
    required this.resolveField,
    required this.getStatusColor,
  });

  @override
  State<_ExpandableProposalCard> createState() => _ExpandableProposalCardState();
}

class _ExpandableProposalCardState extends State<_ExpandableProposalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final status = (widget.proposal['status'] ?? 'PENDING').toString().toUpperCase();
    final statusColor = widget.getStatusColor(widget.proposal['status']);
    final dp = Provider.of<DataProvider>(context, listen: false);
    
    // Resolve Course
    final course = widget.proposal['course'];
    String courseCode = 'N/A';
    if (course is Map) {
      courseCode = course['courseCode']?.toString() ?? 'N/A';
    } else if (course != null) {
      final found = dp.allCourses?.firstWhere((c) => c['_id']?.toString() == course.toString(), orElse: () => null);
      if (found != null) courseCode = found['courseCode']?.toString() ?? 'N/A';
    }

    // Resolve Supervisor
    final dynamic supervisor = widget.proposal['assignedSupervisor'];
    String supName = 'Not Assigned';
    if (supervisor is Map) {
      supName = supervisor['name'] ?? supervisor['abbreviation'] ?? 'Not Assigned';
    } else if (supervisor != null && dp.allSupervisors != null) {
      final found = dp.allSupervisors!.firstWhere((s) => s['_id']?.toString() == supervisor.toString(), orElse: () => null);
      if (found != null) supName = (found['name'] ?? found['abbreviation'] ?? 'Not Assigned').toString();
    }

    // Resolve Members
    final leaderMap = widget.proposal['student'];
    final String? leaderStudentId = leaderMap is Map ? leaderMap['studentId']?.toString() : null;
    final rawMembers = (widget.proposal['teamMembers'] as List? ?? []);
    final otherMembers = rawMembers.where((m) {
      if (m is! Map) return false;
      final sid = m['studentId']?.toString();
      return sid != null && sid != leaderStudentId;
    }).toList();

    // Theme setup
    final isDark = widget.theme.brightness == Brightness.dark;
    final bgColor = isDark ? widget.theme.colorScheme.surfaceVariant.withOpacity(0.3) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.card,
        border: Border.all(color: widget.theme.colorScheme.outline.withOpacity(0.3)),
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
          // HEADER (Always Visible & Clickable)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque, 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.book_rounded, size: 14, color: widget.theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(courseCode, style: TextStyle(fontWeight: FontWeight.bold, color: widget.theme.colorScheme.primary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.proposal['title'] ?? 'Untitled Proposal',
                        style: widget.theme.textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    const SizedBox(height: 12),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0, 
                      duration: const Duration(milliseconds: 300),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: labelColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // EXPANDABLE BODY (Supervisor, Links, and Members)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: !_isExpanded ? const SizedBox.shrink() : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 12),
                
                widget.buildInfoRow('Assigned Supervisor', supName, textColor: textColor, labelColor: labelColor),
                const SizedBox(height: 12),
                widget.buildInfoRow('Description/Link', widget.proposal['description'] ?? 'No link provided', isLink: true, textColor: textColor, labelColor: labelColor),
                
                const SizedBox(height: 20),
                Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Submitted Team Members', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 12),

                // Render Leader
                if (leaderMap is Map)
                  widget.buildMemberCard(
                    name: leaderMap['name']?.toString() ?? 'Unknown',
                    studentId: leaderMap['studentId']?.toString() ?? 'N/A',
                    email: leaderMap['email']?.toString() ?? 'N/A',
                    mobile: widget.resolveField(
                      fromPopulated: leaderMap['mobile'],
                      rawMembers: rawMembers,
                      studentId: leaderStudentId,
                      field: 'mobile',
                    ),
                    cgpa: widget.resolveField(
                      fromPopulated: leaderMap['cgpa'],
                      rawMembers: rawMembers,
                      studentId: leaderStudentId,
                      field: 'cgpa',
                    ),
                    isLeader: true,
                  ),

                // Render Other Members
                ...otherMembers.map((m) => widget.buildMemberCard(
                      name: m['name']?.toString() ?? 'Unknown',
                      studentId: m['studentId']?.toString() ?? 'N/A',
                      email: m['email']?.toString() ?? 'N/A',
                      mobile: m['mobile']?.toString(),
                      cgpa: m['cgpa']?.toString(),
                      isLeader: false,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}