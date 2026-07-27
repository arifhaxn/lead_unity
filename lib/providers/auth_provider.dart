import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:link_unity/services/notification_service.dart';
import '../services/api_services.dart';
import '../../models/user_model.dart';
import '../widgets/custom_snackbar.dart'; // 🟢 Import the custom snackbar!

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

  Future<bool> tryAutoLogin() async {
    final savedToken = await _storage.read(key: 'jwt_token');
    final userDataString = await _storage.read(key: 'user_data');

    if (savedToken == null || userDataString == null) return false;

    try {
      _token = savedToken;
      _user = User.fromJson(json.decode(userDataString));
      notifyListeners();

      // Cache-first: the line above loads the snapshot saved at last login.
      // Kick off a background refresh so account info (name, ID, designation…)
      // isn't frozen until the next manual logout+login. Not awaited — the UI
      // shows cached data instantly and updates if/when the server responds.
      refreshUserProfile();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Re-fetches the logged-in user's own profile from the backend and updates
  /// both the in-memory user and the cached `user_data`.
  ///
  /// Without this, [tryAutoLogin] keeps showing whatever was stored at login
  /// time — the reported bug where a user's info only refreshes after logging
  /// out and back in. Safe to call any time; it only rebuilds the UI when
  /// something actually changed.
  Future<void> refreshUserProfile() async {
    final current = _user;
    if (current == null || _token == null) return;

    try {
      // The backend has no dedicated "current user" route, so pull the user
      // list (already fetched elsewhere) and locate this account by id.
      final users = await _apiService.getUsers();

      Map<String, dynamic>? me;
      for (final u in users) {
        if (u is Map && u['_id']?.toString() == current.id) {
          me = Map<String, dynamic>.from(u);
          break;
        }
      }
      // Fallback: match by email when the id didn't line up.
      if (me == null && current.email.isNotEmpty) {
        for (final u in users) {
          if (u is Map && u['email']?.toString() == current.email) {
            me = Map<String, dynamic>.from(u);
            break;
          }
        }
      }
      if (me == null) return; // couldn't locate the account — keep the cache

      final refreshed = User.fromJson(me);
      final userMap = {
        '_id': refreshed.id,
        'name': refreshed.name,
        'email': refreshed.email,
        'role': refreshed.role,
        'studentId': refreshed.studentId,
        'designation': refreshed.designation,
      };
      final encoded = json.encode(userMap);

      // Only rewrite storage / rebuild the UI when the profile changed.
      final existing = await _storage.read(key: 'user_data');
      if (encoded == existing) return;

      _user = refreshed;
      await _storage.write(key: 'user_data', value: encoded);
      notifyListeners();
    } catch (e) {
      debugPrint('Could not refresh user profile: $e');
    }
  }

  //Login with Name Correction & ID
  // 🟢 FIX: Added BuildContext context
  Future<void> login(BuildContext context, String identifier, String password, {String? role}) async {
    _setLoading(true);
    try {
      final data = await _apiService.login(identifier, password);

      _token = data['token'];
      await _storage.write(key: 'jwt_token', value: _token);

      if (data['user'] != null) {
        _user = User.fromJson(data['user']);
      } else {
        debugPrint(
            "Missing user object structure. attempting manual construction...");

        if (data['name'] != null) {
          _user = User(
            id: data['_id']?.toString() ?? '',
            name: data['name']?.toString() ?? 'User',
            email: data['email']?.toString() ?? '',
            role: data['role']?.toString() ?? 'student',
            studentId: data['studentId']?.toString(),
            designation: data['designation']?.toString(),
          );
        } else {
          try {
            final payload = _parseJwt(_token!);

            String userId = (payload['_id'] ?? payload['sub'] ?? '').toString();
            String? userRole = payload['role']?.toString().toLowerCase();
            String realName = payload['name']?.toString() ?? identifier;
            String? extractedStudentId = payload['studentId']?.toString();
            String? extractedDesignation;

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
                extractedStudentId = me['studentId'].toString();
              }
              if (me['designation'] != null) {
                extractedDesignation = me['designation'].toString();
              }
            } catch (e) {
              debugPrint("Could not fetch real profile: $e");
            }

            _user = User(
              id: userId,
              name: realName,
              email: identifier.contains('@') ? identifier : '',
              role: userRole ?? 'unknown',
              studentId: extractedStudentId,
              designation: extractedDesignation,
            );
          } catch (e) {
            _user = User(
                id: 'temp', name: 'User', email: identifier, role: 'unknown');
          }
        }
      }

      if (_user != null) {
        final userMap = {
          '_id': _user!.id,
          'name': _user!.name,
          'email': _user!.email,
          'role': _user!.role,
          'studentId': _user!.studentId,
          'designation': _user!.designation,
        };
        await _storage.write(key: 'user_data', value: json.encode(userMap));
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      // 🟢 FIX: Passed context to CustomSnackBar, and added mounted check
      if (context.mounted) {
         CustomSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
      rethrow;
    }
  }

  //Registration
  // 🟢 FIX: Added BuildContext context
  Future<void> register(BuildContext context, String name, String email, String password, String sid,
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

      //Send data to backend
      final data = await _apiService.registerStudent(registrationData);

      //Save the token immediately
      _token = data['token'];
      await _storage.write(key: 'jwt_token', value: _token);

      //Extract IDs if the backend provided them
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

      _user = User(
        id: userId.isNotEmpty ? userId : 'temp_id',
        name: name,
        email: email,
        role: userRole,
        studentId: sid,
      );

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

      // 🟢 FIX: Passed context to CustomSnackBar, and added mounted check
      if (context.mounted) {
        CustomSnackBar.showSuccess(context, 'Account created successfully!');
      }
    } catch (e) {
      _setLoading(false);
      // 🟢 FIX: Passed context to CustomSnackBar, and added mounted check
      if (context.mounted) {
         CustomSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
      rethrow;
    }
  }

  //OTP Helper
  // 🟢 FIX: Added BuildContext context
  Future<void> sendOtp(BuildContext context, String email) async {
    try {
      await _apiService.sendOtp(email);
      // 🟢 FIX: Context is now available and passed
      if (context.mounted) {
         CustomSnackBar.showSuccess(context, 'OTP sent successfully to $email');
      }
    } catch (e) {
      // 🟢 FIX: Context is now available and passed
      if (context.mounted) {
         CustomSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
      }
      rethrow;
    }
  }

  Future<void> logout() async {
  try {
    // ✅ Un-register ONLY this device's FCM token before we delete the JWT.
    // Sending the specific token matters: the backend stores one entry per
    // device, so a logout on web must not silence the user's phone.
    if (_token != null) {
      final deviceToken = await NotificationService.currentToken();
      await _apiService.clearFcmToken(_token!, fcmToken: deviceToken);
    }
    await _apiService.logout();
  } catch (e) {
    debugPrint("API Logout error: $e");
  }
    NotificationService.reset();

    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'jwt_token'); // Make sure to delete token too!
    _user = null;
    _token = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //Token Decoders
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