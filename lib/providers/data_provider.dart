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
  if (!forceRefresh && _allTeams != null) return;

  _isLoadingTeams = true;
  notifyListeners(); 

  try {
    List<dynamic> rawTeams = await _apiService.getAllProposals();

    // --- 🟢 ADD THE SORTING LOGIC HERE ---
    rawTeams.sort((a, b) {
      // 1. If defenseDate is missing, move to the bottom
      if (a['defenseDate'] == null && b['defenseDate'] == null) return 0;
      if (a['defenseDate'] == null) return 1;
      if (b['defenseDate'] == null) return -1;

      // 2. Parse strings to DateTime (Dart's parse handles ISO 8601)
      DateTime dateA = DateTime.parse(a['defenseDate']);
      DateTime dateB = DateTime.parse(b['defenseDate']);

      // 3. Chronological sort (Earliest first)
      return dateA.compareTo(dateB);
    });

    _allTeams = rawTeams; // Save the sorted list to your cache
    
  } catch (e) {
    debugPrint("Error fetching teams: $e");
    _allTeams = []; 
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