import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 🟢 No need for Provider to get token anymore
import '../api services/api_services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class MarkingScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  const MarkingScreen({Key? key, required this.team}) : super(key: key);

  @override
  _MarkingScreenState createState() => _MarkingScreenState();
}

class _MarkingScreenState extends State<MarkingScreen> {
  Map<String, dynamic>? _settings;
  bool _isLoading = true;

  // Marks State: { studentId: { c1: 0, c2: 0, absent: false, data: {} } }
  final Map<String, Map<String, dynamic>> _studentMarks = {};
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMarks();
  }

  _loadSettingsAndMarks() async {
    try {
      // 🟢 1. Fetch Criteria Settings (Token auto-injected)
      final s = await _apiService.getEvaluationSettings();

      // 2. Map Existing Saved Marks (if any)
      final List<dynamic> existingMarksList = widget.team['marks'] ?? [];
      Map<String, dynamic> existingMarksMap = {};
      for (var m in existingMarksList) {
        existingMarksMap[m['studentId']] = m;
      }

      // 3. Get ONLY Team Members
      final allStudents = [...widget.team['teamMembers']];

      // 4. Initialize Local State
      for (var student in allStudents) {
        String uid = student['studentId'] ?? student['_id'];

        if (existingMarksMap.containsKey(uid)) {
          // Load Saved Data
          var saved = existingMarksMap[uid];
          _studentMarks[uid] = {
            'c1': (saved['criteria1'] ?? 0).toDouble(),
            'c2': (saved['criteria2'] ?? 0).toDouble(),
            'absent': saved['isAbsent'] ?? false,
            'data': student
          };
        } else {
          // New Entry
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
          _settings = s;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading settings: $e")));
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
      // 🟢 Token auto-injected. No need to pass it.
      await _apiService.saveTeamMarks(widget.team['_id'], payload);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Evaluations Saved Successfully"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final c1Name =
        _settings?['criteria1']['name'] ?? 'Problem Definition, Design & Viva';
    final c1Max = _settings?['criteria1']['max'] ?? 30;
    final c2Name =
        _settings?['criteria2']['name'] ?? 'Presentation, Testing & Report';
    final c2Max = _settings?['criteria2']['max'] ?? 30;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.team['title'] ?? 'Untitled Project'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadii.card,
                  border: Border.all(color: theme.colorScheme.outline),
                  boxShadow: AppShadows.level1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCriteriaRow("Criteria - 1", c1Name, c1Max),
                  const SizedBox(height: 8),
                  _buildCriteriaRow("Criteria - 2", c2Name, c2Max),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Marking Cards
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
              height: 56,
              child: ElevatedButton(
                onPressed: _submitMarks,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.button)),
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

  Widget _buildCriteriaRow(String label, String name, int max) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary)),
        Expanded(
          child: Text(
            "$name ($max)",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// --- ISOLATED WIDGET FOR MARKING CARD ---
class StudentMarkingCard extends StatefulWidget {
  final dynamic studentData;
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
  late bool _isAbsent;
  final _c1Ctrl = TextEditingController();
  final _c2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isAbsent = widget.marksData['absent'];
    _c1Ctrl.text =
        widget.marksData['c1'] == 0.0 ? '' : widget.marksData['c1'].toString();
    _c2Ctrl.text =
        widget.marksData['c2'] == 0.0 ? '' : widget.marksData['c2'].toString();
  }

  void _update() {
    double c1 = double.tryParse(_c1Ctrl.text) ?? 0;
    double c2 = double.tryParse(_c2Ctrl.text) ?? 0;

    if (c1 > widget.maxC1) {
      c1 = widget.maxC1.toDouble();
      _c1Ctrl.text = c1.toString();
      _c1Ctrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _c1Ctrl.text.length));
    }
    if (c2 > widget.maxC2) {
      c2 = widget.maxC2.toDouble();
      _c2Ctrl.text = c2.toString();
      _c2Ctrl.selection =
          TextSelection.fromPosition(TextPosition(offset: _c2Ctrl.text.length));
    }

    widget.onChanged({
      'data': widget.marksData['data'],
      'c1': c1,
      'c2': c2,
      'absent': _isAbsent
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double total = (double.tryParse(_c1Ctrl.text) ?? 0) +
        (double.tryParse(_c2Ctrl.text) ?? 0);
    String name = widget.studentData['name'] ?? 'Unknown';
    String id =
        widget.studentData['studentId'] ?? widget.studentData['_id'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.level1,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentTeal.withOpacity(0.6),
                  AppColors.accentTeal.withOpacity(0.25),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary)),
                    Text(id,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Marks as Absent",
                      style: TextStyle(
                          fontSize: 11,
                          color: _isAbsent
                              ? AppColors.accentCoral
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Switch(
                      value: _isAbsent,
                      activeColor: AppColors.accentCoral,
                      onChanged: (val) {
                        setState(() => _isAbsent = val);
                        _update();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isAbsent
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                      child: _buildInputBox("Criteria - 1", _c1Ctrl,
                          enabled: !_isAbsent)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildInputBox("Criteria - 2", _c2Ctrl,
                          enabled: !_isAbsent)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: AppRadii.input,
                          border: Border.all(color: theme.colorScheme.outline)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Total",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant)),
                          Text(total.toStringAsFixed(0),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController ctrl,
      {required bool enabled}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: AppRadii.input,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        enabled: enabled,
        onChanged: (_) => _update(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
      ),
    );
  }
}
