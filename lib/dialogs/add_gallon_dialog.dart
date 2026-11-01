import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/sweet_alert.dart';

class AddGallonDialog extends StatefulWidget {
  final List<CustomerModel>? customers;
  final List<ProductModel>? products;
  final VoidCallback onSuccess;
  final Function(String) onError;
  final VoidCallback? onOpenBatchMode;

  const AddGallonDialog({
    super.key,
    this.customers,
    this.products,
    required this.onSuccess,
    required this.onError,
    this.onOpenBatchMode,
  });

  @override
  State<AddGallonDialog> createState() => _AddGallonDialogState();
}

class _AddGallonDialogState extends State<AddGallonDialog> {
  late TextEditingController codeCtrl;
  late TextEditingController locationCtrl;
  String selectedStatus = 'available';
  String selectedContainerType = 'Standard 5-Gallon Container';
  List<String> _containerTypes = ['Standard 5-Gallon Container', 'Slim 5-Gallon Container', 'Round 5-Gallon Container'];
  String? selectedCustomerId;
  bool _isSaving = false;
  bool _hasGeneratedQr = false;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    codeCtrl = TextEditingController(text: '');
    locationCtrl = TextEditingController(text: 'AQUAZONE Water Refill Station');
    _initContainerTypes();
  }

  Future<void> _initContainerTypes() async {
    List<String> types = [];
    if (widget.products != null && widget.products!.isNotEmpty) {
      types = widget.products!.where((p) => p.isActive).map((p) => p.name).toList();
    } else {
      try {
        final raw = await SupabaseService.fetchProducts();
        final list = raw.map((m) => ProductModel.fromSupabase(m)).where((p) => p.isActive).map((p) => p.name).toList();
        if (list.isNotEmpty) types = list;
      } catch (_) {}
    }

    if (types.isNotEmpty) {
      if (mounted) {
        setState(() {
          _containerTypes = types;
          if (!_containerTypes.contains(selectedContainerType)) {
            selectedContainerType = _containerTypes.first;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  String get _customerLastName {
    if (selectedCustomerId == null || widget.customers == null) return 'AQUAZONE STOCK';
    final cust = widget.customers!.firstWhere(
      (c) => c.id == selectedCustomerId,
      orElse: () => CustomerModel(id: '', fullName: 'AQUAZONE STOCK', phone: '', address: '', rfidUid: '', isRfidActive: false, isActive: true, createdAt: ''),
    );
    final name = cust.fullName.trim();
    if (name.isEmpty) return 'AQUAZONE STOCK';
    final parts = name.split(' ');
    return parts.last.toUpperCase();
  }

  void _generateQr() {
    final randomCode = 'AQS-G-${(DateTime.now().millisecondsSinceEpoch % 900000) + 100000}';
    setState(() {
      codeCtrl.text = randomCode;
      _hasGeneratedQr = true;
    });
    SweetAlert.showGlobalSuccess('Unique 1-to-1 QR code generated for AQUAZONE!');
  }

  Future<void> _saveQrImage() async {
    final code = codeCtrl.text.trim();
    if (code.isEmpty || !_hasGeneratedQr) {
      widget.onError('Please generate a QR code first before saving.');
      return;
    }

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
          ..setAttribute('download', 'AQUAZONE_QR_${_customerLastName}_${code.replaceAll(' ', '_')}.png')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      SweetAlert.showGlobalSuccess('AQUAZONE QR Card for "$code" saved successfully.');
    } catch (e) {
      widget.onError('Failed to save QR image: $e');
    }
  }

  Future<void> _submit() async {
    final code = codeCtrl.text.trim();
    if (code.isEmpty || !_hasGeneratedQr) {
      widget.onError('Please click "Generate QR Code" to create a unique QR code before registering.');
      return;
    }

    final locationStr = locationCtrl.text.trim();
    if (locationStr.isEmpty) {
      widget.onError('Refill Station / Location cannot be empty.');
      return;
    }
    if (locationStr.length > 100) {
      widget.onError('Location cannot exceed 100 characters.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.addGallonWithQr(
        gallonCode: code,
        status: selectedStatus,
        customerId: selectedCustomerId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
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
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
            padding: const EdgeInsets.all(28),
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
                  // Header
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
                            child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Register Gallon & Generate QR',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'AQUAZONE 1-to-1 unique container identity',
                                style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (widget.onOpenBatchMode != null) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onOpenBatchMode!();
                              },
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                              label: const Text('Batch Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF38BDF8),
                                side: const BorderSide(color: Color(0xFF38BDF8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(height: 28, color: Colors.white.withValues(alpha: 0.18)),

                  // Info Banner with Batch Mode option
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0x330284C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x6638BDF8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'AQUAZONE Guarantee: Click "Generate QR Code" to create a strictly 1-to-1 unique scannable code with customer last name security marker.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                        if (widget.onOpenBatchMode != null) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onOpenBatchMode!();
                            },
                            icon: const Icon(Icons.dataset_linked_rounded, size: 14, color: Color(0xFF7DD3FC)),
                            label: const Text('Batch Generate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // QR Preview / Generator Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.5),
                    ),
                    child: !_hasGeneratedQr
                        ? Column(
                            children: [
                              Container(
                                height: 140,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_scanner_rounded, size: 36, color: Color(0xFF7DD3FC)),
                                    SizedBox(height: 8),
                                    Text(
                                      'No QR Code Generated Yet',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Click the button below to generate an AQUAZONE 1-to-1 QR code.',
                                      style: TextStyle(fontSize: 10, color: Color(0xFFBAE6FD)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _generateQr,
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                label: const Text('Generate AQUAZONE QR Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              RepaintBoundary(
                                key: _repaintBoundaryKey,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
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
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0284C7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.water_drop_rounded, size: 16, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          const Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'AQUAZONE',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.5,
                                                  color: Color(0xFF0284C7),
                                                ),
                                              ),
                                              Text(
                                                'WATER REFILL STATION',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // QR ImageView
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFBAE6FD)),
                                        ),
                                        child: QrImageView(
                                          data: codeCtrl.text.trim(),
                                          version: QrVersions.auto,
                                          size: 140.0,
                                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Gallon Code
                                      Text(
                                        codeCtrl.text,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Customer Last Name Security Marker Badge
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
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
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF075985),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'PROPERTY OF AQUAZONE • DO NOT SWAP WITH OTHER STATIONS',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _generateQr,
                                    icon: const Icon(Icons.refresh_rounded, size: 16),
                                    label: const Text('Generate New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF38BDF8),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: _saveQrImage,
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: const Text('Save QR Card', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Form Fields
                  if (widget.customers != null && widget.customers!.isNotEmpty) ...[
                    const Text(
                      'Assigned Customer (Owner Last Name Tag)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCustomerId,
                      dropdownColor: const Color(0xFF0A3052),
                      hint: const Text('Unassigned / AQUAZONE Station Stock', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.10),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                      items: widget.customers!.map((cust) {
                        return DropdownMenuItem<String>(
                          value: cust.id,
                          child: Text('${cust.fullName} (Last Name Tag: ${cust.fullName.split(" ").last.toUpperCase()})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedCustomerId = val);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Text(
                    'Container Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _containerTypes.contains(selectedContainerType) ? selectedContainerType : (_containerTypes.isNotEmpty ? _containerTypes.first : null),
                    dropdownColor: const Color(0xFF0A3052),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    items: _containerTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedContainerType = val);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Initial Container Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    dropdownColor: const Color(0xFF0A3052),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('Available', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'borrowed', child: Text('Borrowed', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'damaged', child: Text('Damaged', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedStatus = val);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Refill Station / Location (Max 100 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: locationCtrl,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'e.g. AQUAZONE Water Refill Station',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 20, color: Color(0xFF7DD3FC)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Register Container & QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
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
