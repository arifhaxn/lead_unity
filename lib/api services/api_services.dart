import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 Ensure this URL matches your backend
  static const String _baseUrl = 'https://leading-unity-backend.vercel.app/api'; 

  // --- 1. Student Registration ---
  Future<Map<String, dynamic>> register(
      String name, 
      String email, 
      String password,
      String studentId, 
      String batch,     
      String section,   
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register/student'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        'password': password,
        'studentId': studentId, 
        'batch': batch,     
        'section': section,   
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      // Extract specific backend error message
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to register');
    }
  }

  // --- 2. User Login ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to login');
    }
  }

  // --- 3. Fetch Courses ---
  Future<List<dynamic>> getCourses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/courses'), 
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // --- 4. Fetch Supervisors ---
  Future<List<dynamic>> getSupervisors(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users'), 
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> allUsers = json.decode(response.body);
      // Filter: Return only users where role is 'supervisor'
      return allUsers.where((user) => user['role'].toString().toLowerCase() == 'supervisor').toList();
    } else {
      throw Exception('Failed to load supervisors');
    }
  }

  // --- 5. Submit Proposal (Correctly Handles Lists & Errors) ---
  Future<void> submitProposal({
    required String title,
    required String description,
    required List<String> supervisorIds, // 🟢 Accepts List
    required String courseId,
    required List<Map<String, String>> teamMembers, 
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/proposals'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', 
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'supervisorIds': supervisorIds, // 🟢 Sends List
        'courseId': courseId,
        'teamMembers': teamMembers,
      }),
    );

    if (response.statusCode != 201) {
      // 🟢 Parse JSON to get the specific "Student already in team" message
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to submit proposal');
    }
  }
}
//   // --- 6. Fetch User Proposals ---
// Future<List<dynamic>> getUserProposals(String token) async {
//   final response = await http.get(
//     Uri.parse('$_baseUrl/proposals/my-proposals'), // Assuming this endpoint exists on your backend
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//   );

//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     throw Exception('Failed to load your proposals');
//   }
// }