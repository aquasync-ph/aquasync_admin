import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class GenerateQrDialog extends StatefulWidget {
  final List<GallonItemModel> gallons;
  final VoidCallback onSuccess;
  final Function(GallonItemModel) onShowQr;
  final Function(String) onError;

  const GenerateQrDialog({
    super.key,
    required this.gallons,
    required this.onSuccess,
    required this.onShowQr,
    required this.onError,
  });

  @override
  State<GenerateQrDialog> createState() => _GenerateQrDialogState();
}

class _GenerateQrDialogState extends State<GenerateQrDialog> {
  String? selectedGallonId;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final unqoredGallons = widget.gallons.where((g) => !g.hasQr && g.status.toLowerCase() == 'available').toList();
    final availableGallons = unqoredGallons.isNotEmpty ? unqoredGallons : widget.gallons.where((g) => g.status.toLowerCase() == 'available').toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
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
                          'Generate AQUAZONE QR Code',
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
                const Text(
                  'Select an existing physical gallon container to generate and link its unique scannable AQUAZONE QR code with Last Name security marker.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Gallon Container',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedGallonId,
                  dropdownColor: const Color(0xFF0A3052),
                  hint: const Text('Select container...', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
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
                  items: availableGallons.map((g) {
                    final lastNameTag = g.assigned.split(' ').last.toUpperCase();
                    return DropdownMenuItem<String>(
                      value: g.id,
                      child: Text('${g.gallonCode} (${g.status}) • Tag: $lastNameTag ${g.hasQr ? "[Has QR]" : "[No QR]"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedGallonId = val);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD))),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: (_isGenerating || selectedGallonId == null) ? null : () async {
                        final gallon = availableGallons.firstWhere((g) => g.id == selectedGallonId);
                        final nav = Navigator.of(context);
                        setState(() => _isGenerating = true);
                        try {
                          await SupabaseService.generateQrForGallon(
                            gallonId: gallon.id,
                            gallonCode: gallon.gallonCode,
                          );
                          if (!mounted) return;
                          nav.pop();
                          widget.onSuccess();
                          widget.onShowQr(gallon);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isGenerating = false);
                          widget.onError(e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      icon: _isGenerating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: const Text('Generate AQUAZONE QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
