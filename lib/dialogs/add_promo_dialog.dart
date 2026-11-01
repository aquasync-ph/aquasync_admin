import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';

class AddPromoDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AddPromoDialog({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AddPromoDialog> createState() => _AddPromoDialogState();
}

class _AddPromoDialogState extends State<AddPromoDialog> {
  final codeCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final minSpendCtrl = TextEditingController(text: '0');
  final maxUsesCtrl = TextEditingController(text: '0');
  
  String selectedDiscountType = 'fixed';
  bool isActive = true;
  bool _isSaving = false;

  DateTime startDateTime = DateTime.now();
  DateTime endDateTime = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    codeCtrl.dispose();
    valueCtrl.dispose();
    minSpendCtrl.dispose();
    maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? startDateTime : endDateTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) return;

    setState(() {
      final combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (isStart) {
        startDateTime = combined;
      } else {
        endDateTime = combined;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final y = dt.year;
    final m = twoDigits(dt.month);
    final d = twoDigits(dt.day);
    final h = twoDigits(dt.hour);
    final min = twoDigits(dt.minute);
    return '$y-$m-$d $h:$min';
  }

  Future<void> _submit() async {
    final code = codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      widget.onError('Promo code cannot be empty.');
      return;
    }
    if (code.length < 3) {
      widget.onError('Promo code must be at least 3 characters.');
      return;
    }
    if (code.length > 20) {
      widget.onError('Promo code cannot exceed 20 characters.');
      return;
    }

    final val = double.tryParse(valueCtrl.text.trim());
    if (val == null || val <= 0) {
      widget.onError('Please enter a valid discount value greater than 0.');
      return;
    }
    if (selectedDiscountType == 'percentage' && val > 100) {
      widget.onError('Percentage discount cannot exceed 100%.');
      return;
    }
    if (selectedDiscountType == 'fixed' && val > 100000) {
      widget.onError('Fixed discount value cannot exceed ₱100,000.');
      return;
    }

    final minSpend = double.tryParse(minSpendCtrl.text.trim()) ?? 0.0;
    if (minSpend < 0) {
      widget.onError('Minimum spend cannot be negative.');
      return;
    }
    if (minSpend > 1000000) {
      widget.onError('Minimum spend cannot exceed ₱1,000,000.');
      return;
    }

    final maxUses = int.tryParse(maxUsesCtrl.text.trim()) ?? 0;
    if (maxUses < 0) {
      widget.onError('Max usage limit cannot be negative.');
      return;
    }

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      widget.onError('Valid Until date & time must be after Valid From date & time.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.createPromo(
        code: code,
        discountValue: val,
        discountType: selectedDiscountType,
        minSpend: minSpend,
        isActive: isActive,
        validFrom: startDateTime.toIso8601String(),
        validUntil: endDateTime.toIso8601String(),
        maxUses: maxUses,
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
            constraints: const BoxConstraints(maxWidth: 540),
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
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.local_offer_rounded, color: Color(0xFF38BDF8), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Create New Promo Code',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

                  const Text('PROMO CODE (Max 20 chars)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'e.g. WATER50 or AQUA10',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20, color: Color(0xFF38BDF8)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DISCOUNT VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: valueCtrl,
                              maxLength: 10,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                hintText: 'e.g. 50 or 10',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DISCOUNT TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedDiscountType,
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
                                DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₱)', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => selectedDiscountType = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MINIMUM SPEND (₱)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: minSpendCtrl,
                              maxLength: 10,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MAX USAGE LIMIT (0 = Unlimited)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: maxUsesCtrl,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: '0 = Unlimited',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.people_outline_rounded, size: 20, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VALID FROM (START)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickDateTime(true),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.10),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDateTime(startDateTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                    const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF38BDF8)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VALID UNTIL (END)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickDateTime(false),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.10),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDateTime(endDateTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                    const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF38BDF8)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isActive,
                        activeColor: const Color(0xFF38BDF8),
                        onChanged: (val) => setState(() => isActive = val ?? true),
                      ),
                      const Text('Active (Available for users to apply)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
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
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Create Promo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
