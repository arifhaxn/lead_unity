import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController();
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setBackgroundColor(Colors.white);
    }

    // 3. Load the URL
    _controller.loadRequest(
      Uri.parse('https://www.chatbase.co/chatbot-iframe/bzLf1XTKhj6lHvP3myOYm'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        top: false, // Allow content to extend behind status bar
        child: Stack(
          children: [
            // WebView with padding to push content down
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: WebViewWidget(
                controller: _controller,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top +
                  8, // Account for status bar
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
