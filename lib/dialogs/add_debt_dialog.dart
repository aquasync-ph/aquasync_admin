import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class AddDebtDialog extends StatefulWidget {
  final List<CustomerModel> customers;
  final List<OrderItemModel> orders;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AddDebtDialog({
    super.key,
    required this.customers,
    required this.orders,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  String? selectedCustomerId;
  String? selectedOrderId;
  final descCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final dueDateCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    dueDateCtrl.text = '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-${nextMonth.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
    dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (selectedCustomerId == null || selectedCustomerId!.isEmpty) {
      widget.onError('Please select a customer.');
      return;
    }

    final amountStr = amountCtrl.text.trim();
    final amt = double.tryParse(amountStr) ?? 0.0;
    if (amt <= 0) {
      widget.onError('Please enter a valid debt amount greater than 0.');
      return;
    }
    if (amt > 100000) {
      widget.onError('Debt amount cannot exceed ₱100,000.');
      return;
    }

    final descStr = descCtrl.text.trim();
    if (descStr.isEmpty) {
      widget.onError('Please enter a description for the customer debt.');
      return;
    }
    if (descStr.length > 100) {
      widget.onError('Description cannot exceed 100 characters.');
      return;
    }

    final dueDateStr = dueDateCtrl.text.trim();
    if (dueDateStr.isEmpty) {
      widget.onError('Due Date cannot be empty.');
      return;
    }

    // Basic date validation YYYY-MM-DD
    final dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegExp.hasMatch(dueDateStr)) {
      widget.onError('Due Date must be in YYYY-MM-DD format.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.createDebt(
        customerId: selectedCustomerId!,
        orderId: selectedOrderId,
        description: descStr,
        amount: amt,
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
    final availableOrders = selectedCustomerId == null
        ? <OrderItemModel>[]
        : widget.orders.where((o) {
            final cust = widget.customers.firstWhere(
              (c) => c.id == selectedCustomerId,
              orElse: () => CustomerModel(id: '', fullName: '', phone: '', address: '', rfidUid: '', isRfidActive: false, isActive: true, createdAt: ''),
            );
            return o.customer == cust.fullName || o.customer.toLowerCase().contains(cust.fullName.toLowerCase());
          }).toList();

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
                            child: const Icon(Icons.request_quote_rounded, color: Color(0xFFFCD34D), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Record Customer Debt',
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
                    'Customer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCustomerId,
                    dropdownColor: const Color(0xFF0A3052),
                    hint: const Text('Select customer', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    items: widget.customers.map((cust) {
                      return DropdownMenuItem<String>(
                        value: cust.id,
                        child: Text(cust.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCustomerId = val;
                        selectedOrderId = null;
                      });
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Related Order (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOrderId,
                    dropdownColor: const Color(0xFF0A3052),
                    hint: const Text('Unlinked / General Credit', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFCD34D), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    items: availableOrders.map((ord) {
                      return DropdownMenuItem<String>(
                        value: ord.id,
                        child: Text('Order ${ord.displayId} (₱${ord.totalAmount.toStringAsFixed(2)})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedOrderId = val);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Debt Description / Notes (Max 100 chars)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'e.g. Unpaid 5-gallon refills for August',
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
                              'Total Debt Amount (₱)',
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
                                hintText: '0.00',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.payments_rounded, size: 20, color: Color(0xFFFCD34D)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFFFCD34D)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
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
                              'Due Date (YYYY-MM-DD)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: dueDateCtrl,
                              maxLength: 10,
                              decoration: InputDecoration(
                                hintText: '2025-10-15',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
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
                            : const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Record Customer Debt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
