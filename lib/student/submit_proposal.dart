import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:link_unity/auth_provider.dart';
import 'package:link_unity/api services/api_services.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen>
    with TickerProviderStateMixin {
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
          _tabController = TabController(
              length: _courses.isEmpty ? 1 : _courses.length, vsync: this);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _errorMessage =
              "Failed to load data: ${e.toString().replaceAll('Exception: ', '')}";
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
// 
  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Error'), backgroundColor: Colors.teal),
        body: Center(
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red))),
      );
    }

    if (_courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Submit Proposal'), backgroundColor: Colors.teal),
        body: const Center(child: Text("No courses available.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Proposal'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: _courses
              .map<Widget>((course) => Tab(text: course['courseCode']))
              .toList(),
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
  bool _isSubmitted = false; // 🟢 Tracking successful submission
  bool _hasFourthMember = false;

  String? _preferredSupervisor1Id;
  String? _preferredSupervisor2Id;
  String? _preferredSupervisor3Id;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    for (var map in _memberControllers) {
      map.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_preferredSupervisor1Id == null) {
      _showErrorDialog('Please select at least Supervisor 1.');
      return;
    }

    setState(() => _isSubmitting = true);

    List<String> selectedSupervisors = [];
    if (_preferredSupervisor1Id != null)
      selectedSupervisors.add(_preferredSupervisor1Id!);
    if (_preferredSupervisor2Id != null)
      selectedSupervisors.add(_preferredSupervisor2Id!);
    if (_preferredSupervisor3Id != null)
      selectedSupervisors.add(_preferredSupervisor3Id!);

    List<Map<String, String>> collectedMembers = [];
    Set<String> localIds = {};
    int memberCount = _hasFourthMember ? 4 : 3;

    for (int i = 0; i < memberCount; i++) {
      String id = _memberControllers[i]['id']!.text.trim();
      String name = _memberControllers[i]['name']!.text.trim();
      if (name.isNotEmpty && id.isNotEmpty) {
        if (localIds.contains(id)) {
          setState(() => _isSubmitting = false);
          _showErrorDialog('Duplicate Student ID detected: $id.');
          return;
        }
        localIds.add(id);
        collectedMembers.add({
          'name': name,
          'studentId': id,
          'cgpa': _memberControllers[i]['cgpa']!.text.trim(),
          'email': _memberControllers[i]['email']!.text.trim(),
          'mobile': _memberControllers[i]['mobile']!.text.trim(),
        });
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await _apiService.submitProposal(
        title: _titleController.text.trim(),
        description: _linkController.text.trim(),
        supervisorIds: selectedSupervisors,
        courseId: widget.courseId,
        teamMembers: collectedMembers,
        token: authProvider.token!,
      );

      if (mounted) {
        setState(() {
          _isSubmitted = true; // 🟢 Set to true on success
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Proposal for ${widget.courseCode} submitted!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text("Submission Error", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))
        ],
      ),
    );
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
            Text('Submitting for: ${widget.courseCode}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal)),
            const SizedBox(height: 16),
            TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Project Title', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                    labelText: 'Google Drive Link',
                    border: OutlineInputBorder())),
            const SizedBox(height: 24),

            const Text('Preferred Supervisors (Select 3)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSupervisorDropdown(
                    label: 'Sup 1',
                    value: _preferredSupervisor1Id,
                    onChanged: (val) =>
                        setState(() => _preferredSupervisor1Id = val)),
                const SizedBox(width: 8),
                _buildSupervisorDropdown(
                    label: 'Sup 2',
                    value: _preferredSupervisor2Id,
                    onChanged: (val) =>
                        setState(() => _preferredSupervisor2Id = val)),
                const SizedBox(width: 8),
                _buildSupervisorDropdown(
                    label: 'Sup 3',
                    value: _preferredSupervisor3Id,
                    onChanged: (val) =>
                        setState(() => _preferredSupervisor3Id = val)),
              ],
            ),
            const SizedBox(height: 30),

            const Text('Team Member Details',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey)),
            _buildMemberTile('Member 1 (Leader)', 0, isExpanded: true),
            _buildMemberTile('Member 2', 1),
            _buildMemberTile('Member 3', 2),
            if (_hasFourthMember) _buildMemberTile('Member 4', 3),

            TextButton.icon(
              onPressed: () =>
                  setState(() => _hasFourthMember = !_hasFourthMember),
              icon: Icon(
                  _hasFourthMember ? Icons.group_remove : Icons.group_add,
                  color: _hasFourthMember ? Colors.red : Colors.blue),
              label: Text(
                  _hasFourthMember ? 'Remove 4th Member' : 'Add 4th Member',
                  style: TextStyle(
                      color: _hasFourthMember ? Colors.red : Colors.blue)),
            ),

            const SizedBox(height: 30),

            // 🟢 Replacement Logic
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator())
            else if (_isSubmitted)
              // 🟢 Show message instead of button if submitted
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade400)),
                child: Text(
                  'Proposal Already Submitted for ${widget.courseCode}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.red.shade900, fontWeight: FontWeight.bold),
                ),
              )
            else
              // 🟢 Show Button if not yet submitted
              ElevatedButton.icon(
                onPressed: _submitProposal,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Submit Proposal',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupervisorDropdown(
      {required String label,
      required String? value,
      required ValueChanged<String?> onChanged}) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 10)),
        items: widget.supervisors.map<DropdownMenuItem<String>>((dynamic user) {
          String displayName = user['name'].toString().split(' ').last;
          return DropdownMenuItem<String>(
              value: user['_id'],
              child: Text(displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)));
        }).toList(),
        onChanged: onChanged,
        validator: (val) => (label == 'Sup 1' && val == null) ? '' : null,
      ),
    );
  }

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
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _memberControllers[index]['id'],
                          decoration: const InputDecoration(
                              labelText: 'Student ID',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextFormField(
                          controller: _memberControllers[index]['cgpa'],
                          decoration: const InputDecoration(
                              labelText: 'CGPA', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _memberControllers[index]['email'],
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _memberControllers[index]['mobile'],
                  decoration: const InputDecoration(
                      labelText: 'Mobile', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone),
            ],
          ),
        )
      ],
    );
  }
}
