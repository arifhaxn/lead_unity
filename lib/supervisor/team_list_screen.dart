import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_unity/supervisor/sup_team_details.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  List<dynamic>? _cachedRawTeams;
  List<dynamic> _processedTeams = [];
  List<String> _courseTabs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).fetchTeamsIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _processDataIfNeeded(List<dynamic>? rawTeams, String? myId) {
    if (rawTeams == null) return;
    if (_cachedRawTeams == rawTeams) return;

    _cachedRawTeams = rawTeams;
    var teams = List.from(rawTeams);

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

    // Updated Sorting Logic: Sort by Defense Schedule
    teams.sort((a, b) {
      if (a['defenseDate'] == null && b['defenseDate'] == null) return 0;
      if (a['defenseDate'] == null) return 1;
      if (b['defenseDate'] == null) return -1;

      DateTime dateA = DateTime.parse(a['defenseDate']);
      DateTime dateB = DateTime.parse(b['defenseDate']);
      return dateA.compareTo(dateB);
    });

    _processedTeams = teams;
    _courseTabs = _extractCourseTabs(_processedTeams);
  }

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
    final dataProvider = Provider.of<DataProvider>(context);
    final myId = authProvider.user?.id;
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    _processDataIfNeeded(dataProvider.allTeams, myId);

    // Identify Next Team ID
    final now = DateTime.now();
    String? nextTeamId;
    try {
      nextTeamId = _processedTeams.firstWhere((t) {
        if (t['defenseEndDate'] == null) return false;
        return DateTime.parse(t['defenseEndDate']).toLocal().isAfter(now);
      })['_id'];
    } catch (_) {
      nextTeamId = null;
    }

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
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showInstructions,
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          if (dataProvider.isLoadingTeams && dataProvider.allTeams == null) {
            return _buildSkeletonLoader(theme);
          }

          if (_processedTeams.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  dataProvider.fetchTeamsIfNeeded(forceRefresh: true),
              color: theme.colorScheme.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("No approved teams found.")),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: _courseTabs.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseTabs(context, _courseTabs),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
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
                    children: _courseTabs.map((courseCode) {
                      final filtered = _filterTeams(
                          teams: _processedTeams,
                          courseCode: courseCode,
                          query: _searchQuery);

                      if (filtered.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => dataProvider.fetchTeamsIfNeeded(
                              forceRefresh: true),
                          color: theme.colorScheme.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                  child: Text("No teams match your filter.")),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            dataProvider.fetchTeamsIfNeeded(forceRefresh: true),
                        color: theme.colorScheme.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final team = filtered[index];
                            final teamMap = team as Map<String, dynamic>;
                            final isNext = teamMap['_id'] == nextTeamId;

                            return _buildTeamCard(
                              context,
                              serialNumber: teamMap['serialNumber'] ?? (index + 1),
                              team: teamMap,
                              myId: myId,
                              dataProvider: dataProvider,
                              isNext: isNext,
                            );
                          },
                        ),
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

  Widget _buildCourseTabs(BuildContext context, List<String> courseTabs) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      color: theme.colorScheme.surface,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.center,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        tabs: courseTabs
            .map((c) => Tab(
                height: 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                )))
            .toList(),
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                    height: 30,
                    width: 80,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                    height: 30,
                    width: 80,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _teamKey(Map<String, dynamic> team) {
    final key =
        (team['_id'] ?? team['id'] ?? team['proposalId'] ?? '').toString();
    if (key.isNotEmpty) return key;
    final title = (team['title'] ?? '').toString();
    final createdAt =
        (team['createdAt'] ?? team['submittedAt'] ?? '').toString();
    return '$title|$createdAt';
  }

  List<String> _extractCourseTabs(List<dynamic> teams) {
    final courseCodes = <String>{};
    for (final team in teams) {
      if (team['course'] is Map && team['course']['courseCode'] != null) {
        courseCodes.add(team['course']['courseCode'].toString());
      }
    }
    return courseCodes.toList()..sort();
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
      final supervisorMatch = supervisors.any((s) =>
          s is Map &&
          (s['name'] ?? '').toLowerCase().contains(normalizedQuery));
      return title.contains(normalizedQuery) ||
          supervisorMatch ||
          assignedSupervisorName.contains(normalizedQuery);
    }).toList();
  }

  bool _hasSubmittedEvaluation(
      Map<String, dynamic> team, String? myId, String evaluationType) {
    if (myId == null || myId.isEmpty) return false;
    final marks = team['marks'] as List? ?? [];
    for (final mark in marks) {
      if (mark is! Map) continue;
      final supervisorId =
          (mark['supervisorId'] ?? mark['supervisor'] ?? '').toString();
      final type = (mark['type'] ?? '').toString().toLowerCase().trim();
      if (supervisorId == myId && type == evaluationType) return true;
    }
    return false;
  }

  Widget _buildTeamCard(BuildContext context,
      {required int serialNumber,
      required Map<String, dynamic> team,
      required String? myId,
      required DataProvider dataProvider,
      required bool isNext}) {
    final theme = Theme.of(context);
    final title = team['title'] ?? 'Untitled Team';
    String supervisorName = 'Not Assigned';
    final assignedSupervisor = team['assignedSupervisor'];
    if (assignedSupervisor is Map)
      supervisorName = (assignedSupervisor['name'] ?? '').toString().trim();

    bool isMyTeam = false;
    if (myId != null) {
      final assigned = (team['assignedSupervisor'] is Map)
          ? team['assignedSupervisor']['_id']
          : team['assignedSupervisor'];
      isMyTeam = assigned == myId;
    }
    bool isActionDisabled = !widget.onlyMyTeams && isMyTeam;
    final evaluationType = widget.onlyMyTeams ? 'own' : 'defense';
    final hasSubmitted = _hasSubmittedEvaluation(team, myId, evaluationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isNext ? theme.colorScheme.primary.withOpacity(0.05) : theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.level1,
        border: Border.all(
          color: isNext ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isNext ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.1),
              child: Text(serialNumber.toString(),
                  style: TextStyle(
                      color: isNext ? Colors.white : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("NEXT", 
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Text("Supervisor: $supervisorName",
                style: TextStyle(
                    fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasSubmitted ? const Color(0xFF16A34A) : null,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: hasSubmitted
                        ? const Color(0xFF16A34A)
                        : theme.colorScheme.outline.withOpacity(0.8),
                    width: 1.6),
              ),
              child: hasSubmitted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              SupervisorTeamDetailsScreen(team: team))),
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
                                      evaluationType: evaluationType)));
                          dataProvider.fetchTeamsIfNeeded(forceRefresh: true);
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