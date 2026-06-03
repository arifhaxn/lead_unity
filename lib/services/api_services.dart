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

  Future<dynamic> login(String identifier, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

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

  Future<DateTime?> getSubmissionDeadline() async {
    try {
      final response = await _dio.get('/settings');
      final raw = response.data['submissionDeadline'];
      if (raw != null) return DateTime.parse(raw);
      return null;
    } catch (e) {
      return null;
    }
  }

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
      // 🟢 Throws error so the DataProvider doesn't wipe your local cache
      throw Exception('Failed to load user proposals: $e');
    }
  }

  Future<List<dynamic>> getAllProposals() async {
    try {
      final response = await _dio.get('/proposals');
      return response.data;
    } catch (e) {
      // 🟢 Throws error so the DataProvider doesn't wipe your local cache
      throw Exception('Failed to load all proposals: $e');
    }
  }

  // 🟢 Fetches the specific proposal for the logged-in student
  // This is used by the Dashboard to show Supervisor and Defense info
  Future<Map<String, dynamic>?> getMyProposal() async {
    try {
      final response = await _dio.get('/proposals/my');
      final List proposals = response.data;

      if (proposals.isNotEmpty) {
        // Return the first one (usually the active one for the current semester)
        return proposals.first as Map<String, dynamic>;
      }
      return null; // Student hasn't submitted a proposal yet
    } on DioException catch (e) {
      // If the error is a 404 or empty, we just treat it as "no proposal"
      if (e.response?.statusCode == 404) return null;
      throw e.response?.data['message'] ?? 'Failed to fetch team status';
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getEvaluationSettings() async {
    try {
      final response = await _dio.get('/settings');
      final data = response.data;

      // Build a list of {name, max} maps from the dynamic criteria arrays.
      // Falls back gracefully to two equal criteria if the server returns nothing.
      List<Map<String, dynamic>> parseCriteria(dynamic raw, String prefix) {
        if (raw is List && raw.isNotEmpty) {
          return raw
              .map<Map<String, dynamic>>((c) => {
                    'name': (c['name'] ?? '$prefix Criteria').toString(),
                    'max': (c['max'] as num?)?.toInt() ?? 50,
                  })
              .toList();
        }
        // Fallback: two equal criteria summing to 100
        return [
          {'name': '$prefix Criteria 1', 'max': 50},
          {'name': '$prefix Criteria 2', 'max': 50},
        ];
      }

      return {
        'defense': parseCriteria(data['defenseCriteria'], 'Defense'),
        'own': parseCriteria(data['ownTeamCriteria'], 'Internal'),
      };
    } catch (e) {
      return {};
    }
  }

  Future<void> saveTeamMarks(String proposalId,
      List<Map<String, dynamic>> marksData, String type) async {
    try {
      await _dio.post('/proposals/$proposalId/marks',
          data: {'marks': marksData, 'type': type});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to save marks';
    }
  }

  // 🟢 Sends OTP to user's email for password recovery
  Future<void> sendForgotPasswordOtp(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to send reset OTP';
    }
  }

  // 🟢 Verifies OTP and updates the password
  Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to reset password';
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _dio.post('/auth/send-otp', data: {'email': email});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to send OTP';
    }
  }

  /// Fetch all notifications for the logged-in user
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return response.data as List;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load notifications';
    }
  }

  /// Get only the unread count (lightweight — for the badge)
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return (response.data['count'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Mark a single notification as read
  Future<void> markNotificationRead(String notifId) async {
    try {
      await _dio.patch('/notifications/$notifId/read');
    } catch (_) {}
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } catch (_) {}
  }

  // api_services.dart - Add this method
  Future<Map<String, dynamic>?> getMyTeam() async {
    try {
      final response = await _dio.get('/proposals/my-team');
      if (response.data == null) return null;
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      return null;
    } catch (e) {
      return null;
    }
  }
}