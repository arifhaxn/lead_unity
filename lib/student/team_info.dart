// lib/student/view_teams_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../api services/api_services.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _courses = [];
  Map<String, dynamic> _submittedProposals = {}; // Mapping Course ID to Proposal Data

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final results = await Future.wait([
        _apiService.getCourses(),
       // _apiService.getUserProposal(token!),
      ]);

      setState(() {
        _courses = results[0];
        // Organize proposals by courseId for easy lookup
        for (var p in results[1]) {
          _submittedProposals[p['course'].toString()] = p;
        }
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Status & Teams'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final proposal = _submittedProposals[course['_id']];
                final bool isSubmitted = proposal != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ExpansionTile(
                    leading: Icon(
                      isSubmitted ? Icons.check_circle : Icons.pending_actions,
                      color: isSubmitted ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      course['courseCode'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      isSubmitted ? 'Proposal Submitted' : 'No Proposal Submitted Yet',
                      style: TextStyle(color: isSubmitted ? Colors.green : Colors.redAccent),
                    ),
                    children: [
                      if (isSubmitted)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Title', proposal['title']),
                              const SizedBox(height: 8),
                              _buildInfoRow('Status', proposal['status'].toUpperCase()),
                              const SizedBox(height: 16),
                              const Text('Team Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Divider(),
                              // Check if teamMembers exists in your proposal object
                              if (proposal['teamMembers'] != null)
                                ...((proposal['teamMembers'] as List).map((m) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('• ${m['name']} (${m['studentId']})'),
                                    ))),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'You have not submitted a proposal for this course. Please go to the Submit Proposal screen to start.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}