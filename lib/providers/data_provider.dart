import 'package:flutter/material.dart';
import '../api services/api_services.dart';

class DataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // --- TEAMS CACHE ---
  List<dynamic>? _allTeams;
  List<dynamic>? get allTeams => _allTeams;
  
  bool _isLoadingTeams = false;
  bool get isLoadingTeams => _isLoadingTeams;

  Future<void> fetchTeamsIfNeeded({bool forceRefresh = false}) async {
    // If we already have the data and aren't forcing a refresh, STOP!
    if (!forceRefresh && _allTeams != null) {
      return; 
    }

    _isLoadingTeams = true;
    // 🟢 THE FIX: ALWAYS notify listeners when loading starts, so the Shimmer triggers!
    notifyListeners(); 

    try {
      _allTeams = await _apiService.getAllProposals();
    } catch (e) {
      debugPrint("Error fetching teams: $e");
      _allTeams = []; // Prevent infinite loading loops on error
    } finally {
      _isLoadingTeams = false;
      notifyListeners(); // Tell the UI to update with the new data
    }
  }

  // --- SUPERVISORS CACHE ---
  List<dynamic>? _allSupervisors;
  List<dynamic>? get allSupervisors => _allSupervisors;

  bool _isLoadingSupervisors = false;
  bool get isLoadingSupervisors => _isLoadingSupervisors;

  Future<void> fetchSupervisorsIfNeeded({bool forceRefresh = false}) async {
    if (!forceRefresh && _allSupervisors != null) return;

    _isLoadingSupervisors = true;
    // 🟢 THE FIX: Same here for supervisors!
    notifyListeners();

    try {
      _allSupervisors = await _apiService.getSupervisors();
    } catch (e) {
      debugPrint("Error fetching supervisors: $e");
      _allSupervisors = [];
    } finally {
      _isLoadingSupervisors = false;
      notifyListeners();
    }
  }
}

//Color.fromARGB(255, 74, 65, 91), 