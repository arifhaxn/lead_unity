// ============================================================
// NEW FILE: lib/student/notifications_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});


  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchNotificationsIfNeeded(forceRefresh: true);
    });
  }

  // ── Type metadata ─────────────────────────────────────────────────────────
  _NotifStyle _getStyle(String type) {
    switch (type) {
      case 'merge':
        return _NotifStyle(
          icon: Icons.merge_type_rounded,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
          darkBg: const Color(0xFF2D1F4E),
        );
      case 'defense':
        return _NotifStyle(
          icon: Icons.event_available_rounded,
          color: const Color(0xFFEA580C),
          bg: const Color(0xFFFFF7ED),
          darkBg: const Color(0xFF3D2008),
        );
      case 'status':
        return _NotifStyle(
          icon: Icons.verified_rounded,
          color: const Color(0xFF059669),
          bg: const Color(0xFFF0FDF4),
          darkBg: const Color(0xFF0D2818),
        );
      default:
        return _NotifStyle(
          icon: Icons.notifications_rounded,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFEFF6FF),
          darkBg: const Color(0xFF0F1E3D),
        );
    }
  }

  String _timeAgo(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dp = Provider.of<DataProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: theme.colorScheme.outline.withOpacity(0.15),
          ),
        ),
        actions: [
          if ((dp.notifications?.any((n) => n['isRead'] == false)) ?? false)
            TextButton(
              onPressed: () => dp.markAllNotificationsRead(),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Loading state
          if (dp.isLoadingNotifications && dp.notifications == null) {
            return _buildSkeleton(theme, isDark);
          }

          final notifs = dp.notifications ?? [];

          // Empty state
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_rounded,
                      size: 48,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'All clear!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No notifications yet.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // List
          return RefreshIndicator(
            onRefresh: () =>
                dp.fetchNotificationsIfNeeded(forceRefresh: true),
            color: theme.colorScheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifs[i] as Map;
                final isRead = n['isRead'] == true;
                final style = _getStyle(n['type']?.toString() ?? 'general');
                final bgColor = isDark ? style.darkBg : style.bg;

                return GestureDetector(
                  onTap: () {
                    if (!isRead) {
                      dp.markNotificationRead(n['_id'].toString());
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead
                          ? (isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade50)
                          : bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? theme.colorScheme.outline.withOpacity(0.15)
                            : style.color.withOpacity(0.3),
                        width: isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon bubble
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: style.color.withOpacity(isRead ? 0.1 : 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            style.icon,
                            size: 20,
                            color: style.color
                                .withOpacity(isRead ? 0.5 : 1.0),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n['title']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        color: isRead
                                            ? theme.colorScheme.onSurfaceVariant
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8, top: 3),
                                      decoration: BoxDecoration(
                                        color: style.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                n['message']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isRead
                                      ? theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.7)
                                      : theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _timeAgo(n['createdAt']?.toString()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme, bool isDark) {
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color darkBg;
  const _NotifStyle({
    required this.icon,
    required this.color,
    required this.bg,
    required this.darkBg,
  });
}