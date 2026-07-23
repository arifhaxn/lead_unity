import 'package:flutter/material.dart';
import 'package:link_unity/widgets/web_constrain.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_provider.dart';

class ViewTemplateScreen extends StatelessWidget {
  ViewTemplateScreen({super.key});

  final String templateDownloadUrl =
      "https://docs.google.com/document/d/1BPCYOcpawc7uii39VChTyUF9Z0H-erCR/edit?usp=sharing&ouid=105632695343912870187&rtpof=true&sd=true";

  final List<String> templateImages = [
    'assets/template/page1.png',
    'assets/template/page2.png',
    'assets/template/page3.png',
    'assets/template/page4.png',
    'assets/template/page5.png',
    'assets/template/page6.png',
    'assets/template/page7.png',
    'assets/template/page8.png',
  ];

Future<void> _launchDownload(BuildContext context) async {
    final Uri url = Uri.parse(templateDownloadUrl);
    try {
      // 🟢 FIX: We bypass the strict `canLaunchUrl` check entirely.
      // We just directly command the OS to open the link in the browser.
      final bool launched = await launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        throw 'Could not launch download link.';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Template Preview'),
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
          )
        ],
      ),
      // --- Image List ---
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: templateImages.length,
        itemBuilder: (context, index) {
          return WebConstraint(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Card(
                elevation: 0,
                child: Image.asset(
                  templateImages[index],
                  fit: BoxFit.cover,
                  
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: Text('Image Page Missing')),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchDownload(context),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('Download Template',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
