// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 IMPORTANT: CHANGE THIS URL to your teammate's actual server IP and Port.
  static const String _baseUrl = 'http://localhost:5000/api'; 

  // --- Student Registration (Slight adjustment to match current UI inputs) ---
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

  // --- Student/User Login (No changes needed) ---
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

  // 🟢 NEW METHOD: Submit Proposal
  Future<void> submitProposal(String title, String description, String token) async {
    final response = await http.post(
      // 🛑 ASSUMPTION: The proposal endpoint is /api/proposals
      Uri.parse('$_baseUrl/proposals'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        // 🔑 CRITICAL: Attach the JWT token for authorization
        'Authorization': 'Bearer $token', 
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      // Expecting a 201 CREATED response from the backend
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to submit proposal');
    }
  }
}