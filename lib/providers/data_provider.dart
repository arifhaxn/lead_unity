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
    // 1. 🟢 INSTANT CACHE LOAD
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

    // 2. 🟢 THE BACKGROUND FETCH
    if (forceRefresh) {
      _isLoadingSupervisors = true;
      notifyListeners();
    }

    try {
      final freshData = await _apiService.getSupervisors();
      final prefs = await SharedPreferences.getInstance();
      final freshDataString = json.encode(freshData);
      final cachedData = prefs.getString('cached_supervisors');

      // 3. 🟢 SILENT UI UPDATE
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




//Color.fromARGB(255, 74, 65, 91), 
