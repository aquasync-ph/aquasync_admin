import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';

class DriverDetailsDialog extends StatelessWidget {
  final DriverModel driver;
  final int totalDeliveries;
  final int completedDeliveries;
  final int activeDeliveries;

  const DriverDetailsDialog({
    super.key,
    required this.driver,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.activeDeliveries,
  });

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFA082A45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x3838BDF8), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 36,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                              image: driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(driver.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: driver.avatarUrl == null || driver.avatarUrl!.isEmpty
                                ? const Icon(Icons.badge_rounded, color: Color(0xFF38BDF8), size: 26)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Driver Profile • ${driver.id.length >= 8 ? driver.id.substring(0, 8) : driver.id}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),

                  // SECTION 1: DRIVER INFORMATION
                  const Text(
                    'DRIVER INFORMATION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Full Name', driver.fullName, isBold: true),
                        _buildDetailRow('Email Address', driver.email),
                        _buildDetailRow('Phone Number', driver.phone ?? '—'),
                        _buildDetailRow('System Role', 'Driver'),
                        _buildDetailRow('Registration Date', driver.createdAt),
                        _buildDetailRow('Account Status', driver.isActive ? 'Active' : 'Archived', valueColor: driver.isActive ? const Color(0xFF34D399) : const Color(0xFFFCA5A5), isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SECTION 2: DELIVERY STATISTICS
                  const Text(
                    'DELIVERY STATISTICS (FROM DISPATCH RECORDS)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Total Assigned Deliveries', '$totalDeliveries'),
                        _buildDetailRow('Completed / Delivered', '$completedDeliveries', isBold: true, valueColor: const Color(0xFF34D399)),
                        _buildDetailRow('Active / In Transit', '$activeDeliveries', isBold: true, valueColor: const Color(0xFFFCD34D)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x330284C7),
                        ),
                        child: const Text('Close Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
