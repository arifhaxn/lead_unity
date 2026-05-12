import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 
import '../providers/data_provider.dart'; 
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SupervisorListScreen extends StatefulWidget {
  const SupervisorListScreen({Key? key}) : super(key: key);

  @override
  State<SupervisorListScreen> createState() => _SupervisorListScreenState();
}

class _SupervisorListScreenState extends State<SupervisorListScreen> {

  List<dynamic>? _cachedRawSups;
  List<dynamic> _processedSups = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).fetchSupervisorsIfNeeded();
    });
  }

  int _designationPriority(String? designation) {
    final value = (designation ?? '').trim().toLowerCase();

    if (value.contains('head') ||
        value.contains('hod') ||
        value.contains('chair')) {
      return 0;
    }
    if (value.contains('professor') &&
        !value.contains('associate') &&
        !value.contains('assistant')) {
      return 1;
    }
    if (value.contains('associate professor')) return 2;
    if (value.contains('assistant professor')) return 3;
    if (value.contains('lecturer')) return 4;
    if (value.contains('adjunct')) return 5;
    return 99;
  }

  String _fullName(dynamic supervisor) {
    final name = (supervisor['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final firstName = (supervisor['firstName'] ?? '').toString().trim();
    final lastName = (supervisor['lastName'] ?? '').toString().trim();
    final full = '$firstName $lastName'.trim();

    return full.isNotEmpty ? full : 'Unknown Supervisor';
  }

  String _designation(dynamic supervisor) {
    final designation = (supervisor['designation'] ?? supervisor['title'] ?? '')
        .toString()
        .trim();
    return designation.isNotEmpty ? designation : 'Designation not set';
  }

  void _processDataIfNeeded(List<dynamic>? rawSups) {
    if (rawSups == null) return;
    if (_cachedRawSups == rawSups) return; 

    _cachedRawSups = rawSups;
    
    _processedSups = [...rawSups]..sort((a, b) {
      final rankA = _designationPriority(
          (a['designation'] ?? a['title'])?.toString());
      final rankB = _designationPriority(
          (b['designation'] ?? b['title'])?.toString());
      if (rankA != rankB) return rankA.compareTo(rankB);

      final nameA = _fullName(a).toLowerCase();
      final nameB = _fullName(b).toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dataProvider = Provider.of<DataProvider>(context); 

    _processDataIfNeeded(dataProvider.allSupervisors);

    final appBarBottomLine = PreferredSize(
      preferredSize: const Size.fromHeight(1.0),
      child: Container(
        color: theme.colorScheme.outline.withOpacity(0.2), 
        height: 1.0,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("All Supervisors"),
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
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dataProvider.fetchSupervisorsIfNeeded(forceRefresh: true),
        color: theme.colorScheme.primary,
        child: Builder(
          builder: (context) {
            
            if (dataProvider.isLoadingSupervisors && dataProvider.allSupervisors == null) {
              return _buildSkeletonLoader(theme);
            }

            if (_processedSups.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), 
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("No other supervisors found.")),
                ],
              );
            }

            return AnimationLimiter(
              child: ListView.builder(
                itemCount: _processedSups.length,
                padding: const EdgeInsets.all(20),
                itemBuilder: (context, index) {
                  final s = _processedSups[index];
                  final name = _fullName(s);
                  final designation = _designation(s);

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF245E63),
                            borderRadius: AppRadii.card,
                            boxShadow: AppShadows.level1,
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F6F55),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (index + 1).toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontSize: 16, color: Colors.white)),
                            subtitle: Text(designation,
                                style:
                                    const TextStyle(fontSize: 12, color: Colors.white70)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        itemCount: 8, 
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.card, 
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}