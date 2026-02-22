import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api services/api_services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  List<dynamic> _courses = [];
  List<dynamic> _supervisors = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _apiService.getCourses(),
        _apiService.getSupervisors(),
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0];
          _supervisors = results[1];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _errorMessage =
              "Failed to load data: ${e.toString().replaceAll('Exception: ', '')}";
        });
      }
    }
  }

  // 🟢 Helper to show the Instructions Dialog
  void _showInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text("How to Submit"),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "• First, select your Target Course from the top dropdown.\n\n"
            "• Provide a valid Google Drive link containing your proposal documents. Ensure the link access is set to 'Anyone with the link'.\n\n"
            "• Select 3 distinct supervisors in your preferred order.\n\n"
            "• Fill in the details for all team members (3 or 4). The first member listed will be designated as the Team Leader.\n\n"
            "• Note: You cannot submit a new proposal if you are already leading an active team.",
            style: TextStyle(height: 1.5),
          ),
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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: themeProvider.toggleTheme,
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: _showInstructions,
            ),
          ],
        ),
        body: Center(
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red))),
      );
    }

    if (_courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Submit Proposal'),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: themeProvider.toggleTheme,
            ),
            IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              onPressed: _showInstructions,
            ),
          ],
        ),
        body: const Center(child: Text("No courses available.")),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Submit Proposal'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          // 🟢 Dark Mode Button First
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
          // 🟢 Info Button Second (Far Right)
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showInstructions,
            tooltip: 'Submission Instructions',
          ),
        ],
      ),
      body: SingleProposalForm(
        courses: _courses,
        supervisors: _supervisors,
      ),
    );
  }
}

class SingleProposalForm extends StatefulWidget {
  final List<dynamic> courses;
  final List<dynamic> supervisors;

  const SingleProposalForm({
    super.key,
    required this.courses,
    required this.supervisors,
  });

  @override
  State<SingleProposalForm> createState() => _SingleProposalFormState();
}

class _SingleProposalFormState extends State<SingleProposalForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? _selectedCourseId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  final List<Map<String, TextEditingController>> _memberControllers =
      List.generate(
          4,
          (index) => {
                'name': TextEditingController(),
                'id': TextEditingController(),
                'cgpa': TextEditingController(),
                'email': TextEditingController(),
                'mobile': TextEditingController(),
              });

  bool _isSubmitting = false;
  bool _hasFourthMember = false;

  String? _sup1, _sup2, _sup3;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    for (var map in _memberControllers) {
      map.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null) {
      _showError('Please select a course at the top of the form.');
      return;
    }

    if (_sup1 == null || _sup2 == null || _sup3 == null) {
      _showError('Please select all 3 supervisor preferences.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final myProposals = await _apiService.getUserProposals();
      if (myProposals.isNotEmpty) {
        _showError(
            'Your account is already leading a team. Use another student account or remove the existing team first.');
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }
    } catch (e) {
      _showError('Could not verify existing teams. Please try again.');
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    List<String> supervisorIds = [];
    if (_sup1 != null) supervisorIds.add(_sup1!);
    if (_sup2 != null) supervisorIds.add(_sup2!);
    if (_sup3 != null) supervisorIds.add(_sup3!);

    List<Map<String, dynamic>> members = [];
    Set<String> uniqueIds = {};
    int count = _hasFourthMember ? 4 : 3;

    for (int i = 0; i < count; i++) {
      String id = _memberControllers[i]['id']!.text.trim();
      String name = _memberControllers[i]['name']!.text.trim();
      String cgpaRaw = _memberControllers[i]['cgpa']!.text.trim();
      String email = _memberControllers[i]['email']!.text.trim();
      String mobile = _memberControllers[i]['mobile']!.text.trim();

      if (id.isEmpty ||
          name.isEmpty ||
          cgpaRaw.isEmpty ||
          email.isEmpty ||
          mobile.isEmpty) {
        setState(() => _isSubmitting = false);
        _showError('Please complete all fields for Member ${i + 1}.');
        return;
      }

      if (uniqueIds.contains(id)) {
        setState(() => _isSubmitting = false);
        _showError('Duplicate Student ID: $id');
        return;
      }

      final cgpa = double.tryParse(cgpaRaw);
      if (cgpa == null) {
        setState(() => _isSubmitting = false);
        _showError('Invalid CGPA for Member ${i + 1}.');
        return;
      }

      uniqueIds.add(id);
      members.add({
        'name': name,
        'studentId': id,
        'cgpa': cgpaRaw,
        'email': email,
        'mobile': mobile,
      });
    }

    try {
      await _apiService.submitProposal({
        'title': _titleController.text.trim(),
        'description': _linkController.text.trim(),
        'courseId': _selectedCourseId!,
        'supervisorIds': supervisorIds,
        'teamMembers': members
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Proposal Submitted Successfully!'),
            backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to Dashboard
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 🟢 Prominent Course Selection Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _selectedCourseId == null
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : Colors.green.withOpacity(0.5),
                    width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedCourseId == null
                            ? Icons.school_rounded
                            : Icons.check_circle_rounded,
                        color: _selectedCourseId == null
                            ? theme.colorScheme.primary
                            : Colors.green,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target Course',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    hint: const Text("Select a course..."),
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) =>
                        value == null ? 'Required to submit' : null,
                    items:
                        widget.courses.map<DropdownMenuItem<String>>((course) {
                      return DropdownMenuItem<String>(
                        value: course['_id'],
                        child: Text(course['courseCode'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCourseId = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Project Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _linkController,
                decoration:
                    const InputDecoration(labelText: 'Google Drive Link'),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 24),

            Text('Select Supervisors',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 10),
            Row(children: [
              _buildSupDropdown(1, _sup1, (v) => setState(() => _sup1 = v)),
              const SizedBox(width: 8),
              _buildSupDropdown(2, _sup2, (v) => setState(() => _sup2 = v)),
              const SizedBox(width: 8),
              _buildSupDropdown(3, _sup3, (v) => setState(() => _sup3 = v)),
            ]),

            const SizedBox(height: 30),
            Text('Team Members',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 10),

            ...List.generate(
                _hasFourthMember ? 4 : 3, (index) => _buildMemberCard(index)),

            if (!_hasFourthMember)
              TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = true),
                icon: const Icon(Icons.add, color: Color(0xFF245E63)),
                label: const Text('Add 4th Member',
                    style: TextStyle(color: Color(0xFF245E63))),
              ),

            if (_hasFourthMember)
              TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = false),
                icon: Icon(Icons.remove, color: theme.colorScheme.error),
                label: Text('Remove 4th Member',
                    style: TextStyle(color: theme.colorScheme.error)),
              ),

            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProposal,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF245E63)),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Proposal',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSupDropdown(
      int index, String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Sup $index',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
        items: widget.supervisors.map<DropdownMenuItem<String>>((s) {
          String name = s['name'].toString().split(' ')[0];
          return DropdownMenuItem(
              value: s['_id'],
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMemberCard(int index) {
    bool isLeader = index == 0;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF245E63),
        borderRadius: AppRadii.card,
        border: Border.all(
            color: isLeader
                ? AppColors.primary.withOpacity(0.5)
                : theme.colorScheme.outline),
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLeader ? "Member 1 (Leader)" : "Member ${index + 1}",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLeader ? Colors.white : Colors.white70),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _memberControllers[index]['name'],
            decoration: const InputDecoration(labelText: 'Name', isDense: true),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextFormField(
              controller: _memberControllers[index]['id'],
              decoration: const InputDecoration(labelText: 'ID', isDense: true),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
              controller: _memberControllers[index]['cgpa'],
              decoration:
                  const InputDecoration(labelText: 'CGPA', isDense: true),
            )),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['email'],
            decoration:
                const InputDecoration(labelText: 'Email', isDense: true),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['mobile'],
            decoration:
                const InputDecoration(labelText: 'Mobile', isDense: true),
          ),
        ],
      ),
    );
  }
}