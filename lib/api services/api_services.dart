// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 IMPORTANT: Change this to your teammate's actual server IP and Port.
  static const String _baseUrl = 'http://localhost:5000/api'; 

  // --- Student Registration ---
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
      // Handles 400 or 401 errors from Node.js and extracts the message
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to register');
    }
  }

  // --- Student/User Login ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'), // Uses the /auth/login endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      // Success: Returns the user object, role, and JWT token
      return json.decode(response.body);
    } else {
      // Failure: Throws the error message from the Node.js backend
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to login');
    }
  }

  // --- Other API methods will go here (e.g., submitProposal, fetchTeams) ---
}