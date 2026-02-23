import 'package:flutter/material.dart';
import 'package:link_unity/api%20services/api_services.dart';
import 'package:provider/provider.dart';


import '../../auth_provider.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading: $e"), backgroundColor: Colors.red));
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
    
    // Config Loading Logic
    final config = _allSettings[_evaluationType] ?? {};
    final c1Name = config['c1']?['name'] ?? 'Criteria 1';
    final c1Max = config['c1']?['max'] ?? 30;
    final c2Name = config['c2']?['name'] ?? 'Criteria 2';
    final c2Max = config['c2']?['max'] ?? 30;

    final isOwn = _evaluationType == 'own';
    final primaryColor = isOwn ? Colors.teal : Colors.deepPurple;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isOwn ? "Supervisor Evaluation (Own)" : "Defense Board Evaluation"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.team['title'] ?? 'Untitled Project', 
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            
            // Info Banner (UI Kept)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCriteriaRow(theme, "Criteria 1", c1Name, c1Max, primaryColor),
                  const SizedBox(height: 8),
                  _buildCriteriaRow(theme, "Criteria 2", c2Name, c2Max, primaryColor),
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

// --- STUDENT MARKING CARD (Strict UI Preservation + Logic Injection) ---
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
    // Handle 0.0 display cleaner
    _c1Controller = TextEditingController(text: widget.marksData['c1'] == 0.0 ? '' : widget.marksData['c1'].toString());
    _c2Controller = TextEditingController(text: widget.marksData['c2'] == 0.0 ? '' : widget.marksData['c2'].toString());
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

    // 🟢 LOGIC INJECTION: Max Marks Enforcement
    if (c1 > widget.maxC1) {
      c1 = widget.maxC1.toDouble();
      _c1Controller.text = c1.toString();
      _c1Controller.selection = TextSelection.fromPosition(TextPosition(offset: _c1Controller.text.length));
    }
    if (c2 > widget.maxC2) {
      c2 = widget.maxC2.toDouble();
      _c2Controller.text = c2.toString();
      _c2Controller.selection = TextSelection.fromPosition(TextPosition(offset: _c2Controller.text.length));
    }

    widget.onChanged({
      'c1': c1,
      'c2': c2,
      'absent': _isAbsent,
      'data': widget.studentData
    });
    
    // Trigger rebuild to show calculated Total
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentName = widget.studentData['name'] ?? 'Unknown Student';
    
    // 🟢 LOGIC INJECTION: Calculate Total
    double total = (double.tryParse(_c1Controller.text) ?? 0) + (double.tryParse(_c2Controller.text) ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  studentName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                // 🟢 LOGIC INJECTION: Display Total (Minimally invasive)
                if (!_isAbsent)
                  Text("Total: ${total.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isAbsent,
                  onChanged: (value) {
                    setState(() {
                      _isAbsent = value ?? false;
                      _updateMarks();
                    });
                  },
                ),
                const Text("Mark as Absent"),
              ],
            ),
            // 🟢 LOGIC INJECTION: Hide/Disable inputs if absent
            if (!_isAbsent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _c1Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Criteria 1 (Max: ${widget.maxC1})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => _updateMarks(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c2Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Criteria 2 (Max: ${widget.maxC2})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => _updateMarks(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}