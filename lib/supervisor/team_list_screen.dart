import 'dart:async';
import 'package:flutter/material.dart';
import 'package:link_unity/supervisor/sup_team_details.dart';
import 'package:link_unity/widgets/animated_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart'; 
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
    var teams = rawTeams;

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

    _processedTeams = [...teams]..sort((a, b) =>
        _submissionTime(a as Map<String, dynamic>)
            .compareTo(_submissionTime(b as Map<String, dynamic>)));

    _courseTabs = _extractCourseTabs(_processedTeams);
  }

  void _showInstructions() {
    final title = widget.onlyMyTeams ? "Personal Marking" : "Defense Board Marking";
    final content = widget.onlyMyTeams
        ? "This list contains only the teams directly assigned to you. Use this section to provide your personal marking and evaluate your own students."
        : "This list contains all registered teams. Use this section to evaluate and mark teams as an external member during a Defense Board.";

    showAnimatedDialog(
      context: context,
      dialog: AlertDialog(
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
            onPressed: () => Navigator.pop(context), 
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
              onRefresh: () => dataProvider.fetchTeamsIfNeeded(forceRefresh: true),
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
                      hintText: 'Search by title or ID',
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
                      final courseOrdered = _getTeamsForCourse(_processedTeams, courseCode);

                      final serialByTeamKeyInCourse = <String, int>{
                        for (int i = 0; i < courseOrdered.length; i++)
                          _teamKey(courseOrdered[i] as Map<String, dynamic>): i + 1,
                      };

                      final normalizedQuery = _searchQuery.toLowerCase();
                      
                      // 🟢 THE CORRECTED GOD-MODE SEARCH LOGIC
                      final filteredWithCardId = courseOrdered.where((team) {
                        if (normalizedQuery.isEmpty) return true;

                        final teamMap = team as Map<String, dynamic>;
                        final serial = serialByTeamKeyInCourse[_teamKey(teamMap)] ?? 0;
                        
                        // 1. Explicitly grab Title
                        final title = (teamMap['title'] ?? '').toString().toLowerCase();
                        
                        // 2. Explicitly grab Assigned Supervisor
                        String supName = '';
                        if (teamMap['assignedSupervisor'] is Map) {
                          supName = (teamMap['assignedSupervisor']['name'] ?? '').toString().toLowerCase();
                        }
                        
                        // 3. Explicitly grab Secondary Supervisors
                        String otherSups = '';
                        if (teamMap['supervisors'] is List) {
                          for (var s in teamMap['supervisors']) {
                            if (s is Map) {
                              otherSups += (s['name'] ?? '').toString().toLowerCase() + ' ';
                            }
                          }
                        }

                        // 4. Combine them perfectly into one giant searchable string
                        final searchableString = "$title $supName $otherSups team $serial #$serial $serial".replaceAll(RegExp(r'\s+'), ' ');

                        // 5. Split query by spaces to allow searching things like "John 3"
                        final searchTerms = normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();
                        
                        // 6. Check if EVERY word the user typed exists in the searchable string
                        return searchTerms.every((term) => searchableString.contains(term));
                      }).toList();

                      if (filteredWithCardId.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => dataProvider.fetchTeamsIfNeeded(forceRefresh: true),
                          color: theme.colorScheme.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text("No teams match your filter.")),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => dataProvider.fetchTeamsIfNeeded(forceRefresh: true),
                        color: theme.colorScheme.primary,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            itemCount: filteredWithCardId.length,
                            itemBuilder: (context, index) {
                              final team = filteredWithCardId[index];
                              final teamMap = team as Map<String, dynamic>;
                              final serial =
                                  serialByTeamKeyInCourse[_teamKey(teamMap)] ??
                                      (index + 1);

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildTeamCard(
                                      context,
                                      serialNumber: serial,
                                      team: teamMap,
                                      myId: myId,
                                      dataProvider: dataProvider, 
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ))
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
                child: Container(height: 30, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(height: 30, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
    final key = (team['_id'] ?? team['id'] ?? team['proposalId'] ?? '').toString();
    if (key.isNotEmpty) return key;
    final title = (team['title'] ?? '').toString();
    final createdAt = (team['createdAt'] ?? team['submittedAt'] ?? '').toString();
    return '$title|$createdAt';
  }

  DateTime _submissionTime(Map<String, dynamic> team) {
    final raw = (team['createdAt'] ?? team['submittedAt'] ?? team['created_at'] ?? '').toString();
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
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

  List<dynamic> _getTeamsForCourse(List<dynamic> teams, String courseCode) {
    return teams.where((team) {
      final code = (team['course'] is Map) ? team['course']['courseCode']?.toString() : null;
      return code == courseCode;
    }).toList();
  }

  bool _hasSubmittedEvaluation(Map<String, dynamic> team, String? myId, String evaluationType) {
    if (myId == null || myId.isEmpty) return false;
    final marks = team['marks'] as List? ?? [];
    for (final mark in marks) {
      if (mark is! Map) continue;
      final supervisorId = (mark['supervisorId'] ?? mark['supervisor'] ?? '').toString();
      final type = (mark['type'] ?? '').toString().toLowerCase().trim();
      if (supervisorId == myId && type == evaluationType) return true;
    }
    return false;
  }

  Widget _buildTeamCard(BuildContext context, {required int serialNumber, required Map<String, dynamic> team, required String? myId, required DataProvider dataProvider}) { 
    final theme = Theme.of(context);
    final title = team['title'] ?? 'Untitled Team';
    String supervisorName = 'Not Assigned';
    final assignedSupervisor = team['assignedSupervisor'];
    if (assignedSupervisor is Map) supervisorName = (assignedSupervisor['name'] ?? '').toString().trim();
    
    final uniqueTag = 'team_title_${team['_id'] ?? team['title']}';

    bool isMyTeam = false;
    if (myId != null) {
      final assigned = (team['assignedSupervisor'] is Map) ? team['assignedSupervisor']['_id'] : team['assignedSupervisor'];
      isMyTeam = assigned == myId;
    }
    bool isActionDisabled = !widget.onlyMyTeams && isMyTeam;
    final evaluationType = widget.onlyMyTeams ? 'own' : 'defense';
    final hasSubmitted = _hasSubmittedEvaluation(team, myId, evaluationType);

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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(serialNumber.toString(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Hero(
              tag: uniqueTag, 
              child: Material(
                color: Colors.transparent,
                child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            subtitle: Text("Supervisor: $supervisorName", style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            trailing: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: hasSubmitted ? const Color(0xFF16A34A) : null,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: hasSubmitted ? const Color(0xFF16A34A) : theme.colorScheme.outline.withOpacity(0.8), width: 1.6),
              ),
              child: hasSubmitted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorTeamDetailsScreen(team: team))),
                  child: const Text("Details"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isActionDisabled ? null : () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => MarkingScreen(team: team, evaluationType: evaluationType)));
                    dataProvider.fetchTeamsIfNeeded(forceRefresh: true);
                  },
                  icon: Icon(isActionDisabled ? Icons.lock : Icons.edit_note, size: 16),
                  label: Text(isActionDisabled ? "Your Team" : "Evaluate"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActionDisabled ? Colors.grey[300] : const Color(0xFFF59E0B),
                    foregroundColor: isActionDisabled ? Colors.grey[600] : Colors.white,
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