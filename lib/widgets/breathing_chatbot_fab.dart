import 'package:flutter/material.dart';
import 'package:lead_unity/widgets/custom_page_route.dart';
import '../chatbot_screen.dart'; // Make sure this path is correct for your project!

class BreathingChatbotFab extends StatefulWidget {
  const BreathingChatbotFab({Key? key}) : super(key: key);

  @override
  State<BreathingChatbotFab> createState() => _BreathingChatbotFabState();
}

class _BreathingChatbotFabState extends State<BreathingChatbotFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 🟢 Setup the continuous looping animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Slow, calm 2-second breath
    )..repeat(reverse: true); // Loops back and forth automatically

    // 🟢 Define how much it grows (1.0 = normal size, 1.08 = 8% larger)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose to prevent memory leaks!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🟢 ScaleTransition is highly optimized and runs at 60+ FPS without lagging
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          FadeScaleRoute(page: const ChatbotScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Chat with Assistant',
        // Added a slight shadow for a premium feel
        elevation: 4, 
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}