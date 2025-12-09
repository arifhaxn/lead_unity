// lib/student/submit_proposal_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:link_unity/auth_provider.dart'; 
import 'package:link_unity/api services/api_services.dart'; 

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> with TickerProviderStateMixin {
  // Data holders
  List<dynamic> _courses = [];
  List<dynamic> _supervisors = [];
  bool _isLoadingData = true;
  String? _errorMessage;

  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetch Courses and Supervisors concurrently
  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = "Authentication error. Please log in again.";
      });
      return;
    }

    try {
      final results = await Future.wait([
        _apiService.getCourses(),
        _apiService.getSupervisors(token),
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0]; 
          _supervisors = results[1];
          _isLoadingData = false;
          // Initialize TabController based on number of courses
          _tabController = TabController(length: _courses.isEmpty ? 1 : _courses.length, vsync: this);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = "Failed to load data: ${e.toString().replaceAll('Exception: ', '')}";
          _tabController = TabController(length: 1, vsync: this); // Fallback
        });
      }
    }
  }

  @override
  void dispose() {
    if (!_isLoadingData) _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Error State
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.teal),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    // 3. Empty State
    if (_courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Submit Proposal'), backgroundColor: Colors.teal),
        body: const Center(child: Text("No courses available for proposal submission.")),
      );
    }

    // 4. Main Content
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Proposal'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _courses.map<Widget>((course) {
            return Tab(text: course['courseCode']); 
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proposal Submission Guidelines.')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _courses.map((course) {
          return SingleProposalForm(
            courseId: course['_id'], 
            courseCode: course['courseCode'], 
            supervisors: _supervisors, 
          );
        }).toList(),
      ),
    );
  }
}

// --- Proposal Form Widget ---
class SingleProposalForm extends StatefulWidget {
  final String courseId;
  final String courseCode;
  final List<dynamic> supervisors;

  const SingleProposalForm({
    super.key, 
    required this.courseId,
    required this.courseCode,
    required this.supervisors,
  });

  @override
  State<SingleProposalForm> createState() => _SingleProposalFormState();
}

class _SingleProposalFormState extends State<SingleProposalForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  
  // List of Maps containing controllers for 4 potential members
  final List<Map<String, TextEditingController>> _memberControllers = List.generate(4, (index) => {
    'name': TextEditingController(),
    'id': TextEditingController(),
    'cgpa': TextEditingController(),
    'email': TextEditingController(),
    'mobile': TextEditingController(),
  });

  bool _isSubmitting = false;
  bool _hasFourthMember = false;

  // Supervisor Selection
  String? _preferredSupervisor1Id;
  String? _preferredSupervisor2Id;
  String? _preferredSupervisor3Id;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    // Dispose all member controllers
    for (var map in _memberControllers) {
      map.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }
  
  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_preferredSupervisor1Id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Supervisor 1.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    // 1. Collect Team Member Data
    List<Map<String, String>> collectedMembers = [];
    int memberCount = _hasFourthMember ? 4 : 3;

    for (int i = 0; i < memberCount; i++) {
      // Only add if Name and ID are provided
      if (_memberControllers[i]['name']!.text.isNotEmpty && _memberControllers[i]['id']!.text.isNotEmpty) {
        collectedMembers.add({
          'name': _memberControllers[i]['name']!.text,
          'studentId': _memberControllers[i]['id']!.text,
          'cgpa': _memberControllers[i]['cgpa']!.text,
          'email': _memberControllers[i]['email']!.text,
          'mobile': _memberControllers[i]['mobile']!.text,
        });
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 2. Call API
      await _apiService.submitProposal(
        title: _titleController.text,
        description: _linkController.text,
        supervisorId: _preferredSupervisor1Id!,
        courseId: widget.courseId,
        teamMembers: collectedMembers,
        token: authProvider.token!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proposal for ${widget.courseCode} submitted!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Submitting for: ${widget.courseCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
            ),
            const SizedBox(height: 16),

            // --- Title ---
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project or Thesis Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Title is required.' : null,
            ),
            const SizedBox(height: 16),

            // --- Link ---
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Proposal Google Drive Link',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Drive link is required.' : null,
            ),
            const SizedBox(height: 8),
             const Text(
              'Before sharing the link, give view access to anyone with the link.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- Supervisor Dropdowns ---
            const Text(
              'Preferred Supervisors (Select 3)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSupervisorDropdown(
                  label: 'Sup 1', 
                  value: _preferredSupervisor1Id, 
                  onChanged: (val) => setState(() => _preferredSupervisor1Id = val),
                ),
                const SizedBox(width: 8),
                _buildSupervisorDropdown(
                  label: 'Sup 2', 
                  value: _preferredSupervisor2Id, 
                  onChanged: (val) => setState(() => _preferredSupervisor2Id = val),
                ),
                const SizedBox(width: 8),
                _buildSupervisorDropdown(
                  label: 'Sup 3', 
                  value: _preferredSupervisor3Id, 
                  onChanged: (val) => setState(() => _preferredSupervisor3Id = val),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Members Section ---
            const Text('Team Member Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 10),
            
            _buildMemberTile('Details of Member - 1 (You)', 0, isExpanded: true),
            _buildMemberTile('Details of Member - 2', 1),
            _buildMemberTile('Details of Member - 3', 2),
            
            if (_hasFourthMember)
               _buildMemberTile('Details of Member - 4', 3),

            if (!_hasFourthMember)
              TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = true),
                icon: const Icon(Icons.group_add, color: Colors.blue),
                label: const Text('Add 4th Member', style: TextStyle(color: Colors.blue)),
              )
            else 
              TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = false),
                icon: const Icon(Icons.group_remove, color: Colors.red),
                label: const Text('Remove 4th Member', style: TextStyle(color: Colors.red)),
              ),
              
            const SizedBox(height: 30),

            // --- Submit Button ---
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submitProposal,
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('Submit Proposal', style: TextStyle(color: Colors.white, fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Helper: Dropdown
  Widget _buildSupervisorDropdown({required String label, required String? value, required ValueChanged<String?> onChanged}) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        isExpanded: true,
        items: widget.supervisors.map<DropdownMenuItem<String>>((dynamic user) {
          // Display last name / initial
          String displayName = user['name'].toString().split(' ').last; 
          return DropdownMenuItem<String>(
            value: user['_id'], 
            child: Text(
              displayName, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (val) {
          if (label == 'Sup 1' && val == null) return ''; 
          return null;
        },
      ),
    );
  }

  // Helper: Member Input Tile
  Widget _buildMemberTile(String title, int index, {bool isExpanded = false}) {
    return ExpansionTile(
      title: Text(title),
      initiallyExpanded: isExpanded,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              TextFormField(
                controller: _memberControllers[index]['name'],
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _memberControllers[index]['id'],
                      decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _memberControllers[index]['cgpa'],
                      decoration: const InputDecoration(labelText: 'CGPA', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _memberControllers[index]['email'],
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _memberControllers[index]['mobile'],
                decoration: const InputDecoration(labelText: 'Mobile', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        )
      ],
    );
  }
}