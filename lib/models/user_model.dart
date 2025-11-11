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
      // The backend returns the MongoDB ID as '_id'
      id: json['_id'] as String, 
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      // Safely check for optional fields (These fields must be updated in your backend to be returned)
      studentId: json['studentId'] as String?, 
      batch: json['batch'] as String?,
    );
  }
  
  // Utility getter to easily check the user type
  bool get isStudent => role == 'student';
}