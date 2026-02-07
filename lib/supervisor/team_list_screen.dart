import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api services/api_services.dart';
import '../../auth_provider.dart';

class TeamListScreen extends StatelessWidget {
  final bool onlyMyTeams;
  const TeamListScreen({Key? key, required this.onlyMyTeams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 1. Get Auth Data (ID only, token handled by Service)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.id; 
    final ApiService apiService = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          onlyMyTeams ? "My Assigned Teams" : "All Registered Teams",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 2. Call API directly (No token argument needed)
        future: apiService.getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          var teams = snapshot.data ?? [];

          // 🟢 3. Filter Logic
          if (onlyMyTeams && myId != null) {
            teams = teams.where((t) {
              final sups = t['supervisors'] as List? ?? [];
              // Robust check: Handle Object vs String ID
              return sups.any((s) {
                 if (s is Map) return s['_id'] == myId;
                 return s == myId;
              });
            }).toList();
          }

          if (teams.isEmpty) {
            return const Center(child: Text("No teams found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final title = team['title'] ?? 'Untitled Team';
              
              // 🟢 4. Safety Check for Course Code
              final courseCode = (team['course'] is Map) 
                  ? team['course']['courseCode'] 
                  : 'Course: ${team['course'] ?? 'N/A'}'; // Fallback
              
              final status = team['status']?.toString().toUpperCase() ?? 'PENDING';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE0F2F1),
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?', 
                      style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(
                    title, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))
                  ),
                  subtitle: Text(
                    "$courseCode • $status", 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () {
                      // Placeholder for detail view navigation if needed later
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}