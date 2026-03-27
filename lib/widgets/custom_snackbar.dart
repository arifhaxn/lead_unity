import 'package:flutter/material.dart';

class CustomSnackBar {
  // 🟢 1. The Global Key that lets us show snackbars from anywhere!
  static final GlobalKey<ScaffoldMessengerState> messengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  // 🟢 2. The generic builder with glass-style styling
  static void _showCustomBar({
    required String message,
    required IconData icon,
    required Color color, // This will now only influence the background opacity
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          // ⚪ White Icon
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white, // ⚪ White Text
                fontSize: 14, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      // 🟢 Colored background with high opacity for readability
      backgroundColor: color.withOpacity(0.9), 
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // ⚪ White Outline added here
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 3),
    );

    // Remove current snackbar if one is showing, then show the new one
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  // 🔴 Error Message (Transparent Red background, White Text/Outline)
  static void showError(String message) {
    _showCustomBar(
      message: message,
      icon: Icons.error_outline_rounded,
      color: Colors.redAccent,
    );
  }

  // 🟢 Success Message (Transparent Green background, White Text/Outline)
  static void showSuccess(String message) {
    _showCustomBar(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981), // Emerald Green
    );
  }

  // 🔵 Info/Warning Message (Transparent Blue background, White Text/Outline)
  static void showInfo(String message) {
    _showCustomBar(
      message: message,
      icon: Icons.info_outline_rounded,
      color: const Color(0xFF3B82F6), // Blue
    );
  }
}