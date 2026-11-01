import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/status_badges.dart';

void showFullProofImageDialog(
  BuildContext context,
  String imageUrl, {
  required String orderNumber,
  required String driverName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                  SizedBox(height: 12),
                  Text('Failed to load Proof of Delivery image', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Proof of Delivery — $orderNumber ($driverName)',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}

void showProofOfDeliveryDialog(
  BuildContext context,
  DeliveryModel delivery, {
  VoidCallback? onProofUpdated,
}) {
  showDialog(
    context: context,
    builder: (context) => ProofOfDeliveryDialog(
      delivery: delivery,
    ),
  );
}

class ProofOfDeliveryDialog extends StatelessWidget {
  final DeliveryModel delivery;

  const ProofOfDeliveryDialog({
    super.key,
    required this.delivery,
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
          const SizedBox(width: 12),
          Expanded(
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
    final proofUrl = delivery.proofUrl.trim();
    final hasProofImage = proofUrl.isNotEmpty;
    final isDelivered = delivery.status.toLowerCase() == 'delivered' || delivery.status.toLowerCase() == 'completed';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: const Color(0xFA082A45),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x3838BDF8), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0x2038BDF8))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x3310B981),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4034D399)),
                        ),
                        child: const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Proof of Delivery',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                OrderStatusBadge(status: delivery.status),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Order: ${delivery.orderNumber}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF7DD3FC), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metadata card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DRIVER DISPATCH DETAILS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow('Assigned Driver', delivery.driverName.isEmpty ? 'Unassigned' : delivery.driverName, isBold: true, valueColor: const Color(0xFF38BDF8)),
                              _buildDetailRow('Customer Name', delivery.customerName),
                              _buildDetailRow('Dispatched At', delivery.assignedAt),
                              _buildDetailRow('Delivered At', delivery.deliveredAt),
                              _buildDetailRow('Payment Method', delivery.paymentMethod),
                              if (delivery.totalAmount > 0)
                                _buildDetailRow('Total Amount', '₱${delivery.totalAmount.toStringAsFixed(2)}', isBold: true, valueColor: const Color(0xFF34D399)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Image / Proof Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'DRIVER PROOF PHOTO',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 0.8),
                            ),
                            if (hasProofImage)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0x3310B981),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0x6634D399)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF34D399)),
                                    SizedBox(width: 4),
                                    Text('Photo Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        if (hasProofImage) ...[
                          GestureDetector(
                            onTap: () => showFullProofImageDialog(
                              context,
                              proofUrl,
                              orderNumber: delivery.orderNumber,
                              driverName: delivery.driverName,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  height: 240,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                                    color: Colors.black38,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      proofUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
                                            SizedBox(height: 8),
                                            Text('Unable to load proof image', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Click for Fullscreen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isDelivered ? Icons.task_alt_rounded : Icons.camera_alt_outlined,
                                  size: 40,
                                  color: isDelivered ? const Color(0xFF34D399) : const Color(0xFF7DD3FC),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isDelivered
                                      ? 'Order Delivered (No Photo Attached by Driver)'
                                      : 'No proof photo uploaded yet',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isDelivered
                                      ? 'Delivery status was completed and confirmed by driver on ${delivery.deliveredAt}.'
                                      : 'The driver will upload a proof photo on the Driver App upon completing delivery.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (delivery.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'DRIVER NOTES FROM DRIVER APP',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              delivery.notes,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x2038BDF8))),
                  ),
                  child: Row(
                    children: [
                      if (hasProofImage) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => showFullProofImageDialog(
                              context,
                              proofUrl,
                              orderNumber: delivery.orderNumber,
                              driverName: delivery.driverName,
                            ),
                            icon: const Icon(Icons.fullscreen_rounded, size: 16),
                            label: const Text('View Full Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0x8038BDF8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
