import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class EditGallonDialog extends StatefulWidget {
  final GallonItemModel gallon;
  final List<CustomerModel>? customers;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const EditGallonDialog({
    super.key,
    required this.gallon,
    this.customers,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<EditGallonDialog> createState() => _EditGallonDialogState();
}

class _EditGallonDialogState extends State<EditGallonDialog> {
  late String selectedStatus;
  late String selectedContainerType;
  String? selectedCustomerId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    String rawStatus = widget.gallon.status.toLowerCase().trim().replaceAll(' ', '_');
    final allowedStatuses = ['available', 'out_for_delivery', 'borrowed', 'returned', 'lost', 'damaged', 'retired'];
    selectedStatus = allowedStatuses.contains(rawStatus) ? rawStatus : 'available';
    selectedContainerType = widget.gallon.containerType;
    selectedCustomerId = widget.gallon.customerId;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateGallonStatus(
        gallonId: widget.gallon.id,
        newStatus: selectedStatus,
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
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Container Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Gallon Code: ${widget.gallon.gallonCode}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
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
                    'Container Status',
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
                      DropdownMenuItem(value: 'returned', child: Text('Returned', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'lost', child: Text('Lost', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'damaged', child: Text('Damaged', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'retired', child: Text('Retired / Archived', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedStatus = val;
                          if (val == 'available' || val == 'returned' || val == 'retired') {
                            selectedCustomerId = null;
                          }
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Current Container Location',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (selectedStatus == 'available' || selectedStatus == 'returned' || selectedStatus == 'retired' || selectedCustomerId == null)
                                ? 'Aqua Pure Water Station'
                                : widget.customers?.firstWhere((c) => c.id == selectedCustomerId, orElse: () => CustomerModel(id: '', fullName: '', phone: '', address: 'Station', rfidUid: '', isRfidActive: false, isActive: true, createdAt: '')).address ?? 'Station',
                            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (widget.customers != null && widget.customers!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Assigned Customer',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCustomerId,
                      dropdownColor: const Color(0xFF0A3052),
                      hint: const Text('Unassigned / Station Stock', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
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
                          child: Text(cust.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCustomerId = val;
                          if (val != null) {
                            if (selectedStatus == 'available' || selectedStatus == 'returned') {
                              selectedStatus = 'borrowed';
                            }
                          }
                        });
                      },
                    ),
                  ],

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
                        label: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
