import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:link_unity/student/request_team_screen.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'view_template.dart';
import 'team_info.dart';
import '../features/app_drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchDeadlineIfNeeded();
      // 🟢 FORCE REFRESH: Guarantees the dashboard never gets stuck on a stale cache!
      dp.fetchMyProposalsIfNeeded(forceRefresh: true);
      dp.fetchSupervisorsIfNeeded();
      dp.fetchNotificationsIfNeeded(forceRefresh: true);
    });

    _startTickingClock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Clock Logic ---
  void _startTickingClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

// 🟢 AGGRESSIVE OVERRIDE: Hunts for the merged team, ignores crashes
  Map<String, dynamic>? _getNewestProposal(DataProvider dp) {
    if (dp.myProposals == null || dp.myProposals!.isEmpty) return null;

    try {
      final list = List<dynamic>.from(dp.myProposals!);

      // Step 1: Specifically hunt for the merged proposal FIRST
      for (var p in list) {
        if (p is Map && p['isMergedByAdmin'] == true) {
          return Map<String, dynamic>.from(p);
        }
      }

      // Step 2: If no merged team exists, hunt for an approved one
      for (var p in list) {
        if (p is Map &&
            (p['status'] ?? '').toString().toLowerCase() == 'approved') {
          return Map<String, dynamic>.from(p);
        }
      }

      // Step 3: If no approved team exists, hunt for a pending one
      for (var p in list) {
        if (p is Map &&
            (p['status'] ?? '').toString().toLowerCase() == 'pending') {
          return Map<String, dynamic>.from(p);
        }
      }

      // Step 4: Fallback to the very first item in the list
      final firstItem = list.first;
      if (firstItem is Map) {
        return Map<String, dynamic>.from(firstItem);
      }

      return null;
    } catch (e) {
      // If it crashes, return null so the screen doesn't break
      return null;
    }
  }

  // --- Status & Navigation Logic ---
  bool _canSubmit(DateTime? deadline) {
    if (deadline != null && DateTime.now().isAfter(deadline)) return false;
    return true;
  }

  String _getSubmissionStatusText(DateTime? deadline) {
    if (deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(deadline)) {
        return '🚨 Deadline Passed';
      }
      final diff = deadline.difference(now);
      if (diff.inDays > 0) {
        return 'Closes in ${diff.inDays}d ${diff.inHours.remainder(24)}h ${diff.inMinutes.remainder(60)}m';
      } else {
        return 'Closes in ${diff.inHours}h ${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}m ${diff.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
      }
    }
    return 'Upload your team project proposal';
  }

  Color _getSubmissionStatusColor(DateTime? deadline) {
    if (deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(deadline)) return Colors.redAccent;
      final diff = deadline.difference(now);
      if (diff.inHours < 24) return Colors.redAccent;
      return Colors.amberAccent;
    }
    return Colors.white70;
  }

  void _navigateToSubmitProposal() {
    final dp = Provider.of<DataProvider>(context, listen: false);
    if (!_canSubmit(dp.deadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Submission deadline has passed.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const SubmitProposalScreen())).then((_) {
      dp.fetchMyProposalsIfNeeded(forceRefresh: true);
    });
  }

  void _navigateToTeamInfo() => Navigator.push(
      context, MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  void _navigateToRequestTeam() => Navigator.push(context,
      MaterialPageRoute(builder: (context) => const RequestTeamScreen()));
  void _downloadTemplate() => Navigator.push(
      context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dp = Provider.of<DataProvider>(context);

    final user = authProvider.user;
    final String displayName = (user?.name ?? 'Student')
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .join(' ');

    final proposal = _getNewestProposal(dp);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('LeadUnity'),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            dp.fetchDeadlineIfNeeded(forceRefresh: true),
            dp.fetchMyProposalsIfNeeded(forceRefresh: true),
            dp.fetchSupervisorsIfNeeded(forceRefresh: true),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello,', style: theme.textTheme.titleLarge),
                        Text(displayName,
                            style: theme.textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  _buildTeamStatusBadge(proposal, dp),
                ],
              ),
              const SizedBox(height: 20),
              _buildStatusBanner(proposal, dp),
              const SizedBox(height: 30),
              _buildActionCards(dp.deadline),
            ],
          ),
        ),
      ),
      floatingActionButton: const BreathingChatbotFab(),
    );
  }

  Widget _buildTeamStatusBadge(
      Map<String, dynamic>? proposal, DataProvider dp) {
    final isLoadingTeam = dp.isLoadingMyProposals && dp.myProposals == null;
    if (isLoadingTeam) return const SizedBox.shrink();

    final bool hasTeam = proposal != null;
    final String status = (proposal?['status'] ?? '').toString().toLowerCase();

    final bool isApproved = status == 'approved';
    final bool isPending = status == 'pending';
    final bool isRejected = status == 'rejected';

    final Color emeraldGreen = const Color(0xFF10B981);
    final Color pendingGold = Colors.orange.shade700;
    final Color rejectedRed = Colors.red.shade600;

    final Color statusColor = isApproved
        ? emeraldGreen
        : (isPending
            ? pendingGold
            : (isRejected
                ? rejectedRed
                : Theme.of(context).colorScheme.primary));

    String label = "No Team";
    IconData icon = Icons.warning_amber_rounded;

    if (hasTeam) {
      if (isApproved) {
        label = "Registered";
        icon = Icons.verified_user_rounded;
      } else if (isPending) {
        label = "Pending";
        icon = Icons.lock_clock_rounded;
      } else if (isRejected) {
        label = "Rejected";
        icon = Icons.cancel_rounded;
      } else {
        label = "Formed";
        icon = Icons.group_add_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic>? proposal, DataProvider dp) {
    final theme = Theme.of(context);

    final isLoadingTeam = dp.isLoadingMyProposals && dp.myProposals == null;
    if (isLoadingTeam) return const LinearProgressIndicator();

    if (proposal == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceVariant.withOpacity(0.2)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(
                  10), // Slightly reduced padding to fit the image perfectly
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/logo/logo.png',
                width:
                    32, // Sized up slightly to match the visual weight of the old icon
                height: 32,
                fit: BoxFit.contain,
                // Optional: If your logo is a solid shape and you want it to match your app's primary color, uncomment the line below:
                // color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No Active Proposal",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Submit a project proposal below to view your assigned supervisor and schedule.",
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String status = (proposal['status'] ?? '').toString().toLowerCase();
    final bool isApproved = status == 'approved';
    final bool isPending = status == 'pending';
    final bool isRejected = status == 'rejected';

    final Color emeraldGreen = const Color(0xFF10B981);
    final Color pendingGold = Colors.orange.shade700;
    final Color rejectedRed = Colors.red.shade600;

    final Color statusColor = isApproved
        ? emeraldGreen
        : (isPending
            ? pendingGold
            : (isRejected ? rejectedRed : theme.colorScheme.primary));

    final Color bgColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
        : Colors.white;

    // 🟢 UPGRADED FALLBACKS: Aggressively hunts for Course Code
    String? courseCode;
    if (proposal['course'] is Map) {
      courseCode = proposal['course']['courseCode'];
    } else {
      final searchId =
          proposal['course']?.toString() ?? proposal['courseId']?.toString();
      if (searchId != null && dp.allCourses != null) {
        final found = dp.allCourses!.firstWhere(
            (c) =>
                c['_id']?.toString() == searchId ||
                c['courseCode']?.toString() == searchId,
            orElse: () => null);
        if (found != null) courseCode = found['courseCode'];
      }
    }

    // 🟢 UPGRADED FALLBACKS: Aggressively hunts for Supervisor
    final dynamic supervisor =
        proposal['assignedSupervisor'] ?? proposal['supervisorId'];
    String supName = 'TBA';
    if (supervisor is Map) {
      supName = supervisor['abbreviation'] ?? supervisor['name'] ?? 'Assigned';
    } else if (supervisor != null && dp.allSupervisors != null) {
      final foundSup = dp.allSupervisors!.firstWhere(
          (s) => s['_id']?.toString() == supervisor.toString(),
          orElse: () => null);
      if (foundSup != null)
        supName = (foundSup['name'] ?? foundSup['abbreviation'] ?? 'Assigned')
            .toString();
    }

    String formattedDate = "TBA";
    if (proposal['defenseDate'] != null) {
      final localDate = DateTime.parse(proposal['defenseDate']).toLocal();
      formattedDate = DateFormat('dd MMM, hh:mm a').format(localDate);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildInfoChip(
                  context: context,
                  icon: Icons.book_rounded,
                  label: "Course",
                  value: courseCode ?? "N/A",
                  color: const Color(0xFF2563EB),
                ),
              ),
              if (isApproved || proposal['defenseDate'] != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildInfoChip(
                    context: context,
                    icon: Icons.event_available_rounded,
                    label: "Defense",
                    value: formattedDate,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoChip(
            context: context,
            icon: Icons.person_pin_rounded,
            label: "Supervisor",
            value: supName,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      {required BuildContext context,
      required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(DateTime? deadline) {
    final canSubmit = _canSubmit(deadline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnimatedStudentCard(
          icon:
              canSubmit ? Icons.upload_file_rounded : Icons.lock_clock_rounded,
          title: canSubmit ? 'Submit Proposal' : 'Submissions Closed',
          action: _getSubmissionStatusText(deadline),
          actionColor: _getSubmissionStatusColor(deadline),
          iconColor: Colors.white,
          onTap: canSubmit ? _navigateToSubmitProposal : () {},
          isProminent: true,
          isDisabled: !canSubmit,
          bgColor: canSubmit ? const Color(0xFF1E3A8A) : Colors.grey[800]!,
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _AnimatedStudentCard(
                  icon: Icons.groups_2_rounded,
                  title: 'Team Info',
                  action: 'View Team & Status',
                  iconColor: Colors.white,
                  onTap: _navigateToTeamInfo,
                  isCompact: true,
                  bgColor: const Color.fromARGB(255, 86, 75, 105),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AnimatedStudentCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Request Team',
                  action: 'Join a group',
                  iconColor: Colors.white,
                  onTap: _navigateToRequestTeam,
                  isCompact: true,
                  bgColor: const Color(0xFF0E7490),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AnimatedStudentCard(
          icon: Icons.download_for_offline_rounded,
          title: 'Get Template',
          action: 'Preview and Download',
          iconColor: Colors.white,
          onTap: _downloadTemplate,
          bgColor: const Color(0xFF4338CA),
        ),
      ],
    );
  }
}

class _AnimatedStudentCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String action;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;
  final Color? actionColor;
  final bool isProminent;
  final bool isCompact;
  final bool isDisabled;

  const _AnimatedStudentCard({
    required this.icon,
    required this.title,
    required this.action,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
    this.actionColor,
    this.isProminent = false,
    this.isCompact = false,
    this.isDisabled = false,
  });

  @override
  State<_AnimatedStudentCard> createState() => _AnimatedStudentCardState();
}

class _AnimatedStudentCardState extends State<_AnimatedStudentCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: widget.isDisabled ? 0.6 : 1.0,
      child: GestureDetector(
        onTapDown:
            widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onTap();
              },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isDisabled || _isPressed
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            padding: EdgeInsets.all(widget.isProminent ? 24.0 : 20.0),
            child: widget.isCompact
                ? _buildCompactContent()
                : _buildStandardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedIcon(),
        const SizedBox(height: 16),
        Text(widget.title,
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(widget.action,
            style: TextStyle(
                fontSize: 12, color: widget.actionColor ?? Colors.white70)),
      ],
    );
  }

  Widget _buildStandardContent() {
    return Row(
      children: <Widget>[
        _buildAnimatedIcon(),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: TextStyle(
                      fontSize: widget.isProminent ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                widget.action,
                style: TextStyle(
                  fontSize: widget.isProminent ? 15 : 14,
                  color: widget.actionColor ?? Colors.white70,
                  fontWeight: widget.isProminent || widget.actionColor != null
                      ? FontWeight.w800
                      : FontWeight.normal,
                ),
              )
            ],
          ),
        ),
        if (!widget.isDisabled)
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.white70),
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedScale(
      scale: _isPressed ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      child: Container(
        padding: EdgeInsets.all(widget.isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: widget.iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.iconColor.withOpacity(0.3)),
        ),
        child: Icon(widget.icon,
            size: widget.isCompact ? 28 : 30, color: widget.iconColor),
      ),
    );
  }
}
