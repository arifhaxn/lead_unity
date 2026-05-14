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
import 'request_team_screen.dart'; 
import '../widgets/custom_snackbar.dart'; 

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {

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
            const Text("How to Submit"),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            "• First, select your Target Course from the top dropdown.\n\n"
            "• Provide a valid Google Drive link containing your proposal documents. Ensure the link access is set to 'Anyone with the link'.\n\n"
            "• Select 3 distinct supervisors in your preferred order.\n\n"
            // 🟢 UPDATED: Changed instructions to reflect 3 members minimum
            "• Fill in the details for at least 3 team members. You can submit info for 3 or 4 members. Leave unused cards blank.\n\n"
            "• Note: You can only submit one proposal per course.",
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

  void _showSoloStudentDialog() {
    showAnimatedDialog(
      context: context,
      dialog: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.group_off_rounded, color: Colors.amber[700]),
            const SizedBox(width: 8),
            const Text("Need a Team?"),
          ],
        ),
        // 🟢 UPDATED: Changed dialog text to reflect 3 members minimum
        content: const Text(
          "Proposals require at least 3 members to be submitted. If you don't have a full team yet, you can send a 'Request Team' application so supervisors can group you with others.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pushReplacement( 
                context,
                MaterialPageRoute(builder: (_) => const RequestTeamScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Go to Request Team", 
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
          title: const Text('Submit Proposal'),
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
                Container(height: 90, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                const SizedBox(height: 30),
                Container(height: 55, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 16),
                Container(height: 55, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 24),
                Container(height: 20, width: 150, color: Colors.white),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Container(height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 55, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))),
                  ],
                ),
                const SizedBox(height: 30),
                Container(height: 20, width: 120, color: Colors.white),
                const SizedBox(height: 10),
                Container(height: 250, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
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
          title: const Text('Submit Proposal'),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          bottom: appBarBottomLine, 
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
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
      submittedCourseIds = dp.myProposals!.map((p) {
        final courseData = p['course'];
        if (courseData is Map) return courseData['_id']?.toString();
        return courseData?.toString();
      }).whereType<String>().toSet();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Submit Proposal'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: appBarBottomLine, 
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: themeProvider.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
            onPressed: _showInstructions,
            tooltip: 'Submission Instructions',
          ),
        ],
      ),
      floatingActionButton: const BreathingChatbotFab(),
      body: SingleProposalForm(
        courses: dp.allCourses!,
        supervisors: dp.allSupervisors!,
        submittedCourseIds: submittedCourseIds,
        onSoloStudentDetected: _showSoloStudentDialog, 
      ),
    );
  }
}

class SingleProposalForm extends StatefulWidget {
  final List<dynamic> courses;
  final List<dynamic> supervisors;
  final Set<String> submittedCourseIds; 
  final VoidCallback onSoloStudentDetected; 

  const SingleProposalForm({
    super.key,
    required this.courses,
    required this.supervisors,
    required this.submittedCourseIds,
    required this.onSoloStudentDetected,
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

  SubmitState _submitState = SubmitState.idle;
  bool _showFourthMember = false;
  String? _sup1, _sup2, _sup3;

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

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null) {
      CustomSnackBar.showError('Please select a course at the top of the form.');
      return;
    }

    if (widget.submittedCourseIds.contains(_selectedCourseId)) {
      CustomSnackBar.showError('You have already submitted a proposal for this course.');
      return;
    }

    if (_sup1 == null || _sup2 == null || _sup3 == null) {
      CustomSnackBar.showError('Please select all 3 supervisor preferences.');
      return;
    }

    setState(() => _submitState = SubmitState.loading);

    List<Map<String, dynamic>> members = [];
    Set<String> uniqueIds = {};
    
    for (int i = 0; i < 4; i++) {
      String id = _memberControllers[i]['id']!.text.trim();
      String name = _memberControllers[i]['name']!.text.trim();
      String cgpaRaw = _memberControllers[i]['cgpa']!.text.trim();
      String email = _memberControllers[i]['email']!.text.trim();
      String mobile = _memberControllers[i]['mobile']!.text.trim();

      bool isCardPartiallyFilled = id.isNotEmpty || name.isNotEmpty || cgpaRaw.isNotEmpty || email.isNotEmpty || mobile.isNotEmpty;

      if (isCardPartiallyFilled) {
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
    }

    // 🟢 UPDATED: Changed the minimum required members to 3 instead of 2
    if (members.length < 3) {
      setState(() => _submitState = SubmitState.idle);
      widget.onSoloStudentDetected();
      return;
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
        'teamMembers': members
      });

      if (mounted) {
        final dp = Provider.of<DataProvider>(context, listen: false);
        dp.fetchMyProposalsIfNeeded(forceRefresh: true);
        dp.fetchTeamsIfNeeded(forceRefresh: true); 

        setState(() => _submitState = SubmitState.success);
        
        CustomSnackBar.showSuccess('Proposal Submitted Successfully!');
            
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(e.toString().replaceAll('Exception: ', ''));
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
                            : (isAlreadySubmitted ? Colors.redAccent.withOpacity(0.5) : Colors.green.withOpacity(0.5)), 
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
                                : (isAlreadySubmitted ? Icons.block_rounded : Icons.check_circle_rounded),
                            color: _selectedCourseId == null
                                ? theme.colorScheme.primary
                                : (isAlreadySubmitted ? Colors.redAccent : Colors.green),
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
                        validator: (value) => value == null ? 'Required to submit' : null,
                        items:
                            widget.courses.map<DropdownMenuItem<String>>((course) {
                          return DropdownMenuItem<String>(
                            value: course['_id'],
                            child: Text(course['courseCode'],
                                style: const TextStyle(fontWeight: FontWeight.w600)),
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
                            style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        )
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
                    decoration: const InputDecoration(labelText: 'Google Drive Link'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 24),

                Text('Preferred Supervisors',
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

                _buildMemberCard(0), 
                _buildMemberCard(1),
                _buildMemberCard(2),

                if (_showFourthMember)
                  _buildMemberCard(3),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_showFourthMember)
                      TextButton.icon(
                        onPressed: () => setState(() => _showFourthMember = true),
                        icon: const Icon(Icons.group_add_rounded, color: Color(0xFF245E63)),
                        label: Row(
                          children: [
                            const Text('Add 4th Member',
                                style: TextStyle(color: Color(0xFF245E63), fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                const Text('(Not Recommended)',
                                style: TextStyle(color: Color.fromARGB(255, 169, 55, 55), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    if (_showFourthMember)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          for (var controller in _memberControllers[3].values) {
                            controller.clear();
                          }
                          _showFourthMember = false;
                        }),
                        icon: Icon(Icons.person_remove_rounded, color: theme.colorScheme.error),
                        label: Text('Remove 4th Member',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),

                const SizedBox(height: 30),
                
                SizedBox(
                  height: 54,
                  child: AnimatedSubmitButton(
                    state: _submitState,
                    title: isAlreadySubmitted ? 'Already Submitted' : 'Submit Proposal',
                    onPressed: isAlreadySubmitted ? null : _submitProposal,
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

  Widget _buildSupDropdown(
      int index, String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        menuMaxHeight: 300, 
        decoration: InputDecoration(
          labelText: 'Sup $index',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
        validator: (value) => value == null ? 'Required' : null,
        items: widget.supervisors.map<DropdownMenuItem<String>>((s) {
          final abbreviation = [
            s['abbreviation'],
            s['abbr'],
            s['shortName'],
            s['initials'],
          ].map((v) => (v ?? '').toString().trim()).firstWhere(
                (v) => v.isNotEmpty,
                orElse: () => '',
              );

          return DropdownMenuItem(
              value: s['_id'],
              child: Text(abbreviation,
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
    final isDarkMode = theme.brightness == Brightness.dark;

    // 🟢 DYNAMIC COLORS BASED ON LIGHT/DARK MODE
    final cardBackgroundColor = isDarkMode 
        ? const Color(0xFF245E63) // Keep the dark green for Dark Mode
        : theme.colorScheme.primary.withOpacity(0.08); // Subtle primary tint for Light Mode
        
    final inputFillColor = isDarkMode 
        ? Colors.white10 
        : theme.colorScheme.surface;

    final textColor = isDarkMode ? Colors.white : theme.colorScheme.onSurface;
    final labelColor = isDarkMode ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    final activeLabelColor = isDarkMode ? Colors.white : theme.colorScheme.primary;

    // Dynamic Text Styles
    final textStyle = TextStyle(color: textColor, fontWeight: FontWeight.w500);
    final labelStyle = TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500);
    final floatingLabelStyle = TextStyle(color: activeLabelColor, fontWeight: FontWeight.bold);

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
            isLeader ? "Member 1 (Leader)" : "Member ${index + 1}",
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