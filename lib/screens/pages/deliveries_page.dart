import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../dialogs/order_details_dialog.dart';
import '../../dialogs/proof_of_delivery_dialog.dart';

class DeliveriesPage extends StatefulWidget {
  final List<DeliveryModel> deliveries;
  final Function(DeliveryModel) onCancelDelivery;
  final Function(DeliveryModel)? onOverrideStatus;
  final String? highlightQuery;
  final VoidCallback? onClearHighlight;
  final Function(DeliveryModel)? onLocateCustomer;

  const DeliveriesPage({
    super.key,
    required this.deliveries,
    required this.onCancelDelivery,
    this.onOverrideStatus,
    this.highlightQuery,
    this.onClearHighlight,
    this.onLocateCustomer,
  });

  @override
  State<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> {
  late bool _isGridView;
  String _statusFilter = 'all';
  String _searchQuery = '';
  late TextEditingController _searchController;
  int _currentPage = 1;
  int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _isGridView = widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isDeliveryHighlighted(DeliveryModel del) {
    if (widget.highlightQuery == null || widget.highlightQuery!.trim().isEmpty) {
      return false;
    }
    final q = widget.highlightQuery!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (q.isEmpty) return false;

    final idClean = del.id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final numClean = del.orderNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    return numClean.contains(q) || q.contains(numClean) ||
           idClean.contains(q) || q.contains(idClean);
  }

  List<DeliveryModel> get _filteredDeliveries {
    final list = widget.deliveries.where((del) {
      final matchesSearch = del.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          del.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          del.driverName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'all' || del.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    if (widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty) {
      list.sort((a, b) {
        final aH = _isDeliveryHighlighted(a);
        final bH = _isDeliveryHighlighted(b);
        if (aH && !bH) return -1;
        if (!aH && bH) return 1;
        return 0;
      });
    }

    return list;
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppSummaryCard(
      label: label,
      value: value,
      icon: icon,
      accentColor: const Color(0xFF38BDF8),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() {
        _searchQuery = val;
        _currentPage = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Search order number, customer, driver...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF5A5E63)),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0098DA)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF5A5E63), size: 18),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _currentPage = 1;
                  });
                  if (widget.onClearHighlight != null) widget.onClearHighlight!();
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFE6F3FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w600),
    );
  }

  Widget _buildFilterDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _statusFilter,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE6F3FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w500),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Dispatches', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'assigned', child: Text('Assigned', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'accepted', child: Text('Accepted', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'delivered', child: Text('Delivered', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _statusFilter = val;
            _currentPage = 1;
          });
        }
      },
    );
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty || raw.toLowerCase() == 'not yet recorded') return '—';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[dt.month - 1];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$month ${dt.day}, $hour:$minute $period';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildDispatchInfoBadge(DeliveryModel del) {
    final statusLower = del.status.toLowerCase();
    final hasProof = del.proofUrl.isNotEmpty;

    Widget badge;
    if (statusLower == 'cancelled') {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 14, color: Color(0xFF991B1B)),
            SizedBox(width: 4),
            Text('Cancelled by Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
          ],
        ),
      );
    } else if (statusLower == 'delivered' || statusLower == 'completed') {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF166534)),
            const SizedBox(width: 4),
            Text(
              hasProof ? 'Delivered (Proof Attached)' : 'Delivered Successfully',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
            ),
            if (hasProof) ...[
              const SizedBox(width: 4),
              const Icon(Icons.camera_alt_rounded, size: 12, color: Color(0xFF166534)),
            ],
          ],
        ),
      );
    } else if (statusLower == 'out_for_delivery' || statusLower == 'accepted') {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run_rounded, size: 14, color: Color(0xFF92400E)),
            SizedBox(width: 4),
            Text('In Transit with Driver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
          ],
        ),
      );
    } else {
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0369A1)),
            SizedBox(width: 4),
            Text('Dispatched to Driver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => showProofOfDeliveryDialog(context, del, onProofUpdated: () => setState(() {})),
      borderRadius: BorderRadius.circular(8),
      child: badge,
    );
  }

  Widget _buildPaymentReceiptCell(DeliveryModel del) {
    final pMethod = del.paymentMethod.toUpperCase();
    final bool isGcash = pMethod.contains('GCASH') || 
                         pMethod.contains('ONLINE') || 
                         pMethod.contains('PAYMONGO') || 
                         pMethod.contains('MAYA') || 
                         pMethod.contains('E-WALLET');

    if (!isGcash) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          del.paymentMethod.isNotEmpty ? del.paymentMethod : 'COD',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
      );
    }

    final bool hasImage = del.receiptUrl.trim().isNotEmpty && 
                          (del.receiptUrl.startsWith('http://') || del.receiptUrl.startsWith('https://'));

      return InkWell(
        onTap: () => showFullReceiptImageDialog(
          context,
          del.receiptUrl,
          orderNumber: del.orderNumber,
          referenceNumber: del.gcashReference,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasImage ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasImage ? const Color(0xFF10B981) : const Color(0xFF0284C7).withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasImage ? Icons.image_rounded : Icons.account_balance_wallet_rounded,
                      size: 13,
                      color: hasImage ? const Color(0xFF059669) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'GCash',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasImage ? const Color(0xFF059669) : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      hasImage ? Icons.open_in_new_rounded : Icons.info_outline_rounded,
                      size: 11,
                      color: hasImage ? const Color(0xFF059669) : const Color(0xFF0284C7),
                    ),
                  ],
                ),
              ),
              if (del.gcashReference.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Ref: ${del.gcashReference}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      );

  }

  Widget _buildDeliveryCard(DeliveryModel del) {
    final isHighlighted = _isDeliveryHighlighted(del);

    return AppGlassCard(
      isHighlighted: isHighlighted,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isHighlighted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF38BDF8)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'TARGETED NOTIFICATION ITEM',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                del.orderNumber,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
              ),
              OrderStatusBadge(status: del.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  del.customerName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildPaymentReceiptCell(del),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Driver: ${del.driverName.isEmpty ? "Unassigned" : del.driverName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DISPATCHED AT', style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(_formatDateTime(del.assignedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('DELIVERED AT', style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(_formatDateTime(del.deliveredAt), style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDispatchInfoBadge(del),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(
                  del.proofUrl.isNotEmpty ? Icons.verified_rounded : Icons.camera_alt_outlined,
                  size: 13,
                ),
                label: const Text('POD Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: del.status.toLowerCase() == 'delivered' ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => showProofOfDeliveryDialog(context, del, onProofUpdated: () => setState(() {})),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBanner() {
    if (widget.highlightQuery == null || widget.highlightQuery!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C3860), Color(0xFF03182B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 15, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x2238BDF8), blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7DD3FC), size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TARGETED ITEM HIGHLIGHTED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7DD3FC), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Viewing targeted item: "${widget.highlightQuery}"',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onClearHighlight,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Dismiss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDeliveries;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <DeliveryModel>[]
        : filtered.sublist(
            startIndex.clamp(0, filtered.length),
            (startIndex + _itemsPerPage).clamp(0, filtered.length),
          );

    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 24.0
        : screenWidth >= 768
            ? 18.0
            : 12.0;

    int totalCount = widget.deliveries.length;
    int assignedCount = widget.deliveries.where((d) => d.status.toLowerCase() == 'assigned').length;
    int inTransitCount = widget.deliveries.where((d) => d.status.toLowerCase() == 'out_for_delivery' || d.status.toLowerCase() == 'accepted').length;
    int deliveredCount = widget.deliveries.where((d) => d.status.toLowerCase() == 'delivered' || d.status.toLowerCase() == 'completed').length;
    int cancelledCount = widget.deliveries.where((d) => d.status.toLowerCase() == 'cancelled').length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return Row(
            children: [
              Expanded(child: _buildSummaryCard(label: 'Total Dispatches', value: '$totalCount', icon: Icons.local_shipping_outlined, color: const Color(0xFF38BDF8))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(label: 'Driver Assigned', value: '$assignedCount', icon: Icons.badge_outlined, color: const Color(0xFF7DD3FC))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(label: 'In Transit', value: '$inTransitCount', icon: Icons.directions_run_rounded, color: const Color(0xFFFCD34D))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(label: 'Delivered', value: '$deliveredCount', icon: Icons.task_alt_rounded, color: const Color(0xFF34D399))),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard(label: 'Cancelled', value: '$cancelledCount', icon: Icons.cancel_outlined, color: const Color(0xFFF87171))),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Total', value: '$totalCount', icon: Icons.local_shipping_outlined, color: const Color(0xFF38BDF8))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Assigned', value: '$assignedCount', icon: Icons.badge_outlined, color: const Color(0xFF7DD3FC))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'In Transit', value: '$inTransitCount', icon: Icons.directions_run_rounded, color: const Color(0xFFFCD34D))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Delivered', value: '$deliveredCount', icon: Icons.task_alt_rounded, color: const Color(0xFF34D399))),
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: _buildSummaryCard(label: 'Cancelled', value: '$cancelledCount', icon: Icons.cancel_outlined, color: const Color(0xFFF87171))),
            ],
          );
        }
      },
    );

    Widget viewToggleWidget = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6F3FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(() => _isGridView = true),
            icon: const Icon(Icons.grid_view_rounded, size: 20),
            color: _isGridView ? const Color(0xFF0098DA) : const Color(0xFF5A5E63),
            tooltip: 'Grid View',
          ),
          IconButton(
            onPressed: () => setState(() => _isGridView = false),
            icon: const Icon(Icons.table_rows_rounded, size: 20),
            color: !_isGridView ? const Color(0xFF0098DA) : const Color(0xFF5A5E63),
            tooltip: 'List / Table View',
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHighlightBanner(),
          summaryStrip,
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
              boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 10),
                          viewToggleWidget,
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: _buildFilterDropdown()),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 10),
                    SizedBox(width: 200, child: _buildFilterDropdown()),
                    const SizedBox(width: 10),
                    viewToggleWidget,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
                      boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(40),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 44, color: Color(0xFF0284C7)),
                          SizedBox(height: 12),
                          Text('No dispatches found.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text('Dispatched orders will appear here automatically via Realtime.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  )
                : _isGridView
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 3;
                          if (constraints.maxWidth < 700) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 1100) {
                            crossAxisCount = 2;
                          }
                          return GridView.builder(
                            itemCount: paginated.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 240,
                            ),
                            itemBuilder: (context, index) => _buildDeliveryCard(paginated[index]),
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
                          boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                      child: DataTable(
                                        dataRowMinHeight: 56,
                                        dataRowMaxHeight: 62,
                                        headingRowHeight: 52,
                                        columnSpacing: 18,
                                        horizontalMargin: 16,
                                        columns: const [
                                          DataColumn(label: Text('ORDER NUMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('DRIVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('PAYMENT / RECEIPT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('DISPATCHED AT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('DELIVERED AT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('PROOF OF DELIVERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                          DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                        ],
                                        rows: paginated.map((del) {
                                          final isHighlighted = _isDeliveryHighlighted(del);
                                          return animatedDataRow(
                                            isHighlighted: isHighlighted,
                                            cells: [
                                              DataCell(Text(del.orderNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF0284C7), fontWeight: FontWeight.bold))),
                                              DataCell(Text(del.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0284C7)),
                                                    const SizedBox(width: 6),
                                                    Text(del.driverName.isEmpty ? 'Unassigned' : del.driverName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                                  ],
                                                ),
                                              ),
                                              DataCell(OrderStatusBadge(status: del.status)),
                                              DataCell(_buildPaymentReceiptCell(del)),
                                              DataCell(Text(_formatDateTime(del.assignedAt), style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                              DataCell(Text(_formatDateTime(del.deliveredAt), style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                                              DataCell(
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                  child: del.proofUrl.isNotEmpty
                                                      ? ElevatedButton.icon(
                                                          icon: const Icon(Icons.verified_rounded, size: 14),
                                                          label: const Text('View Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF10B981),
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            elevation: 1,
                                                          ),
                                                          onPressed: () => showProofOfDeliveryDialog(context, del, onProofUpdated: () => setState(() {})),
                                                        )
                                                      : OutlinedButton.icon(
                                                          icon: Icon(
                                                            del.status.toLowerCase() == 'delivered' ? Icons.camera_alt_outlined : Icons.timer_outlined,
                                                            size: 14,
                                                          ),
                                                          label: Text(
                                                            del.status.toLowerCase() == 'delivered' ? 'View Proof' : 'No Proof Yet',
                                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                          ),
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: del.status.toLowerCase() == 'delivered' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                                            side: BorderSide(
                                                              color: del.status.toLowerCase() == 'delivered' ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          onPressed: () => showProofOfDeliveryDialog(context, del, onProofUpdated: () => setState(() {})),
                                                        ),
                                                ),
                                              ),
                                              DataCell(Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 105,
                                                      child: OutlinedButton.icon(
                                                        icon: const Icon(Icons.pin_drop_rounded, size: 14),
                                                        label: const Text('View Map', style: TextStyle(fontSize: 11)),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: const Color(0xFF0284C7),
                                                          side: const BorderSide(color: Color(0xFF0284C7)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        onPressed: widget.onLocateCustomer != null
                                                            ? () => widget.onLocateCustomer!(del)
                                                            : null,
                                                      ),
                                                    ),
                                                    if (del.receiptUrl.isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      ElevatedButton.icon(
                                                        icon: const Icon(Icons.receipt_long_rounded, size: 14),
                                                        label: const Text('Receipt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF10B981),
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          elevation: 1,
                                                        ),
                                                        onPressed: () => showFullReceiptImageDialog(
                                                          context,
                                                          del.receiptUrl,
                                                          orderNumber: del.orderNumber,
                                                          referenceNumber: del.gcashReference,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              )),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppPaginationControls(
              totalItems: filtered.length,
              currentPage: _currentPage,
              itemsPerPage: _itemsPerPage,
              onPageChanged: (page) => setState(() => _currentPage = page),
              onItemsPerPageChanged: (perPage) => setState(() {
                _itemsPerPage = perPage;
                _currentPage = 1;
              }),
            ),
          ],
        ],
      ),
    );
  }
}
