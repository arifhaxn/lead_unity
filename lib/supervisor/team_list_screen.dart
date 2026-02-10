import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api services/api_services.dart';
import '../../auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    // 🟢 1. Get Auth Data (ID only, token handled by Service)
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
          )
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        // 🟢 2. Call API directly (No token argument needed)
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          var teams = snapshot.data ?? [];

          teams = teams.where((t) {
            final status = t['status']?.toString().toUpperCase() ?? '';
            final assignedId = _getAssignedSupervisorId(t);
            return status == 'APPROVED' && assignedId != null;
          }).toList();

          teams.sort((a, b) => _compareByCreatedAt(a, b));

          final stableIndexById = <String, int>{};
          for (int i = 0; i < teams.length; i++) {
            final id = _getTeamId(teams[i]);
            if (id != null) {
              stableIndexById[id] = i + 1;
            }
          }

          // 🟢 3. Filter Logic
          if (widget.onlyMyTeams && myId != null) {
            teams = teams
                .where((t) => _getAssignedSupervisorId(t) == myId)
                .toList();
          }

          if (teams.isEmpty) {
            return const Center(child: Text("No teams found."));
          }

          final courseTabs = _extractCourseTabs(teams);

          return DefaultTabController(
            length: courseTabs.length,
            child: Column(
              children: [
                _buildCourseTabs(context, courseTabs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 250),
                        () => setState(() => _searchQuery = v.trim()),
                      );
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by supervisor, title, ID or name',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary),
                      ),
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

                      if (filtered.isEmpty) {
                        return const Center(child: Text("No teams found."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final team = filtered[index];
                          final title = team['title'] ?? 'Untitled Team';
                          final supervisorName =
                              _getAssignedSupervisorName(team);

                          final indexToShow =
                              stableIndexById[_getTeamId(team)] ?? index + 1;

                          return _buildTeamCard(
                            context,
                            index: indexToShow,
                            title: title,
                            supervisorName: supervisorName,
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
    );
  }

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
        indicatorColor: theme.colorScheme.primary,
        tabs: courseTabs.map((c) => Tab(text: c)).toList(),
      ),
    );
  }

  List<dynamic> _filterTeams({
    required List<dynamic> teams,
    required String courseCode,
    required String query,
  }) {
    final normalizedQuery = query.toLowerCase();

    return teams.where((team) {
      if (courseCode != 'All') {
        final code = (team['course'] is Map)
            ? team['course']['courseCode']?.toString()
            : null;
        if (code == null || code != courseCode) return false;
      }

      if (normalizedQuery.isEmpty) return true;

      final title = (team['title'] ?? '').toString().toLowerCase();
      final assignedSupervisor =
          (_getAssignedSupervisorName(team) ?? '').toLowerCase();
      final supervisorMatch = assignedSupervisor.contains(normalizedQuery);

      return title.contains(normalizedQuery) || supervisorMatch;
    }).toList();
  }

  Widget _buildTeamCard(
    BuildContext context, {
    required int index,
    required String title,
    required String? supervisorName,
    required Map<String, dynamic> team,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentTeal.withOpacity(0.18),
            theme.colorScheme.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.level1,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: _buildIndexBadge(context, index),
        title: Text(title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
        subtitle: Text(
          'Supervisor: ${supervisorName ?? 'N/A'}',
          style: TextStyle(
              fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.level1,
          ),
          child: Icon(
            _hasMarks(team)
                ? Icons.assignment_turned_in_rounded
                : Icons.assignment_turned_in_outlined,
            size: 18,
            color: _hasMarks(team)
                ? AppColors.accentTeal
                : theme.colorScheme.primary,
          ),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MarkingScreen(team: team)),
          );
          if (!mounted) return;
          setState(() {
            _teamsFuture = _apiService.getAllProposals();
          });
        },
      ),
    );
  }

  Widget _buildIndexBadge(BuildContext context, int index) {
    final theme = Theme.of(context);
    return Container(
      height: 34,
      width: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: AppShadows.level1,
      ),
      child: Text(
        index.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  String? _getAssignedSupervisorId(Map<String, dynamic> team) {
    final assigned = team['assignedSupervisor'] ??
        team['assignedSupervisorId'] ??
        team['assignedSupervisorID'];

    if (assigned is Map) {
      return (assigned['_id'] ?? assigned['id'])?.toString();
    }
    if (assigned is String) return assigned;
    return null;
  }

  String? _getAssignedSupervisorName(Map<String, dynamic> team) {
    final assigned = team['assignedSupervisor'] ??
        team['assignedSupervisorId'] ??
        team['assignedSupervisorID'];

    if (assigned is Map) {
      final name = assigned['name'] ?? assigned['fullName'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    return null;
  }

  bool _hasMarks(Map<String, dynamic> team) {
    final marks = team['marks'] as List?;
    return marks != null && marks.isNotEmpty;
  }

  String? _getTeamId(Map<String, dynamic> team) {
    final id = team['_id'] ?? team['id'];
    return id?.toString();
  }

  DateTime? _getCreatedAt(Map<String, dynamic> team) {
    final raw = team['createdAt'] ?? team['created_at'];
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  int _compareByCreatedAt(Map<String, dynamic> a, Map<String, dynamic> b) {
    final da = _getCreatedAt(a);
    final db = _getCreatedAt(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }
}
