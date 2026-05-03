import 'package:flutter/material.dart';

enum SubmitState { idle, loading, success }

class AnimatedSubmitButton extends StatelessWidget {
  final SubmitState state;
  final String title;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  
  const AnimatedSubmitButton({
    Key? key,
    required this.state,
    required this.title,
    required this.onPressed,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;

    return ElevatedButton(
      onPressed: state == SubmitState.idle ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: state == SubmitState.success ? const Color(0xFF16A34A) : bgColor, // Turns green on success
        disabledBackgroundColor: state == SubmitState.success ? const Color(0xFF16A34A) : bgColor.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: state == SubmitState.idle ? 2 : 0,
      ),
      // 🟢 AnimatedSwitcher handles the smooth morphing between states!
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutBack, // Bouncy pop-in
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    switch (state) {
      case SubmitState.loading:
        return const SizedBox(
          key: ValueKey('loading'), // Keys are required for AnimatedSwitcher!
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        );
      case SubmitState.success:
        // 🟢 Just the checkmark, slightly larger to fill the space nicely
        return const Icon(
          Icons.check_circle_outline_rounded,
          key: ValueKey('success'),
          color: Colors.white,
          size: 32,
        );
      case SubmitState.idle:
        return Text(
          title,
          key: const ValueKey('idle'),
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        );
    }
  }
}