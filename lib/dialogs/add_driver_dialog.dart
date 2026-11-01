import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';

class AddDriverDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AddDriverDialog({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameStr = nameCtrl.text.trim();
    if (nameStr.isEmpty) {
      widget.onError('Driver Full Name cannot be empty.');
      return;
    }
    if (nameStr.length < 2) {
      widget.onError('Driver Full Name must be at least 2 characters.');
      return;
    }
    if (nameStr.length > 50) {
      widget.onError('Driver Full Name cannot exceed 50 characters.');
      return;
    }

    final phoneStr = phoneCtrl.text.trim();
    if (phoneStr.isNotEmpty && phoneStr.length != 11) {
      widget.onError('Phone number must be exactly 11 digits (e.g. 09171234567).');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.createDriver(
        fullName: nameStr,
        phone: phoneStr,
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
                          child: const Icon(Icons.badge_outlined, color: Color(0xFF38BDF8), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Register New Delivery Driver',
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

                const Text(
                  'Driver Full Name (Max 50 chars)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: 'e.g. Juan Dela Cruz',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                    prefixIcon: const Icon(Icons.person_rounded, size: 20, color: Color(0xFF7DD3FC)),
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

                const SizedBox(height: 14),
                const Text(
                  'Phone Number (11 digits)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  maxLength: 11,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: 'e.g. 09171234567',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                    prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF7DD3FC)),
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
                      label: const Text('Register Driver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
