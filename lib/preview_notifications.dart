// TEMPORARY preview entry point — not part of the app.
// Renders the real NotificationsScreen against fake cached data so the
// Clear-all button can be reviewed without logging in.
//
//   flutter run -d chrome -t lib/preview_notifications.dart
//
// Delete this file once the design is signed off.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/data_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/notifications_screen.dart';

String _ago(Duration d) =>
    DateTime.now().subtract(d).toUtc().toIso8601String();

final _fake = [
  {
    '_id': '1',
    'title': 'Proposal approved',
    'message': 'Your proposal "Smart Campus Navigation" was approved by EBH.',
    'type': 'status',
    'isRead': false,
    'createdAt': _ago(const Duration(minutes: 4)),
  },
  {
    '_id': '2',
    'title': 'Defense scheduled',
    'message': 'Your defense is on Oct 14 at 11:00 AM, Room 304.',
    'type': 'defense',
    'isRead': false,
    'createdAt': _ago(const Duration(hours: 3)),
  },
  {
    '_id': '3',
    'title': 'Team merged',
    'message': 'Omio Mahim joined your team.',
    'type': 'merge',
    'isRead': true,
    'createdAt': _ago(const Duration(days: 2)),
  },
  {
    '_id': '4',
    'title': 'Deadline reminder',
    'message': 'Proposal submission closes in 3 days.',
    'type': 'general',
    'isRead': true,
    'createdAt': _ago(const Duration(days: 5)),
  },
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed the cache, then let DataProvider load from it. The screen's own
  // forceRefresh will fail (no backend here) but the catch preserves whatever
  // the cache already populated.
  SharedPreferences.setMockInitialValues({
    'cached_notifications': json.encode(_fake),
  });

  final dp = DataProvider();
  await dp.fetchNotificationsIfNeeded();

  runApp(
    ChangeNotifierProvider<DataProvider>.value(
      value: dp,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const NotificationsScreen(),
      ),
    ),
  );
}
