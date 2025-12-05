import 'package:flutter/material.dart';
// import '../auth_provider.dart'; // Already used via provider
// import '../api services/api_services.dart'; // Already used via provider

// NOTE: I'm merging the code into one file for simplicity, 
// assuming you'll put this in lib/student/submit_proposal_screen.dart

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> with SingleTickerProviderStateMixin {
  // Placeholder Course Codes (Admin should provide these)
  final List<String> _courseCodes = ['CSE-3240', 'CSE-4800', 'SWE-4999']; 
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _courseCodes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _courseCodes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Submit Proposal'),
          backgroundColor: Colors.teal,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: _courseCodes.map((code) => Tab(text: code)).toList(),
          ),
          actions: [
            // Info Button (Mimicking the screenshot)
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
          children: _courseCodes.map((code) {
            return SingleProposalForm(courseCode: code);
          }).toList(),
        ),
      ),
    );
  }
}

// --- Proposal Form Widget ---
class SingleProposalForm extends StatefulWidget {
  final String courseCode;
  const SingleProposalForm({super.key, required this.courseCode});

  @override
  State<SingleProposalForm> createState() => _SingleProposalFormState();
}

class _SingleProposalFormState extends State<SingleProposalForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  
  bool _isLoading = false;
  
  // 🟢 Supervisor Selection
  String? _preferredSupervisor1;
  String? _preferredSupervisor2;
  String? _preferredSupervisor3;
  
  // 🛑 Dummy Supervisor Initials (Replace with API fetched data)
  final List<String> _dummySupervisors = ['Dr. AFZ', 'Engr. AHQ', 'Prof. AMD', 'Mr. RJK', 'Ms. TSL'];

  // 🟢 Member Details (Currently placeholders for form fields)
  // In a real app, this data (Name, ID, CGPA, etc.) should be stored in a list 
  // of custom objects (e.g., List<ProposalMember>) and fetched from a source 
  // (e.g., AuthProvider for the current user, or an API for teammates).
  final List<Map<String, String?>> _teamMembers = [
    // Member 1 (Current Logged-in User)
    {'name': 'Student Name', 'id': '018231XXXXXXXXXX', 'cgpa': '0.00', 'email': 'name@example.edu', 'mobile': '01XXXXXXXXX'}, 
    // Member 2 (Currently empty/placeholder)
    {'name': null, 'id': null, 'cgpa': null, 'email': null, 'mobile': null},
    // Member 3 (Currently empty/placeholder)
    {'name': null, 'id': null, 'cgpa': null, 'email': null, 'mobile': null},
  ];
  
  // 🟢 State for the optional 4th member
  bool _hasFourthMember = false;


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if at least one supervisor is selected
    if (_preferredSupervisor1 == null) {
      _showError('Please select at least one preferred supervisor.');
      return;
    }
    
    // ... submission logic ...
    
    // For demo purposes, we skip the actual API call for now.
    setState(() { _isLoading = true; });
    await Future.delayed(const Duration(seconds: 2));
    _showSuccess('Proposal for ${widget.courseCode} submitted successfully!');
    setState(() { _isLoading = false; });
    Navigator.pop(context);
  }

  // 🟢 Helper to build the member details form fields
  Widget _buildMemberDetailsForm(int index) {
    // This is a static UI based on your second screenshot. 
    // In a real app, these fields should be pre-filled/disabled if the data exists.
    final memberData = _teamMembers[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Name Field
          _buildReadOnlyField(
            label: 'Name', 
            initialValue: memberData['name'] ?? 'Not Selected',
          ),
          const SizedBox(height: 10),
          
          // Student ID & CGPA (Two fields in one row)
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  label: 'Student ID', 
                  initialValue: memberData['id'] ?? 'N/A',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildReadOnlyField(
                  label: 'CGPA', 
                  initialValue: memberData['cgpa'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Email Field
          _buildReadOnlyField(
            label: 'Email', 
            initialValue: memberData['email'] ?? 'N/A',
          ),
          const SizedBox(height: 10),

          // Mobile Field
          _buildReadOnlyField(
            label: 'Mobile', 
            initialValue: memberData['mobile'] ?? 'N/A',
          ),
        ],
      ),
    );
  }
  
  // Helper for read-only display fields
  Widget _buildReadOnlyField({required String label, required String initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
      style: const TextStyle(color: Colors.black87),
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
            Text(
              'Submitting for: ${widget.courseCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal),
            ),
            const SizedBox(height: 16),

            // --- Project/Thesis Title Field ---
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project or Thesis Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Title is required.' : null,
            ),
            const SizedBox(height: 16),

            // --- Proposal Google Drive Link Field ---
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Proposal Google Drive Link',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Drive link is required.' : null,
            ),
            
            const SizedBox(height: 8),
            const Text(
              'Before sharing the link, give view access to anyone with the link.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- Supervisor Preference Dropdowns (3 in one row) ---
            const Text(
              'Preferred Supervisors (Select 3)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSupervisorDropdown(
                    label: 'Supervisor 1', 
                    value: _preferredSupervisor1, 
                    onChanged: (val) => setState(() => _preferredSupervisor1 = val), 
                    items: _dummySupervisors
                ),
                const SizedBox(width: 8),
                _buildSupervisorDropdown(
                    label: 'Supervisor 2', 
                    value: _preferredSupervisor2, 
                    onChanged: (val) => setState(() => _preferredSupervisor2 = val), 
                    items: _dummySupervisors
                ),
                const SizedBox(width: 8),
                _buildSupervisorDropdown(
                    label: 'Supervisor 3', 
                    value: _preferredSupervisor3, 
                    onChanged: (val) => setState(() => _preferredSupervisor3 = val), 
                    items: _dummySupervisors
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Member Details Section ---
            const Text(
              'Team Member Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),
            
            // Member 1 (The current user)
            ExpansionTile(
              title: const Text('Details of Member - 1 (You)'),
              initiallyExpanded: true,
              children: [_buildMemberDetailsForm(0)],
            ),
            
            // Member 2
            ExpansionTile(
              title: const Text('Details of Member - 2'),
              children: [_buildMemberDetailsForm(1)],
            ),
            
            // Member 3
            ExpansionTile(
              title: const Text('Details of Member - 3'),
              children: [_buildMemberDetailsForm(2)],
            ),
            
            // 🟢 Optional 4th Member Section
            if (_hasFourthMember)
              const ExpansionTile(
                title: Text('Details of Member - 4'),
                children: [
                  // Placeholder for 4th member details (add a 4th dummy member map if needed)
                   Padding(padding: EdgeInsets.all(16.0), child: Text('Member 4 details will be fetched here.')),
                ],
              ),
              
            const SizedBox(height: 10),
            
            // 🟢 Add 4th Member Button
            if (!_hasFourthMember)
              TextButton.icon(
                onPressed: () => setState(() => _hasFourthMember = true),
                icon: const Icon(Icons.group_add, color: Colors.blue),
                label: const Text('Add 4th Member (Optional)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              )
            else 
              TextButton.icon(
                onPressed: () {
                   // 🛑 NOTE: In a real app, you'd clear the data for member 4 before setting to false.
                   setState(() => _hasFourthMember = false);
                },
                icon: const Icon(Icons.group_remove, color: Colors.red),
                label: const Text('Remove 4th Member', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              
            const SizedBox(height: 30),


            // --- Submit Button ---
            _isLoading
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
            const SizedBox(height: 20),

            // --- Error/Status Banner (Mimicking the screenshot) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade400)
              ),
              child: Text(
                'Proposal Already Submitted for ${widget.courseCode}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 🟢 Helper for the supervisor selection dropdowns
  Widget _buildSupervisorDropdown({required String label, required String? value, required ValueChanged<String?> onChanged, required List<String> items}) {
    // Items are like 'Dr. AFZ', but we only want to show 'AFZ' in the field.
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          // hintText: label, // We don't want a label/hint due to the space constraints in a Row of 3
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        hint: Text(label.split(' ')[0]), // Display just "Supervisor"
        items: items.map((String supervisor) {
          // Display only the initials (last word of the string) in the menu
          final initials = supervisor.split(' ').last;
          return DropdownMenuItem<String>(
            value: supervisor,
            child: Text(initials), 
          );
        }).toList(),
        onChanged: onChanged,
        // Validator: Check if this is the first supervisor and is required
        validator: (val) {
          if (label == 'Supervisor 1' && val == null) {
            return ''; // Minimal validator message for the first required field
          }
          return null;
        },
      ),
    );
  }
}