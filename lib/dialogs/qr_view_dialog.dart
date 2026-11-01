import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../widgets/sweet_alert.dart';

class QrViewDialog extends StatelessWidget {
  final GallonItemModel gallon;

  QrViewDialog({super.key, required this.gallon});

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  String get _customerLastName {
    final assignedStr = gallon.assigned.trim();
    if (assignedStr.isEmpty ||
        assignedStr == '—' ||
        assignedStr.toLowerCase().contains('available') ||
        assignedStr.toLowerCase().contains('station stock')) {
      return 'AQUAZONE STOCK';
    }
    final parts = assignedStr.split(' ');
    if (parts.isNotEmpty) {
      return parts.last.toUpperCase();
    }
    return assignedStr.toUpperCase();
  }

  Future<void> _saveQrImage(BuildContext context) async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'AQUAZONE_QR_${_customerLastName}_${gallon.gallonCode.replaceAll(' ', '_')}.png')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      SweetAlert.showGlobalSuccess('AQUAZONE QR Card for "${gallon.gallonCode}" saved successfully.');
    } catch (e) {
      SweetAlert.showGlobalError('Failed to save QR image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrValue = gallon.qrCode ?? gallon.gallonCode;
    final statusText = gallon.isQrActive ? 'ACTIVE' : (gallon.hasQr ? 'INACTIVE' : 'NOT REGISTERED');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8), size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Gallon QR Preview & Identity',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

                  // OFFICIAL PRINTABLE AQUAZONE QR CARD
                  RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0284C7), width: 2.0),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          // AQUAZONE Brand Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0284C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.water_drop_rounded, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AQUAZONE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  Text(
                                    'WATER REFILL STATION',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // QR Code Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: QrImageView(
                              data: qrValue,
                              version: QrVersions.auto,
                              size: 160.0,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Gallon Code
                          Text(
                            qrValue,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Customer Last Name Security Badge Marker
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'CONTAINER OWNER / LAST NAME',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _customerLastName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF075985),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PROPERTY OF AQUAZONE • DO NOT SWAP WITH OTHER STATIONS',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DETAILS METRICS
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Station Brand:', 'AQUAZONE Water Refill Station'),
                        const SizedBox(height: 6),
                        _buildDetailRow('Owner Last Name:', _customerLastName),
                        const SizedBox(height: 6),
                        _buildDetailRow('Gallon Code:', gallon.gallonCode),
                        const SizedBox(height: 6),
                        _buildDetailRow('QR Code Value:', qrValue),
                        const SizedBox(height: 6),
                        _buildDetailRow('Status:', statusText),
                        const SizedBox(height: 6),
                        _buildDetailRow('Date Generated:', gallon.qrCreatedAt ?? gallon.createdAt),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _saveQrImage(context),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Save QR Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBAE6FD)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
