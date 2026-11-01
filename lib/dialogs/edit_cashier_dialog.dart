import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class EditCashierDialog extends StatefulWidget {
  final CashierModel cashier;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const EditCashierDialog({
    super.key,
    required this.cashier,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<EditCashierDialog> createState() => _EditCashierDialogState();
}

class _EditCashierDialogState extends State<EditCashierDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController addrCtrl;
  late bool canAssignDrivers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.cashier.fullName);
    emailCtrl = TextEditingController(text: widget.cashier.email == '—' ? '' : widget.cashier.email);
    phoneCtrl = TextEditingController(text: widget.cashier.phone == '—' ? '' : widget.cashier.phone);
    addrCtrl = TextEditingController(text: widget.cashier.address == '—' ? '' : widget.cashier.address);
    canAssignDrivers = widget.cashier.canAssignDrivers;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nameStr = nameCtrl.text.trim();
    if (nameStr.isEmpty) {
      widget.onError('Full Name cannot be empty.');
      return;
    }
    if (nameStr.length < 2) {
      widget.onError('Full Name must be at least 2 characters.');
      return;
    }
    if (nameStr.length > 50) {
      widget.onError('Full Name cannot exceed 50 characters.');
      return;
    }

    final phoneStr = phoneCtrl.text.trim();
    if (phoneStr.isNotEmpty && phoneStr.length != 11) {
      widget.onError('Phone number must be exactly 11 digits (e.g. 09171234567).');
      return;
    }

    final addrStr = addrCtrl.text.trim();
    if (addrStr.length > 100) {
      widget.onError('Station Address / Branch cannot exceed 100 characters.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateProfileFields(
        userId: widget.cashier.id,
        updates: {
          'full_name': nameStr,
          'phone': phoneStr,
          'address': addrStr,
          'can_assign_drivers': canAssignDrivers,
        },
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
            child: SingleChildScrollView(
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
                              color: const Color(0x33C084FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x66C084FC)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFFC084FC), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Cashier Profile',
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
                    'Cashier Full Name (Max 50 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    maxLength: 50,
                    decoration: InputDecoration(
                      hintText: 'e.g. Juan Dela Cruz',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.person_rounded, size: 20, color: Color(0xFFC084FC)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFC084FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC084FC), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Email Address',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    maxLength: 80,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true, // Typically email cannot be changed easily without extra auth steps
                    decoration: InputDecoration(
                      hintText: 'e.g. cashier@example.com',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.email_rounded, size: 20, color: Color(0xFFC084FC)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFC084FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC084FC), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600),
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
                      prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFFC084FC)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFC084FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC084FC), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Station Address / Branch (Max 100 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addrCtrl,
                    maxLength: 100,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Main Station Counter 1',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFC084FC)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFC084FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC084FC), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: SwitchListTile(
                      title: const Text('Authorize Driver Assignment & Order Acceptance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: const Text('Allows this cashier to accept orders and assign drivers on Cashier POS', style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                      value: canAssignDrivers,
                      activeTrackColor: const Color(0xFFC084FC).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFFC084FC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => canAssignDrivers = val),
                    ),
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
                            : const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Save Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x339333EA),
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
