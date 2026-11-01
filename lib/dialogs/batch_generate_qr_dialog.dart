import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../utils/print_helper.dart';
import '../widgets/sweet_alert.dart';

class BatchGenerateQrDialog extends StatefulWidget {
  final List<CustomerModel>? customers;
  final List<ProductModel>? products;
  final List<GallonItemModel>? gallons;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const BatchGenerateQrDialog({
    super.key,
    this.customers,
    this.products,
    this.gallons,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<BatchGenerateQrDialog> createState() => _BatchGenerateQrDialogState();
}

class _BatchGenerateQrDialogState extends State<BatchGenerateQrDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _batchCount = 5;
  String selectedStatus = 'available';
  String selectedContainerType = 'Standard 5-Gallon Container';
  List<String> _containerTypes = ['Standard 5-Gallon Container', 'Slim 5-Gallon Container', 'Round 5-Gallon Container'];
  String? selectedCustomerId;
  late TextEditingController locationCtrl;

  bool _isSaving = false;
  List<Map<String, String>> _generatedResults = [];
  bool _showSuccessPreview = false;

  // Existing gallons without QR selection
  Set<String> _selectedGallonIdsForQr = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    locationCtrl = TextEditingController(text: 'AQUAZONE Water Refill Station');
    _initContainerTypes();
    _initUnqoredGallons();
  }

  Future<void> _initContainerTypes() async {
    List<String> types = [];
    if (widget.products != null && widget.products!.isNotEmpty) {
      types = widget.products!.where((p) => p.isActive).map((p) => p.name).toList();
    } else {
      try {
        final raw = await SupabaseService.fetchProducts();
        final list = raw.map((m) => ProductModel.fromSupabase(m)).where((p) => p.isActive).map((p) => p.name).toList();
        if (list.isNotEmpty) types = list;
      } catch (_) {}
    }

    if (types.isNotEmpty && mounted) {
      setState(() {
        _containerTypes = types;
        if (!_containerTypes.contains(selectedContainerType)) {
          selectedContainerType = _containerTypes.first;
        }
      });
    }
  }

  void _initUnqoredGallons() {
    if (widget.gallons != null) {
      final unqored = widget.gallons!.where((g) => !g.hasQr && g.status.toLowerCase() != 'retired').toList();
      _selectedGallonIdsForQr = unqored.map((g) => g.id).toSet();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  String get _customerLastName {
    if (selectedCustomerId == null || widget.customers == null) return 'AQUAZONE STOCK';
    final cust = widget.customers!.firstWhere(
      (c) => c.id == selectedCustomerId,
      orElse: () => CustomerModel(id: '', fullName: 'AQUAZONE STOCK', phone: '', address: '', rfidUid: '', isRfidActive: false, isActive: true, createdAt: ''),
    );
    final name = cust.fullName.trim();
    if (name.isEmpty) return 'AQUAZONE STOCK';
    final parts = name.split(' ');
    return parts.last.toUpperCase();
  }

  Future<void> _submitBatchRegister() async {
    if (_batchCount < 1 || _batchCount > 100) {
      widget.onError('Batch quantity must be between 1 and 100.');
      return;
    }

    final loc = locationCtrl.text.trim();
    if (loc.isEmpty) {
      widget.onError('Refill Station / Location cannot be empty.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final results = await SupabaseService.batchAddGallonsWithQr(
        count: _batchCount,
        status: selectedStatus,
        containerType: selectedContainerType,
        customerId: selectedCustomerId,
        location: loc,
      );

      final formattedList = results.map((item) {
        return {
          'code': item['code'] ?? '',
          'customer': _customerLastName,
          'type': selectedContainerType,
          'location': loc,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _generatedResults = formattedList;
        _showSuccessPreview = true;
      });

      SweetAlert.showGlobalSuccess('Batch of ${results.length} AQUAZONE QR Codes generated successfully!');
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _submitGenerateExistingQr() async {
    if (_selectedGallonIdsForQr.isEmpty) {
      widget.onError('Please select at least one container to generate QR code.');
      return;
    }

    if (widget.gallons == null) return;
    final selectedGallons = widget.gallons!.where((g) => _selectedGallonIdsForQr.contains(g.id)).toList();

    setState(() => _isSaving = true);
    try {
      final ids = selectedGallons.map((g) => g.id).toList();
      final codes = selectedGallons.map((g) => g.gallonCode).toList();

      final generatedCount = await SupabaseService.batchGenerateQrForGallons(ids, codes);

      final formattedList = selectedGallons.map((g) {
        final assignedStr = g.assigned.trim();
        String lastName = 'AQUAZONE STOCK';
        if (assignedStr.isNotEmpty && assignedStr != '—' && !assignedStr.toLowerCase().contains('available') && !assignedStr.toLowerCase().contains('station stock')) {
          lastName = assignedStr.split(' ').last.toUpperCase();
        }

        return {
          'code': g.gallonCode,
          'customer': lastName,
          'type': g.containerType,
          'location': g.location,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _generatedResults = formattedList;
        _showSuccessPreview = true;
      });

      SweetAlert.showGlobalSuccess('Generated $generatedCount 1-to-1 QR codes for existing containers!');
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _triggerPrintSheet() {
    if (_generatedResults.isEmpty) return;
    PrintHelper.printBatchQrSheet(_generatedResults);
    SweetAlert.showGlobalSuccess('Printing AQUAZONE Batch QR Code Sticker Sheet...');
  }

  @override
  Widget build(BuildContext context) {
    final unqoredGallons = (widget.gallons ?? []).where((g) => !g.hasQr && g.status.toLowerCase() != 'retired').toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
            padding: const EdgeInsets.all(28),
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
            child: _showSuccessPreview ? _buildSuccessPreviewScreen() : _buildMainBatchForm(unqoredGallons),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBatchForm(List<GallonItemModel> unqoredGallons) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x330284C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x4038BDF8)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8), size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
 crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch Generate QR Codes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'AQUAZONE 1-to-1 bulk container registration & QR generator',
                      style: TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
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
        const SizedBox(height: 18),

        // Tabs
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFBAE6FD),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: [
              const Tab(text: 'Register New Gallons in Bulk'),
              Tab(text: 'Missing QR (${unqoredGallons.length})'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Bulk Register Form
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quantity Selector
                    const Text('Select Batch Quantity (Containers)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPresetButton(5),
                        const SizedBox(width: 8),
                        _buildPresetButton(10),
                        const SizedBox(width: 8),
                        _buildPresetButton(20),
                        const SizedBox(width: 8),
                        _buildPresetButton(50),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                                onPressed: () {
                                  if (_batchCount > 1) setState(() => _batchCount--);
                                },
                              ),
                              Text('$_batchCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8))),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                onPressed: () {
                                  if (_batchCount < 100) setState(() => _batchCount++);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer Selection
                    if (widget.customers != null && widget.customers!.isNotEmpty) ...[
                      const Text('Assigned Customer (Owner Last Name Tag)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCustomerId,
                        dropdownColor: const Color(0xFF0A3052),
                        hint: const Text('Unassigned / AQUAZONE Station Stock', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        items: widget.customers!.map((cust) {
                          return DropdownMenuItem<String>(
                            value: cust.id,
                            child: Text('${cust.fullName} (Tag: ${cust.fullName.split(" ").last.toUpperCase()})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedCustomerId = val),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Container Type & Status Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Container Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _containerTypes.contains(selectedContainerType) ? selectedContainerType : (_containerTypes.isNotEmpty ? _containerTypes.first : null),
                                dropdownColor: const Color(0xFF0A3052),
                                isExpanded: true,
                                decoration: _inputDecoration(),
                                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                                items: _containerTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedContainerType = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Initial Container Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                dropdownColor: const Color(0xFF0A3052),
                                decoration: _inputDecoration(),
                                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                                items: const [
                                  DropdownMenuItem(value: 'available', child: Text('Available in Station', style: TextStyle(color: Colors.white))),
                                  DropdownMenuItem(value: 'borrowed', child: Text('Borrowed / Out', style: TextStyle(color: Colors.white))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedStatus = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Refill Station Location
                    const Text('Refill Station / Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locationCtrl,
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 18),

                    // Live Code Batch Preview Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x330284C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x6638BDF8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF38BDF8), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BATCH QR PREVIEW: $_batchCount CONTAINER(S)',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Will generate $_batchCount unique 1-to-1 scannable codes (AQS-G-XXXXXX) with owner tag "$_customerLastName".',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submitBatchRegister,
                        icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.qr_code_2_rounded, size: 20),
                        label: Text(_isSaving ? 'Generating Batch QR Codes...' : 'Generate & Register $_batchCount Container QR Codes', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab 2: Existing Gallons Missing QR
              unqoredGallons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 44, color: Color(0xFF10B981)),
                          const SizedBox(height: 10),
                          const Text('All Active Gallons Have QR Codes!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Every container in your registry is currently linked with a 1-to-1 scannable QR code.', style: TextStyle(fontSize: 12, color: const Color(0xFFBAE6FD).withValues(alpha: 0.8))),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Containers Without QR Codes (${unqoredGallons.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (_selectedGallonIdsForQr.length == unqoredGallons.length) {
                                    _selectedGallonIdsForQr.clear();
                                  } else {
                                    _selectedGallonIdsForQr = unqoredGallons.map((g) => g.id).toSet();
                                  }
                                });
                              },
                              icon: Icon(_selectedGallonIdsForQr.length == unqoredGallons.length ? Icons.check_box_outlined : Icons.check_box_outline_blank, size: 16, color: const Color(0xFF38BDF8)),
                              label: Text(_selectedGallonIdsForQr.length == unqoredGallons.length ? 'Deselect All' : 'Select All', style: const TextStyle(fontSize: 12, color: Color(0xFF38BDF8))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: unqoredGallons.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final g = unqoredGallons[idx];
                              final isSel = _selectedGallonIdsForQr.contains(g.id);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSel) {
                                      _selectedGallonIdsForQr.remove(g.id);
                                    } else {
                                      _selectedGallonIdsForQr.add(g.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0x330284C7) : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSel ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isSel,
                                        activeColor: const Color(0xFF0284C7),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedGallonIdsForQr.add(g.id);
                                            } else {
                                              _selectedGallonIdsForQr.remove(g.id);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(g.gallonCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                            Text('${g.containerType} • ${g.assigned}', style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                        ),
                                        child: const Text('NO QR CODE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_isSaving || _selectedGallonIdsForQr.isEmpty) ? null : _submitGenerateExistingQr,
                            icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.qr_code_2_rounded, size: 20),
                            label: Text(_isSaving ? 'Generating QR Codes...' : 'Generate QR Codes for Selected (${_selectedGallonIdsForQr.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessPreviewScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                SizedBox(width: 10),
                Text('Batch QR Cards Ready', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 20, color: Color(0xFFBAE6FD)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Generated ${_generatedResults.length} scannable 1-to-1 AQUAZONE QR sticker labels.', style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD))),
        const SizedBox(height: 16),

        // Grid of Preview QR Cards
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisExtent: 220,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _generatedResults.length,
              itemBuilder: (context, idx) {
                final item = _generatedResults[idx];
                final code = item['code'] ?? '';
                final cust = item['customer'] ?? 'AQUAZONE STOCK';
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text('AQUAZONE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0284C7), letterSpacing: 1.0)),
                      const Text('WATER REFILL STATION', style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 90,
                        width: 90,
                        child: QrImageView(
                          data: code,
                          version: QrVersions.auto,
                          size: 90.0,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF0284C7)),
                        ),
                        child: Text(
                          cust,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF075985)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _triggerPrintSheet,
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print Batch QR Sticker Sheet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Finish & Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(int count) {
    final isSel = _batchCount == count;
    return InkWell(
      onTap: () => setState(() => _batchCount = count),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0284C7) : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.20)),
        ),
        child: Text('+$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFFBAE6FD))),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
    );
  }
}
