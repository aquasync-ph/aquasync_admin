import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../dialogs/order_details_dialog.dart';

class OrdersPage extends StatefulWidget {
  final List<OrderItemModel> orders;
  final Set<String> processingOrderIds;
  final Function(OrderItemModel) onApprove;
  final Function(OrderItemModel, String)? onReject;
  final Function(OrderItemModel) onAssignDriver;
  final Function(OrderItemModel) onViewDetails;
  final Function(OrderItemModel)? onDeleteOrder;
  final VoidCallback? onAuthorizeCashiers;
  final String? highlightQuery;
  final VoidCallback? onClearHighlight;
  final Function(OrderItemModel)? onLocateCustomer;

  const OrdersPage({
    super.key,
    required this.orders,
    this.processingOrderIds = const {},
    required this.onApprove,
    this.onReject,
    required this.onAssignDriver,
    required this.onViewDetails,
    this.onDeleteOrder,
    this.onAuthorizeCashiers,
    this.highlightQuery,
    this.onClearHighlight,
    this.onLocateCustomer,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late bool _isGridView;
  String _orderStatusFilter = 'all';
  String _paymentFilter = 'all';
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

  bool _isOrderHighlighted(OrderItemModel order) {
    if (widget.highlightQuery == null || widget.highlightQuery!.trim().isEmpty) {
      return false;
    }
    final q = widget.highlightQuery!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (q.isEmpty) return false;

    final idClean = order.id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final numClean = order.orderNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final dispClean = order.displayId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    return numClean.contains(q) || q.contains(numClean) ||
           dispClean.contains(q) || q.contains(dispClean) ||
           idClean.contains(q) || q.contains(idClean);
  }

  List<OrderItemModel> get _filteredOrders {
    final list = widget.orders.where((order) {
      final matchesSearch = order.displayId
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          order.customer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.driver.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.fulfillmentType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.payment.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.status.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _orderStatusFilter == 'all' ||
          (_orderStatusFilter == 'pickup' && order.fulfillmentType.toLowerCase() == 'pickup') ||
          (_orderStatusFilter == 'delivery' && order.fulfillmentType.toLowerCase() == 'delivery') ||
          order.status.toLowerCase() == _orderStatusFilter.toLowerCase();
      final pUpper = order.payment.toUpperCase();
      final matchesPayment = _paymentFilter == 'all' ||
          (_paymentFilter == 'cod' && (pUpper.contains('COD') || pUpper.contains('CASH') || pUpper.contains('DELIVERY'))) ||
          (_paymentFilter == 'gcash' && pUpper.contains('GCASH'));
      return matchesSearch && matchesStatus && matchesPayment;
    }).toList();

    if (widget.highlightQuery != null && widget.highlightQuery!.isNotEmpty) {
      list.sort((a, b) {
        final aH = _isOrderHighlighted(a);
        final bH = _isOrderHighlighted(b);
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
        hintText: 'Search order number, customer, address, status, driver, pickup/delivery...',
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

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _orderStatusFilter,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE6F3FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w600),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Orders', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'pending', child: Text('Pending Approval', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'confirmed', child: Text('Confirmed & Awaiting Driver', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'assigned', child: Text('Driver Assigned', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'accepted', child: Text('Accepted by Driver', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'delivered', child: Text('Delivered / Completed', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'pickup', child: Text('Store Pick-up Only', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'delivery', child: Text('Store Delivery Only', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled / Rejected', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _orderStatusFilter = val;
            _currentPage = 1;
          });
        }
      },
    );
  }

  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _paymentFilter,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE6F3FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF0B1D2A), fontWeight: FontWeight.w600),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Payment Methods', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'cod', child: Text('Cash on Delivery (COD)', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
        DropdownMenuItem(value: 'gcash', child: Text('GCash Payment', style: TextStyle(fontSize: 13, color: Color(0xFF0B1D2A)))),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _paymentFilter = val;
            _currentPage = 1;
          });
        }
      },
    );
  }

  void _showRejectDialog(OrderItemModel order) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A3052),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x3838BDF8)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reject Order ${order.displayId}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify a reason for rejecting order ${order.displayId}. This feedback will be recorded and sent to the customer.',
              style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Invalid GCash reference number, unreadable receipt image, out of stock, or outside delivery area...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF7DD3FC)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final rawReason = controller.text.trim();
              final reason = rawReason.isNotEmpty ? rawReason : 'Order rejected by Admin';
              Navigator.of(ctx).pop();
              if (widget.onReject != null) {
                widget.onReject!(order, reason);
              }
            },
            icon: const Icon(Icons.cancel_schedule_send_rounded, size: 16),
            label: const Text('Reject & Send Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCell(OrderItemModel order) {
    final payMethod = order.payment.toUpperCase();
    final bool isGcash = payMethod.contains('GCASH') || 
                         payMethod.contains('ONLINE') || 
                         payMethod.contains('PAYMONGO') || 
                         payMethod.contains('MAYA') || 
                         payMethod.contains('E-WALLET');

    if (!isGcash) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          order.payment.isNotEmpty ? order.payment : 'COD',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
      );
    }

    final bool hasImage = order.receiptUrl.trim().isNotEmpty && 
                          (order.receiptUrl.startsWith('http://') || order.receiptUrl.startsWith('https://'));

      return InkWell(
        onTap: () => showFullReceiptImageDialog(
          context,
          order.receiptUrl,
          orderNumber: order.displayId,
          referenceNumber: order.referenceNumber,
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
              if (order.referenceNumber.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Ref: ${order.referenceNumber}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      );

  }

  Widget _buildOrderActionButtons(OrderItemModel order) {
    final status = order.status.toLowerCase();
    final bool isLoading = widget.processingOrderIds.contains(order.id);

    Widget mainButton;
    if (status == 'pending') {
      mainButton = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: isLoading ? null : () => widget.onApprove(order),
            icon: isLoading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline_rounded, size: 14),
            label: Text(isLoading ? 'Approving...' : 'Approve', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x3310B981),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: isLoading ? null : () => _showRejectDialog(order),
            icon: isLoading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cancel_outlined, size: 14),
            label: Text(isLoading ? 'Rejecting...' : 'Reject', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x33EF4444),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      );
    } else if (status == 'confirmed') {
      mainButton = ElevatedButton.icon(
        onPressed: isLoading ? null : () => widget.onAssignDriver(order),
        icon: isLoading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.motorcycle_rounded, size: 14),
        label: const Text('Dispatch Driver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0x333B82F6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      mainButton = OutlinedButton.icon(
        onPressed: () => widget.onViewDetails(order),
        icon: const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF0284C7)),
        label: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0284C7),
          side: const BorderSide(color: Color(0xFF0284C7)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return mainButton;
  }

  Widget _buildOrderCard(OrderItemModel order) {
    final isHighlighted = _isOrderHighlighted(order);

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
              InkWell(
                onTap: () => widget.onViewDetails(order),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  order.displayId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.customer,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.address.isEmpty ? 'No address specified' : order.address,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
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
                  const Text('QTY / PAYMENT', style: TextStyle(fontSize: 9, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${order.qty} pcs • ${order.payment}', style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                      if (order.receiptUrl.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => showFullReceiptImageDialog(
                            context,
                            order.receiptUrl,
                            orderNumber: order.displayId,
                            referenceNumber: order.referenceNumber,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.image_outlined, size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 2),
                                Text('Receipt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 9, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _buildOrderActionButtons(order),
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
    final filtered = _filteredOrders;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.isEmpty
        ? <OrderItemModel>[]
        : filtered.sublist(
            startIndex.clamp(0, filtered.length),
            (startIndex + _itemsPerPage).clamp(0, filtered.length),
          );

    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    int totalCount = widget.orders.length;
    int pendingCount = widget.orders.where((o) => o.status.toLowerCase() == 'pending').length;
    int awaitingDriverCount = widget.orders.where((o) => o.status.toLowerCase() == 'confirmed').length;
    int completedCount = widget.orders.where((o) => o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed').length;

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 850) {
          return Row(
            children: [
              Expanded(
                child: _buildSummaryCard(label: 'Total Orders', value: '$totalCount', icon: Icons.shopping_bag_outlined, color: const Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSummaryCard(label: 'Pending Approval', value: '$pendingCount', icon: Icons.hourglass_top_rounded, color: const Color(0xFFFCD34D)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSummaryCard(label: 'Awaiting Driver', value: '$awaitingDriverCount', icon: Icons.badge_outlined, color: const Color(0xFF7DD3FC)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSummaryCard(label: 'Completed Orders', value: '$completedCount', icon: Icons.task_alt_rounded, color: const Color(0xFF34D399)),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: _buildSummaryCard(label: 'Total Orders', value: '$totalCount', icon: Icons.shopping_bag_outlined, color: const Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 250,
                child: _buildSummaryCard(label: 'Pending Approval', value: '$pendingCount', icon: Icons.hourglass_top_rounded, color: const Color(0xFFFCD34D)),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 250,
                child: _buildSummaryCard(label: 'Awaiting Driver', value: '$awaitingDriverCount', icon: Icons.badge_outlined, color: const Color(0xFF7DD3FC)),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 250,
                child: _buildSummaryCard(label: 'Completed Orders', value: '$completedCount', icon: Icons.task_alt_rounded, color: const Color(0xFF34D399)),
              ),
            ],
          ),
        );
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

    Widget? authorizeCashiersBtn = widget.onAuthorizeCashiers != null
        ? ElevatedButton.icon(
            onPressed: widget.onAuthorizeCashiers,
            icon: const Icon(Icons.assignment_ind_rounded, size: 18),
            label: const Text('Authorize Cashiers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              shadowColor: const Color(0x409333EA),
            ),
          )
        : null;

    return SingleChildScrollView(
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
                if (constraints.maxWidth < 640) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 8),
                          viewToggleWidget,
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildStatusDropdown()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPaymentDropdown()),
                        ],
                      ),
                      if (authorizeCashiersBtn != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: authorizeCashiersBtn),
                      ],
                    ],
                  );
                } else if (constraints.maxWidth < 1080) {
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
                      Row(
                        children: [
                          Expanded(child: _buildStatusDropdown()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPaymentDropdown()),
                          if (authorizeCashiersBtn != null) ...[
                            const SizedBox(width: 8),
                            authorizeCashiersBtn,
                          ],
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 10),
                    SizedBox(width: 190, child: _buildStatusDropdown()),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, child: _buildPaymentDropdown()),
                    const SizedBox(width: 10),
                    viewToggleWidget,
                    if (authorizeCashiersBtn != null) ...[
                      const SizedBox(width: 10),
                      authorizeCashiersBtn,
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          filtered.isEmpty
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30)),
                  ),
                  padding: const EdgeInsets.all(40),
                  child: const Center(
                    child: Text('No orders found matching search.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
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
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 250,
                          ),
                          itemBuilder: (context, index) => _buildOrderCard(paginated[index]),
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
                        builder: (context, tableConstraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                              child: DataTable(
                                dataRowMinHeight: 68,
                                dataRowMaxHeight: 76,
                                headingRowHeight: 56,
                                columnSpacing: 24,
                                horizontalMargin: 20,
                                columns: const [
                                  DataColumn(label: Text('ORDER NUMBER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('ADDRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('QTY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('PAYMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                  DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                                ],
                                rows: paginated.map((order) {
                                  final isHighlighted = _isOrderHighlighted(order);
                                  return animatedDataRow(
                                    isHighlighted: isHighlighted,
                                    cells: [
                                      DataCell(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: InkWell(
                                            onTap: () => widget.onViewDetails(order),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                              child: Text(
                                                order.displayId,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  color: Color(0xFF0284C7),
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(order.customer, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: SizedBox(
                                          width: 170,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                order.address.isEmpty ? 'No address specified' : order.address,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              InkWell(
                                                onTap: widget.onLocateCustomer != null ? () => widget.onLocateCustomer!(order) : null,
                                                borderRadius: BorderRadius.circular(4),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 2.0),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0284C7)),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'View Map',
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF0284C7),
                                                          decoration: TextDecoration.underline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text('${order.qty}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: _buildPaymentCell(order),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text('₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: OrderStatusBadge(status: order.status),
                                      )),
                                      DataCell(Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: _buildOrderActionButtons(order),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          if (filtered.isNotEmpty) ...[
            const SizedBox(height: 16),
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
