import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../widgets/custom_snackbar.dart';

class DataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ── TEAMS CACHE ────────────────────────────────────────────────────────────
  List<dynamic>? _allTeams;
  List<dynamic>? get allTeams => _allTeams;

  bool _isLoadingTeams = false;
  bool get isLoadingTeams => _isLoadingTeams;

  Future<void> fetchTeamsIfNeeded({bool forceRefresh = false}) async {
    // 1. Instant cache load
    if (!forceRefresh && _allTeams == null) {
      _isLoadingTeams = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final cachedTeams = prefs.getString('cached_teams');

      if (cachedTeams != null) {
        List<dynamic> localData = json.decode(cachedTeams);
        localData.sort((a, b) {
          final serialA = a['serialNumber'] ?? 999;
          final serialB = b['serialNumber'] ?? 999;
          return serialA.compareTo(serialB);
        });
        _allTeams = localData;
        _isLoadingTeams = false;
        notifyListeners();
      }
    }

    // 2. Background / pull-to-refresh fetch
    if (forceRefresh) {
      _isLoadingTeams = true;
      notifyListeners();
    }

    try {
      final freshTeams = await _apiService.getAllProposals();
      freshTeams.sort((a, b) {
        if (a['defenseDate'] == null && b['defenseDate'] == null) return 0;
        if (a['defenseDate'] == null) return 1;
        if (b['defenseDate'] == null) return -1;
        return DateTime.parse(a['defenseDate'])
            .compareTo(DateTime.parse(b['defenseDate']));
      });

      final prefs = await SharedPreferences.getInstance();
      final freshDataString = json.encode(freshTeams);
      final cachedTeams = prefs.getString('cached_teams');

      if (freshDataString != cachedTeams) {
        _allTeams = freshTeams;
        await prefs.setString('cached_teams', freshDataString);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching teams: $e");
      if (_allTeams == null) _allTeams = [];
    } finally {
      _isLoadingTeams = false;
      notifyListeners();
    }
  }

  // ── SUPERVISORS CACHE ──────────────────────────────────────────────────────
  List<dynamic>? _allSupervisors;
  List<dynamic>? get allSupervisors => _allSupervisors;

  bool _isLoadingSupervisors = false;
  bool get isLoadingSupervisors => _isLoadingSupervisors;

  Future<void> fetchSupervisorsIfNeeded({BuildContext? context, bool forceRefresh = false}) async {
    if (!forceRefresh && _allSupervisors == null) {
      _isLoadingSupervisors = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_supervisors');

      if (cachedData != null) {
        _allSupervisors = json.decode(cachedData);
        _isLoadingSupervisors = false;
        notifyListeners();
      }
    }

    if (forceRefresh) {
      _isLoadingSupervisors = true;
      notifyListeners();
    }

    try {
      final freshData = await _apiService.getSupervisors();
      final prefs = await SharedPreferences.getInstance();
      final freshDataString = json.encode(freshData);
      final cachedData = prefs.getString('cached_supervisors');

      if (freshDataString != cachedData) {
        _allSupervisors = freshData;
        await prefs.setString('cached_supervisors', freshDataString);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching supervisors: $e");
      if (_allSupervisors == null) _allSupervisors = [];
      // 🟢 FIX: Check if context exists and is mounted before showing toast
      if (forceRefresh && context != null && context.mounted) {
        CustomSnackBar.showError(context, 'Failed to refresh supervisors.');
      }
    } finally {
      _isLoadingSupervisors = false;
      notifyListeners();
    }
  }

  // ── COURSES CACHE ──────────────────────────────────────────────────────────
  List<dynamic>? _allCourses;
  List<dynamic>? get allCourses => _allCourses;

  bool _isLoadingCourses = false;
  bool get isLoadingCourses => _isLoadingCourses;

  Future<void> fetchCoursesIfNeeded({BuildContext? context, bool forceRefresh = false}) async {
    if (!forceRefresh && _allCourses == null) {
      _isLoadingCourses = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_courses');
      if (cached != null) {
        _allCourses = json.decode(cached);
        _isLoadingCourses = false;
        notifyListeners();
      }
    }

    if (forceRefresh) {
      _isLoadingCourses = true;
      notifyListeners();
    }

    try {
      final fresh = await _apiService.getCourses();
      final prefs = await SharedPreferences.getInstance();
      final freshString = json.encode(fresh);
      if (freshString != prefs.getString('cached_courses')) {
        _allCourses = fresh;
        await prefs.setString('cached_courses', freshString);
        notifyListeners();
      }
    } catch (e) {
      if (_allCourses == null) _allCourses = [];
      if (forceRefresh && context != null && context.mounted) {
        CustomSnackBar.showError(context, 'Failed to refresh courses.');
      }
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  // ── MY PROPOSALS CACHE ─────────────────────────────────────────────────────
  List<dynamic>? _myProposals;
  List<dynamic>? get myProposals => _myProposals;

  bool _isLoadingMyProposals = false;
  bool get isLoadingMyProposals => _isLoadingMyProposals;

  Future<void> fetchMyProposalsIfNeeded({bool forceRefresh = false}) async {
    if (!forceRefresh && _myProposals == null) {
      _isLoadingMyProposals = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_my_proposals');
      if (cached != null) {
        _myProposals = json.decode(cached);
        _isLoadingMyProposals = false;
        notifyListeners();
      }
    }

    if (forceRefresh) {
      _isLoadingMyProposals = true;
      notifyListeners();
    }

    try {
      final fresh = await _apiService.getUserProposals();
      final prefs = await SharedPreferences.getInstance();
      final freshString = json.encode(fresh);
      if (freshString != prefs.getString('cached_my_proposals')) {
        _myProposals = fresh;
        await prefs.setString('cached_my_proposals', freshString);
        notifyListeners();
      }
    } catch (e) {
      if (_myProposals == null) _myProposals = [];
    } finally {
      _isLoadingMyProposals = false;
      notifyListeners();
    }
  }

  // ── DEADLINE CACHE ─────────────────────────────────────────────────────────
  DateTime? _deadline;
  DateTime? get deadline => _deadline;

  bool _isLoadingDeadline = false;
  bool get isLoadingDeadline => _isLoadingDeadline;

  Future<void> fetchDeadlineIfNeeded({BuildContext? context, bool forceRefresh = false}) async {
    // 1. Instant cache load
    if (!forceRefresh && _deadline == null) {
      _isLoadingDeadline = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final cachedDateString = prefs.getString('cached_deadline');

      if (cachedDateString != null && cachedDateString.isNotEmpty) {
        _deadline = DateTime.tryParse(cachedDateString);
        _isLoadingDeadline = false;
        notifyListeners();
      }
    }

    // 2. Background fetch
    if (forceRefresh) {
      _isLoadingDeadline = true;
      notifyListeners();
    }

    try {
      final freshDeadline = await _apiService.getSubmissionDeadline();
      final prefs = await SharedPreferences.getInstance();

      final freshString = freshDeadline?.toIso8601String() ?? '';
      final cachedString = prefs.getString('cached_deadline') ?? '';

      if (freshString != cachedString) {
        _deadline = freshDeadline;
        if (freshDeadline != null) {
          await prefs.setString('cached_deadline', freshString);
        } else {
          await prefs.remove('cached_deadline');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching deadline: $e");
     // 🟢 FIX: Context check
      if (forceRefresh && context != null && context.mounted) {
        CustomSnackBar.showError(context, 'Failed to refresh submission deadline.');
      }
    } finally {
      _isLoadingDeadline = false;
      notifyListeners();
    }
  }

  // ── NOTIFICATIONS CACHE ────────────────────────────────────────────────────
  List<dynamic>? _notifications;
  List<dynamic>? get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoadingNotifications = false;
  bool get isLoadingNotifications => _isLoadingNotifications;

// ── NOTIFICATIONS CACHE ────────────────────────────────────────────────────
  // ... (keep your variables _notifications, _unreadCount, etc. exactly the same)

  // 🟢 FIX: Added BuildContext? context to the signature
  Future<void> fetchNotificationsIfNeeded({BuildContext? context, bool forceRefresh = false}) async {
    // 1. Instant cache load from SharedPreferences
    if (!forceRefresh && _notifications == null) {
      _isLoadingNotifications = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_notifications');

      if (cached != null) {
        _notifications = json.decode(cached);
        _unreadCount = _notifications!
            .where((n) => n['isRead'] == false)
            .length;
        _isLoadingNotifications = false;
        notifyListeners();
      }
    }

    // 2. Background / force refresh fetch
    if (forceRefresh) {
      _isLoadingNotifications = true;
      notifyListeners();
    }

    try {
      final fresh = await _apiService.getNotifications();
      
      // 🟢 NEW LOGIC: Check if any of these fetched notifications are brand new
      if (forceRefresh && _notifications != null && context != null && context.mounted) {
        // Create a quick list of all the IDs we already knew about
        final oldIds = _notifications!.map((n) => n['_id'].toString()).toSet();

        // Check if the fresh data has anything that isn't in our old list
        final newArrivals = fresh.where((n) => !oldIds.contains(n['_id'].toString())).toList();

        // If we found new ones, drop the purple pill for the most recent one!
        if (newArrivals.isNotEmpty) {
          final latestNew = newArrivals.first;
          CustomSnackBar.showPushNotification(
            context, 
            latestNew['title']?.toString() ?? "New Notification",
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final freshString = json.encode(fresh);

      // Always update — notifications change frequently (isRead state etc.)
      _notifications = fresh;
      _unreadCount = fresh.where((n) => n['isRead'] == false).length;
      await prefs.setString('cached_notifications', freshString);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (_notifications == null) _notifications = [];
      
      // Optional: Show error if the refresh fails
      if (forceRefresh && context != null && context.mounted) {
        CustomSnackBar.showError(context, 'Failed to refresh notifications.');
      }
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  /// Mark one notification as read — optimistic local update then syncs server.
  Future<void> markNotificationRead(String notifId) async {
    if (_notifications != null) {
      for (final n in _notifications!) {
        if (n['_id']?.toString() == notifId) {
          n['isRead'] = true;
          break;
        }
      }
      _unreadCount = _notifications!
          .where((n) => n['isRead'] == false)
          .length;

      // Persist updated state to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_notifications', json.encode(_notifications));

      notifyListeners();
    }
    await _apiService.markNotificationRead(notifId);
  }

  /// Mark all notifications as read.
  Future<void> markAllNotificationsRead() async {
    if (_notifications != null) {
      for (final n in _notifications!) {
        n['isRead'] = true;
      }
      _unreadCount = 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_notifications', json.encode(_notifications));

      notifyListeners();
    }
    await _apiService.markAllNotificationsRead();
  }

  // data_provider.dart - Add team info cache
Map<String, dynamic>? _myTeam;
Map<String, dynamic>? get myTeam => _myTeam;

bool _isLoadingMyTeam = false;
bool get isLoadingMyTeam => _isLoadingMyTeam;

Future<void> fetchMyTeamIfNeeded({bool forceRefresh = false}) async {
  if (!forceRefresh && _myTeam == null) {
    _isLoadingMyTeam = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_my_team');
    if (cached != null) {
      _myTeam = json.decode(cached) as Map<String, dynamic>?;
      _isLoadingMyTeam = false;
      notifyListeners();
    }
  }

  if (forceRefresh) {
    _isLoadingMyTeam = true;
    notifyListeners();
  }

  try {
    final fresh = await _apiService.getMyTeam();
    final prefs = await SharedPreferences.getInstance();
    final freshString = fresh != null ? json.encode(fresh) : '';
    final cached = prefs.getString('cached_my_team') ?? '';

    if (freshString != cached) {
      _myTeam = fresh;
      if (fresh != null) {
        await prefs.setString('cached_my_team', freshString);
      } else {
        await prefs.remove('cached_my_team');
      }
      notifyListeners();
    }
  } catch (e) {
    debugPrint("Error fetching my team: $e");
    if (_myTeam == null) _myTeam = null;
  } finally {
    _isLoadingMyTeam = false;
    notifyListeners();
  }
}
}