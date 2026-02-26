import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'https://leading-unity-nest-backend.vercel.app/api';
  
  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // ===========================================================================
  // 🔐 AUTH & REGISTRATION
  // ===========================================================================

    // --- AUTH ---
  Future<dynamic> login(String identifier, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'identifier': identifier, // ⚠️ KEY MUST BE 'identifier' (not 'email')
        'password': password,
      });
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  // 🟢 CRITICAL FIX: Fallback to get user details if login response is empty
  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      final response = await _dio.get('/users');
      final List users = response.data;
      final user = users.firstWhere(
        (u) => u['email'] == email,
        orElse: () => null,
      );
      if (user != null) return user;
      throw "User not found";
    } catch (e) {
      throw "Failed to fetch user details";
    }
  }

  Future<Map<String, dynamic>> registerStudent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register/student', data: data);
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // ===========================================================================
  // 👮 SUPERVISOR SPECIFIC
  // ===========================================================================

  Future<void> changePasswordFirstLogin(String email, String tempPass, String newPass) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'email': email,
        'oldPassword': tempPass,
        'newPassword': newPass
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to change password';
    }
  }

  // ===========================================================================
  // 🏫 COMMON DATA
  // ===========================================================================

  Future<List<dynamic>> getCourses() async {
    final response = await _dio.get('/courses');
    return response.data;
  }

  Future<List<dynamic>> getUsers() async {
    final response = await _dio.get('/users');
    return response.data;
  }

  Future<List<dynamic>> getSupervisors() async {
    final res = await _dio.get('/users');
    return (res.data as List)
        .where((u) => u['role'].toString().toLowerCase() == 'supervisor')
        .toList();
  }

  Future<bool> isRegistrationOpen() async {
    try {
      final response = await _dio.get('/settings');
      return response.data['isStudentRegistrationOpen'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // 🟢 NEW: Check Submission Status
  Future<bool> isSubmissionOpen() async {
    try {
      final response = await _dio.get('/settings');
      // If the field doesn't exist yet, assume OPEN (true) to prevent blocking
      return response.data['isSubmissionOpen'] ?? true;
    } catch (e) {
      return true; // Fail safe to open
    }
  }

  // ===========================================================================
  // 📝 PROPOSALS & TEAMS
  // ===========================================================================

  Future<void> submitProposal(Map<String, dynamic> data) async {
    try {
      await _dio.post('/proposals', data: data);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        throw payload['message'].toString();
      }
      if (payload is String) {
        throw payload;
      }
      throw e.response?.data['message'] ?? 'Submission failed';
    }
  }

  Future<List<dynamic>> getUserProposals() async {
    try {
      final response = await _dio.get('/proposals/my');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAllProposals() async {
    try {
      final response = await _dio.get('/proposals'); 
      return response.data;
    } catch (e) {
      return []; 
    }
  }

  // ===========================================================================
  // 📊 EVALUATION
  // ===========================================================================

  // 🟢 NEW: Updated to return 'defense' and 'own' criteria categories
  Future<Map<String, dynamic>> getEvaluationSettings() async {
    try {
      final response = await _dio.get('/settings');
      final data = response.data;
      
      return {
        'defense': {
           'c1': {'name': data['criteria1Name'] ?? 'Defense 1', 'max': data['criteria1Max'] ?? 30},
           'c2': {'name': data['criteria2Name'] ?? 'Defense 2', 'max': data['criteria2Max'] ?? 30},
        },
        'own': {
           'c1': {'name': data['ownTeamCriteria1Name'] ?? 'Own 1', 'max': data['ownTeamCriteria1Max'] ?? 40},
           'c2': {'name': data['ownTeamCriteria2Name'] ?? 'Own 2', 'max': data['ownTeamCriteria2Max'] ?? 40},
        }
      };
    } catch (e) {
      return {};
    }
  }

  // 🟢 NEW: Added the 'type' string parameter for saving marks
  Future<void> saveTeamMarks(String proposalId, List<Map<String, dynamic>> marksData, String type) async {
    try {
      await _dio.post('/proposals/$proposalId/marks', data: {
        'marks': marksData,
        'type': type
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to save marks';
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _dio.post('/auth/send-otp', data: {'email': email});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to send OTP';
    }
  }
}