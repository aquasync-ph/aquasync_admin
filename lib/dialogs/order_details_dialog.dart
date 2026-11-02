import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/status_badges.dart';
import '../widgets/sweet_alert.dart';
import '../services/supabase_service.dart';
import '../utils/print_helper.dart';
import 'proof_of_delivery_dialog.dart';

void showFullReceiptImageDialog(
  BuildContext context,
  String url, {
  String? orderNumber,
  String? referenceNumber,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: const Color(0xFF0A3052),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x3838BDF8)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x330284C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderNumber != null && orderNumber.isNotEmpty
                              ? 'GCash Receipt — $orderNumber'
                              : 'Online Payment Receipt Screenshot',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (referenceNumber != null && referenceNumber.isNotEmpty)
                          Text(
                            'Ref No: $referenceNumber',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFFBAE6FD), size: 20),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SmartReceiptImageViewer(
                  primaryUrl: url,
                  orderNumber: orderNumber,
                  referenceNumber: referenceNumber,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SmartReceiptImageViewer extends StatefulWidget {
  final String primaryUrl;
  final String? orderNumber;
  final String? referenceNumber;

  const SmartReceiptImageViewer({
    super.key,
    required this.primaryUrl,
    this.orderNumber,
    this.referenceNumber,
  });

  @override
  State<SmartReceiptImageViewer> createState() => _SmartReceiptImageViewerState();
}

class _SmartReceiptImageViewerState extends State<SmartReceiptImageViewer> {
  late List<String> _candidateUrls;
  int _currentIndex = 0;
  bool _allFailed = false;

  @override
  void initState() {
    super.initState();
    _candidateUrls = [];
    if (widget.primaryUrl.trim().isNotEmpty) {
      _candidateUrls.add(widget.primaryUrl.trim());
    }

    final ord = widget.orderNumber?.trim() ?? '';
    final ref = widget.referenceNumber?.trim() ?? '';

    if (ord.isNotEmpty) {
      final cleanOrd = ord.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
      final numOnlyOrd = ord.replaceAll(RegExp(r'[^0-9]'), '');

      for (final idToTry in [ord, cleanOrd, numOnlyOrd]) {
        if (idToTry.isEmpty) continue;
        for (final bucket in ['receipts', 'user_assets', 'payments', 'payment_proofs', 'proofs', 'gcash_receipts']) {
          for (final prefix in ['', 'receipts/', 'payments/', 'gcash/']) {
            for (final ext in ['jpg', 'png', 'jpeg', 'webp']) {
              _candidateUrls.add(SupabaseService.client.storage.from(bucket).getPublicUrl('$prefix$idToTry.$ext'));
            }
          }
        }
      }
    }
    if (ref.isNotEmpty && ref != ord) {
      final cleanRef = ref.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
      final numOnlyRef = ref.replaceAll(RegExp(r'[^0-9]'), '');

      for (final idToTry in [ref, cleanRef, numOnlyRef]) {
        if (idToTry.isEmpty) continue;
        for (final bucket in ['receipts', 'user_assets', 'payments', 'payment_proofs', 'proofs', 'gcash_receipts']) {
          for (final prefix in ['', 'receipts/', 'payments/', 'gcash/']) {
            for (final ext in ['jpg', 'png', 'jpeg', 'webp']) {
              _candidateUrls.add(SupabaseService.client.storage.from(bucket).getPublicUrl('$prefix$idToTry.$ext'));
            }
          }
        }
      }
    }

    _candidateUrls = _candidateUrls.toSet().toList();
    if (_candidateUrls.isEmpty) {
      _allFailed = true;
    }
  }

  void _tryNextUrl() {
    if (_currentIndex + 1 < _candidateUrls.length) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _allFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allFailed || _candidateUrls.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.05),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'GCash Payment Verified via App',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GCash Reference No.', style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 12)),
                        Text(
                          widget.referenceNumber != null && widget.referenceNumber!.isNotEmpty
                              ? widget.referenceNumber!
                              : '—',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Number', style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 12)),
                        Text(
                          widget.orderNumber ?? '—',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Note: As configured in the user order form, this GCash payment was verified and recorded with the transaction reference number submitted by the customer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentUrl = _candidateUrls[_currentIndex];

    return Image.network(
      currentUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryNextUrl();
        });
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
        );
      },
    );
  }
}

class OrderDetailsDialog extends StatefulWidget {
  final OrderItemModel order;
  final VoidCallback? onApprove;
  final Function(String reason)? onReject;
  final VoidCallback? onAssignDriver;
  final VoidCallback? onDelete;
  final bool isProcessing;

  const OrderDetailsDialog({
    super.key,
    required this.order,
    this.onApprove,
    this.onReject,
    this.onAssignDriver,
    this.onDelete,
    this.isProcessing = false,
  });

  @override
  State<OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<OrderDetailsDialog> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await SupabaseService.fetchOrderStatusHistory(widget.order.id);
      if (mounted) {
        setState(() {
          _history = data;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _showRejectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A3052),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x3838BDF8)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Reject Customer Order',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please enter a reason for rejecting Order ${widget.order.displayId}. This feedback will be sent directly to the customer.',
              style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Invalid GCash reference number, unreadable receipt screenshot, or outside delivery area...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF7DD3FC)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              if (widget.onReject != null) {
                widget.onReject!(reason);
              }
            },
            icon: const Icon(Icons.cancel_schedule_send_rounded, size: 16),
            label: const Text('Reject & Send Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailLine(String label, String? value, {Color? valueColor, bool isBold = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFBAE6FD),
            ),
          ),
          Flexible(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReceiptSection() {
    final payMethod = widget.order.payment.toUpperCase();
    final isGcash = payMethod.contains('GCASH') ||
        payMethod.contains('MAYA') ||
        payMethod.contains('PAYMONGO') ||
        payMethod.contains('CARD') ||
        payMethod.contains('ONLINE') ||
        payMethod.contains('E-WALLET') ||
        payMethod.contains('DIGITAL');

    final isOnline = isGcash;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0x220284C7)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0x5538BDF8)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOnline ? Icons.verified_rounded : Icons.payments_rounded,
                    size: 16,
                    color: isOnline ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PAYMENT METHOD: ${widget.order.payment.isNotEmpty ? widget.order.payment.toUpperCase() : "COD"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0x3310B981) : const Color(0x33FBBF24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOnline ? 'GCash / Digital Payment' : 'Cash on Delivery (COD)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailLine(
            'Transaction Ref No.',
            widget.order.referenceNumber.isNotEmpty
                ? widget.order.referenceNumber
                : (isOnline ? 'Verified via OCR / PayMongo' : 'N/A (Cash)'),
            valueColor: const Color(0xFF38BDF8),
          ),
          if (isOnline && widget.order.receiptUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'UPLOADED RECEIPT PREVIEW:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => showFullReceiptImageDialog(
                context,
                widget.order.receiptUrl,
                orderNumber: widget.order.displayId,
                referenceNumber: widget.order.referenceNumber,
              ),
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.order.receiptUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Colors.white38, size: 36),
                              SizedBox(height: 4),
                              Text('Failed to load image', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Click to Expand', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showFullReceiptImageDialog(
                      context,
                      widget.order.receiptUrl,
                      orderNumber: widget.order.displayId,
                      referenceNumber: widget.order.referenceNumber,
                    ),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 15),
                    label: const Text('View Full Receipt Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0x8038BDF8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.order.proofUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'PROOF OF DELIVERY (DRIVER UPLOAD):',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF34D399), letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => showFullProofImageDialog(
                context,
                widget.order.proofUrl,
                orderNumber: widget.order.displayId,
                driverName: widget.order.driver.isNotEmpty ? widget.order.driver : 'Driver',
              ),
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.4)),
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.order.proofUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, color: Colors.white38, size: 36),
                              SizedBox(height: 4),
                              Text('Failed to load proof image', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('View Driver Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.order.status.toLowerCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
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
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF38BDF8), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.order.displayId,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OrderStatusBadge(status: widget.order.status),
                            ],
                          ),
                          Text(
                            widget.order.createdAt.isNotEmpty
                                ? 'Placed on ${widget.order.createdAt.replaceAll("T", " ").split(".").first}'
                                : 'Order Details & Processing Dashboard',
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

              // CUSTOMER INFORMATION
              const Text(
                'CUSTOMER INFORMATION',
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
                    _buildDetailLine('Customer Name', widget.order.customerName.isNotEmpty ? widget.order.customerName : widget.order.customer),
                    _buildDetailLine('Phone Number', widget.order.customerPhone),
                    if (widget.order.customerEmail.isNotEmpty && widget.order.customerEmail != '—')
                      _buildDetailLine('Email Address', widget.order.customerEmail),
                    _buildDetailLine(
                      'Delivery / Pickup Address',
                      widget.order.deliveryAddress.isNotEmpty ? widget.order.deliveryAddress : widget.order.address,
                    ),
                    if (widget.order.deliverySchedule.isNotEmpty)
                      _buildDetailLine('Delivery Schedule', widget.order.deliverySchedule, valueColor: const Color(0xFF34D399)),
                    if (widget.order.notes.isNotEmpty)
                      _buildDetailLine('Order Notes', widget.order.notes, valueColor: const Color(0xFFFCD34D)),
                    _buildDetailLine('Fulfillment', widget.order.fulfillmentType.isNotEmpty ? widget.order.fulfillmentType : '—'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // PAYMENT & RECEIPT VERIFICATION
              const Text(
                'PAYMENT & RECEIPT VERIFICATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
              ),
              const SizedBox(height: 8),
              _buildPaymentReceiptSection(),

              const SizedBox(height: 18),

              // REJECTION / CANCELLATION REASON DISPLAY
              () {
                final cancelReason = widget.order.rejectionReason.isNotEmpty 
                    ? widget.order.rejectionReason 
                    : (widget.order.notes.toLowerCase().contains('reason') || widget.order.notes.toLowerCase().contains('rejected') || widget.order.notes.toLowerCase().contains('cancelled') || widget.order.notes.toLowerCase().contains('admin') ? widget.order.notes : '');
                
                if (s == 'cancelled' || s == 'rejected' || cancelReason.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x33EF4444),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66EF4444)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ADMIN REJECTION / CANCELLATION FEEDBACK',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cancelReason.isNotEmpty ? cancelReason : 'Order cancelled / rejected.',
                                style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }(),
              const SizedBox(height: 18),

              // ORDER ITEMS SUMMARY
              const Text(
                'ITEMIZED ORDER SUMMARY',
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
                    ...widget.order.itemsList.map((item) {
                      final name = item['name']?.toString() ?? 'Water Refill';
                      final q = item['qty'] ?? 1;
                      final unitPrice = (item['unit_price'] is num) ? (item['unit_price'] as num).toDouble() : 0.0;
                      final lineTotal = (item['total'] is num) ? (item['total'] as num).toDouble() : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                            Text(
                              '$q × ₱${unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '₱${lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white24, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL AMOUNT DUE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                        Text('₱${widget.order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // DRIVER
              const Text(
                'DRIVER DISPATCH ASSIGNMENT',
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
                child: _buildDetailLine(
                  'Assigned Driver',
                  widget.order.driver.isEmpty ? 'Not Assigned' : widget.order.driver,
                  valueColor: widget.order.driver.isEmpty ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                ),
              ),

              const SizedBox(height: 24),

              // REAL TIMELINE
              const Text(
                'ORDER STATUS AUDIT HISTORY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: _isLoadingHistory
                    ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Color(0xFF38BDF8))))
                    : _history.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No history found.', style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)))))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _history.map((record) {
                              final statusStr = record['status']?.toString().toUpperCase() ?? 'UNKNOWN';
                              final notes = record['notes']?.toString() ?? 'Status updated to ${record['status']}';
                              final createdStr = record['created_at']?.toString() ?? '';
                              final timeFormat = createdStr.contains('T') ? createdStr.replaceAll('T', ' ').split('.').first : createdStr;
                              String changedBy = 'System';
                              if (record['profiles'] != null && record['profiles'] is Map) {
                                changedBy = record['profiles']['full_name']?.toString() ?? 'System';
                              } else if (record['changed_by'] != null) {
                                changedBy = 'Admin UID: ${record['changed_by'].toString().substring(0, 8)}...';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF38BDF8),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Container(width: 2, height: 32, color: Colors.white.withValues(alpha: 0.18)),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(statusStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                              Text(timeFormat, style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(notes, style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD))),
                                          const SizedBox(height: 2),
                                          Text('By: $changedBy', style: const TextStyle(fontSize: 10, color: Color(0xFF93C5FD))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ),

              const SizedBox(height: 24),

              // ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final List<Map<String, dynamic>> saleItems = widget.order.itemsList.isNotEmpty
                          ? widget.order.itemsList.map((item) => {
                              'product_name': item['name']?.toString() ?? 'Water Refill',
                              'quantity': item['qty'] ?? widget.order.qty,
                              'unit_price': (item['unit_price'] is num) ? (item['unit_price'] as num).toDouble() : (widget.order.qty > 0 ? (widget.order.totalAmount / widget.order.qty) : widget.order.totalAmount),
                              'subtotal': (item['total'] is num) ? (item['total'] as num).toDouble() : widget.order.totalAmount,
                            }).toList()
                          : [
                              {
                                'product_name': 'Water Refill Container',
                                'quantity': widget.order.qty,
                                'unit_price': widget.order.qty > 0 ? (widget.order.totalAmount / widget.order.qty) : widget.order.totalAmount,
                                'subtotal': widget.order.totalAmount,
                              }
                            ];

                      final saleData = {
                        'id': widget.order.id,
                        'invoice_number': widget.order.displayId,
                        'receipt_number': widget.order.displayId.replaceAll('ORD-', 'RCP-'),
                        'customer_name': widget.order.customerName.isNotEmpty ? widget.order.customerName : widget.order.customer,
                        'notes': widget.order.notes,
                        'payment_method': widget.order.payment,
                        'is_walk_in': widget.order.isWalkIn,
                        'order_type': widget.order.orderType.isNotEmpty ? widget.order.orderType : 'Online',
                        'classification': 'Online',
                        'total_amount': widget.order.totalAmount,
                        'created_at': widget.order.createdAt,
                        'sale_items': saleItems,
                      };
                      PrintHelper.printReceipt(saleData);
                      SweetAlert.showToast(
                        'Official Invoice & Receipt sent to printer!',
                        type: SweetAlertType.success,
                        title: 'Printing Receipt',
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFF38BDF8)),
                    label: const Text('Print Invoice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (s == 'pending' && widget.onReject != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: widget.isProcessing ? null : _showRejectDialog,
                      icon: widget.isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(widget.isProcessing ? 'Rejecting...' : 'Reject Order', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: const Color(0x33EF4444),
                      ),
                    ),
                  ],
                  if (s == 'pending' && widget.onApprove != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: widget.isProcessing
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              widget.onApprove!();
                            },
                      icon: widget.isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(widget.isProcessing ? 'Approving...' : 'Approve Order', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: const Color(0x3310B981),
                      ),
                    ),
                  ],
                  if (s == 'confirmed' && widget.onAssignDriver != null) ...[
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onAssignDriver!();
                      },
                      icon: const Icon(Icons.badge_outlined, size: 16),
                      label: const Text('Assign Driver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: const Color(0x330284C7),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
