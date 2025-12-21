import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewTemplateScreen extends StatelessWidget {
   ViewTemplateScreen({super.key});

  final String templateDownloadUrl = "https://drive.google.com/file/d/1G9aQGKjf7AGut_6o0YP_pd4E3P0DyMNr/view?usp=drive_link";

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
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch download link.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal Template Preview'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // --- Image List ---
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: templateImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Card(
              elevation: 4,
              child: Image.asset(
                templateImages[index],
                fit: BoxFit.cover,
                // Optional: Show a placeholder if the image is missing
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: Text('Image Page Missing')),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _launchDownload(context),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('Download Template', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}