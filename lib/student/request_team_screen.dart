import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api services/api_services.dart';
import '../chatbot_screen.dart';
import '../theme/theme_provider.dart';

class RequestTeamScreen extends StatefulWidget {
  const RequestTeamScreen({super.key});

  @override
  State<RequestTeamScreen> createState() => _RequestTeamScreenState();
}

class _RequestTeamScreenState extends State<RequestTeamScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  List<dynamic> _courses = [];
  List<dynamic> _supervisors = [];

  String? _selectedCourseId;
  String? _sup1;
  String? _sup2;
  String? _sup3;

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _cgpaController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _apiService.getCourses(),
        _apiService.getSupervisors(),
      ]);

      if (!mounted) return;
      setState(() {
        _courses = results[0];
        _supervisors = results[1];
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingData = false;
        _errorMessage =
            "Failed to load form data: ${e.toString().replaceAll('Exception: ', '')}";
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null) {
      _showError('Please select a target course.');
      return;
    }

    if (_sup1 == null || _sup2 == null || _sup3 == null) {
      _showError('Please select all 3 supervisors.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final myProposals = await _apiService.getUserProposals();
      if (myProposals.isNotEmpty) {
        _showError(
            'Your account is already leading a team. Remove existing team first.');
        if (mounted) setState(() => _isSubmitting = false);
        return;
      }
    } catch (_) {
      _showError('Could not verify existing teams. Please try again.');
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    try {
      final member = {
        'name': _nameController.text.trim(),
        'studentId': _idController.text.trim(),
        'cgpa': _cgpaController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
      };

      await _apiService.submitProposal({
        'title': 'Team Request - ${_nameController.text.trim()}',
        'description': 'Requested via Request Team form',
        'courseId': _selectedCourseId,
        'supervisorIds': [_sup1, _sup2, _sup3],
        'teamMembers': [member],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Team request submitted successfully.'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
          title: const Text('Request Team'),
          actions: [
            IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
              onPressed: themeProvider.toggleTheme,
            ),
          ],
        ),
        body: Center(
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Request Team'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.message, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school_rounded,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Target Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      hint: const Text('Select a course...'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          value == null ? 'Required to submit' : null,
                      items: _courses.map<DropdownMenuItem<String>>((course) {
                        return DropdownMenuItem<String>(
                          value: course['_id'],
                          child: Text((course['courseCode'] ?? '').toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCourseId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Supervisors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSupDropdown(1, _sup1, (value) {
                    setState(() => _sup1 = value);
                  }),
                  const SizedBox(width: 8),
                  _buildSupDropdown(2, _sup2, (value) {
                    setState(() => _sup2 = value);
                  }),
                  const SizedBox(width: 8),
                  _buildSupDropdown(3, _sup3, (value) {
                    setState(() => _sup3 = value);
                  }),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Team Member',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.35)),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Name'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _idController,
                            decoration: const InputDecoration(hintText: 'ID'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _cgpaController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(hintText: 'CGPA'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return double.tryParse(value.trim()) == null
                                  ? 'Invalid'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Email'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Required';
                        if (!text.contains('@')) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Mobile'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF245E63),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        items: _supervisors.map<DropdownMenuItem<String>>((s) {
          final abbreviation = [
            s['abbreviation'],
            s['abbr'],
            s['shortName'],
            s['initial'],
          ].whereType<String>().map((v) => v.trim()).firstWhere(
                (v) => v.isNotEmpty,
                orElse: () => '',
              );

          return DropdownMenuItem<String>(
            value: s['_id']?.toString(),
            child: Text(abbreviation.isEmpty ? 'N/A' : abbreviation),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
