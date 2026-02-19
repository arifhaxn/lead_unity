import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api services/api_services.dart';
import '../auth_provider.dart';
import '../theme/app_theme.dart';

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
  String _evaluationType = 'defense'; // Default to defense
  
  // Marks State: { studentId: { c1: 0, c2: 0, absent: false, data: {} } }
  final Map<String, Map<String, dynamic>> _studentMarks = {};

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMarks();
  }

  _loadSettingsAndMarks() async {
    try {
      // 1. Fetch ALL Criteria Settings
      final settings = await _apiService.getEvaluationSettings();
      final myId = Provider.of<AuthProvider>(context, listen: false).user?.id;

      // 2. Determine Evaluation Type (Own Team vs Defense Board)
      final sups = widget.team['supervisors'] as List? ?? [];
      final assignedSup = widget.team['assignedSupervisor'] ?? widget.team['assignedSupervisorId'];
      
      bool isMyTeam = false;
      if (myId != null) {
        bool inSupervisorsList = sups.any((s) => (s is Map ? s['_id'] : s) == myId);
        bool isAssigned = (assignedSup is Map ? assignedSup['_id'] : assignedSup) == myId;
        isMyTeam = inSupervisorsList || isAssigned;
      }

      _evaluationType = isMyTeam ? 'own' : 'defense';

      // 3. Load Marks specific to THIS supervisor AND THIS type
      final List<dynamic> allMarksList = widget.team['marks'] ?? [];
      Map<String, dynamic> mySavedMarks = {};

      for (var m in allMarksList) {
        if (m['supervisorId'] == myId && m['type'] == _evaluationType) {
          mySavedMarks[m['studentId']] = m;
        }
      }

      // 4. Initialize Local State for Team Members ONLY
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
      // 🟢 Pass the evaluation type ('own' or 'defense') to the API
      await _apiService.saveTeamMarks(widget.team['_id'], payload, _evaluationType);
      
      if(mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evaluations Saved Successfully"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    
    // Get correct config based on type
    final config = _allSettings[_evaluationType] ?? {};
    final c1Name = config['c1']?['name'] ?? 'Criteria 1';
    final c1Max = config['c1']?['max'] ?? 30;
    final c2Name = config['c2']?['name'] ?? 'Criteria 2';
    final c2Max = config['c2']?['max'] ?? 30;

    final isOwn = _evaluationType == 'own';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isOwn ? "Supervisor Evaluation" : "Defense Evaluation"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Text(
              widget.team['title'] ?? 'Untitled Project', 
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            
            // Criteria Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOwn ? Colors.teal.withOpacity(0.1) : Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOwn ? Colors.teal.withOpacity(0.3) : Colors.deepPurple.withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCriteriaRow(theme, "Criteria 1", c1Name, c1Max, isOwn ? Colors.teal : Colors.deepPurple),
                  const SizedBox(height: 8),
                  _buildCriteriaRow(theme, "Criteria 2", c2Name, c2Max, isOwn ? Colors.teal : Colors.deepPurple),
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
                  backgroundColor: isOwn ? Colors.teal : Colors.deepPurple, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Submit Evaluations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildCriteriaRow(ThemeData theme, String label, String name, int max, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
        Expanded(child: Text("$name ($max Marks)", style: TextStyle(color: theme.colorScheme.onSurface))),
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
    _c1Ctrl.text = widget.marksData['c1'] == 0.0 ? '' : widget.marksData['c1'].toString();
    _c2Ctrl.text = widget.marksData['c2'] == 0.0 ? '' : widget.marksData['c2'].toString();
  }

  void _update() {
    double c1 = double.tryParse(_c1Ctrl.text) ?? 0;
    double c2 = double.tryParse(_c2Ctrl.text) ?? 0;

    if (c1 > widget.maxC1) { 
      c1 = widget.maxC1.toDouble(); 
      _c1Ctrl.text = c1.toString(); 
      _c1Ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _c1Ctrl.text.length));
    }
    if (c2 > widget.maxC2) { 
      c2 = widget.maxC2.toDouble(); 
      _c2Ctrl.text = c2.toString(); 
      _c2Ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _c2Ctrl.text.length));
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
    double total = (double.tryParse(_c1Ctrl.text) ?? 0) + (double.tryParse(_c2Ctrl.text) ?? 0);
    String name = widget.studentData['name'] ?? 'Unknown';
    String id = widget.studentData['studentId'] ?? widget.studentData['_id'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.level1,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(id, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                Column(
                  children: [
                    Switch(
                      value: _isAbsent,
                      activeColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() => _isAbsent = val);
                        _update();
                      },
                    ),
                    Text("Absent", style: TextStyle(fontSize: 10, color: _isAbsent ? Colors.red : Colors.grey)),
                  ],
                )
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isAbsent ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text("Marked as Absent", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _buildInputBox(theme, "Criteria 1", _c1Ctrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputBox(theme, "Criteria 2", _c2Ctrl)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3))
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Total", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(total.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  Widget _buildInputBox(ThemeData theme, String label, TextEditingController ctrl) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (_) => _update(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
      ),
    );
  }
}