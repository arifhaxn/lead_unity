// lib/services/api_service.dart (MODIFIED)

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔴 CHANGE THIS URL to match your setup
  static const String _baseUrl = 'http://localhost:5000/api';

  // ... (Other methods like checkRegistrationStatus, login, submitProposal remain the same) ...

  // 🟢 MODIFIED: Now accepts all five registration fields
  Future<Map<String, dynamic>> register(
      String name, 
      String email, 
      String password,
      String studentId, // 🟢 ADDED
      String batch,     // 🟢 ADDED
      String section,   // 🟢 ADDED
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
        // 🟢 ADDED: Sending the extra data fields
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
}