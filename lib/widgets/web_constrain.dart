import 'package:flutter/material.dart';

class WebConstraint extends StatelessWidget {
  final Widget child;

  const WebConstraint({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // 🟢 Wrapped with Padding to push it down slightly from the absolute top
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0), 
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: child,
        ),
      ),
    );
  }
}