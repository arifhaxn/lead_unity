import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl =
      'https://leading-unity-nest-backend.vercel.app/api';

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

  // --- AUTH ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio
          .post('/auth/login', data: {'email': email, 'password': password});
      // Save token immediately
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  // 🟢 NEW: Fallback method to get user details if login response is empty
  Future<Map<String, dynamic>> getUserByEmail(String email) async {
    try {
      final response = await _dio.get('/users');
      final List users = response.data;
      // Find the user matching the email
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

  // --- REGISTRATION ---
  Future<Map<String, dynamic>> registerStudent(
      Map<String, dynamic> data) async {
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

  // --- SUPERVISOR ---
  Future<void> changePasswordFirstLogin(
      String email, String tempPass, String newPass) async {
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

  // --- COMMON ---
  Future<List<dynamic>> getCourses() async => (await _dio.get('/courses')).data;
  Future<List<dynamic>> getSupervisors() async {
    final res = await _dio.get('/users');
    return (res.data as List)
        .where((u) => u['role'].toString().toLowerCase() == 'supervisor')
        .toList();
  }

  Future<bool> isRegistrationOpen() async {
    try {
      final res = await _dio.get('/settings');
      return res.data['isStudentRegistrationOpen'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // --- PROPOSALS ---
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
      throw 'Submit failed (${e.response?.statusCode ?? 'unknown'})';
    }
  }

  Future<List<dynamic>> getUserProposals() async =>
      (await _dio.get('/proposals/my')).data;
  Future<List<dynamic>> getAllProposals() async =>
      (await _dio.get('/proposals')).data;

  Future<Map<String, dynamic>> getEvaluationSettings() async {
    try {
      final response = await _dio.get('/settings');
      final data = response.data;
      return {
        'criteria1': {
          'name': data['criteria1Name'] ?? 'Criteria 1',
          'max': data['criteria1Max'] ?? 30
        },
        'criteria2': {
          'name': data['criteria2Name'] ?? 'Criteria 2',
          'max': data['criteria2Max'] ?? 30
        },
      };
    } catch (e) {
      return {
        'criteria1': {'name': 'Criteria 1', 'max': 30},
        'criteria2': {'name': 'Criteria 2', 'max': 30}
      };
    }
  }

  Future<void> saveTeamMarks(
      String proposalId, List<Map<String, dynamic>> marksData) async {
    await _dio.post('/proposals/$proposalId/marks', data: marksData);
  }
}
