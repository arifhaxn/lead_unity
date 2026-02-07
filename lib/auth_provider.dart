import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api services/api_services.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  // --- Auto Login ---
  Future<bool> tryAutoLogin() async {
    final savedToken = await _storage.read(key: 'jwt_token');
    final userDataString = await _storage.read(key: 'user_data');

    if (savedToken == null || userDataString == null) return false;

    try {
      _token = savedToken;
      _user = User.fromJson(json.decode(userDataString));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Login with Name Correction ---
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _apiService.login(email, password);

      _token = data['token'];
      // 🟢 Save token immediately so API calls work
      await _storage.write(key: 'jwt_token', value: _token);

      if (data['user'] != null) {
        // Plan A: Server sent everything correctly
        _user = User.fromJson(data['user']);
      } else {
        // Plan B: Server sent null. Use "Rescue Mode".
        print("⚠️ Missing user data. Decoding token...");
        try {
          final payload = _parseJwt(_token!);

          final userId = payload['_id'] ?? payload['sub'] ?? '';
          final userRole = payload['role'] ?? 'supervisor';
          // Default to email name first (e.g. "lol")
          String realName = payload['name'] ?? email.split('@')[0];

          // 🟢 NAME CORRECTION STEP: Fetch real profile if possible
          try {
            if (userRole == 'supervisor') {
              // We use the existing API method to find ourselves in the list
              final sups = await _apiService.getSupervisors();
              final me = sups.firstWhere((s) => s['email'] == email,
                  orElse: () => null);
              if (me != null) {
                realName = me['name']; // Found the real name!
              }
            }
          } catch (e) {
            print("Could not fetch real name: $e");
          }

          // Create the user with the corrected name
          _user = User(
            id: userId,
            name: realName,
            email: email,
            role: userRole,
          );
        } catch (e) {
          // Last resort fallback
          _user = User(
              id: 'temp', name: 'Supervisor', email: email, role: 'supervisor');
        }
      }

      // Save the corrected user data
      if (_user != null) {
        final userMap = {
          '_id': _user!.id,
          'name': _user!.name,
          'email': _user!.email,
          'role': _user!.role
        };
        await _storage.write(key: 'user_data', value: json.encode(userMap));
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // --- Registration Logic ---
  Future<void> register(String name, String email, String password, String sid,
      String batch, String section) async {
    _setLoading(true);
    try {
      final registrationData = {
        'name': name,
        'email': email,
        'password': password,
        'studentId': sid,
        'batch': batch,
        'section': section,
      };

      final data = await _apiService.registerStudent(registrationData);

      _token = data['token'];
      await _storage.write(key: 'jwt_token', value: _token);

      if (data['user'] != null) {
        _user = User.fromJson(data['user']);
        await _storage.write(
            key: 'user_data', value: json.encode(data['user']));
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storage.delete(key: 'user_data');
    _user = null;
    _token = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Helper to Decode Token
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) throw Exception('Invalid payload');

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }
}
