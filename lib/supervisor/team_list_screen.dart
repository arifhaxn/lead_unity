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
    _teamsFuture = _apiService.getAllProposals();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // 🟢 Helper to show dynamic Instructions Dialog
  void _showInstructions() {
    final title =
        widget.onlyMyTeams ? "Personal Marking" : "Defense Board Marking";
    final content = widget.onlyMyTeams
        ? "This list contains only the teams directly assigned to you. Use this section to provide your personal marking and evaluate your own students."
        : "This list contains all registered teams. Use this section to evaluate and mark teams as an external member during a Defense Board.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showInstructions,
            tooltip: 'Information',
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

          if (widget.onlyMyTeams && myId != null) {
            teams = teams.where((t) {
              final assigned = (t['assignedSupervisor'] is Map)
                  ? t['assignedSupervisor']['_id']
                  : t['assignedSupervisor'];
              return assigned == myId;
            }).toList();
          }

          teams = teams.where((t) {
            final status = (t['status'] ?? '').toString().toLowerCase().trim();
            return status == 'approved';
          }).toList();

          final orderedTeams = [...teams]..sort((a, b) =>
              _submissionTime(a as Map<String, dynamic>)
                  .compareTo(_submissionTime(b as Map<String, dynamic>)));

          if (teams.isEmpty) {
            return const Center(child: Text("No approved teams found."));
          }

          final courseTabs = _extractCourseTabs(orderedTeams);

          if (courseTabs.isEmpty) {
            return const Center(child: Text("No course tabs found."));
          }

          return DefaultTabController(
            length: courseTabs.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseTabs(context, courseTabs),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 250),
                          () => setState(() => _searchQuery = v.trim()));
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by supervisor, title, or ID',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: courseTabs.map((courseCode) {
                      final courseOrdered = _filterTeams(
                        teams: orderedTeams,
                        courseCode: courseCode,
                        query: '',
                      );

                      final serialByTeamKeyInCourse = <String, int>{
                        for (int i = 0; i < courseOrdered.length; i++)
                          _teamKey(courseOrdered[i] as Map<String, dynamic>):
                              i + 1,
                      };

                      final filtered = _filterTeams(
                          teams: orderedTeams,
                          courseCode: courseCode,
                          query: _searchQuery);

                      if (filtered.isEmpty)
                        return const Center(
                            child: Text("No teams match your filter."));

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final team = filtered[index];
                          final teamMap = team as Map<String, dynamic>;
                          final serial =
                              serialByTeamKeyInCourse[_teamKey(teamMap)] ??
                                  (index + 1);

                          return _buildTeamCard(
                            context,
                            serialNumber: serial,
                            team: teamMap,
                            myId: myId,
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
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  // --- Helpers ---

  String _teamKey(Map<String, dynamic> team) {
    final key =
        (team['_id'] ?? team['id'] ?? team['proposalId'] ?? '').toString();
    if (key.isNotEmpty) return key;

    final title = (team['title'] ?? '').toString();
    final createdAt =
        (team['createdAt'] ?? team['submittedAt'] ?? '').toString();
    return '$title|$createdAt';
  }

  DateTime _submissionTime(Map<String, dynamic> team) {
    final raw =
        (team['createdAt'] ?? team['submittedAt'] ?? team['created_at'] ?? '')
            .toString();
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<String> _extractCourseTabs(List<dynamic> teams) {
    final courseCodes = <String>{};
    for (final team in teams) {
      if (team['course'] is Map && team['course']['courseCode'] != null) {
        courseCodes.add(team['course']['courseCode'].toString());
      }
    }
    final sorted = courseCodes.toList()..sort();
    return sorted;
  }

  Widget _buildCourseTabs(BuildContext context, List<String> courseTabs) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors
            .transparent, // 🟢 Removes the ugly default grey line underneath
        indicatorSize:
            TabBarIndicatorSize.label, // 🟢 Binds the box closely to the text
        labelPadding:
            const EdgeInsets.symmetric(horizontal: 6), // Space between the tabs
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
        ),
        tabs: courseTabs
            .map((c) => Tab(
                  // 🟢 The padding inside here creates the left/right breathing room inside the box
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(c,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  List<dynamic> _filterTeams(
      {required List<dynamic> teams,
      required String courseCode,
      required String query}) {
    final normalizedQuery = query.toLowerCase();
    return teams.where((team) {
      final code = (team['course'] is Map)
          ? team['course']['courseCode']?.toString()
          : null;
      if (code != courseCode) return false;
      if (normalizedQuery.isEmpty) return true;

      final title = (team['title'] ?? '').toString().toLowerCase();
      final assignedSupervisorName = (team['assignedSupervisor'] is Map)
          ? (team['assignedSupervisor']['name'] ?? '').toString().toLowerCase()
          : '';
      final supervisors = team['supervisors'] as List? ?? [];
      final supervisorMatch = supervisors.any((s) {
        if (s is Map)
          return (s['name'] ?? '').toLowerCase().contains(normalizedQuery);
        return false;
      });

      return title.contains(normalizedQuery) ||
          supervisorMatch ||
          assignedSupervisorName.contains(normalizedQuery);
    }).toList();
  }

  Widget _buildTeamCard(BuildContext context,
      {required int serialNumber,
      required Map<String, dynamic> team,
      required String? myId}) {
    final theme = Theme.of(context);
    final title = team['title'] ?? 'Untitled Team';
    final sups = team['supervisors'] as List? ?? [];

    String supervisorName = 'Not Assigned';
    final assignedSupervisor = team['assignedSupervisor'];
    if (assignedSupervisor is Map) {
      final name = (assignedSupervisor['name'] ?? '').toString().trim();
      if (name.isNotEmpty) supervisorName = name;
    }
    if (supervisorName == 'Not Assigned' && sups.isNotEmpty) {
      final firstSup = sups.first;
      if (firstSup is Map) {
        final name = (firstSup['name'] ?? '').toString().trim();
        if (name.isNotEmpty) supervisorName = name;
      }
    }

    bool isMyTeam = false;
    if (myId != null) {
      final assigned = (team['assignedSupervisor'] is Map)
          ? team['assignedSupervisor']['_id']
          : team['assignedSupervisor'];
      isMyTeam = assigned == myId;
    }

    bool isActionDisabled = !widget.onlyMyTeams && isMyTeam;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.level1,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                serialNumber.toString(),
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "Supervisor: $supervisorName",
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                SupervisorTeamDetailsScreen(team: team)));
                  },
                  child: const Text("Details"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isActionDisabled
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MarkingScreen(
                                    team: team,
                                    evaluationType: widget.onlyMyTeams
                                        ? 'own'
                                        : 'defense')),
                          );
                          setState(() {
                            _teamsFuture = _apiService.getAllProposals();
                          });
                        },
                  icon: Icon(isActionDisabled ? Icons.lock : Icons.edit_note,
                      size: 16),
                  label: Text(isActionDisabled ? "Your Team" : "Evaluate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActionDisabled
                        ? Colors.grey[300]
                        : const Color(0xFFF59E0B),
                    foregroundColor:
                        isActionDisabled ? Colors.grey[600] : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: isActionDisabled ? 0 : 2,
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
