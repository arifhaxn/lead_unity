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

  // --- Login with Name Correction & ID Support ---
  // 🟢 Updated to accept generic identifier and optional role
  Future<void> login(String identifier, String password, {String? role}) async {
    _setLoading(true);
    try {
      // 🟢 Pass identifier to API
      final data = await _apiService.login(identifier, password);

      _token = data['token'];
      // 🟢 Save token immediately so API calls work
      await _storage.write(key: 'jwt_token', value: _token);

      if (data['user'] != null) {
        // Plan A: Server sent everything correctly
        _user = User.fromJson(data['user']);
      } else {
        // Plan B: Server sent null or flat structure. Use "Rescue Mode".
        print("⚠️ Missing user object structure. attempting manual construction...");
        
        // Sometimes backend returns flat fields like {name: '...', email: '...'} at root level
        if (data['name'] != null) {
           _user = User(
             id: data['_id'] ?? '',
             name: data['name'],
             email: data['email'] ?? '',
             role: data['role'] ?? 'student', // Fallback role
           );
        } else {
          // Plan C: Decode Token
          try {
            final payload = _parseJwt(_token!);

            String userId = (payload['_id'] ?? payload['sub'] ?? '').toString();
            String? userRole = payload['role']?.toString().toLowerCase();
            // Default to identifier if name missing
            String realName = payload['name']?.toString() ?? identifier;

            // 🟢 Fetch real profile to fix role/name when missing
            try {
              // We assume getUserByEmail can basically find "me" regardless of input
              // Or you might need to implement a dedicated /auth/me endpoint
              final me = await _apiService.getUserByEmail(identifier); 
              if (me['_id'] != null && userId.isEmpty) {
                userId = me['_id'].toString();
              }
              if (me['name'] != null) {
                realName = me['name'].toString();
              }
              if (me['role'] != null) {
                userRole = me['role'].toString().toLowerCase();
              }
            } catch (e) {
              print("Could not fetch real profile: $e");
            }

            // Create the user with the corrected name
            _user = User(
              id: userId,
              name: realName,
              email: identifier.contains('@') ? identifier : '', // Only set email if it looks like one
              role: userRole ?? 'unknown',
            );
          } catch (e) {
            // Last resort fallback
            _user = User(id: 'temp', name: 'User', email: identifier, role: 'unknown');
          }
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

  // Update signature to accept 'otp'
  Future<void> register(String name, String email, String password, String sid,
      String batch, String section, String otp) async { // <--- Added otp
    _setLoading(true);
    try {
      final registrationData = {
        'name': name,
        'email': email,
        'password': password,
        'studentId': sid,
        'batch': batch,
        'section': section,
        'otp': otp, // <--- Send OTP to backend
      };

      await _apiService.registerStudent(registrationData);
      
      // ... rest of logic (token saving, user saving)
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
  
  // Add this wrapper for the UI to call easily
  Future<void> sendOtp(String email) async {
    await _apiService.sendOtp(email);
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