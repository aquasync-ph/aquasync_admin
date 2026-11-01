import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class AssignDriverDialog extends StatefulWidget {
  final OrderItemModel order;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AssignDriverDialog({
    super.key,
    required this.order,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends State<AssignDriverDialog> {
  String? selectedDriverId;
  List<DriverModel> modalDrivers = [];
  bool isLoadingDrivers = true;
  bool hasStartedFetching = false;
  String? fetchError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  void _fetchDrivers() {
    if (hasStartedFetching) return;
    hasStartedFetching = true;
    SupabaseService.fetchDrivers().then((raw) {
      if (mounted) {
        setState(() {
          final uniqueDrivers = <String, DriverModel>{};
          for (var m in raw) {
            final driver = DriverModel.fromSupabase(m);
            uniqueDrivers[driver.id] = driver;
          }
          modalDrivers = uniqueDrivers.values.toList();
          isLoadingDrivers = false;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          fetchError = err.toString();
          isLoadingDrivers = false;
        });
      }
    });
  }

  Widget _buildDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (selectedDriverId == null || selectedDriverId!.isEmpty) {
      widget.onError('Please select a driver first.');
      return;
    }

    final chosenDriver = modalDrivers.firstWhere(
      (d) => d.id == selectedDriverId,
      orElse: () => DriverModel(id: selectedDriverId!, fullName: 'Driver', isActive: true, createdAt: ''),
    );

    setState(() => _isSaving = true);
    try {
      await SupabaseService.assignDriver(
        orderId: widget.order.id,
        driverId: chosenDriver.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.order.driver = chosenDriver.fullName;
      widget.order.status = 'assigned';
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
                    const Text(
                      'Assign Delivery Driver',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailLine('Order ID', widget.order.displayId),
                      _buildDetailLine('Customer', widget.order.customer),
                      _buildDetailLine('Address', widget.order.address),
                      _buildDetailLine('Quantity', '${widget.order.qty} gallon(s)'),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  'Select Registered Driver',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF7DD3FC),
                  ),
                ),
                const SizedBox(height: 8),

                if (isLoadingDrivers)
                  Container(
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Loading registered drivers...',
                          style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                        ),
                      ],
                    ),
                  )
                else if (fetchError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x33EF4444),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66FCA5A5)),
                    ),
                    child: Text(
                      'Failed to load drivers: $fetchError',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFFCA5A5)),
                    ),
                  )
                else if (modalDrivers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x33F59E0B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x66FCD34D)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFCD34D), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No registered drivers found in database.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFCD34D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: selectedDriverId,
                    dropdownColor: const Color(0xFF0A3052),
                    hint: const Text(
                      'Choose a registered driver',
                      style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                    ),
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    items: modalDrivers.map((driver) {
                      return DropdownMenuItem<String>(
                        value: driver.id,
                        child: Text(
                          driver.fullName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDriverId = val;
                      });
                    },
                  ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.badge_outlined, size: 16),
                      label: const Text(
                        'Assign Driver',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
