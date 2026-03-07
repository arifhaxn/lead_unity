import 'package:flutter/material.dart';

/// A globally reusable function to show dialogs with a bouncy scale & fade animation.
void showAnimatedDialog({
  required BuildContext context,
  required Widget dialog,
  bool barrierDismissible = true,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54, // Dimmed background overlay
    transitionDuration: const Duration(milliseconds: 350), // Animation speed
    pageBuilder: (context, animation, secondaryAnimation) {
      return dialog; // This is where your AlertDialog goes
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // 🟢 The Magic: Fades in while scaling up with a bounce!
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // Bouncy curve
          ),
          child: child,
        ),
      );
    },
  );
}