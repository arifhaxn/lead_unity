// ============================================================
// NEW FILE: lib/widgets/notification_bell.dart
// A reusable AppBar action widget with an unread badge.
// Drop it in any AppBar's actions: list.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final dp = Provider.of<DataProvider>(context);
    final count = dp.unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            count > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 6,
            child: IgnorePointer(
              child: AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: count > 9
                        ? BorderRadius.circular(8)
                        : null,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


// ============================================================
// INTEGRATION: Add NotificationBell to StudentDashboard AppBar
// ============================================================
//
// In student_dashboard.dart, update initState to also fetch notifications:
//
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     final dp = Provider.of<DataProvider>(context, listen: false);
//     dp.fetchDeadlineIfNeeded();
//     dp.fetchMyProposalsIfNeeded();
//     dp.fetchSupervisorsIfNeeded();
//     dp.fetchNotificationsIfNeeded();   // <-- ADD THIS
//   });
//
// Then update the AppBar in build():
//
//   appBar: AppBar(
//     title: const Text('LeadUnity'),
//     actions: const [
//       NotificationBell(),   // <-- ADD THIS
//     ],
//   ),
//
// Import at top of student_dashboard.dart:
//   import '../widgets/notification_bell.dart';
//
//
// ============================================================
// INTEGRATION: Add NotificationBell to TeamInfoScreen AppBar
// ============================================================
//
// In team_info.dart, update initState:
//
//   dp.fetchNotificationsIfNeeded();   // <-- ADD THIS
//
// Update the AppBar actions list (it already has a theme toggle):
//
//   actions: [
//     const NotificationBell(),   // <-- ADD THIS
//     IconButton( ... theme toggle ... ),
//   ],
//
// Import:
//   import '../widgets/notification_bell.dart';