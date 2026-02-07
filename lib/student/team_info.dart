import 'package:flutter/material.dart';
import '../api services/api_services.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Team & Proposal'),
        backgroundColor: Colors.blueAccent, // 🟢 Keeping your blue theme
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 Using his API method which automatically attaches the token
        future: _apiService.getUserProposals(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diversity_3_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "No Team Found", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)
                  ),
                  const SizedBox(height: 8),
                  const Text("Submit a proposal to form a team.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 🟢 Logic: Display the first active proposal (similar to his logic)
          final proposal = snapshot.data![0];
          final members = proposal['teamMembers'] as List? ?? [];
          final course = proposal['course'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Your Card UI for the Project Info
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(course['courseCode'] ?? 'N/A'),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _getStatusColor(proposal['status']),
                                borderRadius: BorderRadius.circular(12)
                              ),
                              child: Text(
                                (proposal['status'] ?? 'PENDING').toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text("Project Title", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          proposal['title'] ?? 'Untitled Project', 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildInfoRow('Description/Link', proposal['description'] ?? 'No link provided'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text("Team Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),

                // 🟢 Your List-based UI for members
                ...members.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        (m['name']?[0] ?? 'U').toString().toUpperCase(),
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(m['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(m['studentId'] ?? 'No ID', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("CGPA", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(m['cgpa'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }
}