import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl =
      'https://leading-unity-nest-backend.vercel.app/api';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  final _storage = const FlutterSecureStorage();

  /// Called when a protected request returns 401 — an expired or otherwise
  /// rejected token. Wired up once in main.dart to log the user out cleanly and
  /// return them to login. Static so every ApiService instance shares it.
  static void Function()? onUnauthorized;

  /// De-dupes the burst of parallel 401s a dashboard produces (several calls
  /// fire at once) so the logout flow runs only once. Re-armed on next login.
  static bool _handlingUnauthorized = false;

  /// Re-arms the 401 handler — after a fresh login, or if the handler couldn't
  /// act yet (e.g. the navigator wasn't ready).
  static void resetUnauthorizedGuard() => _handlingUnauthorized = false;

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        // 401 on a protected endpoint = the session is no longer valid (the
        // token expired or was rejected). Auth endpoints are excluded so a
        // wrong-password login still surfaces its own "Login failed" message.
        final isAuthCall = e.requestOptions.path.startsWith('/auth/');
        if (e.response?.statusCode == 401 &&
            !isAuthCall &&
            !_handlingUnauthorized) {
          _handlingUnauthorized = true;
          onUnauthorized?.call();
        }
        return handler.next(e);
      },
    ));
  }

  /// Turns a backend error payload into ONE clean, human-readable sentence.
  ///
  /// NestJS (class-validator) returns `message` as an array of technical
  /// strings, e.g. ["teamMembers.1.email must be an email"]. Thrown and
  /// `.toString()`-ed raw, that reaches the user as
  /// "[teamMembers.1.email must be an email]" — brackets, field paths and all.
  /// This collapses it into something presentable.
  static String friendlyError(dynamic data, String fallback) {
    dynamic msg;
    if (data is Map) {
      msg = data['message'] ?? data['error'];
    } else if (data is String) {
      msg = data;
    }

    if (msg is List) {
      msg = msg.isNotEmpty ? msg.first : null;
    }
    if (msg == null) return fallback;

    var text = msg.toString().trim();
    if (text.isEmpty) return fallback;

    // class-validator prefixes each message with the field path
    // ("teamMembers.1.email must be an email"). Rewrite that prefix into a
    // friendly subject so no dotted paths reach the user.
    final firstSpace = text.indexOf(' ');
    if (firstSpace > 0) {
      final path = text.substring(0, firstSpace);
      final looksLikeField = RegExp(r'^[A-Za-z_][\w.]*$').hasMatch(path) &&
          RegExp(r'[a-z]').hasMatch(path);
      if (looksLikeField) {
        final subject = _friendlyField(path);
        if (subject.isNotEmpty) {
          text = '$subject ${text.substring(firstSpace + 1)}';
        }
      }
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  /// "teamMembers.1.email" -> "Member 2 email"; "studentId" -> "Student id".
  static String _friendlyField(String path) {
    final out = <String>[];
    for (final part in path.split('.')) {
      if (RegExp(r'^\d+$').hasMatch(part)) {
        final n = int.parse(part) + 1;
        if (out.isNotEmpty) out[out.length - 1] = 'Member $n';
      } else {
        out.add(part
            .replaceAllMapped(
                RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
            .toLowerCase());
      }
    }
    final joined = out.join(' ').trim();
    if (joined.isEmpty) return '';
    return joined[0].toUpperCase() + joined.substring(1);
  }

  Future<dynamic> login(String identifier, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      await _storage.write(key: 'jwt_token', value: response.data['token']);
      _handlingUnauthorized = false; // re-arm for the new session
      return response.data;
    } on DioException catch (e) {
      throw friendlyError(e.response?.data, 'Login failed');
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
      _handlingUnauthorized = false; // re-arm for the new session
      return response.data;
    } on DioException catch (e) {
      throw friendlyError(e.response?.data, 'Registration failed');
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
      throw friendlyError(e.response?.data, 'Failed to change password');
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
      throw friendlyError(e.response?.data, 'Submission failed');
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
      // Backend now returns { data, total, page, totalPages }
      // Fetch all pages and merge into one flat list
      final firstResponse = await _dio.get('/proposals?page=1&limit=50');
      final Map<String, dynamic> firstBody = firstResponse.data;
      final int totalPages = firstBody['totalPages'] ?? 1;
      List<dynamic> allProposals = List.from(firstBody['data']);

      if (totalPages > 1) {
        // Fetch remaining pages in parallel
        final futures = List.generate(
          totalPages - 1,
          (i) => _dio.get('/proposals?page=${i + 2}&limit=50'),
        );
        final responses = await Future.wait(futures);
        for (final res in responses) {
          allProposals.addAll(res.data['data']);
        }
      }

      return allProposals;
    } catch (e) {
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
      throw friendlyError(e.response?.data, 'Failed to fetch team status');
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getEvaluationSettings() async {
    try {
      final response = await _dio.get('/settings');
      final data = response.data;

      // Combined total marks (admin-defined, default 100)
      final int totalMarks = (data['totalMarks'] as num?)?.toInt() ?? 100;

      List<Map<String, dynamic>> parseCriteria(dynamic raw, String prefix) {
        if (raw is List && raw.isNotEmpty) {
          return raw
              .map<Map<String, dynamic>>((c) => {
                    'name': (c['name'] ?? '$prefix Criteria').toString(),
                    'max': (c['max'] as num?)?.toInt() ?? 0,
                  })
              .toList();
        }
        return [];
      }

      return {
        'totalMarks': totalMarks,
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
      throw friendlyError(e.response?.data, 'Failed to save marks');
    }
  }

  // 🟢 Sends OTP to user's email for password recovery
  Future<void> sendForgotPasswordOtp(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw friendlyError(e.response?.data, 'Failed to send reset OTP');
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
      throw friendlyError(e.response?.data, 'Failed to reset password');
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      await _dio.post('/auth/send-otp', data: {'email': email});
    } on DioException catch (e) {
      throw friendlyError(e.response?.data, 'Failed to send OTP');
    }
  }

  /// Fetch all notifications for the logged-in user
  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return response.data as List;
    } on DioException catch (e) {
      throw friendlyError(e.response?.data, 'Failed to load notifications');
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

  /// Registers this device's FCM token. The backend stores a SET of tokens, so
  /// signing in on web no longer evicts the phone's token.
  Future<void> saveFcmToken(String fcmToken) async {
    try {
      await _dio.patch('/users/fcm-token', data: {'fcmToken': fcmToken});
    } on DioException catch (e) {
      throw friendlyError(
          e.response?.data, 'Failed to register this device for notifications');
    }
  }

  /// Un-registers ONE device on logout.
  ///
  /// The token must be sent explicitly — the backend keeps a list per user and
  /// otherwise cannot tell which device is signing out.
  Future<void> clearFcmToken(String authToken, {String? fcmToken}) async {
    if (fcmToken == null || fcmToken.isEmpty) return;
    await _dio.patch(
      '/users/fcm-token/remove',
      data: {'fcmToken': fcmToken},
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
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
