import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_unity/supervisor/sup_team_details.dart';
import 'package:provider/provider.dart';

// 🟢 Core Imports
import '../../api services/api_services.dart';
import '../../auth_provider.dart';
import '../../chatbot_screen.dart';
import 'marking_screen.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class TeamListScreen extends StatefulWidget {
  final bool onlyMyTeams;
  const TeamListScreen({Key? key, required this.onlyMyTeams}) : super(key: key);

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<dynamic>>? _teamsFuture;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // 🟢 1. Call API directly (Token auto-handled)
    _teamsFuture = _apiService.getAllProposals();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 2. Get User ID for filtering
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myId = authProvider.user?.id;
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.onlyMyTeams ? "My Assigned Teams" : "All Registered Teams",
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          var teams = snapshot.data ?? [];

          // 🟢 3. Filter Logic (Merged Logic)
          // Filter if 'onlyMyTeams' is true
          if (widget.onlyMyTeams && myId != null) {
            teams = teams.where((t) {
              final sups = t['supervisors'] as List? ?? [];
              // Robust check for object vs string ID
              return sups.any((s) {
                 if (s is Map) return s['_id'] == myId;
                 return s == myId;
              });
            }).toList();
          }

          if (teams.isEmpty) {
            return const Center(child: Text("No teams found."));
          }

          // 🟢 4. Your Tab Logic
          final courseTabs = _extractCourseTabs(teams);

          return DefaultTabController(
            length: courseTabs.length,
            child: Column(
              children: [
                _buildCourseTabs(context, courseTabs),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 250), () => setState(() => _searchQuery = v.trim()));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by supervisor, title, or ID',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: courseTabs.map((courseCode) {
                      final filtered = _filterTeams(
                          teams: teams,
                          courseCode: courseCode,
                          query: _searchQuery);

                      if (filtered.isEmpty) return const Center(child: Text("No teams match your filter."));

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final team = filtered[index];
                          
                          return _buildTeamCard(
                            context,
                            index: index + 1,
                            team: team,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  // --- Helpers ---

  List<String> _extractCourseTabs(List<dynamic> teams) {
    final courseCodes = <String>{};
    for (final team in teams) {
      if (team['course'] is Map && team['course']['courseCode'] != null) {
        courseCodes.add(team['course']['courseCode'].toString());
      }
    }
    final sorted = courseCodes.toList()..sort();
    return ['All', ...sorted];
  }

  Widget _buildCourseTabs(BuildContext context, List<String> courseTabs) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        isScrollable: true,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
        tabs: courseTabs.map((c) => Tab(child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
      ),
    );
  }

  List<dynamic> _filterTeams({required List<dynamic> teams, required String courseCode, required String query}) {
    final normalizedQuery = query.toLowerCase();
    return teams.where((team) {
      if (courseCode != 'All') {
        final code = (team['course'] is Map) ? team['course']['courseCode']?.toString() : null;
        if (code != courseCode) return false;
      }
      if (normalizedQuery.isEmpty) return true;
      
      final title = (team['title'] ?? '').toString().toLowerCase();
      // Robust Supervisor Name Search
      final supervisors = team['supervisors'] as List? ?? [];
      final supervisorMatch = supervisors.any((s) {
         if (s is Map) return (s['name'] ?? '').toLowerCase().contains(normalizedQuery);
         return false;
      });

      return title.contains(normalizedQuery) || supervisorMatch;
    }).toList();
  }

  Widget _buildTeamCard(BuildContext context, {required int index, required Map<String, dynamic> team}) {
    final theme = Theme.of(context);
    final title = team['title'] ?? 'Untitled Team';
    final courseCode = (team['course'] is Map) ? team['course']['courseCode'] : 'N/A';
    final status = team['status']?.toString().toUpperCase() ?? 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.level1,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE0F2F1),
              child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
            ),
            title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text("$courseCode • $status", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          const Divider(height: 1),
          // 🟢 Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // 🟢 Navigates to the Details screen (from his code)
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorTeamDetailsScreen(team: team)));
                  },
                  child: const Text("Details"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MarkingScreen(team: team)),
                    );
                    // Refresh list after marking
                    setState(() { _teamsFuture = _apiService.getAllProposals(); });
                  },
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text("Evaluate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}