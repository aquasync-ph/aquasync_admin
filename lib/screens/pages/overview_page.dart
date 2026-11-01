import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class OverviewPage extends StatelessWidget {
  final String adminName;
  final double totalSalesToday;
  final double cashSalesToday;
  final double gcashSalesToday;
  final int transactionCountToday;
  final int pendingCount;
  final int activeDeliveriesCount;
  final List<CustomerModel> customers;
  final List<DriverModel> drivers;
  final List<ProductModel> products;
  final List<GallonItemModel> gallons;
  final List<OrderItemModel> orders;
  final List<DeliveryModel> deliveries;
  final List<ReviewModel> reviews;
  final Function(OrderItemModel) onApproveOrder;
  final Function(OrderItemModel) onAssignDriver;
  final Function(int) onNavigate;

  const OverviewPage({
    super.key,
    required this.adminName,
    required this.totalSalesToday,
    required this.cashSalesToday,
    required this.gcashSalesToday,
    required this.transactionCountToday,
    required this.pendingCount,
    required this.activeDeliveriesCount,
    required this.customers,
    required this.drivers,
    required this.products,
    required this.gallons,
    required this.orders,
    required this.deliveries,
    required this.reviews,
    required this.onApproveOrder,
    required this.onAssignDriver,
    required this.onNavigate,
  });

  double get _availablePct {
    if (gallons.isEmpty) return 0;
    int count = gallons.where((g) => g.status.toLowerCase() == 'available').length;
    return (count / gallons.length) * 100;
  }

  double get _outPct {
    if (gallons.isEmpty) return 0;
    int count = gallons.where((g) => g.status.toLowerCase() == 'out_for_delivery' || g.status.toLowerCase() == 'out for delivery').length;
    return (count / gallons.length) * 100;
  }

  double get _borrowedPct {
    if (gallons.isEmpty) return 0;
    int count = gallons.where((g) => g.status.toLowerCase() == 'borrowed').length;
    return (count / gallons.length) * 100;
  }

  Widget _buildWelcomeHeader(double width) {
    final isDesktopHeader = width >= 768;

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF38BDF8)),
                  SizedBox(width: 6),
                  Text(
                    'AquaSync ADMIN CONTROL CENTER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x3310B981),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x6634D399)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: Color(0xFF34D399)),
                  SizedBox(width: 6),
                  Text(
                    'Station Operational',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD1FAE5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back, $adminName',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Aqua Pure Water Station • Realtime Station Dispatches & Container Monitoring',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFBAE6FD),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    final ctaButton = ElevatedButton.icon(
      onPressed: () => onNavigate(1),
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
      label: const Text('Manage Orders'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0098DA),
        foregroundColor: Colors.white,
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1D2A),
            Color(0xFF1B4965),
            Color(0xFF0098DA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B1D2A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isDesktopHeader
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 16),
                ctaButton,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoColumn,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ctaButton),
              ],
            ),
    );
  }

  Widget _buildActionRow({
    required double parentWidth,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    final isCompact = parentWidth < 520;

    final leadingAndText = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: textColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      ],
    );

    final actionButton = ElevatedButton(
      onPressed: onAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: textColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        actionLabel,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.30)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0098DA),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leadingAndText,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            )
          : Row(
              children: [
                Expanded(child: leadingAndText),
                const SizedBox(width: 10),
                actionButton,
              ],
            ),
    );
  }

  Widget _buildDashboardActionPanel(double parentWidth) {
    final pendingOrders = orders.where((o) => o.status.toLowerCase() == 'pending').toList();
    final readyForAssignment = orders.where((o) => o.status.toLowerCase() == 'confirmed').toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.30), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x140098DA), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Text('Action Required', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x22F59E0B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x66F59E0B)),
                  ),
                  child: Text(
                    '${pendingOrders.length + readyForAssignment.length} Action Items',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: const Color(0xFFE2E8F0), height: 1),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingOrders.isEmpty && readyForAssignment.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 32),
                          SizedBox(height: 8),
                          Text('All Operations Up to Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          SizedBox(height: 2),
                          Text('No urgent order approvals or driver assignments required.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (pendingOrders.isNotEmpty) ...[
                    const Text('PENDING APPROVALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFFFCD34D))),
                    const SizedBox(height: 8),
                    ...pendingOrders.take(3).map((o) => _buildActionRow(
                      parentWidth: parentWidth,
                      title: 'Order ${o.displayId}',
                      subtitle: 'from ${o.customer} • ${o.qty} gallon(s) • ₱${o.totalAmount.toStringAsFixed(2)}',
                      actionLabel: 'Approve Order',
                      onAction: () => onApproveOrder(o),
                      color: const Color(0xFFFEF3C7),
                      textColor: const Color(0xFF92400E),
                      icon: Icons.hourglass_top_rounded,
                    )),
                    const SizedBox(height: 12),
                  ],
                  if (readyForAssignment.isNotEmpty) ...[
                    const Text('AWAITING DRIVER DISPATCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC))),
                    const SizedBox(height: 8),
                    ...readyForAssignment.take(3).map((o) => _buildActionRow(
                      parentWidth: parentWidth,
                      title: 'Order ${o.displayId}',
                      subtitle: 'from ${o.customer} • Confirmed & Ready for Driver',
                      actionLabel: 'Assign Driver',
                      onAction: () => onAssignDriver(o),
                      color: const Color(0xFFE0F2FE),
                      textColor: const Color(0xFF0369A1),
                      icon: Icons.badge_outlined,
                    )),
                    const SizedBox(height: 12),
                  ],
                  _buildActionRow(
                    parentWidth: parentWidth,
                    title: 'Customer Loyalty & Reward Thresholds',
                    subtitle: 'Inspect customers reaching 15 qualifying gallons for reward redemption',
                    actionLabel: 'View Loyalty Cards',
                    onAction: () => onNavigate(5),
                    color: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF166534),
                    icon: Icons.card_giftcard_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersPanel() {
    final recent = orders.take(5).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.30), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x140B1D2A), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Color(0xFF0098DA), size: 18),
                    SizedBox(width: 8),
                    Text('Recent Station Orders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => onNavigate(1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 12),
                  label: const Text('View All Orders'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0098DA),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No recent orders recorded.', style: TextStyle(fontSize: 12, color: Color(0xFF475569)))),
            )
          else
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('ORDER #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                          DataColumn(label: Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                          DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                          DataColumn(label: Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                        ],
                        rows: recent.map((o) {
                          return DataRow(
                            cells: [
                              DataCell(Text(o.displayId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                              DataCell(Text(o.customer, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                              DataCell(OrderStatusBadge(status: o.status)),
                              DataCell(Text('₱${o.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryActivityPanel() {
    final active = deliveries.take(5).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text('Live Delivery Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => onNavigate(1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 12),
                  label: const Text('View All Deliveries'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No active delivery activity.', style: TextStyle(fontSize: 12, color: Color(0xFF475569)))),
            )
          else
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 18,
                        columns: const [
                          DataColumn(label: Text('ORDER #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                          DataColumn(label: Text('DRIVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                          DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                          DataColumn(label: Text('ASSIGNED AT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                        ],
                        rows: active.map((d) {
                          return DataRow(
                            cells: [
                              DataCell(Text(d.orderNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)))),
                              DataCell(Text(d.driverName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                              DataCell(OrderStatusBadge(status: d.status)),
                              DataCell(Text(d.assignedAt, style: const TextStyle(fontSize: 10, color: Color(0xFF475569)))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGallonStatusPanel() {
    int availableCount = gallons.where((g) => g.status.toLowerCase() == 'available').length;
    int outCount = gallons.where((g) => g.status.toLowerCase() == 'out_for_delivery' || g.status.toLowerCase() == 'out for delivery').length;
    int borrowedCount = gallons.where((g) => g.status.toLowerCase() == 'borrowed').length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.30), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x140284C7), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.opacity_rounded, color: Color(0xFF0284C7), size: 18),
                    SizedBox(width: 8),
                    Text('Gallon Inventory Snapshot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                TextButton(
                  onPressed: () => onNavigate(8),
                  child: const Text('Manage QR Registry →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildMetricRow(label: 'Available Containers', count: availableCount, percentage: _availablePct, color: const Color(0xFF10B981)),
                const SizedBox(height: 16),
                _buildMetricRow(label: 'Out for Delivery Dispatches', count: outCount, percentage: _outPct, color: const Color(0xFF0284C7)),
                const SizedBox(height: 16),
                _buildMetricRow(label: 'Borrowed Customer Containers', count: borrowedCount, percentage: _borrowedPct, color: const Color(0xFFEF4444)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({required String label, required int count, required double percentage, required Color color}) {
    int pctInt = percentage.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('$count ($pctInt%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(20)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (percentage / 100).clamp(0.0, 1.0),
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20))),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pagePadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth;
          final isLargeDesktop = parentWidth >= 1200;
          final isTabletOrDesktop = parentWidth >= 768;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(parentWidth),
              const SizedBox(height: 20),

              // KPI CARDS BREAKPOINT SYSTEM
              if (isLargeDesktop)
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        width: double.infinity,
                        label: "Today's Revenue",
                        value: '₱${totalSalesToday.toStringAsFixed(2)}',
                        subText: '$transactionCountToday Completed Transactions',
                        icon: Icons.payments_outlined,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        width: double.infinity,
                        label: 'Pending Orders',
                        value: '$pendingCount',
                        subText: 'Awaiting Admin Approval',
                        icon: Icons.hourglass_top_rounded,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        width: double.infinity,
                        label: 'Active Deliveries',
                        value: '$activeDeliveriesCount',
                        subText: 'In Transit with Drivers',
                        icon: Icons.local_shipping_outlined,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KpiCard(
                        width: double.infinity,
                        label: 'Available Gallons',
                        value: '${gallons.where((g) => g.status == 'Available').length}',
                        subText: 'Containers Ready for Refill',
                        icon: Icons.opacity_rounded,
                        accentColor: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                )
              else if (isTabletOrDesktop)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            width: double.infinity,
                            label: "Today's Revenue",
                            value: '₱${totalSalesToday.toStringAsFixed(2)}',
                            subText: '$transactionCountToday Completed Transactions',
                            icon: Icons.payments_outlined,
                            accentColor: const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: KpiCard(
                            width: double.infinity,
                            label: 'Pending Orders',
                            value: '$pendingCount',
                            subText: 'Awaiting Admin Approval',
                            icon: Icons.hourglass_top_rounded,
                            accentColor: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            width: double.infinity,
                            label: 'Active Deliveries',
                            value: '$activeDeliveriesCount',
                            subText: 'In Transit with Drivers',
                            icon: Icons.local_shipping_outlined,
                            accentColor: const Color(0xFF38BDF8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: KpiCard(
                            width: double.infinity,
                            label: 'Available Gallons',
                            value: '${gallons.where((g) => g.status == 'Available').length}',
                            subText: 'Containers Ready for Refill',
                            icon: Icons.opacity_rounded,
                            accentColor: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    KpiCard(
                      width: double.infinity,
                      label: "Today's Revenue",
                      value: '₱${totalSalesToday.toStringAsFixed(2)}',
                      subText: '$transactionCountToday Completed Transactions',
                      icon: Icons.payments_outlined,
                      accentColor: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(height: 12),
                    KpiCard(
                      width: double.infinity,
                      label: 'Pending Orders',
                      value: '$pendingCount',
                      subText: 'Awaiting Admin Approval',
                      icon: Icons.hourglass_top_rounded,
                      accentColor: const Color(0xFFFCD34D),
                    ),
                    const SizedBox(height: 12),
                    KpiCard(
                      width: double.infinity,
                      label: 'Active Deliveries',
                      value: '$activeDeliveriesCount',
                      subText: 'In Transit with Drivers',
                      icon: Icons.local_shipping_outlined,
                      accentColor: const Color(0xFF34D399),
                    ),
                    const SizedBox(height: 12),
                    KpiCard(
                      width: double.infinity,
                      label: 'Available Gallons',
                      value: '${gallons.where((g) => g.status == 'Available').length}',
                      subText: 'Containers Ready for Refill',
                      icon: Icons.opacity_rounded,
                      accentColor: const Color(0xFF38BDF8),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              _buildSalesChannelCard(parentWidth),
              const SizedBox(height: 16),
              _buildStationStatsCard(parentWidth),
              const SizedBox(height: 20),

              // MIDDLE & BOTTOM PANELS BREAKPOINT SYSTEM
              if (isLargeDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 68, child: _buildDashboardActionPanel(parentWidth)),
                    const SizedBox(width: 20),
                    Expanded(flex: 32, child: _buildGallonStatusPanel()),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 50, child: _buildRecentOrdersPanel()),
                    const SizedBox(width: 20),
                    Expanded(flex: 50, child: _buildDeliveryActivityPanel()),
                  ],
                ),
              ] else ...[
                _buildDashboardActionPanel(parentWidth),
                const SizedBox(height: 18),
                _buildGallonStatusPanel(),
                const SizedBox(height: 18),
                _buildRecentOrdersPanel(),
                const SizedBox(height: 18),
                _buildDeliveryActivityPanel(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSalesChannelCard(double parentWidth) {
    final cashPct = totalSalesToday > 0 ? (cashSalesToday / totalSalesToday).clamp(0.0, 1.0) : 0.0;
    final gcashPct = totalSalesToday > 0 ? (gcashSalesToday / totalSalesToday).clamp(0.0, 1.0) : 0.0;

    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text("Today's Payment Channels Breakdown", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Text(
                '₱${totalSalesToday.toStringAsFixed(2)} Total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_rounded, color: Color(0xFF059669), size: 16),
                          SizedBox(width: 6),
                          Text('Cash Sales', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('₱${cashSalesToday.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('${(cashPct * 100).toStringAsFixed(1)}% of revenue', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0284C7), size: 16),
                          SizedBox(width: 6),
                          Text('GCash / Digital', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('₱${gcashSalesToday.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('${(gcashPct * 100).toStringAsFixed(1)}% of revenue', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationStatsCard(double parentWidth) {
    final activeDriversCount = drivers.where((d) => d.isActive).length;
    double avgRating = 0.0;
    if (reviews.isNotEmpty) {
      double sum = reviews.fold(0.0, (acc, r) => acc + r.rating);
      avgRating = sum / reviews.length;
    }

    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Text('Station Network & Fleet Health', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onNavigate(5),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('CUSTOMERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            Icon(Icons.people_rounded, size: 14, color: Color(0xFF0284C7)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${customers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        const Text('Registered accounts', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => onNavigate(13),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('DRIVERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            Icon(Icons.badge_rounded, size: 14, color: Color(0xFF059669)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('$activeDriversCount / ${drivers.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        const Text('Active / Total drivers', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => onNavigate(7),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('PRODUCTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFFD97706)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${products.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        const Text('Items catalog', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => onNavigate(4),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('RATINGS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                            Icon(Icons.star_rounded, size: 14, color: Color(0xFFDC2626)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(reviews.isNotEmpty ? avgRating.toStringAsFixed(1) : '—', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('${reviews.length} reviews', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
