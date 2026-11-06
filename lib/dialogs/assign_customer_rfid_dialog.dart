import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class AssignCustomerRfidDialog extends StatefulWidget {
  final List<CustomerModel> customers;
  final CustomerModel? initialCustomer;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AssignCustomerRfidDialog({
    super.key,
    required this.customers,
    this.initialCustomer,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AssignCustomerRfidDialog> createState() => _AssignCustomerRfidDialogState();
}

class _AssignCustomerRfidDialogState extends State<AssignCustomerRfidDialog> {
  String? selectedCustomerId;
  List<CustomerModel> uniqueCustomers = [];
  late TextEditingController rfidCtrl;
  bool isActive = true;
  bool _isSaving = false;
  
  RealtimeChannel? _rfidSubscription;
  String? _lastScannedUid;

  @override
  void initState() {
    super.initState();
    
    // Deduplicate customer list by ID to prevent Dropdown assertion errors on duplicates
    final Map<String, CustomerModel> map = {};
    for (var c in widget.customers) {
      if (c.id.isNotEmpty) {
        map[c.id] = c;
      }
    }
    uniqueCustomers = map.values.toList();

    selectedCustomerId = widget.initialCustomer?.id ??
        (uniqueCustomers.isNotEmpty ? uniqueCustomers.first.id : null);

    final initialCust = uniqueCustomers.firstWhere(
      (c) => c.id == selectedCustomerId,
      orElse: () => uniqueCustomers.isNotEmpty
          ? uniqueCustomers.first
          : CustomerModel(
              id: '',
              fullName: '',
              phone: '',
              address: '',
              rfidUid: '',
              isRfidActive: false,
              isActive: true,
              createdAt: '',
            ),
    );

    rfidCtrl = TextEditingController(text: initialCust.rfidUid);
    isActive = initialCust.isRfidActive;

    _listenForLiveRfidScans();
  }

  void _listenForLiveRfidScans() async {
    // 1. Fetch latest unassigned card if empty
    try {
      final unassignedList = await SupabaseService.fetchUnassignedRfidCards();
      if (unassignedList.isNotEmpty && mounted) {
        final latest = unassignedList.first;
        final codeStr = latest['code']?.toString() ?? '';
        if (codeStr.isNotEmpty && rfidCtrl.text.isEmpty) {
          setState(() {
            rfidCtrl.text = codeStr;
            _lastScannedUid = codeStr;
          });
        }
      }
    } catch (_) {}

    // 2. Real-time subscription to ESP32 hardware card scans
    try {
      _rfidSubscription = SupabaseService.subscribeToTableChanges(
        channelName: 'public:assign_rfid_dialog_${DateTime.now().millisecondsSinceEpoch}',
        table: 'rfid_qr_records',
        onData: (payload) {
          if (!mounted) return;
          final newRecord = payload.newRecord;
          if (newRecord.isNotEmpty) {
            final codeType = newRecord['code_type']?.toString().toUpperCase();
            final code = newRecord['code']?.toString().trim();
            if (codeType == 'RFID' && code != null && code.isNotEmpty) {
              setState(() {
                rfidCtrl.text = code;
                _lastScannedUid = code;
              });
            }
          }
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_rfidSubscription != null) {
      SupabaseService.client.removeChannel(_rfidSubscription!);
    }
    rfidCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (selectedCustomerId == null || selectedCustomerId!.isEmpty) {
      widget.onError('Please select a customer.');
      return;
    }
    final uid = rfidCtrl.text.trim();
    if (uid.isEmpty) {
      widget.onError('RFID UID cannot be empty.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.assignCustomerRfid(
        customerId: selectedCustomerId!,
        rfidUid: uid,
        isActive: isActive,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      String msg = e.toString().replaceAll('Exception: ', '');
      widget.onError(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validValue = (selectedCustomerId != null && uniqueCustomers.any((c) => c.id == selectedCustomerId))
        ? selectedCustomerId
        : (uniqueCustomers.isNotEmpty ? uniqueCustomers.first.id : null);

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
                    const Text(
                      'Register Customer Loyalty RFID Card',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
                    ),
                  ],
                ),
                Divider(height: 20, color: Colors.white.withValues(alpha: 0.18)),
                
                // Realtime Hardware Scanner Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _lastScannedUid != null
                        ? const Color(0x3310B981)
                        : const Color(0x330284C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lastScannedUid != null
                          ? const Color(0xFF10B981)
                          : const Color(0xFF38BDF8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastScannedUid != null ? Icons.check_circle_rounded : Icons.sensors_rounded,
                        color: _lastScannedUid != null ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lastScannedUid != null
                              ? 'Card Auto-Filled: $_lastScannedUid'
                              : 'Tap your card on the RFID Scanner to auto-fill UID',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _lastScannedUid != null ? const Color(0xFF34D399) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Text('SELECT CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: validValue,
                  dropdownColor: const Color(0xFF0A3052),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                  ),
                  items: uniqueCustomers.map((c) {
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final selected = uniqueCustomers.firstWhere((c) => c.id == val);
                      setState(() {
                        selectedCustomerId = val;
                        rfidCtrl.text = selected.rfidUid;
                        isActive = selected.isRfidActive;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: rfidCtrl,
                  decoration: InputDecoration(
                    labelText: 'Loyalty RFID Card UID',
                    labelStyle: const TextStyle(color: Color(0xFFBAE6FD)),
                    hintText: 'e.g. 04:A2:8F:91:XX',
                    hintStyle: const TextStyle(color: Color(0xFFBAE6FD)),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF7DD3FC)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                  ),
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Card Active Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  value: isActive,
                  activeTrackColor: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFF38BDF8),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => isActive = val),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD))),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Loyalty Card', style: TextStyle(fontWeight: FontWeight.bold)),
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
