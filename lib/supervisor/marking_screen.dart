import 'package:flutter/material.dart';
import 'package:link_unity/services/api_services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/animated_submit_button.dart';
import '../widgets/custom_snackbar.dart';

class MarkingScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  final String? evaluationType;
  const MarkingScreen({Key? key, required this.team, this.evaluationType})
      : super(key: key);

  @override
  _MarkingScreenState createState() => _MarkingScreenState();
}

class _MarkingScreenState extends State<MarkingScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _allSettings = {};
  bool _isScreenLoading = true;
  SubmitState _submitState = SubmitState.idle;
  String _evaluationType = 'defense';

  // State mapped by Student ID
  final Map<String, Map<String, dynamic>> _studentMarks = {};

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMarks();
  }

  _loadSettingsAndMarks() async {
    try {
      final settings = await _apiService.getEvaluationSettings();
      final myId = Provider.of<AuthProvider>(context, listen: false).user?.id;

      String getId(dynamic obj) {
        if (obj is Map) return obj['_id']?.toString() ?? '';
        return obj?.toString() ?? '';
      }

      final sups = widget.team['supervisors'] as List? ?? [];
      final assignedSup = widget.team['assignedSupervisor'];

      if (widget.evaluationType != null) {
        _evaluationType = widget.evaluationType!;
      } else {
        bool isMyTeam = false;
        if (myId != null) {
          bool isAssigned = getId(assignedSup) == myId;
          bool isPreferred = sups.any((s) => getId(s) == myId);
          isMyTeam = isAssigned || isPreferred;
        }
        _evaluationType = isMyTeam ? 'own' : 'defense';
      }

      final List<dynamic> allMarksList = widget.team['marks'] ?? [];
      Map<String, dynamic> mySavedMarks = {};

      for (var m in allMarksList) {
        if (m['supervisorId'] == myId && m['type'] == _evaluationType) {
          mySavedMarks[m['studentId']] = m;
        }
      }

      final members = [...widget.team['teamMembers'] ?? []];

      // Helper to cleanly format saved doubles to strings (removes trailing .0)
      String formatMark(dynamic val) {
        if (val == null) return '';
        double numVal = val as double;
        return numVal == numVal.toInt()
            ? numVal.toInt().toString()
            : numVal.toString();
      }

      for (var student in members) {
        String uid = student['studentId'] ?? student['_id'];

        if (mySavedMarks.containsKey(uid)) {
          var saved = mySavedMarks[uid];
          double? c1Val = saved['criteria1'] != null
              ? (saved['criteria1'] as num).toDouble()
              : null;
          double? c2Val = saved['criteria2'] != null
              ? (saved['criteria2'] as num).toDouble()
              : null;

          // Build dynamic per-criterion entries from the saved criteria array
          final savedCriteria = (saved['criteria'] as List?)
                  ?.map<double?>((v) => v != null ? (v as num).toDouble() : null)
                  .toList() ??
              [c1Val, c2Val]; // backward-compat with old c1/c2 fields

          _studentMarks[uid] = {
            'criteria': savedCriteria,
            'criteria_text': savedCriteria
                .map((v) => v != null ? formatMark(v) : '')
                .toList(),
            'absent': saved['isAbsent'] ?? false,
            'data': student
          };
        } else {
          _studentMarks[uid] = {
            'criteria': <double?>[],
            'criteria_text': <String>[],
            'absent': false,
            'data': student
          };
        }
      }

      if (mounted) {
        setState(() {
          _allSettings = settings;
          _isScreenLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
            "Error loading evaluation data: ${e.toString().replaceAll('Exception: ', '')}");
        setState(() => _isScreenLoading = false);
      }
    }
  }

  void _submitMarks() async {
    // Strict validation: every present student must have all criteria filled
    bool hasEmptyBox = false;
    String? missingStudentName;

    for (var entry in _studentMarks.entries) {
      final marks = entry.value;
      if (marks['absent'] == false) {
        final texts = (marks['criteria_text'] as List<String>?) ?? [];
        if (texts.isEmpty || texts.any((t) => t.trim().isEmpty)) {
          hasEmptyBox = true;
          missingStudentName = marks['data']['name'] ?? 'a student';
          break;
        }
      }
    }

    if (hasEmptyBox) {
      CustomSnackBar.showError(
          "Please fill all marks for $missingStudentName, or mark them absent.");
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    List<Map<String, dynamic>> payload = [];

    _studentMarks.forEach((key, value) {
      payload.add({
        'studentId': key,
        'criteria': (value['criteria'] as List?)
            ?.map((v) => (v as double?) ?? 0.0)
            .toList() ?? [],
        'isAbsent': value['absent']
      });
    });

    try {
      await _apiService.saveTeamMarks(
          widget.team['_id'], payload, _evaluationType);

      if (!mounted) return;

      setState(() => _submitState = SubmitState.success);
      CustomSnackBar.showSuccess("Marks submitted successfully!");

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(e.toString().replaceAll('Exception: ', ''));
        setState(() => _submitState = SubmitState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final String teamTitle =
        widget.team['title']?.toString() ?? "Evaluation Board";

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2),
        height: 1.0,
      ),
    );

    if (_isScreenLoading) {
      return _buildSkeletonLoader(
          theme, themeProvider, appBarBottomLine, teamTitle);
    }

    final int totalMarks = (_allSettings['totalMarks'] as int?) ?? 100;
    final List<dynamic> criteriaList =
        (_allSettings[_evaluationType] as List?) ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          teamTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                children: [
                  ...criteriaList.asMap().entries.map((e) {
                    final idx = e.key;
                    final c = e.value as Map;
                    final color = idx % 2 == 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary;
                    return Column(
                      children: [
                        if (idx > 0)
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(height: 1)),
                        _buildCriteriaRow(theme,
                            '${idx + 1}', c['name'], c['max'], color),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Team Members",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._studentMarks.keys.map((uid) {
              return StudentMarkingCard(
                studentData: _studentMarks[uid]!['data'],
                marksData: _studentMarks[uid]!,
                criteriaList: criteriaList,
                totalMarks: totalMarks,
                onChanged: (updatedMarks) {
                  _studentMarks[uid] = updatedMarks;
                },
              );
            }).toList(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedSubmitButton(
                state: _submitState,
                title: "Submit Scores",
                onPressed: _submitMarks,
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(
      ThemeData theme, String number, String name, int max, Color accentColor) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(
            child: Text("C$number",
                style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10)),
          child: Text(
            "Max: $max",
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme, ThemeProvider themeProvider,
      PreferredSizeWidget appBarBottomLine, String teamTitle) {
    final isDark = themeProvider.isDarkMode;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(teamTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: theme.colorScheme.onSurfaceVariant),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 110,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 32),
              Container(
                  height: 24,
                  width: 140,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              ...List.generate(
                  3,
                  (index) => Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      height: 170,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)))),
              const SizedBox(height: 20),
              Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- STUDENT MARKING CARD ---
class StudentMarkingCard extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final Map<String, dynamic> marksData;
  final List<dynamic> criteriaList; // [{name, max}, ...]
  final int totalMarks;
  final Function(Map<String, dynamic>) onChanged;

  const StudentMarkingCard({
    Key? key,
    required this.studentData,
    required this.marksData,
    required this.criteriaList,
    required this.totalMarks,
    required this.onChanged,
  }) : super(key: key);

  @override
  _StudentMarkingCardState createState() => _StudentMarkingCardState();
}

class _StudentMarkingCardState extends State<StudentMarkingCard> {
  late List<TextEditingController> _controllers;
  late bool _isAbsent;

  @override
  void initState() {
    super.initState();
    _isAbsent = widget.marksData['absent'] ?? false;

    final texts =
        (widget.marksData['criteria_text'] as List?)?.cast<String>() ?? [];
    final n = widget.criteriaList.length;

    // Ensure we have exactly n controllers, padding with empty if needed
    _controllers = List.generate(
      n,
      (i) => TextEditingController(text: i < texts.length ? texts[i] : ''),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateMarks() {
    final n = widget.criteriaList.length;
    final List<double?> values = [];
    final List<String> textValues = [];

    for (int i = 0; i < n; i++) {
      if (_isAbsent) {
        values.add(0.0);
        textValues.add('0');
      } else {
        final int maxVal = (widget.criteriaList[i]['max'] as num).toInt();
        final text = _controllers[i].text.trim();
        double? val = text.isEmpty ? null : double.tryParse(text);

        // Clamp to max
        if (val != null && val > maxVal) {
          val = maxVal.toDouble();
          _controllers[i].text = val.toStringAsFixed(0);
          _controllers[i].selection = TextSelection.fromPosition(
              TextPosition(offset: _controllers[i].text.length));
        }
        values.add(val);
        textValues.add(_controllers[i].text);
      }
    }

    widget.onChanged({
      'criteria': values,
      'criteria_text': textValues,
      'absent': _isAbsent,
      'data': widget.studentData,
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentName = widget.studentData['name'] ?? 'Unknown Student';
    final studentId = widget.studentData['studentId']?.toString() ??
        widget.studentData['_id']?.toString() ??
        '';
    final initials =
        studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';

    // Running total across all non-absent criteria
    double total = 0;
    for (final c in _controllers) {
      total += double.tryParse(c.text) ?? 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
        border: Border.all(
            color: _isAbsent
                ? Colors.redAccent.withOpacity(0.3)
                : theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // ── Student header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _isAbsent
                      ? Colors.redAccent.withOpacity(0.1)
                      : theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    initials,
                    style: TextStyle(
                        color: _isAbsent
                            ? Colors.redAccent
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration:
                                _isAbsent ? TextDecoration.lineThrough : null),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentId,
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Absent toggle
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAbsent = !_isAbsent;
                      if (_isAbsent) {
                        for (final c in _controllers) {
                          c.clear();
                        }
                      }
                      _updateMarks();
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isAbsent
                              ? Colors.green.withOpacity(0.1)
                              : Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isAbsent
                                ? Colors.green.withOpacity(0.5)
                                : Colors.redAccent.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                                scale: animation, child: child);
                          },
                          child: Icon(
                            _isAbsent
                                ? Icons.settings_backup_restore_rounded
                                : Icons.person_off_rounded,
                            key: ValueKey<bool>(_isAbsent),
                            size: 18,
                            color:
                                _isAbsent ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              _isAbsent ? Colors.green : Colors.redAccent,
                        ),
                        child:
                            Text(_isAbsent ? "Mark Present" : "Mark Absent"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Score inputs ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAbsent
                  ? Colors.redAccent.withOpacity(0.02)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: _isAbsent
                ? _buildAbsentBadge()
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // One input box per criterion
                      ...widget.criteriaList.asMap().entries.map((e) {
                        final idx = e.key;
                        final label = 'C${idx + 1}';
                        final maxVal =
                            (e.value['max'] as num).toInt();
                        return SizedBox(
                          width: 80,
                          child: _buildDigitalInput(
                              context, label, _controllers[idx], maxVal),
                        );
                      }).toList(),
                      // Total box
                      SizedBox(
                        width: 80,
                        child: _buildTotalBox(context, total),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsentBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_off_rounded, color: Colors.redAccent, size: 20),
          SizedBox(width: 8),
          Text("SCORES LOCKED (ABSENT)",
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildDigitalInput(BuildContext context, String label,
      TextEditingController controller, int max) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant)),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface),
            decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none),
            onChanged: (_) => _updateMarks(),
          ),
          Text('/$max',
              style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildTotalBox(BuildContext context, double total) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("TOTAL",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70)),
          const SizedBox(height: 4),
          Text(total.toStringAsFixed(0),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text("/${widget.totalMarks}",
              style: TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}