
class Proposal {
  final String id;
  final String title;
  final String description;
  final String status;
  // This would ideally be a reference to a User/Team object
  final String studentId; 
  final DateTime createdAt;

  Proposal({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.studentId,
    required this.createdAt,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    return Proposal(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      studentId: json['student'] as String, // Assuming the backend returns the student's ID here
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}