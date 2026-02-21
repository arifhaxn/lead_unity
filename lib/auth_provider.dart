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
  Future<void> login(String identifier, String password, {String? role}) async {
    _setLoading(true);
    try {
      final data = await _apiService.login(identifier, password);

      _token = data['token'];
      await _storage.write(key: 'jwt_token', value: _token);

      if (data['user'] != null) {
        _user = User.fromJson(data['user']);
      } else {
        print("⚠️ Missing user object structure. attempting manual construction...");
        
        if (data['name'] != null) {
           _user = User(
             id: data['_id']?.toString() ?? '',
             name: data['name']?.toString() ?? 'User',
             email: data['email']?.toString() ?? '',
             role: data['role']?.toString() ?? 'student',
             studentId: data['studentId']?.toString(), // 🟢 Catch ID here too
           );
        } else {
          try {
            final payload = _parseJwt(_token!);

            String userId = (payload['_id'] ?? payload['sub'] ?? '').toString();
            String? userRole = payload['role']?.toString().toLowerCase();
            String realName = payload['name']?.toString() ?? identifier;
            String? extractedStudentId = payload['studentId']?.toString(); // 🟢 Extract ID

            try {
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
              if (me['studentId'] != null) {
                extractedStudentId = me['studentId'].toString(); // 🟢 Extract ID from API
              }
            } catch (e) {
              print("Could not fetch real profile: $e");
            }

            _user = User(
              id: userId,
              name: realName,
              email: identifier.contains('@') ? identifier : '', 
              role: userRole ?? 'unknown',
              studentId: extractedStudentId, // 🟢 Add to user
            );
          } catch (e) {
            _user = User(id: 'temp', name: 'User', email: identifier, role: 'unknown');
          }
        }
      }

      if (_user != null) {
        final userMap = {
          '_id': _user!.id,
          'name': _user!.name,
          'email': _user!.email,
          'role': _user!.role,
          'studentId': _user!.studentId, // 🟢 Make sure to save it!
        };
        await _storage.write(key: 'user_data', value: json.encode(userMap));
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // --- Registration Logic (Merged OTP + Frontend Override) ---
  Future<void> register(String name, String email, String password, String sid,
      String batch, String section, String otp) async {
    _setLoading(true);
    try {
      final registrationData = {
        'name': name,
        'email': email,
        'password': password,
        'studentId': sid,
        'batch': batch,
        'section': section,
        'otp': otp, 
      };

      // 1. Send data to backend
      final data = await _apiService.registerStudent(registrationData);

      // 2. Save the token immediately
      _token = data['token'];
      await _storage.write(key: 'jwt_token', value: _token);

      // 3. Extract IDs if the backend provided them
      String userId = '';
      String userRole = 'student';

      if (data['user'] != null) {
        userId = data['user']['_id']?.toString() ?? '';
        userRole = data['user']['role']?.toString() ?? 'student';
      } else if (_token != null) {
        try {
          final payload = _parseJwt(_token!);
          userId = (payload['_id'] ?? payload['sub'] ?? '').toString();
        } catch (e) {
          debugPrint("Could not parse token during registration.");
        }
      }

      // 4. 🟢 THE FIX: Build the user profile strictly from the frontend inputs!
      _user = User(
        id: userId.isNotEmpty ? userId : 'temp_id',
        name: name,         
        email: email,       
        role: userRole,
        studentId: sid,     
      );

      // 5. 🟢 CRITICAL: Save this newly built profile to the phone's permanent storage
      final userMap = {
        '_id': _user!.id,
        'name': _user!.name,
        'email': _user!.email,
        'role': _user!.role,
        'studentId': _user!.studentId,
      };
      await _storage.write(key: 'user_data', value: json.encode(userMap));
      
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
  
  // --- OTP Helper ---
  Future<void> sendOtp(String email) async {
    await _apiService.sendOtp(email);
  }

  // --- Logout ---
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

  // --- Token Decoders ---
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