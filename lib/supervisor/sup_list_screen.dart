import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api services/api_services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SupervisorListScreen extends StatelessWidget {
  const SupervisorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🟢 No Provider needed here anymore
    final ApiService apiService = ApiService();
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("All Supervisors"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
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
      body: FutureBuilder<List<dynamic>>(
        // 🟢 FIXED: Call API directly without token argument
        // The Service handles the filtering ('role' == 'supervisor') and the token automatically.
        future: apiService.getSupervisors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final sups = snapshot.data ?? [];

          if (sups.isEmpty) {
            return const Center(child: Text("No other supervisors found."));
          }

          return ListView.builder(
            itemCount: sups.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final s = sups[index];
              final name = s['name'] ?? 'Unknown';
              final firstLetter = name.isNotEmpty ? name[0] : '?';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadii.card,
                  boxShadow: AppShadows.level1,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    child: Text(firstLetter.toUpperCase(),
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name,
                      style:
                          theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
                  subtitle: Text(s['email'] ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
