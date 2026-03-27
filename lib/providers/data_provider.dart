import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api services/api_services.dart';

class DataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- TEAMS CACHE ---
  List<dynamic>? _allTeams;
  List<dynamic>? get allTeams => _allTeams;

  bool _isLoadingTeams = false;
  bool get isLoadingTeams => _isLoadingTeams;

  Future<void> fetchTeamsIfNeeded({bool forceRefresh = false}) async {
    // 1. 🟢 INSTANT CACHE LOAD
    if (!forceRefresh && _allTeams == null) {
      _isLoadingTeams = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final cachedTeams = prefs.getString('cached_teams');

      if (cachedTeams != null) {
        List<dynamic> localData = json.decode(cachedTeams);

        // Apply defense sorting to cached data
        localData.sort((a, b) {
          final serialA = a['serialNumber'] ?? 999; // Put nulls at the end
          final serialB = b['serialNumber'] ?? 999;
          return serialA.compareTo(serialB);
        });

        _allTeams = localData;
        _isLoadingTeams = false;
        notifyListeners();
      }
    }

    // 2. 🟢 THE BACKGROUND/PULL-TO-REFRESH FETCH
    if (forceRefresh) {
      _isLoadingTeams = true;
      notifyListeners();
    }

    try {
      final freshTeams = await _apiService.getAllProposals();

      // Apply defense sorting to fresh data
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

      // 3. 🟢 SILENT UI UPDATE
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

  // --- SUPERVISORS CACHE ---
  List<dynamic>? _allSupervisors;
  List<dynamic>? get allSupervisors => _allSupervisors;

  bool _isLoadingSupervisors = false;
  bool get isLoadingSupervisors => _isLoadingSupervisors;

  Future<void> fetchSupervisorsIfNeeded({bool forceRefresh = false}) async {
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
    } finally {
      _isLoadingSupervisors = false;
      notifyListeners();
    }
  }

  // --- COURSES CACHE ---
  List<dynamic>? _allCourses;
  List<dynamic>? get allCourses => _allCourses;

  bool _isLoadingCourses = false;
  bool get isLoadingCourses => _isLoadingCourses;

  Future<void> fetchCoursesIfNeeded({bool forceRefresh = false}) async {
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
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  // --- MY PROPOSALS CACHE ---
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
}
