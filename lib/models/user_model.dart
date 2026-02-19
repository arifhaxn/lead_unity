class User {
  final String id;
  final String name;
  final String email;
  final String role;
  
  // Assuming the backend might return these fields as well
  final String? studentId; 
  final String? batch;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.batch,
  });

  // Factory constructor to create a User object from the JSON Map returned by the API
factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      // 🟢 BULLETPROOF ID CATCHER: Checks every possible spelling your teammate might use
      studentId: json['studentId']?.toString() ?? 
                 json['student_id']?.toString() ?? 
                 json['studentID']?.toString(), 
    );
  }
  
  // Utility getter to easily check the user type
  bool get isStudent => role == 'student';
}