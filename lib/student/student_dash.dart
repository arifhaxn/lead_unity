import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:link_unity/student/request_team_screen.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:provider/provider.dart';

import '../../api services/api_services.dart';
import '../providers/auth_provider.dart';
import 'view_template.dart';
import '../chatbot_screen.dart';
import 'team_info.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ApiService _api = ApiService();
  DateTime? _deadline;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkDeadline();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkDeadline() async {
    DateTime? deadlineDate = await _api.getSubmissionDeadline();

    if (mounted) {
      setState(() {
        _deadline = deadlineDate;
      });

      if (_deadline != null) {
        _startTickingClock();
      }
    }
  }

  void _startTickingClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool get _canSubmit {
    if (_deadline != null && DateTime.now().isAfter(_deadline!)) return false;
    return true;
  }

  // 🟢 Enhanced text with emojis for immediate visual recognition
  String _getSubmissionStatusText() {
    if (_deadline != null) {
      final now = DateTime.now();

      if (now.isAfter(_deadline!)) {
        _timer?.cancel();
        return '🚨 Deadline Passed';
      }

      final diff = _deadline!.difference(now);

      if (diff.inDays > 0) {
        final hours = diff.inHours.remainder(24);
        final minutes = diff.inMinutes.remainder(60);
        return 'Closes in ${diff.inDays}d ${hours}h ${minutes}m';
      } else {
        final hours = diff.inHours;
        final minutesStr =
            diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        final secondsStr =
            diff.inSeconds.remainder(60).toString().padLeft(2, '0');

        return 'Closes in ${hours}h ${minutesStr}m ${secondsStr}s';
      }
    }

    return 'Upload your team project proposal';
  }

  // 🟢 Bright, high-contrast colors for the clock
  Color _getSubmissionStatusColor() {
    if (_deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(_deadline!)) return Colors.redAccent;

      final diff = _deadline!.difference(now);
      if (diff.inHours < 24) return Colors.redAccent; // Urgent (Red)

      return Colors.amberAccent; // Normal Ticking (Bright Gold)
    }
    return Colors.white70;
  }

  void _navigateToSubmitProposal() {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Submission deadline has passed.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const SubmitProposalScreen()));
  }

  void _navigateToTeamInfo() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  }

  void _navigateToRequestTeam() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const RequestTeamScreen()));
  }

  void _downloadTemplate() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));
  }

  void _openChatbot() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String fullName = user?.name ?? 'Student';
    final String displayName = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .join(' ');
    final bool hasTeam = false;
    final String? currentTeamId = null;

    final canSubmit = _canSubmit;
    final statusText = _getSubmissionStatusText();
    final statusColor = _getSubmissionStatusColor();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Hello,', style: theme.textTheme.titleLarge),
            Text(displayName, style: theme.textTheme.displaySmall),
            const SizedBox(height: 10),
            _buildStatusBanner(hasTeam, currentTeamId),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Submit Proposal Card
                _AnimatedStudentCard(
                  icon: canSubmit
                      ? Icons.upload_file_rounded
                      : Icons.lock_clock_rounded,
                  title: canSubmit ? 'Submit Proposal' : 'Submissions Closed',
                  action: statusText,
                  actionColor: statusColor, // 🟢 Now passes the vibrant colors
                  iconColor: canSubmit
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.grey,
                  onTap: canSubmit ? _navigateToSubmitProposal : () {},
                  isProminent: true,
                  isDisabled: !canSubmit,
                  bgColor:
                      canSubmit ? const Color(0xFF1E3A8A) : Colors.grey[800]!,
                ),
                const SizedBox(height: 16),

                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _AnimatedStudentCard(
                          icon: Icons.groups_2_rounded,
                          title: 'Team Info',
                          action: 'Submitted Info',
                          iconColor: const Color.fromARGB(255, 255, 255, 255),
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
                          action: 'If not in a group',
                          iconColor: const Color.fromARGB(255, 255, 255, 255),
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
                  iconColor: const Color.fromARGB(255, 255, 255, 255),
                  onTap: _downloadTemplate,
                  bgColor: const Color(0xFF4338CA),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: const BreathingChatbotFab(),
    );
  }

  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final theme = Theme.of(context);
    final Color bannerColor = hasTeam
        ? theme.colorScheme.primary.withOpacity(0.08)
        : theme.colorScheme.surfaceVariant;
    final Color textColor = hasTeam
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(
              hasTeam
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: textColor),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  hasTeam
                      ? 'You are part of Team $teamId.'
                      : 'You are not yet on a team.',
                  style: TextStyle(
                      color: textColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// Custom Animated Card Widget for Student Dashboard
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
    final double opacity = widget.isDisabled ? 0.6 : 1.0;

    return Opacity(
      opacity: opacity,
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
              borderRadius: AppRadii.card,
              boxShadow:
                  widget.isDisabled || _isPressed ? [] : AppShadows.level1,
              border:
                  Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            padding: EdgeInsets.all(widget.isProminent ? 24.0 : 20.0),
            child: widget.isCompact
                ? Column(
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
                              fontSize: 12,
                              color: widget.actionColor ?? Colors.white70)),
                    ],
                  )
                : Row(
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
                            // 🟢 Increased font size, letter spacing, and weight for Prominent cards
                            Text(widget.action,
                                style: TextStyle(
                                  fontSize: widget.isProminent ? 15 : 14,
                                  color: widget.actionColor ?? Colors.white70,
                                  fontWeight: widget.isProminent ||
                                          widget.actionColor != null
                                      ? FontWeight.w800
                                      : FontWeight.normal,
                                  letterSpacing: widget.isProminent ? 0.3 : 0,
                                ))
                          ])),
                      if (!widget.isDisabled)
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.white70),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedScale(
      scale: _isPressed ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(widget.isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.iconColor.withOpacity(0.3)
              : widget.iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.iconColor.withOpacity(0.3)),
        ),
        child: Icon(widget.icon,
            size: widget.isCompact ? 28 : 30, color: widget.iconColor),
      ),
    );
  }
}
