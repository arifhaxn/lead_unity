import 'package:flutter/material.dart';

class TopNotification {
  static void show(BuildContext context, {required String title, required String message}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // 🟢 Automatically detect if the phone is in Dark Mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Sits right below the status bar
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: -100, end: 0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack, // Gives it that satisfying little bounce
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // 🟢 Dark grey for Dark Mode, clean white for Light Mode
                  color: isDarkMode ? Colors.grey[900] : Colors.white, 
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo/logo.png', // Your app logo
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            Icon(
                              Icons.error_outline, 
                              // 🟢 Icon fallback adapts too
                              color: isDarkMode ? Colors.white : Colors.black54
                            ), 
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              // 🟢 White text in Dark Mode, almost-black text in Light Mode
                              color: isDarkMode ? Colors.white : Colors.black87, 
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              // 🟢 Faded text adapts perfectly to both modes
                              color: isDarkMode ? Colors.white70 : Colors.black54, 
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}