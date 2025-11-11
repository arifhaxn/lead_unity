// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:link_unity/api%20services/api_services.dart';

// Ensure these imports point to your files
import '../models/user_model.dart'; 

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage(); 

  // --- Getters to expose state ---
  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // --- Registration Logic (UPDATED to 6 arguments) ---
  Future<void> register(
      String name, 
      String email, 
      String password,
      String studentId, 
      String batch,     
      String section,   
  ) async {
    // Calling the API service's register method with all 6 fields
    final data = await _apiService.register(
      name, 
      email, 
      password, 
      studentId, 
      batch, 
      section
    ); 
    
    // Store data locally
    _token = data['token'];
    _user = User.fromJson(data);

    // Store data securely on the device
    await _storage.write(key: 'token', value: _token);
    await _storage.write(key: 'user', value: json.encode(data));

    // Notify listeners (the UI) that the state has changed
    notifyListeners();
  }

  // --- Login Logic ---
  Future<void> login(String email, String password) async {
    final data = await _apiService.login(email, password);
    
    _token = data['token'];
    _user = User.fromJson(data);

    await _storage.write(key: 'token', value: _token);
    await _storage.write(key: 'user', value: json.encode(data));

    notifyListeners();
  }

  // --- Auto Login/Token Persistence ---
  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    final userDataString = await _storage.read(key: 'user');

    if (token == null || userDataString == null) {
      return;
    }

    // Restore state from secure storage
    _token = token;
    _user = User.fromJson(json.decode(userDataString));
    
    notifyListeners();
  }

  // --- Logout Logic ---
  Future<void> logout() async {
    _token = null;
    _user = null;
    // Delete all stored authentication data
    await _storage.deleteAll(); 
    
    // Notify listeners to switch UI (e.g., back to login screen)
    notifyListeners();
  }
}