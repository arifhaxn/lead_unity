import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:link_unity/student/request_team_screen.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Ensure intl is in your pubspec.yaml

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
  
  // Dynamic Team Data
  Map<String, dynamic>? _myProposal;
  bool _isLoadingTeam = true;

  @override
  void initState() {
    super.initState();
    _checkDeadline();
    _fetchStudentTeamStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Data Fetching ---
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

  Future<void> _fetchStudentTeamStatus() async {
    try {
      // Calls your backend (e.g., GET /proposals/my-proposal)
      final data = await _api.getMyProposal(); 
      if (mounted) {
        setState(() {
          _myProposal = data;
          _isLoadingTeam = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTeam = false);
    }
  }

  // --- Clock Logic ---
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

  String _getSubmissionStatusText() {
    if (_deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(_deadline!)) {
        _timer?.cancel();
        return '🚨 Deadline Passed';
      }
      final diff = _deadline!.difference(now);
      if (diff.inDays > 0) {
        return 'Closes in ${diff.inDays}d ${diff.inHours.remainder(24)}h ${diff.inMinutes.remainder(60)}m';
      } else {
        return 'Closes in ${diff.inHours}h ${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}m ${diff.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
      }
    }
    return 'Upload your team project proposal';
  }

  Color _getSubmissionStatusColor() {
    if (_deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(_deadline!)) return Colors.redAccent;
      final diff = _deadline!.difference(now);
      if (diff.inHours < 24) return Colors.redAccent;
      return Colors.amberAccent;
    }
    return Colors.white70;
  }

  // --- Navigation ---
  void _navigateToSubmitProposal() {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission deadline has passed.'), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SubmitProposalScreen())).then((_) => _fetchStudentTeamStatus());
  }

  void _navigateToTeamInfo() => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  void _navigateToRequestTeam() => Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestTeamScreen()));
  void _downloadTemplate() => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String displayName = (user?.name ?? 'Student').trim().split(RegExp(r'\s+')).take(2).join(' ');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          _checkDeadline();
          await _fetchStudentTeamStatus();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Hello,', style: theme.textTheme.titleLarge),
              Text(displayName, style: theme.textTheme.displaySmall),
              const SizedBox(height: 10),
              _buildStatusBanner(_myProposal),
              const SizedBox(height: 30),
              _buildActionCards(),
            ],
          ),
        ),
      ),
      floatingActionButton: const BreathingChatbotFab(),
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic>? proposal) {
    final theme = Theme.of(context);
    if (_isLoadingTeam) return const LinearProgressIndicator();

    final bool hasTeam = proposal != null;
    final String status = (proposal?['status'] ?? '').toString().toLowerCase();
    final String? courseCode = proposal?['course']?['courseCode'];
    final Map<String, dynamic>? supervisor = proposal?['assignedSupervisor'];
    final String? defenseDate = proposal?['defenseDate'];

    // Visual Styling - Replacing 'emerald' with Hex or Teal
    final isApproved = status == 'approved';
    
    // Using Color(0xFF10B981) for a true Emerald Green
    final Color approvedGreen = const Color(0xFF10B981); 
    
    final Color bannerColor = isApproved 
        ? approvedGreen.withOpacity(0.1) 
        : (hasTeam ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surfaceVariant);
    
    final Color textColor = isApproved 
        ? const Color(0xFF065F46) // Darker emerald for text
        : (hasTeam ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant);

    String message = 'You are not yet on a team.';
    if (hasTeam) {
      if (isApproved && supervisor != null) {
        final supName = supervisor['abbreviation'] ?? supervisor['name'] ?? 'Assigned';
        message = 'Approved for $courseCode.\nSupervisor: $supName';
        if (defenseDate != null) {
          final localDate = DateTime.parse(defenseDate).toLocal();
          final formattedDate = DateFormat('dd MMM, hh:mm a').format(localDate);
          message += '\nDefense: $formattedDate';
        }
      } else if (status == 'pending') {
        message = 'Proposal Pending for ${courseCode ?? "Course"}. Waiting for approval.';
      } else {
        message = 'Team Formed for ${courseCode ?? "Course"}. Status: ${status.toUpperCase()}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isApproved ? Icons.verified_user_rounded : (hasTeam ? Icons.check_circle_outline : Icons.warning_amber_outlined), 
            color: textColor
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message, 
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, height: 1.4)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    final canSubmit = _canSubmit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnimatedStudentCard(
          icon: canSubmit ? Icons.upload_file_rounded : Icons.lock_clock_rounded,
          title: canSubmit ? 'Submit Proposal' : 'Submissions Closed',
          action: _getSubmissionStatusText(),
          actionColor: _getSubmissionStatusColor(),
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
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) {
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
              boxShadow: widget.isDisabled || _isPressed ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            padding: EdgeInsets.all(widget.isProminent ? 24.0 : 20.0),
            child: widget.isCompact ? _buildCompactContent() : _buildStandardContent(),
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
        Text(widget.title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(widget.action, style: TextStyle(fontSize: 12, color: widget.actionColor ?? Colors.white70)),
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
              Text(widget.title, style: TextStyle(fontSize: widget.isProminent ? 20 : 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                widget.action,
                style: TextStyle(
                  fontSize: widget.isProminent ? 15 : 14,
                  color: widget.actionColor ?? Colors.white70,
                  fontWeight: widget.isProminent || widget.actionColor != null ? FontWeight.w800 : FontWeight.normal,
                ),
              )
            ],
          ),
        ),
        if (!widget.isDisabled) const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
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
        child: Icon(widget.icon, size: widget.isCompact ? 28 : 30, color: widget.iconColor),
      ),
    );
  }
}