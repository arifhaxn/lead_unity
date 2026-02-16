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

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      // Save token immediately
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

  // 🟢 From His Code: Get all users raw (useful for Admin/general lists)
  Future<List<dynamic>> getUsers() async {
    final response = await _dio.get('/users');
    return response.data;
  }

  // 🟢 From My Code: Filtered list (useful for Dropdowns)
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

  // ===========================================================================
  // 📝 PROPOSALS & TEAMS
  // ===========================================================================

  Future<void> submitProposal(Map<String, dynamic> data) async {
    try {
      await _dio.post('/proposals', data: data);
    } on DioException catch (e) {
      // 🟢 Improved Error Handling: extract the specific message if available
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

  Future<Map<String, dynamic>> getEvaluationSettings() async {
    try {
      final response = await _dio.get('/settings');
      final data = response.data;
      return {
        'criteria1': {'name': data['criteria1Name'] ?? 'Criteria 1', 'max': data['criteria1Max'] ?? 30},
        'criteria2': {'name': data['criteria2Name'] ?? 'Criteria 2', 'max': data['criteria2Max'] ?? 30},
      };
    } catch (e) {
      return {
        'criteria1': {'name': 'Criteria 1', 'max': 30},
        'criteria2': {'name': 'Criteria 2', 'max': 30},
      };
    }
  }

  Future<void> saveTeamMarks(String proposalId, List<Map<String, dynamic>> marksData) async {
    try {
      await _dio.post('/proposals/$proposalId/marks', data: marksData);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to save marks';
    }
  }
}