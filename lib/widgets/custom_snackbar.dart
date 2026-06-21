import 'package:flutter/material.dart';
import 'dart:async';

class CustomSnackBar {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static void _showCustomBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    // 1. Clear any existing snackbar immediately
    _currentOverlay?.remove();
    _timer?.cancel();

    // 2. Create the new Overlay
    _currentOverlay = OverlayEntry(
      builder: (context) => _TopSlidingToast(
        message: message,
        icon: icon,
        color: color,
        onDismissed: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    // 3. Inject it into the screen
    Overlay.of(context).insert(_currentOverlay!);

    // 4. Auto-remove after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      if (_currentOverlay != null) {
        _currentOverlay?.remove();
        _currentOverlay = null;
      }
    });
  }

  // 🔴 Error Message (Solid Vibrant Red)
  static void showError(BuildContext context, String message) {
    _showCustomBar(
      context: context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: Colors.redAccent.shade700, 
    );
  }

  // 🟢 Success Message (Solid Vibrant Green)
  static void showSuccess(BuildContext context, String message) {
    _showCustomBar(
      context: context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981),
    );
  }

  // 🔵 Info Message (Solid Vibrant Blue)
  static void showInfo(BuildContext context, String message) {
    _showCustomBar(
      context: context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: const Color(0xFF3B82F6),
    );
  }

  // 🔔 Push Notification Message (Vibrant Deep Purple)
  static void showPushNotification(BuildContext context, String message) {
    _showCustomBar(
      context: context,
      message: message,
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFF7C3AED), // Vibrant purple
    );
  }
}

// ── The Animation Engine ──────────────────────────────────────────
class _TopSlidingToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismissed;

  const _TopSlidingToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismissed,
  });

  @override
  State<_TopSlidingToast> createState() => _TopSlidingToastState();
}

class _TopSlidingToastState extends State<_TopSlidingToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 0, // 🟢 Changed from 20 to 0 to allow Align to center it
      right: 0, // 🟢 Changed from 20 to 0 to allow Align to center it
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Align(
              alignment: Alignment.topCenter, // 🟢 Centers the shrink-wrapped pill
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20), // Prevents long text from touching screen edges
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // 🟢 More compact vertical padding
                decoration: BoxDecoration(
                  color: widget.color, // 🟢 Removed .withOpacity(0.9) for maximum vibrancy
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // 🟢 Shrink-wraps the pill tightly around the text!
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 16), // 🟢 Smaller icon like the network banner
                    const SizedBox(width: 8), // 🟢 Tighter gap
                    Flexible( // 🟢 Changed from Expanded to Flexible so it can shrink
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
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
  }

}