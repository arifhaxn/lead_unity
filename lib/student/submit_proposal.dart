import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../api services/api_services.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> with TickerProviderStateMixin {
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

  Future<void> _fetchData() async {
    // 🟢 Fix: Using your friend's logic, the token is auto-injected by Dio.
    // We don't need to manually pass it.
    try {
      final results = await Future.wait([
        _apiService.getCourses(),
        _apiService.getSupervisors(), // 🟢 Auto-uses token from storage
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0];
          _supervisors = results[1];
          _isLoadingData = false;
          _tabController = TabController(length: _courses.isEmpty ? 1 : _courses.length, vsync: this);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = "Failed to load data: ${e.toString().replaceAll('Exception: ', '')}";
          _tabController = TabController(length: 1, vsync: this);
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
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.teal),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (_courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Submit Proposal'), backgroundColor: Colors.teal),
        body: const Center(child: Text("No courses available.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Submit Proposal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: _courses.map<Widget>((course) => Tab(text: course['courseCode'])).toList(),
        ),
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

  // 🟢 Fixed: Using simple maps for member data, matching your friend's "Map<String, String>" logic
  final List<Map<String, TextEditingController>> _memberControllers = List.generate(
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
    
    // 🟢 Logic Check: Ensure at least one supervisor is selected
    if (_sup1 == null) {
      _showError('Please select at least Supervisor 1.');
      return;
    }

    setState(() => _isSubmitting = true);

    // 🟢 1. Collect Supervisor IDs
    List<String> supervisorIds = [];
    if (_sup1 != null) supervisorIds.add(_sup1!);
    if (_sup2 != null) supervisorIds.add(_sup2!);
    if (_sup3 != null) supervisorIds.add(_sup3!);

    // 🟢 2. Collect Member Data
    List<Map<String, String>> members = [];
    Set<String> uniqueIds = {};
    int count = _hasFourthMember ? 4 : 3;

    for (int i = 0; i < count; i++) {
      String id = _memberControllers[i]['id']!.text.trim();
      String name = _memberControllers[i]['name']!.text.trim();
      
      if (id.isNotEmpty && name.isNotEmpty) {
        if (uniqueIds.contains(id)) {
           setState(() => _isSubmitting = false);
           _showError('Duplicate Student ID: $id');
           return;
        }
        uniqueIds.add(id);
        members.add({
          'name': name,
          'studentId': id,
          'cgpa': _memberControllers[i]['cgpa']!.text.trim(),
          'email': _memberControllers[i]['email']!.text.trim(),
          'mobile': _memberControllers[i]['mobile']!.text.trim(),
        });
      }
    }

    try {
      // 🟢 3. Call API (Token is auto-injected by ApiService)
      await _apiService.submitProposal({
        'title': _titleController.text.trim(),
        'description': _linkController.text.trim(),
        'courseId': widget.courseId,
        'supervisorIds': supervisorIds,
        'teamMembers': members
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal Submitted Successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to Dashboard
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
            TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'Google Drive Link', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 24),
            
            const Text('Select Supervisors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            Row(children: [
              _buildSupDropdown(1, _sup1, (v) => setState(() => _sup1 = v)),
              const SizedBox(width: 8),
              _buildSupDropdown(2, _sup2, (v) => setState(() => _sup2 = v)),
              const SizedBox(width: 8),
              _buildSupDropdown(3, _sup3, (v) => setState(() => _sup3 = v)),
            ]),
            
            const SizedBox(height: 30),
            const Text('Team Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 10),
            
            ...List.generate(_hasFourthMember ? 4 : 3, (index) => _buildMemberCard(index)),

            if (!_hasFourthMember)
              TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = true),
                icon: const Icon(Icons.add, color: Colors.teal),
                label: const Text('Add 4th Member', style: TextStyle(color: Colors.teal)),
              ),
            
            if (_hasFourthMember)
               TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = false),
                icon: const Icon(Icons.remove, color: Colors.red),
                label: const Text('Remove 4th Member', style: TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitProposal,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Submit Proposal', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSupDropdown(int index, String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Sup $index',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          filled: true,
          fillColor: Colors.white
        ),
        items: widget.supervisors.map<DropdownMenuItem<String>>((s) {
           // Helper to get first name only for small dropdown
           String name = s['name'].toString().split(' ')[0]; 
           return DropdownMenuItem(value: s['_id'], child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMemberCard(int index) {
    bool isLeader = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLeader ? Colors.teal.withOpacity(0.5) : Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isLeader ? "Member 1 (Leader)" : "Member ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: isLeader ? Colors.teal : Colors.grey[700])),
          const SizedBox(height: 10),
          TextFormField(
            controller: _memberControllers[index]['name'],
            decoration: const InputDecoration(labelText: 'Name', isDense: true, border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          Row(children: [
             Expanded(child: TextFormField(
               controller: _memberControllers[index]['id'],
               decoration: const InputDecoration(labelText: 'ID', isDense: true, border: OutlineInputBorder()),
               validator: (v) => v!.isEmpty ? 'Required' : null,
             )),
             const SizedBox(width: 8),
             Expanded(child: TextFormField(
               controller: _memberControllers[index]['cgpa'],
               decoration: const InputDecoration(labelText: 'CGPA', isDense: true, border: OutlineInputBorder()),
             )),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['email'],
            decoration: const InputDecoration(labelText: 'Email', isDense: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['mobile'],
            decoration: const InputDecoration(labelText: 'Mobile', isDense: true, border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}