import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';

class CashierDetailsDialog extends StatelessWidget {
  final CashierModel cashier;
  final int totalTransactions;
  final double totalRevenueHandled;
  final double cashSalesHandled;
  final double gcashSalesHandled;

  const CashierDetailsDialog({
    super.key,
    required this.cashier,
    required this.totalTransactions,
    required this.totalRevenueHandled,
    required this.cashSalesHandled,
    required this.gcashSalesHandled,
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
                              color: const Color(0x33C084FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x66C084FC)),
                              image: cashier.avatarUrl != null && cashier.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(cashier.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: cashier.avatarUrl == null || cashier.avatarUrl!.isEmpty
                                ? const Icon(Icons.point_of_sale_rounded, color: Color(0xFFC084FC), size: 26)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cashier.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Cashier Profile • ${cashier.id.length >= 8 ? cashier.id.substring(0, 8) : cashier.id}',
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

                  // SECTION 1: CASHIER INFORMATION
                  const Text(
                    'CASHIER INFORMATION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFFC084FC)),
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
                        _buildDetailRow('Full Name', cashier.fullName, isBold: true),
                        _buildDetailRow('Email Address', cashier.email),
                        _buildDetailRow('Phone Number', cashier.phone ?? '—'),
                        _buildDetailRow('Station Address', cashier.address ?? '—'),
                        _buildDetailRow('System Role', 'Cashier'),
                        _buildDetailRow('Registration Date', cashier.createdAt),
                        _buildDetailRow(
                          'Driver Assign Permission',
                          cashier.canAssignDrivers ? 'Authorized (Allowed)' : 'Restricted (Disabled)',
                          valueColor: cashier.canAssignDrivers ? const Color(0xFF34D399) : const Color(0xFFFCD34D),
                          isBold: true,
                        ),
                        _buildDetailRow('Account Status', cashier.isActive ? 'Active' : 'Archived', valueColor: cashier.isActive ? const Color(0xFF34D399) : const Color(0xFFFCA5A5), isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SECTION 2: POS SALES STATISTICS
                  const Text(
                    'LIFETIME POS SALES STATISTICS (ALL RECORDS)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFFC084FC)),
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
                        _buildDetailRow('Total POS Transactions', '$totalTransactions'),
                        Divider(height: 16, color: Colors.white.withValues(alpha: 0.16)),
                        _buildDetailRow('Total Revenue Handled', '₱${totalRevenueHandled.toStringAsFixed(2)}', isBold: true, valueColor: Colors.white),
                        _buildDetailRow('Cash Payments Received', '₱${cashSalesHandled.toStringAsFixed(2)}', valueColor: const Color(0xFF34D399)),
                        _buildDetailRow('GCash Payments Processed', '₱${gcashSalesHandled.toStringAsFixed(2)}', valueColor: const Color(0xFF38BDF8)),
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
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x339333EA),
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
