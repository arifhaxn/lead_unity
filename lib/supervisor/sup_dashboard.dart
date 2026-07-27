import 'package:flutter/material.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/registration_status_badge.dart';
// 🟢 REMOVED: NotificationBell import is no longer needed here
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'team_list_screen.dart';
import 'sup_list_screen.dart';
import '../theme/app_theme.dart';
import '../features/app_drawer.dart';
import '../services/notification_service.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({Key? key}) : super(key: key);

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      final ap =
          Provider.of<AuthProvider>(context, listen: false); // ← add this

      // ✅ Register FCM token for supervisor — was completely missing
      NotificationService.setupPushNotifications(ap.token ?? "");

      dp.fetchDeadlineIfNeeded();
      dp.fetchTeamsIfNeeded();
      dp.fetchNotificationsIfNeeded(); // 🟢 Ensure notifications are fetched for the badge
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final dp = Provider.of<DataProvider>(context);
    final user = authProvider.user;
    final myId = user?.id;

    final String fullName = user?.name ?? 'Supervisor';
    final String displayName = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .join(' ');

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2),
        height: 1.0,
      ),
    );

    // 🟢 STATS CALCULATION
    int totalAssigned = 0;
    int completed = 0;

    final allTeamsList = dp.allTeams ?? [];

    if (myId != null && allTeamsList.isNotEmpty) {
      for (var t in allTeamsList) {
        final status = (t['status'] ?? '').toString().toLowerCase().trim();
        final List? members =
            t['teamMembers'] is List ? t['teamMembers'] : null;
        final int memberCount = members?.length ?? 0;

        if (status == 'approved' && memberCount >= 3 && memberCount <= 4) {
          final assigned = (t['assignedSupervisor'] is Map)
              ? t['assignedSupervisor']['_id']
              : t['assignedSupervisor'];

          if (assigned == myId) {
            totalAssigned++;

            final marks = t['marks'] as List? ?? [];
            bool hasMarked = false;

            for (final mark in marks) {
              if (mark is! Map) continue;
              final supId =
                  (mark['supervisorId'] ?? mark['supervisor'] ?? '').toString();
              final type = (mark['type'] ?? '').toString().toLowerCase().trim();

              if (supId == myId && type == 'own') {
                hasMarked = true;
                break;
              }
            }

            if (hasMarked) completed++;
          }
        }
      }
    }

    int pending = totalAssigned - completed;
    double progressPercent =
        totalAssigned == 0 ? 0.0 : (completed / totalAssigned);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('LeadUnity'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
        // 🟢 ADDED: Custom hamburger menu with notification badge
        leading: Builder(
          builder: (context) {
            // Check if there are any unread notifications in the DataProvider
            final bool hasUnread = dp.notifications?.any((n) => 
                n['isRead'] == false || n['read'] == false) ?? false;

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
                            color: theme.scaffoldBackgroundColor, 
                            width: 1.5
                          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24) +
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
                      Text('Welcome Back,',
                          style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text(
                        displayName,
                        style: theme.textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (!(dp.deadline == null && dp.isLoadingDeadline))
                  RegistrationStatusBadge(deadline: dp.deadline),
              ],
            ),
            const SizedBox(height: 30),
            dp.isLoadingTeams && allTeamsList.isEmpty
                ? _buildSkeletonProgressBanner(theme)
                : _buildProgressBanner(
                    theme, totalAssigned, completed, pending, progressPercent),
            const SizedBox(height: 24),
            _AnimatedDashboardCard(
              title: "My Teams",
              subtitle: "Personal Markings",
              icon: Icons.groups_rounded,
              bgColor: const Color(0xFF4338CA),
              iconColor: const Color.fromARGB(255, 24, 255, 143),
              height: 120,
              horizontalLayout: true,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TeamListScreen(onlyMyTeams: true))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AnimatedDashboardCard(
                    title: "All Teams",
                    subtitle: "Board Markings",
                    icon: Icons.format_list_bulleted_rounded,
                    bgColor: const Color.fromARGB(255, 74, 65, 91),
                    iconColor: const Color.fromARGB(255, 255, 156, 252),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TeamListScreen(onlyMyTeams: false))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedDashboardCard(
                    title: "Supervisors",
                    subtitle: "Colleagues",
                    icon: Icons.person_pin_circle_rounded,
                    bgColor: const Color(0xFF0E7490),
                    iconColor: Colors.cyanAccent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SupervisorListScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: const BreathingChatbotFab(),
    );
  }

  // 🟢 Ultra-Slim Progress Banner Widget
  Widget _buildProgressBanner(
      ThemeData theme, int total, int completed, int pending, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Assigned Progress",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15, 
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16, 
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6, 
                backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1.0 && total > 0
                      ? Colors.green
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildStatColumn(
                  "Total", total.toString(), Colors.blueAccent, theme),
              _buildVerticalDivider(),
              _buildStatColumn(
                  "Checked", completed.toString(), Colors.green, theme),
              _buildVerticalDivider(),
              _buildStatColumn(
                  "Pending", pending.toString(), Colors.orangeAccent, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonProgressBanner(ThemeData theme) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.15), width: 1.5),
      ),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 20, 
      width: 1,
      color: Colors.grey.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildStatColumn(
      String label, String value, Color color, ThemeData theme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 19, 
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2), 
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6, 
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, 
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Animated Card Widget
class _AnimatedDashboardCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color iconColor;
  final double height;
  final bool horizontalLayout;

  const _AnimatedDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
    this.height = 180,
    this.horizontalLayout = false,
  });

  @override
  State<_AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<_AnimatedDashboardCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: AppRadii.card,
            boxShadow: _isPressed ? [] : AppShadows.level1,
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: widget.horizontalLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAnimatedIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.subtitle,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withOpacity(0.5), size: 18),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedIcon(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.iconColor.withOpacity(0.3)
              : widget.iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.iconColor.withOpacity(0.3)),
        ),
        child: Icon(widget.icon, size: 28, color: widget.iconColor),
      ),
    );
  }
}