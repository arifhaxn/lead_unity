import 'dart:async'; // 🟢 1. Added this to get access to the Timer!
import 'package:flutter/material.dart';
import 'package:link_unity/student/submit_proposal.dart';
import 'package:link_unity/student/request_team_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 

import '../../api services/api_services.dart';
import '../auth_provider.dart';
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
  Timer? _timer; // 🟢 2. Created the Timer variable

  @override
  void initState() {
    super.initState();
    _checkDeadline();
  }

  // 🟢 3. The Cleanup Crew! We MUST destroy the timer when the user leaves the screen, 
  // otherwise it will keep ticking forever in the background and crash the app.
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
      
      // 🟢 4. Start the ticking clock only AFTER we get the deadline from the kitchen!
      if (_deadline != null) {
        _startTickingClock();
      }
    }
  }

  // 🟢 5. The Heartbeat Function
  void _startTickingClock() {
    // This tells the app: "Every 1 second, run setState to redraw the screen!"
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Redraws the UI with the new second
      }
    });
  }

  bool get _canSubmit {
    if (_deadline != null && DateTime.now().isAfter(_deadline!)) return false; 
    return true;
  }

  // --- Helper: Get Status Text ---
  String _getSubmissionStatusText() {
    if (_deadline != null) {
      final now = DateTime.now();
      
      if (now.isAfter(_deadline!)) {
        _timer?.cancel(); // 🟢 Stop the clock if the deadline passed!
        return 'Deadline Passed';
      }
      
      final diff = _deadline!.difference(now);
      
      // 🟢 6. Format the live countdown!
      if (diff.inDays > 0) {
        // If it's more than a day away, show Days, Hours, and Minutes
        final hours = diff.inHours.remainder(24);
        final minutes = diff.inMinutes.remainder(60);
        return 'Closes in ${diff.inDays}d ${hours}h ${minutes}m';
      } else {
        // If it's less than 24 hours, show Hours, Minutes, and SECONDS ticking!
        final hours = diff.inHours;
        // .padLeft(2, '0') makes sure "5 seconds" looks like "05" instead of just "5"
        final minutesStr = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        final secondsStr = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
        
        return 'Closes in ${hours}h ${minutesStr}m ${secondsStr}s';
      }
    }
    
    return 'Upload your team project proposal';
  }

  // --- Helper: Get Status Color ---
  Color _getSubmissionStatusColor() {
    if (_deadline != null) {
      final now = DateTime.now();
      if (now.isAfter(_deadline!)) return Colors.redAccent; // Expired
      
      final diff = _deadline!.difference(now);
      if (diff.inHours < 24) return Colors.redAccent; // Urgent (<24h)
    }
    return Colors.white70; // Normal
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamInfoScreen()));
  }
  void _navigateToRequestTeam() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestTeamScreen()));
  }
  void _downloadTemplate() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTemplateScreen()));
  }
  void _openChatbot() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String fullName = user?.name ?? 'Student';
    final String displayName = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).join(' ');
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
                //Submit Proposal
                _buildSlickCard(
                  context: context,
                  icon: canSubmit ? Icons.upload_file_outlined : Icons.lock_clock_outlined,
                  title: canSubmit ? 'Submit Proposal' : 'Submissions Closed',
                  action: statusText, // 🟢 This string will now magically update every second!
                  actionColor: statusColor,
                  color: canSubmit ? AppColors.accentCoral : Colors.grey,
                  onTap: canSubmit ? _navigateToSubmitProposal : () {}, 
                  isProminent: true,
                  isDisabled: !canSubmit, 
                  darkBgColor: canSubmit ? const Color(0xFF1E3A8A) : Colors.grey[800],
                  lightBgColor: canSubmit ? const Color(0xFFD6E4FF) : Colors.grey[300],
                ),

                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSlickCard(
                          context: context,
                          icon: Icons.groups_2_outlined,
                          title: 'Team Info',
                          action: 'Submitted Info',
                          color: AppColors.accentGreen,
                          onTap: _navigateToTeamInfo,
                          isCompact: true,
                          darkBgColor: const Color(0xFF6B7280),
                          lightBgColor: const Color(0xFFE5E7EB),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSlickCard(
                          context: context,
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'Request Team',
                          action: 'If not in a group',
                          color: AppColors.accentPink,
                          onTap: _navigateToRequestTeam,
                          isCompact: true,
                          darkBgColor: const Color(0xFF0E7490),
                          lightBgColor: const Color(0xFFCFFAFE),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildSlickCard(
                  context: context,
                  icon: Icons.download_for_offline_outlined,
                  title: 'Get Template',
                  action: 'Preview and Download',
                  color: AppColors.accentLime,
                  onTap: _downloadTemplate,
                  darkBgColor: const Color(0xFF4338CA),
                  lightBgColor: const Color(0xFFDDD6FE),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatbot,
        backgroundColor: accent,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBanner(bool hasTeam, String? teamId) {
    final theme = Theme.of(context);
    final Color bannerColor = hasTeam ? theme.colorScheme.primary.withOpacity(0.08) : theme.colorScheme.surfaceVariant;
    final Color textColor = hasTeam ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bannerColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: textColor.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(hasTeam ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: textColor),
          const SizedBox(width: 12),
          Expanded(child: Text(hasTeam ? 'You are part of Team $teamId.' : 'You are not yet on a team.', style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildSlickCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String action,
    required Color color,
    required VoidCallback onTap,
    bool isProminent = false,
    bool isCompact = false,
    bool isDisabled = false,
    Color? darkBgColor,
    Color? lightBgColor,
    Color? actionColor,
  }) {
    final double opacity = isDisabled ? 0.6 : 1.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Opacity(
        opacity: opacity,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: AppRadii.card,
          child: Container(
            decoration: BoxDecoration(color: darkBgColor ?? const Color(0xFF10B981), borderRadius: AppRadii.card, boxShadow: isDisabled ? [] : AppShadows.level1),
            padding: EdgeInsets.all(isProminent ? 24.0 : 20.0),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 28, color: Colors.white)),
                      const SizedBox(height: 16),
                      Text(title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(action, style: TextStyle(fontSize: 12, color: actionColor ?? Colors.white70)),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 30, color: Colors.white)),
                      const SizedBox(width: 20),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: TextStyle(fontSize: isProminent ? 20 : 18, fontWeight: FontWeight.bold, color: Colors.white)), 
                        const SizedBox(height: 4), 
                        Text(action, style: TextStyle(fontSize: 14, color: actionColor ?? Colors.white70, fontWeight: actionColor != null ? FontWeight.bold : FontWeight.normal))
                      ])),
                      if (!isDisabled) const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}