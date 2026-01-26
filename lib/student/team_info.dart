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
  Map<String, dynamic> _submittedProposals = {};

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
        //_apiService.getAllProposals(token!), // uses /proposals
      ]);

      final courses = results[0] as List;
      final proposals = results[1] as List;

      final Map<String, dynamic> proposalMap = {};

      for (var p in proposals) {
        if (p['course'] != null && p['course']['_id'] != null) {
          proposalMap[p['course']['_id']] = p;
        }
      }

      setState(() {
        _courses = courses;
        _submittedProposals = proposalMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ExpansionTile(
                    leading: Icon(
                      isSubmitted
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      color: isSubmitted ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      course['courseCode'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      isSubmitted
                          ? 'Proposal Submitted'
                          : 'No Proposal Submitted Yet',
                      style: TextStyle(
                        color:
                            isSubmitted ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    children: [
                      if (isSubmitted)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                  'Title', proposal['title'] ?? 'N/A'),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                'Status',
                                (proposal['status'] ?? 'pending')
                                    .toUpperCase(),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Team Members',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              if (proposal['teamMembers'] != null &&
                                  proposal['teamMembers'].isNotEmpty)
                                ...proposal['teamMembers'].map<Widget>((m) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Text(
                                      '• ${m['name']} (${m['studentId']})',
                                    ),
                                  );
                                }).toList()
                              else
                                const Text(
                                  'No team members added.',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'You have not submitted a proposal for this course yet.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}