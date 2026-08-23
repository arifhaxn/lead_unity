import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lead_unity/services/notification_service.dart';
import 'package:lead_unity/student/submit_proposal.dart';
import 'package:lead_unity/student/request_team_screen.dart';
import 'package:lead_unity/widgets/breathing_chatbot_fab.dart';
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

    _startTickingClock();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      final ap = Provider.of<AuthProvider>(context, listen: false);

      NotificationService.setupPushNotifications(ap.token ?? "");

      dp.fetchDeadlineIfNeeded();
      dp.fetchMyTeamIfNeeded();
      dp.fetchMyProposalsIfNeeded();
      dp.fetchSupervisorsIfNeeded();
      dp.fetchNotificationsIfNeeded();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTickingClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  bool _canSubmit(DateTime? deadline) {
    if (deadline != null && DateTime.now().isAfter(deadline)) return false;
    return true;
  }

  String _getSubmissionStatusText(DateTime? deadline) {
    if (deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(deadline)) return '🚨 Deadline Passed';
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
      if (deadline.difference(now).inHours < 24) return Colors.redAccent;
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
      MaterialPageRoute(builder: (_) => const SubmitProposalScreen()),
    ).then((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchMyTeamIfNeeded(forceRefresh: true);
      dp.fetchMyProposalsIfNeeded(forceRefresh: true);
    });
  }

  void _navigateToTeamInfo() {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => const TeamInfoScreen()))
        .then((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchMyTeamIfNeeded(forceRefresh: true);
      dp.fetchMyProposalsIfNeeded(forceRefresh: true);
    });
  }

  void _navigateToRequestTeam() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const RequestTeamScreen())).then((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchMyTeamIfNeeded(forceRefresh: true);
      dp.fetchMyProposalsIfNeeded(forceRefresh: true);
    });
  }

  void _downloadTemplate() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ViewTemplateScreen()));

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

    Map<String, dynamic>? proposal = dp.myTeam;

    // 🟢 FIX: Force the dashboard to always look at the newest proposal 
    // instead of letting the backend default to the oldest one.
    if (dp.myProposals != null && dp.myProposals!.isNotEmpty) {
      final sortedProposals = List<dynamic>.from(dp.myProposals!);
      
      sortedProposals.sort((a, b) {
        // Fallback to Epoch 0 if date strings are missing, preventing crashes
        final dateA = DateTime.tryParse(a['updatedAt'] ?? a['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['updatedAt'] ?? b['createdAt'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        
        return dateB.compareTo(dateA); // Descending order (Newest first)
      });
      
      // Grab the most recent submission
      proposal = sortedProposals.first as Map<String, dynamic>?;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('LeadUnity'),
        leading: Builder(
          builder: (context) {
            final bool hasUnread = dp.notifications
                    ?.any((n) => n['isRead'] == false || n['read'] == false) ??
                false;

            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.menu_rounded),
                  if (hasUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.scaffoldBackgroundColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            authProvider.refreshUserProfile(),
            // 🟢 Passed context to the ones we updated!
            dp.fetchDeadlineIfNeeded(context: context, forceRefresh: true),
            dp.fetchMyTeamIfNeeded(forceRefresh: true),
            dp.fetchMyProposalsIfNeeded(forceRefresh: true),
            dp.fetchSupervisorsIfNeeded(context: context, forceRefresh: true),
            
            // 🟣 THIS is the one that triggers the purple push pill!
            dp.fetchNotificationsIfNeeded(context: context, forceRefresh: true), 
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0) +
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    if (dp.isLoadingMyTeam && dp.myTeam == null) return const SizedBox.shrink();

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
        : isPending
            ? pendingGold
            : isRejected
                ? rejectedRed
                : Theme.of(context).colorScheme.primary;

    String label = 'No Team';
    IconData icon = Icons.warning_amber_rounded;

    if (hasTeam) {
      if (isApproved) {
        label = 'Registered';
        icon = Icons.verified_user_rounded;
      } else if (isPending) {
        label = 'Pending';
        icon = Icons.lock_clock_rounded;
      } else if (isRejected) {
        label = 'Rejected';
        icon = Icons.cancel_rounded;
      } else {
        label = 'Formed';
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

    if (dp.isLoadingMyTeam && dp.myTeam == null) {
      return const LinearProgressIndicator();
    }

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
              color: theme.colorScheme.outline.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/logo/logo.png',
                  width: 32, height: 32, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Active Proposal',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text(
                    'Submit a project proposal below to view your assigned supervisor and schedule.',
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

    final Color emeraldGreen = const Color(0xFF10B981);
    final Color pendingGold = Colors.orange.shade700;
    final Color rejectedRed = Colors.red.shade600;

    final Color statusColor = status == 'approved'
        ? emeraldGreen
        : status == 'pending'
            ? pendingGold
            : status == 'rejected'
                ? rejectedRed
                : theme.colorScheme.primary;

    final Color bgColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
        : Colors.white;

    String? courseCode;
    if (proposal['course'] is Map) {
      courseCode = proposal['course']['courseCode'];
    } else {
      final searchId = proposal['course']?.toString();
      if (searchId != null && dp.allCourses != null) {
        final found = dp.allCourses!.firstWhere(
          (c) => c['_id']?.toString() == searchId,
          orElse: () => null,
        );
        courseCode = found?['courseCode'];
      }
    }

    final dynamic supervisor = proposal['assignedSupervisor'];
    String supName = 'TBA';
    if (supervisor is Map) {
      supName = supervisor['name'] ?? supervisor['abbreviation'] ?? 'TBA';
    } else if (supervisor != null && dp.allSupervisors != null) {
      final found = dp.allSupervisors!.firstWhere(
        (s) => s['_id']?.toString() == supervisor.toString(),
        orElse: () => null,
      );
      if (found != null) {
        supName = (found['name'] ?? found['abbreviation'] ?? 'TBA').toString();
      }
    }

    String formattedDate = 'TBA';
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
              offset: const Offset(0, 4))
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxW = constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 Row 1: Course & Schedule (50/50 split)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.book_rounded,
                      label: 'Course',
                      value: courseCode ?? 'N/A',
                      color: const Color(0xFF2563EB),
                      maxWidth: maxW,
                    ),
                  ),
                  if (isApproved || proposal['defenseDate'] != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.event_available_rounded,
                        label: 'Defense',
                        value: formattedDate,
                        color: const Color(0xFFEA580C),
                        maxWidth: maxW,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 🟢 Row 2: Supervisor & Room (50/50 split)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.person_pin_rounded,
                      label: 'Supervisor',
                      value: supName,
                      color: const Color(0xFF7C3AED),
                      maxWidth: maxW,
                      maxLines:
                          3, // 🟢 Allowed up to 3 lines just for supervisor
                    ),
                  ),
                  if (proposal['room'] != null &&
                      proposal['room'].toString().trim().isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.meeting_room_rounded,
                        label: 'Room',
                        value: proposal['room'].toString(),
                        color: const Color(0xFF059669),
                        maxWidth: maxW,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double maxWidth,
    int maxLines = 2, // 🟢 Added optional maxLines parameter (defaults to 2)
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  maxLines: maxLines, // 🟢 Applies the custom maxLines
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
                  action: 'View Current and Past Submissions',
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

  Widget _buildCompactContent() => Column(
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

  Widget _buildStandardContent() => Row(
        children: [
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
                ),
              ],
            ),
          ),
          if (!widget.isDisabled)
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.white70),
        ],
      );

  Widget _buildAnimatedIcon() => AnimatedScale(
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