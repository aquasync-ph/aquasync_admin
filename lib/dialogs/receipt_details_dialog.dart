import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/sweet_alert.dart';
import '../services/supabase_service.dart';
import '../utils/print_helper.dart';

class ReceiptDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> sale;

  const ReceiptDetailsDialog({
    super.key,
    required this.sale,
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
    final idStr = sale['id']?.toString() ?? '';
    final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
    final invoiceNum = sale['invoice_number']?.toString() ?? 'INV-$shortId';
    final receiptNum = sale['receipt_number']?.toString() ?? 'RCP-$shortId';
    final custStr = sale['customer_name']?.toString() ?? sale['notes']?.toString() ?? 'Walk-in Customer';
    final payMethod = sale['payment_method']?.toString() ?? 'Cash';
    String determineClassification(Map<String, dynamic> item) {
      final invNum = (item['invoice_number'] ?? item['receipt_number'] ?? item['order_number'] ?? item['id'] ?? '').toString().toUpperCase();
      final orderType = (item['order_type'] ?? '').toString().trim().toLowerCase();
      final bool isWalkInFlag = item['is_walk_in'] == true;

      if (orderType == 'online' || orderType == 'app' || orderType == 'delivery' || invNum.contains('ORD-') || invNum.startsWith('ORD') || invNum.startsWith('APP-')) {
        return 'Online';
      }

      if (isWalkInFlag || orderType == 'pos' || orderType == 'walk_in' || orderType == 'walk-in' || invNum.contains('POS-') || invNum.startsWith('POS')) {
        return 'Walk-In';
      }

      final fulfillment = (item['fulfillment_type'] ?? item['notes'] ?? '').toString().toLowerCase();
      if (fulfillment.contains('delivery') || fulfillment.contains('online')) {
        return 'Online';
      }

      if (item['classification'] != null && item['classification'].toString().isNotEmpty) {
        final c = item['classification'].toString().trim().toLowerCase();
        if (c == 'online' || c == 'app' || c == 'delivery') return 'Online';
        if (c == 'walk-in' || c == 'walk_in' || c == 'pos') return 'Walk-In';
      }

      return item['is_online_order'] == true ? 'Online' : 'Walk-In';
    }

    final classification = determineClassification(sale);
    final totalAmt = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
    final cashReceived = (sale['cash_received'] as num?)?.toDouble() ?? totalAmt;
    final changeAmount = (sale['change_amount'] as num?)?.toDouble() ?? 0.0;
    final timeStr = sale['created_at']?.toString() ?? 'Today';
    
    String cashierName = 'Cashier / Admin';
    if (sale['cashier'] != null && sale['cashier']['full_name'] != null) {
      cashierName = sale['cashier']['full_name'].toString();
    } else if (sale['cashier_id'] != null) {
      cashierName = 'Cashier ID: ${sale['cashier_id'].toString().substring(0, 8)}...';
    }

    final items = sale['sale_items'] as List<dynamic>? ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
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
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.description_rounded, color: Color(0xFF38BDF8), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Official Invoice & Receipt',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                '$invoiceNum • $receiptNum',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
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

                  // TRANSACTION METADATA
                  const Text(
                    'TRANSACTION INFORMATION',
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
                        _buildDetailRow('Invoice Number', invoiceNum, isBold: true, valueColor: const Color(0xFF38BDF8)),
                        _buildDetailRow('Receipt Number', receiptNum, isBold: true),
                        _buildDetailRow('Classification', classification.toUpperCase(), isBold: true, valueColor: classification.toLowerCase().contains('online') ? const Color(0xFFA5B4FC) : const Color(0xFF38BDF8)),
                        _buildDetailRow('Customer', custStr, isBold: true),
                        _buildDetailRow('Processed By', cashierName),
                        _buildDetailRow('Timestamp', timeStr.contains('T') ? timeStr.replaceAll('T', ' ').split('.').first : timeStr),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ITEMIZED PRODUCTS
                  const Text(
                    'ITEMIZED PURCHASES',
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
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: Text('No itemized records found for this receipt.', style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)))),
                          )
                        : Column(
                            children: items.map((item) {
                              final pName = item['product_name']?.toString() ?? 'Product';
                              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                              final price = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
                              final sub = (item['subtotal'] as num?)?.toDouble() ?? (qty * price);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(pName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                          Text('$qty × ₱${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                                        ],
                                      ),
                                    ),
                                    Text('₱${sub.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 18),

                  // PAYMENT TOTALS
                  const Text(
                    'PAYMENT DETAILS',
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
                        _buildDetailRow('Payment Method', payMethod.toUpperCase(), isBold: true, valueColor: payMethod.toLowerCase().contains('gcash') ? const Color(0xFF38BDF8) : const Color(0xFF34D399)),
                        Divider(height: 16, color: Colors.white.withValues(alpha: 0.16)),
                        _buildDetailRow('Total Amount', '₱${totalAmt.toStringAsFixed(2)}', isBold: true),
                        if (payMethod.toLowerCase() == 'cash') ...[
                          _buildDetailRow('Cash Received', '₱${cashReceived.toStringAsFixed(2)}'),
                          _buildDetailRow('Change Disbursed', '₱${changeAmount.toStringAsFixed(2)}'),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              PrintHelper.printReceipt(sale);
                              SweetAlert.showToast(
                                'Official Invoice & Receipt sent to printer!',
                                type: SweetAlertType.success,
                                title: 'Printing Receipt',
                              );
                            },
                            icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF38BDF8)),
                            label: const Text('Print', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF0A3052),
                                  title: const Text('Delete Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  content: const Text('Are you sure you want to permanently delete this sales transaction record?', style: TextStyle(color: Color(0xFFBAE6FD))),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await SupabaseService.deleteSale(idStr);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    SweetAlert.showSuccess(context, 'Sales transaction deleted successfully.');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SweetAlert.showError(context, 'Failed to delete sale: $e');
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                            label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x66EF4444)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
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
                        child: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
