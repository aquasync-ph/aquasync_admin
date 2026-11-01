import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class EditDebtDialog extends StatefulWidget {
  final DebtItemModel debt;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const EditDebtDialog({
    super.key,
    required this.debt,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<EditDebtDialog> createState() => _EditDebtDialogState();
}

class _EditDebtDialogState extends State<EditDebtDialog> {
  late TextEditingController descCtrl;
  late TextEditingController amountCtrl;
  late TextEditingController paidAmountCtrl;
  late TextEditingController dueDateCtrl;
  late String selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    descCtrl = TextEditingController(text: widget.debt.description);
    amountCtrl = TextEditingController(text: widget.debt.amount.toStringAsFixed(2));
    paidAmountCtrl = TextEditingController(text: widget.debt.paidAmount.toStringAsFixed(2));
    dueDateCtrl = TextEditingController(text: widget.debt.dueDate);
    final rawStatus = widget.debt.status.toLowerCase().trim();
    if (rawStatus == 'paid') {
      selectedStatus = 'paid';
    } else if (rawStatus == 'partial' || rawStatus == 'partially_paid') {
      selectedStatus = 'partial';
    } else {
      selectedStatus = 'unpaid';
    }
  }

  @override
  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
    paidAmountCtrl.dispose();
    dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    final paid = double.tryParse(paidAmountCtrl.text.trim()) ?? 0.0;
    final desc = descCtrl.text.trim();
    final dueDateStr = dueDateCtrl.text.trim();

    if (amt <= 0) {
      widget.onError('Please enter a valid debt amount greater than 0.');
      return;
    }
    if (amt > 100000) {
      widget.onError('Debt amount cannot exceed ₱100,000.');
      return;
    }

    if (paid < 0) {
      widget.onError('Paid amount cannot be negative.');
      return;
    }
    if (paid > amt) {
      widget.onError('Paid amount cannot exceed the original debt amount.');
      return;
    }

    if (desc.isEmpty) {
      widget.onError('Please enter a description.');
      return;
    }
    if (desc.length > 100) {
      widget.onError('Description cannot exceed 100 characters.');
      return;
    }

    if (dueDateStr.isEmpty) {
      widget.onError('Due Date cannot be empty.');
      return;
    }
    final dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegExp.hasMatch(dueDateStr)) {
      widget.onError('Due Date must be in YYYY-MM-DD format.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateDebt(
        debtId: widget.debt.id,
        description: desc,
        amount: amt,
        paidAmount: paid,
        status: selectedStatus,
        dueDate: dueDateStr,
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
                              color: const Color(0x33F59E0B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x66FCD34D)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFFFCD34D), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Customer Debt',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Customer: ${widget.debt.customerName}',
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

                  const Text(
                    'Description / Notes (Max 100 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'Debt details',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20, color: Color(0xFFFCD34D)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFFCD34D)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Original Amount (₱)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: amountCtrl,
                              maxLength: 10,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFFCD34D)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paid Amount (₱)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: paidAmountCtrl,
                              maxLength: 10,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFFCD34D)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
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
                            const Text(
                              'Debt Status',
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
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'unpaid', child: Text('Unpaid', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'partial', child: Text('Partially Paid', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'paid', child: Text('Fully Paid', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => selectedStatus = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Date (YYYY-MM-DD)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: dueDateCtrl,
                              maxLength: 10,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.event_rounded, size: 20, color: Color(0xFFFCD34D)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFFCD34D)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
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
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Save Debt Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x33D97706),
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
