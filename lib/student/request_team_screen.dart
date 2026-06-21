import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:link_unity/widgets/animated_dialog.dart';
import 'package:link_unity/widgets/breathing_chatbot_fab.dart';
import 'package:link_unity/widgets/animated_submit_button.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_snackbar.dart';

class RequestTeamScreen extends StatefulWidget {
  const RequestTeamScreen({super.key});

  @override
  State<RequestTeamScreen> createState() => _RequestTeamScreenState();
}

class _RequestTeamScreenState extends State<RequestTeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = Provider.of<DataProvider>(context, listen: false);
      dp.fetchCoursesIfNeeded();
      dp.fetchSupervisorsIfNeeded();
      dp.fetchMyProposalsIfNeeded();
    });
  }

  void _showInstructions() {
    showAnimatedDialog(
      context: context,
      dialog: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text("Request a Team"),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "• First, select your Target Course from the top dropdown.\n\n"
            "• Provide a valid Google Drive link containing any proposal documents or portfolio work. Ensure link access is set to 'Anyone with the link'.\n\n"
            "• Select 3 distinct supervisors in your preferred order.\n\n"
            "• Fill in your details. You can submit alone (1 member) or add 1 additional teammate (2 members).\n\n"
            "• Note: You can only submit one request/proposal per course.",
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
    final dp = Provider.of<DataProvider>(context);

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2),
        height: 1.0,
      ),
    );

    final isLoadingInitialData = (dp.allCourses == null) ||
        (dp.allSupervisors == null) ||
        (dp.myProposals == null);

    if (isLoadingInitialData) {
      final isDark = theme.brightness == Brightness.dark;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16))),
                const SizedBox(height: 30),
                Container(
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 16),
                Container(
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 24),
                Container(height: 20, width: 150, color: Colors.white),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)))),
                  ],
                ),
                const SizedBox(height: 30),
                Container(height: 20, width: 120, color: Colors.white),
                const SizedBox(height: 10),
                Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16))),
              ],
            ),
          ),
        ),
      );
    }

    if (dp.allCourses != null && dp.allCourses!.isEmpty) {
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
              ),
              onPressed: themeProvider.toggleTheme,
            ),
          ],
        ),
        body: const Center(child: Text("No courses available.")),
      );
    }

    Set<String> submittedCourseIds = {};
    if (dp.myProposals != null) {
      submittedCourseIds = dp.myProposals!
          .map((p) {
            final courseData = p['course'];
            if (courseData is Map) return courseData['_id']?.toString();
            return courseData?.toString();
          })
          .whereType<String>()
          .toSet();
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
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded,
                color: theme.colorScheme.primary),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      floatingActionButton: const BreathingChatbotFab(),
      body: RequestTeamForm(
        courses: dp.allCourses!,
        supervisors: dp.allSupervisors!,
        submittedCourseIds: submittedCourseIds,
      ),
    );
  }
}

class RequestTeamForm extends StatefulWidget {
  final List<dynamic> courses;
  final List<dynamic> supervisors;
  final Set<String> submittedCourseIds;

  const RequestTeamForm({
    super.key,
    required this.courses,
    required this.supervisors,
    required this.submittedCourseIds,
  });

  @override
  State<RequestTeamForm> createState() => _RequestTeamFormState();
}

class _RequestTeamFormState extends State<RequestTeamForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? _selectedCourseId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  // 🟢 List capped at 2 members
  final List<Map<String, TextEditingController>> _memberControllers =
      List.generate(
          2,
          (index) => {
                'name': TextEditingController(),
                'id': TextEditingController(),
                'cgpa': TextEditingController(),
                'email': TextEditingController(),
                'mobile': TextEditingController(),
              });

  SubmitState _submitState = SubmitState.idle;
  bool _showSecondMember = false;
  String? _sup1, _sup2, _sup3;

@override
  void initState() {
    super.initState();
    // Auto-fill the leader's name, studentId, and email from their logged-in account.
    // This guarantees the studentId in teamMembers[] always matches the populated
    // student object, so cgpa and mobile show correctly in Team Info.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        _memberControllers[0]['name']!.text  = user.name;
        // 🟢 FIX: studentId is nullable in your model, so it still needs the fallback!
        _memberControllers[0]['id']!.text    = user.studentId ?? ''; 
        _memberControllers[0]['email']!.text = user.email;
      }
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
      CustomSnackBar.showError(context, 'Please select a course at the top of the form.');
      return;
    }

    if (widget.submittedCourseIds.contains(_selectedCourseId)) {
      CustomSnackBar.showError(context, 'You have already submitted a proposal/request for this course.');
      return;
    }

    if (_sup1 == null || _sup2 == null || _sup3 == null) {
      CustomSnackBar.showError(context, 'Please select all 3 supervisor preferences.');
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    List<Map<String, dynamic>> members = [];
    Set<String> uniqueIds = {};
    int memberCount = _showSecondMember ? 2 : 1;

    for (int i = 0; i < memberCount; i++) {
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
        setState(() => _submitState = SubmitState.idle);
        CustomSnackBar.showError(context,
            'Please complete all fields for Member ${i + 1}.');
        return;
      }

      if (uniqueIds.contains(id)) {
        setState(() => _submitState = SubmitState.idle);
        CustomSnackBar.showError(context, 'Duplicate Student ID: $id');
        return;
      }

      final cgpa = double.tryParse(cgpaRaw);
      if (cgpa == null) {
        setState(() => _submitState = SubmitState.idle);
        CustomSnackBar.showError(context, 'Invalid CGPA for Member ${i + 1}.');
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

    List<String> supervisorIds = [];
    if (_sup1 != null) supervisorIds.add(_sup1!);
    if (_sup2 != null) supervisorIds.add(_sup2!);
    if (_sup3 != null) supervisorIds.add(_sup3!);

    try {
      await _apiService.submitProposal({
        'title': _titleController.text.trim(),
        'description': _linkController.text.trim(),
        'courseId': _selectedCourseId!,
        'supervisorIds': supervisorIds,
        'teamMembers': members,
        //'status': 'pending', // 🟢 Forces the Pending state required for Requests
      });

      if (mounted) {
        final dp = Provider.of<DataProvider>(context, listen: false);
        dp.fetchMyProposalsIfNeeded(forceRefresh: true);
        dp.fetchTeamsIfNeeded(forceRefresh: true);

        setState(() => _submitState = SubmitState.success);

        CustomSnackBar.showSuccess(context, 'Team Request Submitted Successfully!');

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
        setState(() => _submitState = SubmitState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAlreadySubmitted = _selectedCourseId != null &&
        widget.submittedCourseIds.contains(_selectedCourseId);

    return AnimationLimiter(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _selectedCourseId == null
                            ? theme.colorScheme.primary.withOpacity(0.5)
                            : (isAlreadySubmitted
                                ? Colors.redAccent.withOpacity(0.5)
                                : Colors.green.withOpacity(0.5)),
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
                                : (isAlreadySubmitted
                                    ? Icons.block_rounded
                                    : Icons.check_circle_rounded),
                            color: _selectedCourseId == null
                                ? theme.colorScheme.primary
                                : (isAlreadySubmitted
                                    ? Colors.redAccent
                                    : Colors.green),
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
                        items: widget.courses
                            .map<DropdownMenuItem<String>>((course) {
                          return DropdownMenuItem<String>(
                            value: course['_id'],
                            child: Text(course['courseCode'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCourseId = newValue;
                          });
                        },
                      ),
                      if (isAlreadySubmitted)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            '⚠️ You have already submitted a proposal for this course.',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                    controller: _titleController,
                    decoration:
                        const InputDecoration(labelText: 'Project Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(
                    controller: _linkController,
                    decoration:
                        const InputDecoration(labelText: 'Google Drive Link'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 24),
                Text('Preferred Supervisors',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 10),
                // 🟢 SWAPPED OUT THE NATIVE DROPDOWNS FOR THE SEARCHABLE ONES
                Row(children: [
                  _buildSearchableSupDropdown(1, _sup1, (v) => setState(() => _sup1 = v)),
                  const SizedBox(width: 8),
                  _buildSearchableSupDropdown(2, _sup2, (v) => setState(() => _sup2 = v)),
                  const SizedBox(width: 8),
                  _buildSearchableSupDropdown(3, _sup3, (v) => setState(() => _sup3 = v)),
                ]),
                const SizedBox(height: 30),
                Text('Team Members',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 10),
                _buildMemberCard(0),
                if (_showSecondMember) _buildMemberCard(1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_showSecondMember)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _showSecondMember = true),
                        icon: const Icon(Icons.group_add_rounded,
                            color: Color(0xFF245E63)),
                        label: const Text('Add 2nd Member',
                            style: TextStyle(
                                color: Color(0xFF245E63),
                                fontWeight: FontWeight.bold)),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_showSecondMember)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          for (var controller in _memberControllers[1].values) {
                            controller.clear();
                          }
                          _showSecondMember = false;
                        }),
                        icon: Icon(Icons.person_remove_rounded,
                            color: theme.colorScheme.error),
                        label: Text('Remove 2nd Member',
                            style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 54,
                  child: AnimatedSubmitButton(
                    state: _submitState,
                    title: isAlreadySubmitted
                        ? 'Already Submitted'
                        : 'Submit Request',
                    onPressed: isAlreadySubmitted ? null : _submitRequest,
                    backgroundColor: const Color(0xFF245E63),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 NEW: Custom Searchable Dropdown Builder
Widget _buildSearchableSupDropdown(int index, String? value, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    
    String displayName = 'Select';
    if (value != null) {
      final found = widget.supervisors.firstWhere((s) => s['_id'] == value, orElse: () => null);
      if (found != null) {
        // 🟢 FIX: Prioritize short forms/abbreviations for the selected box!
        // It checks multiple possible backend keys for the short form, and falls back to name if needed.
        displayName = [
          found['abbreviation'],
          found['abbr'],
          found['shortName'],
          found['initials'],
          found['name'], 
        ].map((v) => (v ?? '').toString().trim()).firstWhere(
              (v) => v.isNotEmpty,
              orElse: () => 'Unknown',
            );
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final selectedId = await showDialog<String>(
            context: context,
            builder: (context) => _SupervisorSearchDialog(
              supervisors: widget.supervisors,
              title: 'Select Supervisor $index',
            ),
          );
          if (selectedId != null) {
            onChanged(selectedId);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Sup $index',
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: value == null ? FontWeight.normal : FontWeight.bold,
              color: value == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, 
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(int index) {
    bool isLeader = index == 0;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final cardBackgroundColor = isDarkMode
        ? const Color(0xFF245E63)
        : theme.colorScheme.primary.withOpacity(0.08);

    final inputFillColor =
        isDarkMode ? Colors.white10 : theme.colorScheme.surface;

    final textColor = isDarkMode ? Colors.white : theme.colorScheme.onSurface;
    final labelColor =
        isDarkMode ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    final activeLabelColor =
        isDarkMode ? Colors.white : theme.colorScheme.primary;

    final textStyle = TextStyle(color: textColor, fontWeight: FontWeight.w500);
    final labelStyle =
        TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500);
    final floatingLabelStyle =
        TextStyle(color: activeLabelColor, fontWeight: FontWeight.bold);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: AppRadii.card,
        border: Border.all(
            color: isLeader
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: isDarkMode ? AppShadows.level1 : [],
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
            readOnly: isLeader,
            decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: labelStyle,
                floatingLabelStyle: floatingLabelStyle,
                suffixIcon: isLeader
                    ? Icon(Icons.lock_outline_rounded,
                        size: 16, color: labelColor)
                    : null,
                isDense: true,
                filled: true,
                fillColor: inputFillColor,
                border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)))),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextFormField(
              controller: _memberControllers[index]['id'],
              style: textStyle,
              readOnly: isLeader,
              decoration: InputDecoration(
                  labelText: 'ID',
                  labelStyle: labelStyle,
                  floatingLabelStyle: floatingLabelStyle,
                  suffixIcon: isLeader
                      ? Icon(Icons.lock_outline_rounded,
                          size: 16, color: labelColor)
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: inputFillColor,
                  border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)))),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: TextFormField(
              controller: _memberControllers[index]['cgpa'],
              style: textStyle,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'CGPA',
                  labelStyle: labelStyle,
                  floatingLabelStyle: floatingLabelStyle,
                  isDense: true,
                  filled: true,
                  fillColor: inputFillColor,
                  border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)))),
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
                border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)))),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberControllers[index]['mobile'],
            style: textStyle,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: 'Mobile',
                labelStyle: labelStyle,
                floatingLabelStyle: floatingLabelStyle,
                isDense: true,
                filled: true,
                fillColor: inputFillColor,
                border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)))),
          ),
        ],
      ),
    );
  }
}

// ── 🟢 NEW: Supervisor Search Dialog Widget ─────────────────────────────────
class _SupervisorSearchDialog extends StatefulWidget {
  final List<dynamic> supervisors;
  final String title;

  const _SupervisorSearchDialog({
    required this.supervisors,
    required this.title,
  });

  @override
  State<_SupervisorSearchDialog> createState() => _SupervisorSearchDialogState();
}

class _SupervisorSearchDialogState extends State<_SupervisorSearchDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final filteredList = widget.supervisors.where((s) {
      final name = (s['name'] ?? s['abbreviation'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
      actionsPadding: const EdgeInsets.only(top: 4, bottom: 8, right: 12),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.70,
        child: Column(
          children: [
            TextField(
              autofocus: true, 
              decoration: InputDecoration(
                hintText: 'Search by full name...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filteredList.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),
                itemBuilder: (context, index) {
                  final sup = filteredList[index];
                  final name = sup['name'] ?? sup['abbreviation'] ?? 'Unknown Supervisor';
                  final designation = sup['designation'];
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: designation != null 
                        ? Text(designation, style: const TextStyle(fontSize: 12)) 
                        : null,
                    onTap: () => Navigator.pop(context, sup['_id']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}