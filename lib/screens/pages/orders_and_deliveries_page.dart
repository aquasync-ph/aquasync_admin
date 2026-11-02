import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'orders_page.dart';
import 'deliveries_page.dart';

class OrdersAndDeliveriesPage extends StatefulWidget {
  final List<OrderItemModel> orders;
  final List<DeliveryModel> deliveries;
  final Set<String> processingOrderIds;
  final Function(OrderItemModel) onApprove;
  final Function(OrderItemModel, String)? onReject;
  final Function(OrderItemModel) onAssignDriver;
  final Function(OrderItemModel) onViewDetails;
  final Function(OrderItemModel)? onDeleteOrder;
  final Function(DeliveryModel)? onOverrideStatus;
  final Function(DeliveryModel) onCancelDelivery;
  final VoidCallback? onAuthorizeCashiers;
  final VoidCallback? onRefresh;
  final int initialTab;
  final String? highlightQuery;
  final VoidCallback? onClearHighlight;
  final Function(OrderItemModel)? onLocateCustomer;

  const OrdersAndDeliveriesPage({
    super.key,
    required this.orders,
    required this.deliveries,
    this.processingOrderIds = const {},
    required this.onApprove,
    this.onReject,
    required this.onAssignDriver,
    required this.onViewDetails,
    this.onDeleteOrder,
    this.onOverrideStatus,
    required this.onCancelDelivery,
    this.onAuthorizeCashiers,
    this.onRefresh,
    this.initialTab = 0,
    this.highlightQuery,
    this.onClearHighlight,
    this.onLocateCustomer,
  });

  @override
  State<OrdersAndDeliveriesPage> createState() => _OrdersAndDeliveriesPageState();
}

class _OrdersAndDeliveriesPageState extends State<OrdersAndDeliveriesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void didUpdateWidget(OrdersAndDeliveriesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 1));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF0098DA),
            unselectedLabelColor: const Color(0xFF5A5E63),
            indicatorColor: const Color(0xFF0098DA),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Orders Management', icon: Icon(Icons.shopping_bag_outlined, size: 18)),
              Tab(text: 'Delivery Dispatches', icon: Icon(Icons.local_shipping_outlined, size: 18)),
            ],
          ),
        ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OrdersPage(
                orders: widget.orders,
                processingOrderIds: widget.processingOrderIds,
                onApprove: widget.onApprove,
                onReject: widget.onReject,
                onAssignDriver: widget.onAssignDriver,
                onViewDetails: widget.onViewDetails,
                onDeleteOrder: widget.onDeleteOrder,
                onAuthorizeCashiers: widget.onAuthorizeCashiers,
                highlightQuery: widget.highlightQuery,
                onClearHighlight: widget.onClearHighlight,
                onLocateCustomer: widget.onLocateCustomer,
              ),
              DeliveriesPage(
                deliveries: widget.deliveries,
                onCancelDelivery: widget.onCancelDelivery,
                onOverrideStatus: widget.onOverrideStatus,
                highlightQuery: widget.highlightQuery,
                onClearHighlight: widget.onClearHighlight,
                onLocateCustomer: widget.onLocateCustomer != null
                    ? (DeliveryModel delivery) {
                        // Create a dummy OrderItemModel from DeliveryModel to satisfy the onLocateCustomer signature
                        final dummyOrder = OrderItemModel(
                          id: delivery.orderId,
                          orderNumber: delivery.orderNumber,
                          customer: delivery.customerName,
                          address: '', // Live map will look up the actual address using the customer name
                          qty: 0,
                          payment: delivery.paymentMethod,
                          status: delivery.status,
                          driver: delivery.driverName,
                          totalAmount: delivery.totalAmount,
                          isPos: false,
                          customerPhone: '',
                          customerEmail: '',
                          referenceNumber: delivery.gcashReference,
                          receiptUrl: delivery.receiptUrl,
                          rejectionReason: '',
                          createdAt: '',
                          itemsList: [],
                          fulfillmentType: 'store_delivery',
                          isWalkIn: false,
                        );
                        widget.onLocateCustomer!(dummyOrder);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
