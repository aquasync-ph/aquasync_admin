import 'package:flutter/material.dart';

/// Modern iOS-inspired status badge with a glowing status indicator dot.
class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    Color border = const Color(0xFFCBD5E1);

    final s = status.toLowerCase();

    if (s == 'pending') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      border = const Color(0xFFFCD34D);
    } else if (s == 'confirmed') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
      border = const Color(0xFF93C5FD);
    } else if (s == 'assigned') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      border = const Color(0xFF7DD3FC);
    } else if (s == 'accepted') {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF3730A3);
      border = const Color(0xFFA5B4FC);
    } else if (s == 'out_for_delivery') {
      bg = const Color(0xFFFCE7F3);
      fg = const Color(0xFFBE185D);
      border = const Color(0xFFF472B6);
    } else if (s == 'delivered' || s == 'completed') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      border = const Color(0xFF86EFAC);
    } else if (s == 'cancelled') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      border = const Color(0xFFFCA5A5);
    }

    String label = status;
    if (s == 'pending') label = 'Pending';
    if (s == 'confirmed') label = 'Confirmed';
    if (s == 'assigned') label = 'Driver Assigned';
    if (s == 'accepted') label = 'Accepted';
    if (s == 'out_for_delivery') label = 'Out for Delivery';
    if (s == 'delivered') label = 'Delivered';
    if (s == 'completed') label = 'Completed';
    if (s == 'cancelled') label = 'Cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class GallonStatusBadge extends StatelessWidget {
  final String status;

  const GallonStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    Color border = const Color(0xFFCBD5E1);

    final s = status.toLowerCase().trim().replaceAll(' ', '_');

    if (s == 'available') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      border = const Color(0xFF86EFAC);
    } else if (s == 'out_for_delivery') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      border = const Color(0xFF7DD3FC);
    } else if (s == 'borrowed') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      border = const Color(0xFFFCA5A5);
    } else if (s == 'damaged' || s == 'lost') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      border = const Color(0xFFFCD34D);
    } else if (s == 'retired') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      border = const Color(0xFFCBD5E1);
    } else if (s == 'returned') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      border = const Color(0xFF86EFAC);
    }

    String label = s.toUpperCase().replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
