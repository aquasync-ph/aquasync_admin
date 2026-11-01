import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);

    final s = status.toLowerCase();

    if (s == 'pending') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (s == 'confirmed') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
    } else if (s == 'assigned') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
    } else if (s == 'accepted') {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF3730A3);
    } else if (s == 'out_for_delivery') {
      bg = const Color(0xFFFCE7F3);
      fg = const Color(0xFF9D174D);
    } else if (s == 'delivered' || s == 'completed') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
    } else if (s == 'cancelled') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
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
    final s = status.toLowerCase().trim().replaceAll(' ', '_');

    if (s == 'available') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF166534);
    } else if (s == 'out_for_delivery') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
    } else if (s == 'borrowed') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    } else if (s == 'damaged' || s == 'lost') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (s == 'retired') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    } else if (s == 'returned') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    }

    String label = s.toUpperCase().replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
