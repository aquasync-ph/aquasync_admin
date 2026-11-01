import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AddUnassignedRfidDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AddUnassignedRfidDialog({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AddUnassignedRfidDialog> createState() => _AddUnassignedRfidDialogState();
}

class _AddUnassignedRfidDialogState extends State<AddUnassignedRfidDialog> {
  final uidCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uidStr = uidCtrl.text.trim();
    if (uidStr.isEmpty) {
      widget.onError('RFID UID cannot be empty.');
      return;
    }
    if (uidStr.length < 4) {
      widget.onError('RFID UID must be at least 4 characters.');
      return;
    }
    if (uidStr.length > 30) {
      widget.onError('RFID UID cannot exceed 30 characters.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.addUnassignedRfid(
        rfidUid: uidStr,
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
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x330284C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x4038BDF8)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.tap_and_play_rounded, color: Color(0xFF38BDF8), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Register Unassigned RFID',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0x330284C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x6638BDF8)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use this dialog to register new physical RFID cards into station inventory before assigning them to a customer.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  'RFID Card UID / Code (Max 30 chars)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: uidCtrl,
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'e.g. 04:A1:B2:C3:D4:E5:F6',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF7DD3FC)),
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

                const SizedBox(height: 24),
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
                          : const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Register RFID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
