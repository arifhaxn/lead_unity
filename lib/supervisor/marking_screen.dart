import 'package:flutter/material.dart';
import 'package:link_unity/api%20services/api_services.dart';
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

          _studentMarks[uid] = {
            'c1': c1Val,
            'c2': c2Val,
            'c1_text': formatMark(c1Val), // Store visual text representation
            'c2_text': formatMark(c2Val), // Store visual text representation
            'absent': saved['isAbsent'] ?? false,
            'data': student
          };
        } else {
          _studentMarks[uid] = {
            'c1': null,
            'c2': null,
            'c1_text': '', // Guaranteed physically empty string
            'c2_text': '',
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
    // 🟢 STRICT VALIDATION: Check the literal text string, not just the parsed number
    bool hasEmptyBox = false;
    String? missingStudentName;

    for (var entry in _studentMarks.entries) {
      final marks = entry.value;
      if (marks['absent'] == false) {
        String c1Text = (marks['c1_text'] ?? '').toString().trim();
        String c2Text = (marks['c2_text'] ?? '').toString().trim();

        if (c1Text.isEmpty || c2Text.isEmpty) {
          hasEmptyBox = true;
          missingStudentName = marks['data']['name'] ?? 'a student';
          break;
        }
      }
    }

    if (hasEmptyBox) {
      CustomSnackBar.showError(
          "Please fill all marks for $missingStudentName, or mark them absent.");
      return; // 🛑 HARD STOP: Submission blocked
    }

    setState(() => _submitState = SubmitState.loading);

    List<Map<String, dynamic>> payload = [];

    _studentMarks.forEach((key, value) {
      payload.add({
        'studentId': key,
        'criteria1': value['c1'],
        'criteria2': value['c2'],
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

    final config = _allSettings[_evaluationType] ?? {};
    final c1Name = config['c1']?['name'] ?? 'Criteria 1';
    final c1Max = config['c1']?['max'] ?? 30;
    final c2Name = config['c2']?['name'] ?? 'Criteria 2';
    final c2Max = config['c2']?['max'] ?? 30;

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
                  _buildCriteriaRow(
                      theme, "1", c1Name, c1Max, theme.colorScheme.primary),
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1)),
                  _buildCriteriaRow(
                      theme, "2", c2Name, c2Max, theme.colorScheme.secondary),
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
                maxC1: c1Max,
                maxC2: c2Max,
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
  final int maxC1;
  final int maxC2;
  final Function(Map<String, dynamic>) onChanged;

  const StudentMarkingCard({
    Key? key,
    required this.studentData,
    required this.marksData,
    required this.maxC1,
    required this.maxC2,
    required this.onChanged,
  }) : super(key: key);

  @override
  _StudentMarkingCardState createState() => _StudentMarkingCardState();
}

class _StudentMarkingCardState extends State<StudentMarkingCard> {
  late TextEditingController _c1Controller;
  late TextEditingController _c2Controller;
  late bool _isAbsent;

  @override
  void initState() {
    super.initState();
    _isAbsent = widget.marksData['absent'] ?? false;

    // Initialize text fields with the explicit string passed from parent
    _c1Controller =
        TextEditingController(text: widget.marksData['c1_text'] ?? '');
    _c2Controller =
        TextEditingController(text: widget.marksData['c2_text'] ?? '');
  }

  @override
  void dispose() {
    _c1Controller.dispose();
    _c2Controller.dispose();
    super.dispose();
  }

  void _updateMarks() {
    double? c1;
    if (_c1Controller.text.trim().isNotEmpty) {
      c1 = double.tryParse(_c1Controller.text);
    }

    double? c2;
    if (_c2Controller.text.trim().isNotEmpty) {
      c2 = double.tryParse(_c2Controller.text);
    }

    if (_isAbsent) {
      c1 = 0.0;
      c2 = 0.0;
    } else {
      if (c1 != null && c1 > widget.maxC1) {
        c1 = widget.maxC1.toDouble();
        _c1Controller.text = c1.toStringAsFixed(0);
        _c1Controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _c1Controller.text.length));
      }
      if (c2 != null && c2 > widget.maxC2) {
        c2 = widget.maxC2.toDouble();
        _c2Controller.text = c2.toStringAsFixed(0);
        _c2Controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _c2Controller.text.length));
      }
    }

    // 🟢 Send the literal string back to the parent to ensure validation works
    widget.onChanged({
      'c1': c1,
      'c2': c2,
      'c1_text': _isAbsent ? '0' : _c1Controller.text,
      'c2_text': _isAbsent ? '0' : _c2Controller.text,
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

    final c1Value = double.tryParse(_c1Controller.text) ?? 0;
    final c2Value = double.tryParse(_c2Controller.text) ?? 0;
    final total = c1Value + c2Value;

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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAbsent = !_isAbsent;
                      if (_isAbsent) {
                        _c1Controller.clear();
                        _c2Controller.clear();
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
                            color: _isAbsent ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isAbsent ? Colors.green : Colors.redAccent,
                        ),
                        child: Text(_isAbsent ? "Mark Present" : "Mark Absent"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                : Row(
                    children: [
                      Expanded(
                          child: _buildDigitalInput(
                              context, 'C1', _c1Controller, widget.maxC1)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildDigitalInput(
                              context, 'C2', _c2Controller, widget.maxC2)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTotalBox(context, total)),
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
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        ],
      ),
    );
  }
}
