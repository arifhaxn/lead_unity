import 'package:flutter/material.dart';
import '../../api services/api_services.dart';

class SupervisorListScreen extends StatelessWidget {
  const SupervisorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 No Provider needed here anymore
    final ApiService apiService = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("All Supervisors"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 FIXED: Call API directly without token argument
        // The Service handles the filtering ('role' == 'supervisor') and the token automatically.
        future: apiService.getSupervisors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sups = snapshot.data ?? [];
          
          if (sups.isEmpty) {
            return const Center(child: Text("No other supervisors found."));
          }

          return ListView.builder(
            itemCount: sups.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final s = sups[index];
              final name = s['name'] ?? 'Unknown';
              final firstLetter = name.isNotEmpty ? name[0] : '?';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF3E5F5),
                    child: Text(
                      firstLetter.toUpperCase(), 
                      style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(
                    name, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                  ),
                  subtitle: Text(
                    s['email'] ?? '', 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])
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