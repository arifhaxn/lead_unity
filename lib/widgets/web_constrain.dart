import 'package:flutter/material.dart';

/// Caps content width on wide (web/desktop) viewports so screens don't stretch
/// edge-to-edge on a monitor.
///
/// Usage convention in this app: the scroll view goes OUTSIDE, `WebConstraint`
/// inside — otherwise the scrollbar is constrained too and the page scrolls in
/// a narrow strip.
class WebConstraint extends StatelessWidget {
  final Widget child;

  /// Default for form-style screens (login, proposal submission, team info).
  static const double defaultMaxWidth = 700;

  /// Wider cap for dashboards, whose stat rows and cards look cramped at 700.
  static const double dashboardMaxWidth = 980;

  /// Override the cap for layouts that need more room. Defaults to
  /// [defaultMaxWidth] so existing call sites are unchanged.
  final double maxWidth;

  const WebConstraint({
    super.key,
    required this.child,
    this.maxWidth = defaultMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // 🟢 Wrapped with Padding to push it down slightly from the absolute top
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
