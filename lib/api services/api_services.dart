// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 URL provided in your initial code
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
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to register');
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
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to login');
    }
  }

  // --- 3. Fetch Courses (For Tabs) ---
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

  // --- 4. Fetch Supervisors (For Dropdowns) ---
  Future<List<dynamic>> getSupervisors(String token) async {
    // We fetch all users, then filter for supervisors on the client side 
    // (or adjust backend endpoint if available)
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
      return allUsers.where((user) => user['role'] == 'supervisor').toList();
    } else {
      throw Exception('Failed to load supervisors');
    }
  }

  // --- 5. Submit Proposal (Updated with Team Members) ---
  Future<void> submitProposal({
    required String title,
    required String description,
    required String supervisorId,
    required String courseId,
    required List<Map<String, String>> teamMembers, // 🟢 Added Team Members
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
        'supervisorId': supervisorId,
        'courseId': courseId,
        'teamMembers': teamMembers, // 🟢 Send List to Backend
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to submit proposal');
    }
  }
}