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
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // 1. Clear any existing snackbar immediately
    _currentOverlay?.remove();
    _timer?.cancel();

    void dismiss() {
      _timer?.cancel();
      _currentOverlay?.remove();
      _currentOverlay = null;
    }

    // 2. Create the new Overlay
    _currentOverlay = OverlayEntry(
      builder: (context) => _TopSlidingToast(
        message: message,
        icon: icon,
        color: color,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                dismiss();
                onAction();
              },
        onDismissed: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    // 3. Inject it into the screen
    Overlay.of(context).insert(_currentOverlay!);

    // 4. Auto-remove. A pill with an action gets a little longer so the user
    //    has time to actually reach for it.
    _timer = Timer(
      Duration(seconds: actionLabel == null ? 3 : 5),
      () {
        if (_currentOverlay != null) {
          _currentOverlay?.remove();
          _currentOverlay = null;
        }
      },
    );
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
  //
  // [actionLabel] / [onAction] are optional — pass them for an inline button
  // (e.g. "UNDO"). Existing call sites are unaffected.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showCustomBar(
      context: context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981),
      actionLabel: actionLabel,
      onAction: onAction,
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopSlidingToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
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

    // Stay up longer when there is an action to tap. Must remain shorter than
    // the matching timer in _showCustomBar so the slide-out finishes first.
    Future.delayed(
      Duration(milliseconds: widget.actionLabel == null ? 2500 : 4500),
      () {
        if (mounted) {
          _controller.reverse().then((_) => widget.onDismissed());
        }
      },
    );
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
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: 10),
                      // Hairline divider so the label reads as a button rather
                      // than a run-on of the message.
                      Container(
                        width: 1,
                        height: 16,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: widget.onAction,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            widget.actionLabel!.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
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