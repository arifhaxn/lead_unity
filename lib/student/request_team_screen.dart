import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/animated_submit_button.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../api services/api_services.dart';
import '../theme/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/custom_snackbar.dart'; 

class RequestTeamScreen extends StatefulWidget {
  const RequestTeamScreen({super.key});

  @override
  State<RequestTeamScreen> createState() => _RequestTeamScreenState();
}

class _RequestTeamScreenState extends State<RequestTeamScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // 🟢 NEW: Title and Link controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  // 🟢 NEW: Member controllers converted to a list of maps (Max 2 members for Request)
  final List<Map<String, TextEditingController>> _memberControllers = List.generate(
    2,
    (index) => {
      'name': TextEditingController(),
      'id': TextEditingController(),
      'cgpa': TextEditingController(),
      'email': TextEditingController(),
      'mobile': TextEditingController(),
    },
  );

  String? _selectedCourseId;
  String? _sup1, _sup2, _sup3;

  SubmitState _submitState = SubmitState.idle;
  String? _errorMessage;
  bool _showSecondMember = false; // 🟢 Controls the visibility of the 2nd member card

  @override
  void initState() {
    super.initState();

    // 1. Auto-fill user data instantly into Member 1's card
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _memberControllers[0]['name']!.text = user.name;
      _memberControllers[0]['id']!.text = user.studentId ?? '';
      _memberControllers[0]['email']!.text = user.email;
    }

    // 2. Trigger background fetches from DataProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchCoursesIfNeeded();
      dp.fetchSupervisorsIfNeeded();
      dp.fetchMyProposalsIfNeeded(); 
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    for (var map in _memberControllers) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null) {
      CustomSnackBar.showError('Please select a target course.');
      return;
    }

    if (_sup1 == null || _sup2 == null || _sup3 == null) {
      CustomSnackBar.showError('Please select all 3 supervisors.');
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    final dp = Provider.of<DataProvider>(context, listen: false);

    // Instant Check: Use cached proposals instead of making a new API call
    if (dp.myProposals != null && dp.myProposals!.isNotEmpty) {
      CustomSnackBar.showError('Your account is already in a team. Remove existing team first.');
      setState(() => _submitState = SubmitState.idle);
      return;
    }

    // 🟢 Process members based on whether 1 or 2 are shown
    List<Map<String, dynamic>> members = [];
    int memberCount = _showSecondMember ? 2 : 1;
    Set<String> uniqueIds = {};

    for (int i = 0; i < memberCount; i++) {
      String id = _memberControllers[i]['id']!.text.trim();
      String name = _memberControllers[i]['name']!.text.trim();
      String cgpaRaw = _memberControllers[i]['cgpa']!.text.trim();
      String email = _memberControllers[i]['email']!.text.trim();
      String mobile = _memberControllers[i]['mobile']!.text.trim();

      if (id.isEmpty || name.isEmpty || cgpaRaw.isEmpty || email.isEmpty || mobile.isEmpty) {
        setState(() => _submitState = SubmitState.idle);
        CustomSnackBar.showError('Please complete all fields for Member ${i + 1}.');
        return;
      }

      if (uniqueIds.contains(id)) {
        setState(() => _submitState = SubmitState.idle);
        CustomSnackBar.showError('Duplicate Student ID: $id');
        return;
      }

      final cgpa = double.tryParse(cgpaRaw);
      if (cgpa == null) {
        setState(() => _submitState = SubmitState.idle);
        CustomSnackBar.showError('Invalid CGPA for Member ${i + 1}.');
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
        'courseId': _selectedCourseId,
        'supervisorIds': [_sup1, _sup2, _sup3],
        'teamMembers': members,
        'status': 'pending', // 🟢 Forces the 'Pending' status upon submission
      });

      if (!mounted) return;

      // Force a background refresh so the dashboard shows the new request immediately
      dp.fetchMyProposalsIfNeeded(forceRefresh: true);
      dp.fetchTeamsIfNeeded(forceRefresh: true);

      // Success Animation
      setState(() => _submitState = SubmitState.success);
      
      CustomSnackBar.showSuccess('Team request submitted successfully.');

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitState = SubmitState.idle);
      CustomSnackBar.showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dp = Provider.of<DataProvider>(context); 

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2),
        height: 1.0,
      ),
    );

    final isLoadingInitialData = (dp.allCourses == null) || (dp.allSupervisors == null);

    if (isLoadingInitialData) {
      return _buildSkeletonLoader(theme, themeProvider, appBarBottomLine);
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Request Team'),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          bottom: appBarBottomLine,
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
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      floatingActionButton: const BreathingChatbotFab(),
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school_rounded,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Target Course',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary)),
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
                                borderSide: BorderSide.none),
                          ),
                          validator: (value) =>
                              value == null ? 'Required to submit' : null,
                          items: dp.allCourses!
                              .map<DropdownMenuItem<String>>((course) {
                            return DropdownMenuItem<String>(
                              value: course['_id'],
                              child:
                                  Text((course['courseCode'] ?? '').toString()),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedCourseId = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🟢 NEW: Title and Link Fields
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Project Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(labelText: 'Google Drive Link'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  Text('Preferred Supervisors',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSupDropdown(1, _sup1, dp.allSupervisors!,
                          (value) => setState(() => _sup1 = value)),
                      const SizedBox(width: 8),
                      _buildSupDropdown(2, _sup2, dp.allSupervisors!,
                          (value) => setState(() => _sup2 = value)),
                      const SizedBox(width: 8),
                      _buildSupDropdown(3, _sup3, dp.allSupervisors!,
                          (value) => setState(() => _sup3 = value)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text('Team Members',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 10),

                  // 🟢 Display Member 1 always
                  _buildMemberCard(0, theme),

                  // 🟢 Display Member 2 only if requested
                  if (_showSecondMember) _buildMemberCard(1, theme),

                  // 🟢 Button logic to add/remove 2nd member
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_showSecondMember)
                        TextButton.icon(
                          onPressed: () => setState(() => _showSecondMember = true),
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF245E63)),
                          label: const Text('Add 2nd Member',
                              style: TextStyle(color: Color(0xFF245E63), fontWeight: FontWeight.bold)),
                        )
                      else
                        const SizedBox.shrink(),

                      if (_showSecondMember)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            // Clear inputs when removing to prevent accidental submission
                            for (var controller in _memberControllers[1].values) {
                              controller.clear();
                            }
                            _showSecondMember = false;
                          }),
                          icon: Icon(Icons.person_remove_rounded, color: theme.colorScheme.error),
                          label: Text('Remove 2nd Member',
                              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: AnimatedSubmitButton(
                      state: _submitState,
                      title: "Submit Request",
                      onPressed: _submitRequest,
                      backgroundColor: const Color(0xFF245E63),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme, ThemeProvider themeProvider,
      PreferredSizeWidget appBarBottomLine) {
    final isDark = themeProvider.isDarkMode;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Request Team'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine,
      ),
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 24),
              Container(height: 20, width: 120, color: Colors.white),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                    3,
                    (index) => Expanded(
                          child: Container(
                            height: 50,
                            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        )),
              ),
              const SizedBox(height: 24),
              Container(height: 20, width: 120, color: Colors.white),
              const SizedBox(height: 10),
              Container(
                  height: 240,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 28),
              Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupDropdown(int index, String? value, List<dynamic> supervisors,
      ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        menuMaxHeight: 250,
        decoration: InputDecoration(
          labelText: 'Sup $index',
          labelStyle: const TextStyle(fontSize: 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
        items: supervisors.map<DropdownMenuItem<String>>((s) {
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
            child: Text(
              abbreviation.isEmpty ? 'N/A' : abbreviation.toUpperCase(),
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // 🟢 NEW: Extracted Member Card logic for cleaner code
  Widget _buildMemberCard(int index, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;

    final cardBackgroundColor = isDarkMode 
        ? const Color(0xFF245E63) 
        : theme.colorScheme.primary.withOpacity(0.08);
        
    final inputFillColor = isDarkMode 
        ? Colors.white10 
        : theme.colorScheme.surface;

    final textColor = isDarkMode ? Colors.white : theme.colorScheme.onSurface;
    final labelColor = isDarkMode ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    final activeLabelColor = isDarkMode ? Colors.white : theme.colorScheme.primary;

    final textStyle = TextStyle(color: textColor, fontWeight: FontWeight.w500);
    final labelStyle = TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500);
    final floatingLabelStyle = TextStyle(color: activeLabelColor, fontWeight: FontWeight.bold);

    bool isLeader = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(
            color: isLeader
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: isDarkMode ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : [], 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLeader ? "My Details (Member 1)" : "Member ${index + 1}",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLeader ? activeLabelColor : labelColor),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _memberControllers[index]['name'],
            style: textStyle, 
            decoration: InputDecoration(
              labelText: 'Name', 
              labelStyle: labelStyle,
              floatingLabelStyle: floatingLabelStyle,
              isDense: true, 
              filled: true, 
              fillColor: inputFillColor, 
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8)))
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextFormField(
              controller: _memberControllers[index]['id'],
              style: textStyle,
              decoration: InputDecoration(
                labelText: 'ID', 
                labelStyle: labelStyle,
                floatingLabelStyle: floatingLabelStyle,
                isDense: true, 
                filled: true, 
                fillColor: inputFillColor, 
                border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8)))
              ),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
              controller: _memberControllers[index]['cgpa'],
              style: textStyle,
              decoration: InputDecoration(
                labelText: 'CGPA', 
                labelStyle: labelStyle,
                floatingLabelStyle: floatingLabelStyle,
                isDense: true, 
                filled: true, 
                fillColor: inputFillColor, 
                border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8)))
              ),
            )),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['email'],
            style: textStyle,
            decoration: InputDecoration(
              labelText: 'Email', 
              labelStyle: labelStyle,
              floatingLabelStyle: floatingLabelStyle,
              isDense: true, 
              filled: true, 
              fillColor: inputFillColor, 
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8)))
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['mobile'],
            style: textStyle,
            decoration: InputDecoration(
              labelText: 'Mobile', 
              labelStyle: labelStyle,
              floatingLabelStyle: floatingLabelStyle,
              isDense: true, 
              filled: true, 
              fillColor: inputFillColor, 
              border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8)))
            ),
          ),
        ],
      ),
    );
  }
}