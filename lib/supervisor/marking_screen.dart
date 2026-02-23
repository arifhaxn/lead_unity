import 'package:flutter/material.dart';
import 'package:link_unity/api%20services/api_services.dart';
import 'package:provider/provider.dart';

import '../../auth_provider.dart';
import '../theme/theme_provider.dart';

class MarkingScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  const MarkingScreen({Key? key, required this.team}) : super(key: key);

  @override
  _MarkingScreenState createState() => _MarkingScreenState();
}

class _MarkingScreenState extends State<MarkingScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _allSettings = {};
  bool _isLoading = true;
  String _evaluationType = 'defense';

  // Marks State: { studentId: { c1: 0, c2: 0, absent: false, data: {} } }
  final Map<String, Map<String, dynamic>> _studentMarks = {};

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMarks();
  }

  _loadSettingsAndMarks() async {
    try {
      // 1. Fetch Settings
      final settings = await _apiService.getEvaluationSettings();
      final myId = Provider.of<AuthProvider>(context, listen: false).user?.id;

      // 2. Determine Type (Own vs Defense)
      String getId(dynamic obj) {
        if (obj is Map) return obj['_id']?.toString() ?? '';
        return obj?.toString() ?? '';
      }

      final sups = widget.team['supervisors'] as List? ?? [];
      final assignedSup = widget.team['assignedSupervisor'];

      bool isMyTeam = false;
      if (myId != null) {
        bool isAssigned = getId(assignedSup) == myId;
        bool isPreferred = sups.any((s) => getId(s) == myId);
        isMyTeam = isAssigned || isPreferred;
      }

      _evaluationType = isMyTeam ? 'own' : 'defense';

      // 3. Load Existing Marks
      final List<dynamic> allMarksList = widget.team['marks'] ?? [];
      Map<String, dynamic> mySavedMarks = {};

      for (var m in allMarksList) {
        // Filter: Marks created by ME for this specific TYPE
        if (m['supervisorId'] == myId && m['type'] == _evaluationType) {
          mySavedMarks[m['studentId']] = m;
        }
      }

      // 4. Initialize Local State
      final members = [...widget.team['teamMembers'] ?? []];

      for (var student in members) {
        String uid = student['studentId'] ?? student['_id'];

        if (mySavedMarks.containsKey(uid)) {
          var saved = mySavedMarks[uid];
          _studentMarks[uid] = {
            'c1': (saved['criteria1'] ?? 0).toDouble(),
            'c2': (saved['criteria2'] ?? 0).toDouble(),
            'absent': saved['isAbsent'] ?? false,
            'data': student
          };
        } else {
          _studentMarks[uid] = {
            'c1': 0.0,
            'c2': 0.0,
            'absent': false,
            'data': student
          };
        }
      }

      if (mounted) {
        setState(() {
          _allSettings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error loading: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitMarks() async {
    setState(() => _isLoading = true);
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
      // 🟢 Logic Update: Send the correct evaluation type
      await _apiService.saveTeamMarks(
          widget.team['_id'], payload, _evaluationType);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Evaluations Saved Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Config Loading Logic
    final config = _allSettings[_evaluationType] ?? {};
    final c1Name = config['c1']?['name'] ?? 'Criteria 1';
    final c1Max = config['c1']?['max'] ?? 30;
    final c2Name = config['c2']?['name'] ?? 'Criteria 2';
    final c2Max = config['c2']?['max'] ?? 30;

    final isOwn = _evaluationType == 'own';
    final primaryColor = theme.colorScheme.primary;
    final cardBorderColor = theme.colorScheme.outline.withOpacity(0.15);
    final cardTopColor = theme.colorScheme.primary.withOpacity(0.20);
    final cardBottomColor = theme.colorScheme.surface.withOpacity(0.80);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Supervisor Evaluation"),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.team['title'] ?? 'Untitled Project',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCriteriaRow(
                      theme, "Criteria 1", c1Name, c1Max, primaryColor),
                  const SizedBox(height: 8),
                  _buildCriteriaRow(
                      theme, "Criteria 2", c2Name, c2Max, primaryColor),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ..._studentMarks.keys.map((uid) {
              return StudentMarkingCard(
                studentData: _studentMarks[uid]!['data'],
                marksData: _studentMarks[uid]!,
                maxC1: c1Max,
                maxC2: c2Max,
                cardTopColor: cardTopColor,
                cardBottomColor: cardBottomColor,
                cardBorderColor: cardBorderColor,
                onChanged: (updatedMarks) {
                  _studentMarks[uid] = updatedMarks;
                },
              );
            }).toList(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitMarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Submit Evaluations",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(
      ThemeData theme, String label, String name, int max, Color accentColor) {
    final isLightMode = theme.brightness == Brightness.light;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label:",
          style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "$name ($max Marks)",
            style: TextStyle(
              color: theme.colorScheme.onSurface
                  .withOpacity(isLightMode ? 0.96 : 1),
            ),
          ),
        ),
      ],
    );
  }
}

// --- STUDENT MARKING CARD (Strict UI Preservation + Logic Injection) ---
class StudentMarkingCard extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final Map<String, dynamic> marksData;
  final int maxC1;
  final int maxC2;
  final Color cardTopColor;
  final Color cardBottomColor;
  final Color cardBorderColor;
  final Function(Map<String, dynamic>) onChanged;

  const StudentMarkingCard({
    Key? key,
    required this.studentData,
    required this.marksData,
    required this.maxC1,
    required this.maxC2,
    required this.cardTopColor,
    required this.cardBottomColor,
    required this.cardBorderColor,
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
    _c1Controller = TextEditingController(
      text: widget.marksData['c1'] == 0.0
          ? ''
          : widget.marksData['c1'].toString(),
    );
    _c2Controller = TextEditingController(
      text: widget.marksData['c2'] == 0.0
          ? ''
          : widget.marksData['c2'].toString(),
    );
  }

  @override
  void dispose() {
    _c1Controller.dispose();
    _c2Controller.dispose();
    super.dispose();
  }

  void _updateMarks() {
    double c1 = double.tryParse(_c1Controller.text) ?? 0.0;
    double c2 = double.tryParse(_c2Controller.text) ?? 0.0;

    if (_isAbsent) {
      c1 = 0.0;
      c2 = 0.0;
    }

    if (c1 > widget.maxC1) {
      c1 = widget.maxC1.toDouble();
      _c1Controller.text = c1.toString();
      _c1Controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _c1Controller.text.length),
      );
    }
    if (c2 > widget.maxC2) {
      c2 = widget.maxC2.toDouble();
      _c2Controller.text = c2.toString();
      _c2Controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _c2Controller.text.length),
      );
    }

    widget.onChanged({
      'c1': c1,
      'c2': c2,
      'absent': _isAbsent,
      'data': widget.studentData,
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final studentName = widget.studentData['name'] ?? 'Unknown Student';
    final studentId = widget.studentData['studentId']?.toString() ??
        widget.studentData['_id']?.toString() ??
        '';

    final c1Value = double.tryParse(_c1Controller.text) ?? 0;
    final c2Value = double.tryParse(_c2Controller.text) ?? 0;
    final total = c1Value + c2Value;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.cardBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(color: widget.cardTopColor),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          studentId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(isLightMode ? 0.88 : 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Switch(
                        value: _isAbsent,
                        onChanged: (value) {
                          setState(() {
                            _isAbsent = value;
                            _updateMarks();
                          });
                        },
                        activeColor: Colors.redAccent,
                        activeTrackColor: Colors.redAccent.withOpacity(0.45),
                      ),
                      Text(
                        'Absent',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(isLightMode ? 0.82 : 0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(color: widget.cardBottomColor),
              child: _isAbsent
                  ? _absentState(context)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final rawBoxWidth =
                            (constraints.maxWidth - (spacing * 2)) / 3;
                        final boxWidth = rawBoxWidth * 0.97;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: boxWidth,
                              child: _scoreBox(
                                context,
                                label: 'Criteria 1',
                                controller: _c1Controller,
                                enabled: true,
                                onChanged: _updateMarks,
                              ),
                            ),
                            SizedBox(
                              width: boxWidth,
                              child: _scoreBox(
                                context,
                                label: 'Criteria 2',
                                controller: _c2Controller,
                                enabled: true,
                                onChanged: _updateMarks,
                              ),
                            ),
                            SizedBox(
                              width: boxWidth,
                              child:
                                  _totalBox(context, total.toStringAsFixed(0)),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _absentState(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    return Container(
      width: double.infinity,
      height: 82,
      decoration: BoxDecoration(
        color: isLightMode
            ? theme.colorScheme.surfaceVariant.withOpacity(0.85)
            : theme.colorScheme.surface.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              theme.colorScheme.outline.withOpacity(isLightMode ? 0.45 : 0.25),
        ),
      ),
      child: Center(
        child: Text(
          'Marked as absent',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }

  Widget _scoreBox(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required VoidCallback onChanged,
  }) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant
            .withOpacity(isLightMode ? 0.96 : 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              theme.colorScheme.outline.withOpacity(isLightMode ? 0.48 : 0.34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface
                    .withOpacity(isLightMode ? 0.9 : 0.76),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface
                      .withOpacity(isLightMode ? 0.98 : 1),
                ),
                decoration: const InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalBox(BuildContext context, String totalValue) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant
            .withOpacity(isLightMode ? 0.96 : 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              theme.colorScheme.outline.withOpacity(isLightMode ? 0.48 : 0.34),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface
                  .withOpacity(isLightMode ? 0.9 : 0.76),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalValue,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface
                  .withOpacity(isLightMode ? 0.98 : 1),
            ),
          ),
        ],
      ),
    );
  }
}
