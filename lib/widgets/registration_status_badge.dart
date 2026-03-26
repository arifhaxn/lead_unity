// The Dynamic Registration Status Badge
import 'package:flutter/material.dart';

class RegistrationStatusBadge extends StatelessWidget {
  final DateTime? deadline;

  const RegistrationStatusBadge({Key? key, required this.deadline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isOngoing = deadline == null || DateTime.now().isBefore(deadline!);

    final color = isOngoing ? const Color(0xFF10B981) : Colors.blueAccent;
    final bgColor = isOngoing ? const Color(0xFF10B981).withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1);
    final icon = isOngoing ? Icons.sync_rounded : Icons.task_alt_rounded;
    final text = isOngoing ? "Reg. Ongoing" : "Teams Formed";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}