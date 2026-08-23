import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, fgColor) = _getStatusConfig(status.toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color, Color) _getStatusConfig(String status) {
    switch (status) {
      case 'claimable':
        return ('Claimable', const Color(0xFF065F46), const Color(0xFF34D399));
      case 'claimed':
      case 'succeeded':
      case 'completed':
        return ('Claimed', const Color(0xFF1E3A8A), const Color(0xFF60A5FA));
      case 'pending':
        return ('Pending', const Color(0xFF78350F), const Color(0xFFFBBF24));
      case 'expired':
        return ('Expired', const Color(0xFF4C1D95), const Color(0xFFA78BFA));
      case 'refunded':
        return ('Refunded', const Color(0xFF134E4A), const Color(0xFF2DD4BF));
      case 'failed':
        return ('Failed', const Color(0xFF7F1D1D), const Color(0xFFF87171));
      case 'created':
      default:
        return (status.toUpperCase(), const Color(0xFF334155), const Color(0xFF94A3B8));
    }
  }
}
