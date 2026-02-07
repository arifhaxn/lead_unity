import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api services/api_services.dart';
import '../../auth_provider.dart';
import 'marking_screen.dart';

class MarkingSelectionScreen extends StatelessWidget {
  const MarkingSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 1. Get Logged-in User ID to filter the list
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.id; 
    final ApiService apiService = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Evaluation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 2. Call API directly (Token is auto-injected)
        future: apiService.getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No proposals found."));
          }

          // 🟢 3. Filter Logic: Only show teams assigned to THIS supervisor
          var teams = snapshot.data!.where((t) {
              final sups = t['supervisors'] as List? ?? [];
              // Robust check: Handle if supervisor is an object or just an ID string
              return sups.any((s) {
                if (s is Map) return s['_id'] == myId;
                if (s is String) return s == myId;
                return false;
              });
          }).toList();

          if (teams.isEmpty) {
            return const Center(child: Text("No assigned teams to mark."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              
              // 🟢 4. Safety Check for Course Code display
              final courseCode = (team['course'] is Map) 
                  ? team['course']['courseCode'] 
                  : 'Course: ${team['course'] ?? 'N/A'}';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                              courseCode, 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))
                            ),
                          ),
                          Icon(Icons.more_horiz, color: Colors.grey[400])
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        team['title'] ?? 'Untitled', 
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Color(0xFF1E293B))
                      ),
                      
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MarkingScreen(team: team)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Start Evaluation"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}