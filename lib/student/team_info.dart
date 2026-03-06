import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../api services/api_services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../chatbot_screen.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  final ApiService _apiService = ApiService();
  
  // 🟢 1. Create a variable to hold the Future
  late Future<List<dynamic>> _proposalFuture;

  @override
  void initState() {
    super.initState();
    // 🟢 2. Initialize the future ONLY ONCE when the screen is first created
    _proposalFuture = _apiService.getUserProposals();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // 🟢 NEW: A reusable 1-pixel subtle border line for the bottom of the AppBar
    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2), // Subtle separation
        height: 1.0,
      ),
    );
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Team & Proposal'),
        // 🟢 MATCHES BACKGROUND AND REMOVES SHADOW
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine, // 🟢 ADDED THE LINE HERE
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 3. Use the stored variable here instead of calling the function
        future: _proposalFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonLoader(theme);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diversity_3_outlined,
                      size: 80,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No Team Found",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text("Submit a proposal to form a team.",
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }

          final proposal = snapshot.data![0];
          final members = proposal['teamMembers'] as List? ?? [];
          final course = proposal['course'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF245E63),
                    borderRadius: AppRadii.card,
                    boxShadow: AppShadows.level1,
                  ),
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
                              backgroundColor: const Color(0xFF1A4A4F),
                              labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              side: BorderSide.none,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: _getStatusColor(proposal['status']),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                (proposal['status'] ?? 'PENDING')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text("Project Title",
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70)),
                        Text(proposal['title'] ?? 'Untitled Project',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(color: Colors.white)),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildInfoRow('Description/Link',
                            proposal['description'] ?? 'No link provided'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Team Members", style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ...members.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF245E63),
                        borderRadius: AppRadii.card,
                        boxShadow: AppShadows.level1,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            child: Text(
                              (m['name']?[0] ?? 'U')
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(height: 6),
                                _memberDetailRow(Icons.badge_outlined, 'ID',
                                    m['studentId'] ?? 'N/A'),
                                const SizedBox(height: 4),
                                _memberDetailRow(Icons.email_outlined,
                                    'Email', m['email'] ?? 'N/A'),
                                const SizedBox(height: 4),
                                _memberDetailRow(Icons.phone_outlined,
                                    'Mobile', m['mobile'] ?? 'N/A'),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("CGPA",
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white70)),
                              Text(
                                  m['cgpa'] != null
                                      ? double.tryParse(m['cgpa'].toString())
                                              ?.toStringAsFixed(2) ??
                                          m['cgpa'].toString()
                                      : 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🟢 Skeleton Loader Method
  Widget _buildSkeletonLoader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 24,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _memberDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.accentTeal;
      case 'rejected':
        return AppColors.accentCoral;
      default:
        return AppColors.accentLime;
    }
  }
}