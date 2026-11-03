import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../dialogs/dialogs.dart';
import 'pages/pages.dart';

class DashboardMainScreen extends StatefulWidget {
  final String adminName;
  final VoidCallback onLogout;

  const DashboardMainScreen({
    super.key,
    required this.adminName,
    required this.onLogout,
  });

  @override
  State<DashboardMainScreen> createState() => _DashboardMainScreenState();
}

class _DashboardMainScreenState extends State<DashboardMainScreen> {
  int _selectedPageIndex = 0; 

  bool _isLoading = true;
  DateTime _lastSyncTime = DateTime.now();

  double _totalSalesToday = 0.0;
  double _cashSalesToday = 0.0;
  double _gcashSalesToday = 0.0;
  int _transactionCountToday = 0;
  
  List<CustomerModel> _customers = [];
  List<DriverModel> _drivers = [];
  List<ProductModel> _products = [];
  List<OrderItemModel> _orders = [];
  List<DeliveryModel> _deliveries = [];
  List<GallonItemModel> _gallons = [];
  List<ReviewModel> _reviews = [];
  List<Map<String, dynamic>> _recentSales = [];

  List<SystemNotificationModel> _systemNotifications = [];
  final Set<String> _readNotificationIds = {};
  String? _highlightQuery;
  int _ordersAndDeliveriesInitialTab = 0;
  CustomerModel? _initialFocusCustomerMap;

  void _clearHighlight() {
    setState(() {
      _highlightQuery = null;
    });
  }

  int get _unreadNotificationCount =>
      _systemNotifications.where((n) => !n.isRead).length;

  final List<RealtimeChannel> _activeChannels = [];

  @override
  void initState() {
    super.initState();
    _loadSupabaseData();
    _setupRealtimeSubscriptions();
  }

  Timer? _realtimeDebounceTimer;

  @override
  void dispose() {
    _realtimeDebounceTimer?.cancel();
    for (var channel in _activeChannels) {
      SupabaseService.client.removeChannel(channel);
    }
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    try {
      final tables = [
        'orders',
        'deliveries',
        'gallons',
        'gallon_transactions',
        'profiles',
        'products',
        'promos',
        'reviews',
        'announcements',
        'payments',
        'debts',
        'sales',
        'rfid_qr_records',
        'driver_locations'
      ];

      for (var table in tables) {
        final channel = SupabaseService.subscribeToTableChanges(
          channelName: 'public:$table',
          table: table,
          onData: (payload) {
            if (!mounted) return;

            final eventType = payload.eventType.name.toUpperCase();
            final newRecord = payload.newRecord;

            // Realtime user notifications on live events
            if (table == 'deliveries' && newRecord.isNotEmpty) {
              final status = newRecord['status']?.toString().toLowerCase();
              if (status == 'accepted') {
                SweetAlert.showToast('Rider accepted delivery dispatch!', type: SweetAlertType.success);
              } else if (status == 'out_for_delivery') {
                SweetAlert.showToast('Rider is out for delivery!', type: SweetAlertType.info);
              } else if (status == 'delivered') {
                SweetAlert.showToast('Container delivery completed by rider!', type: SweetAlertType.success);
              }
            } else if (table == 'orders' && eventType.contains('INSERT')) {
              SweetAlert.showToast('New customer order received!', type: SweetAlertType.info);
            } else if (table == 'sales' && eventType.contains('INSERT')) {
              SweetAlert.showToast('POS counter sale recorded!', type: SweetAlertType.success);
            }


            _debouncedLoadSupabaseData();
          },
        );
        _activeChannels.add(channel);
      }
    } catch (_) {}
  }


  void _debouncedLoadSupabaseData() {
    _realtimeDebounceTimer?.cancel();
    _realtimeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadSupabaseData(silent: true);
      }
    });
  }

  Future<void> _loadSupabaseData({bool silent = false}) async {
    if (!silent && _orders.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Execute ALL 13 database network requests SIMULTANEOUSLY in PARALLEL via Future.wait
      final results = await Future.wait<dynamic>([
        SupabaseService.client.from('profiles').select('id, full_name').then((v) => v as List<dynamic>), // 0
        SupabaseService.fetchDailySalesSummary(), // 1
        SupabaseService.fetchCustomers(), // 2
        SupabaseService.fetchDrivers(), // 3
        SupabaseService.fetchProducts(), // 4
        SupabaseService.fetchOrders(), // 5
        SupabaseService.fetchDeliveries(), // 6
        SupabaseService.fetchGallons(), // 7
        SupabaseService.fetchGallonQrRecords(), // 8
        SupabaseService.fetchReviews(), // 9
        SupabaseService.fetchStationSettings(), // 10
      ]);

      final allProfilesRaw = results[0] as List;
      final profileLookup = {for (var p in allProfilesRaw) p['id'].toString(): p['full_name'].toString()};

      final salesData = results[1] as Map<String, dynamic>;
      final salesTotal = (salesData['totalSalesToday'] as num?)?.toDouble() ?? 0.0;
      final cashTotal = (salesData['cashSalesToday'] as num?)?.toDouble() ?? 0.0;
      final gcashTotal = (salesData['gcashSalesToday'] as num?)?.toDouble() ?? 0.0;
      final txCount = salesData['transactionCount'] as int? ?? 0;
      final salesList = List<Map<String, dynamic>>.from(salesData['sales'] ?? []);

      final rawCustomers = results[2] as List<Map<String, dynamic>>;
      final freshCustomers = rawCustomers.map((m) => CustomerModel.fromSupabase(m)).toList();

      final rawDrivers = results[3] as List<Map<String, dynamic>>;
      final freshDrivers = rawDrivers.map((m) => DriverModel.fromSupabase(m)).toList();

      final rawProducts = results[4] as List<Map<String, dynamic>>;
      final freshProducts = rawProducts.map((m) => ProductModel.fromSupabase(m)).toList();

      final rawOrders = results[5] as List<Map<String, dynamic>>;
      final freshOrders = rawOrders.map((m) {
        final order = OrderItemModel.fromSupabase(m);
        if (order.driver.isNotEmpty && profileLookup.containsKey(order.driver)) {
          order.driver = profileLookup[order.driver]!;
        }
        return order;
      }).toList();

      final processedOrders = freshOrders;

      final rawDeliveries = results[6] as List<Map<String, dynamic>>;
      final freshDeliveries = rawDeliveries.map((m) {
        final del = DeliveryModel.fromSupabase(m);
        String resolvedDriverName = del.driverName;
        final rawDriverId = m['driver_id']?.toString();

        if (profileLookup.containsKey(del.driverName)) {
          resolvedDriverName = profileLookup[del.driverName]!;
        } else if (rawDriverId != null && profileLookup.containsKey(rawDriverId)) {
          resolvedDriverName = profileLookup[rawDriverId]!;
        }

        return del.copyWith(driverName: resolvedDriverName);
      }).toList();

      final deliveryMap = {for (var d in freshDeliveries) d.orderId: d};
      for (var order in processedOrders) {
        if (deliveryMap.containsKey(order.id)) {
          final del = deliveryMap[order.id]!;
          if (order.driver.isEmpty && del.driverName.isNotEmpty) {
            order.driver = del.driverName;
          }
          if (order.proofUrl.isEmpty && del.proofUrl.isNotEmpty) {
            order.proofUrl = del.proofUrl;
          }
          if ((order.status.toLowerCase() == 'pending' || order.status.toLowerCase() == 'confirmed') &&
              (del.status.toLowerCase() == 'assigned' || del.status.toLowerCase() == 'out_for_delivery' || del.status.toLowerCase() == 'delivered')) {
            order.status = del.status;
          }
        }
      }

      final rawGallons = results[7] as List<Map<String, dynamic>>;
      final rawQrRecords = results[8] as List<Map<String, dynamic>>;

      final qrMap = <String, Map<String, dynamic>>{};
      for (var qr in rawQrRecords) {
        if ((qr['code_type'] ?? '').toString().toUpperCase() == 'QR') {
          final gId = qr['gallon_id']?.toString();
          if (gId != null) {
            qrMap[gId] = qr;
          }
        }
      }

      final freshGallons = rawGallons.map((m) {
        final gallon = GallonItemModel.fromSupabase(m);
        final qr = qrMap[gallon.id];

        String resolvedAssigned = gallon.assigned;
        String resolvedLocation = gallon.location;

        if (gallon.customerId != null && gallon.customerId!.isNotEmpty) {
          if (profileLookup.containsKey(gallon.customerId)) {
            resolvedAssigned = profileLookup[gallon.customerId]!;
          } else {
            final matchedCust = freshCustomers.firstWhere(
              (c) => c.id == gallon.customerId,
              orElse: () => CustomerModel(id: '', fullName: '', phone: '', address: '', rfidUid: '', isRfidActive: false, isActive: true, createdAt: ''),
            );
            if (matchedCust.fullName.isNotEmpty) {
              resolvedAssigned = matchedCust.fullName;
              if (matchedCust.address.isNotEmpty && matchedCust.address != '—' && resolvedLocation == 'Aqua Pure Water Station') {
                resolvedLocation = matchedCust.address;
              }
            }
          }
        }

        return GallonItemModel(
          id: gallon.id,
          gallonCode: gallon.gallonCode,
          status: gallon.status,
          location: resolvedLocation,
          assigned: resolvedAssigned,
          customerId: gallon.customerId,
          containerType: gallon.containerType,
          borrowedAt: gallon.borrowedAt,
          returnedAt: gallon.returnedAt,
          createdAt: gallon.createdAt,
          hasQr: qr != null,
          qrCode: qr?['code']?.toString() ?? gallon.gallonCode,
          qrId: qr?['id']?.toString(),
          qrCreatedAt: qr?['created_at']?.toString() ?? gallon.createdAt,
          isQrActive: qr?['is_active'] ?? (qr != null),
        );
      }).toList();

      final orderLookup = {
        for (var o in processedOrders) ...{o.id: o.orderNumber, o.orderNumber: o.orderNumber}
      };
      final rawReviews = results[9] as List<Map<String, dynamic>>;
      final freshReviews = rawReviews.map((m) {
        final rev = ReviewModel.fromSupabase(m);
        String finalCustName = rev.customerName;
        if ((finalCustName == 'Customer' || finalCustName.isEmpty) && profileLookup.containsKey(rev.customerId)) {
          finalCustName = profileLookup[rev.customerId]!;
        }
        String finalOrdNum = rev.orderNumber;
        if ((finalOrdNum == 'ORD-001' || finalOrdNum.isEmpty) && orderLookup.containsKey(rev.orderId)) {
          finalOrdNum = orderLookup[rev.orderId]!;
        }
        return ReviewModel(
          id: rev.id,
          orderId: rev.orderId,
          orderNumber: finalOrdNum,
          customerId: rev.customerId,
          customerName: finalCustName,
          rating: rev.rating,
          review: rev.review,
          createdAt: rev.createdAt,
        );
      }).toList();



      if (mounted) {
        _orders = processedOrders;
        _deliveries = freshDeliveries;
        _gallons = freshGallons;
        _recentSales = salesList;
        _customers = freshCustomers;
        _drivers = freshDrivers;
        _products = freshProducts;
        _reviews = freshReviews;

        _recomputeLookups();
        _buildNotificationsFromData();

        setState(() {
          _totalSalesToday = salesTotal;
          _cashSalesToday = cashTotal;
          _gcashSalesToday = gcashTotal;
          _transactionCountToday = txCount;

          _lastSyncTime = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showToast('Failed to load data from Supabase: $e');
    }
  }

  void _buildNotificationsFromData() {
    List<SystemNotificationModel> items = [];

    // 1. Deliveries (Rider accepted, out for delivery, delivered, assigned)
    for (var d in _deliveries) {
      final s = d.status.toLowerCase().trim();
      String title = '';
      String msg = '';
      if (s == 'accepted') {
        title = 'Rider Accepted Order ${d.orderNumber}';
        msg = 'Rider ${d.driverName} accepted delivery dispatch for ${d.customerName}.';
      } else if (s == 'out_for_delivery') {
        title = 'Out for Delivery: ${d.orderNumber}';
        msg = 'Rider ${d.driverName} is delivering containers to ${d.customerName}.';
      } else if (s == 'delivered') {
        title = 'Delivery Completed: ${d.orderNumber}';
        msg = 'Rider ${d.driverName} successfully delivered containers to ${d.customerName}.';
      } else if (s == 'assigned') {
        title = 'Driver Assigned: ${d.orderNumber}';
        msg = 'Rider ${d.driverName} assigned to delivery for ${d.customerName}.';
      }

      if (title.isNotEmpty) {
        final notifId = 'del_${d.id}_$s';
        items.add(SystemNotificationModel(
          id: notifId,
          title: title,
          message: msg,
          category: 'Deliveries',
          timestamp: d.acceptedAt != 'Not yet recorded' ? d.acceptedAt : (d.assignedAt != 'Not yet recorded' ? d.assignedAt : 'Recent'),
          relatedId: d.orderNumber,
          targetPage: 'deliveries',
          isRead: _readNotificationIds.contains(notifId),
        ));
      }
    }

    // 2. Orders (Pending order placed, confirmed, cancelled)
    for (var o in _orders) {
      final s = o.status.toLowerCase().trim();
      String title = '';
      String msg = '';
      if (s == 'pending') {
        title = 'New Order Placed: ${o.orderNumber}';
        msg = '${o.customer} placed order for ${o.qty} gallon(s) — ₱${o.totalAmount.toStringAsFixed(2)} (${o.payment}).';
      } else if (s == 'confirmed') {
        title = 'Order Confirmed: ${o.orderNumber}';
        msg = 'Order for ${o.customer} confirmed and ready for rider dispatch.';
      } else if (s == 'cancelled' || s == 'rejected') {
        title = 'Order Cancelled: ${o.orderNumber}';
        msg = 'Order for ${o.customer} was cancelled/rejected${o.rejectionReason.isNotEmpty ? ' (${o.rejectionReason})' : ''}.';
      }

      if (title.isNotEmpty) {
        final notifId = 'ord_${o.id}_$s';
        items.add(SystemNotificationModel(
          id: notifId,
          title: title,
          message: msg,
          category: 'Orders',
          timestamp: o.createdAt.isNotEmpty ? o.createdAt.split('T').first : 'Recent',
          relatedId: o.orderNumber,
          targetPage: 'orders',
          isRead: _readNotificationIds.contains(notifId),
        ));
      }
    }

    // 3. Gallons & Container Inventory
    for (var g in _gallons) {
      if (g.status.toLowerCase() == 'borrowed') {
        final notifId = 'gal_${g.id}_borrowed';
        items.add(SystemNotificationModel(
          id: notifId,
          title: 'Container Borrowed: ${g.gallonCode}',
          message: 'Gallon container ${g.gallonCode} issued to ${g.assigned}.',
          category: 'Gallons',
          timestamp: g.borrowedAt != 'Not yet recorded' ? g.borrowedAt : 'Recent',
          relatedId: g.gallonCode,
          targetPage: 'gallons',
          isRead: _readNotificationIds.contains(notifId),
        ));
      }
    }

    // 4. POS Sales & Payments
    for (var s in _recentSales.take(10)) {
      final saleId = s['id']?.toString() ?? 'sale';
      final amt = (s['total_amount'] is num) ? (s['total_amount'] as num).toDouble() : 0.0;
      final pm = s['payment_method']?.toString() ?? 'Cash';
      final notifId = 'sale_$saleId';

      items.add(SystemNotificationModel(
        id: notifId,
        title: 'POS Sale Recorded',
        message: 'Station sale recorded for ₱${amt.toStringAsFixed(2)} via $pm.',
        category: 'Sales',
        timestamp: 'Today',
        relatedId: saleId,
        targetPage: 'sales',
        isRead: _readNotificationIds.contains(notifId),
      ));
    }

    // 5. Customer & Staff Accounts
    for (var c in _customers.take(5)) {
      final notifId = 'cust_${c.id}';
      items.add(SystemNotificationModel(
        id: notifId,
        title: 'Customer Account Active',
        message: 'Customer ${c.fullName} active (${c.phone}).',
        category: 'Accounts',
        timestamp: c.createdAt,
        relatedId: c.id,
        targetPage: 'accounts',
        isRead: _readNotificationIds.contains(notifId),
      ));
    }

    _systemNotifications = items;
  }

  void _handleNotificationTap(String category, String? relatedId, String? targetPage) {
    setState(() {
      _highlightQuery = relatedId;
    });

    final cat = category.toLowerCase();
    final target = (targetPage ?? '').toLowerCase();

    if (target == 'deliveries' || cat == 'deliveries') {
      _ordersAndDeliveriesInitialTab = 1; // Delivery Dispatches tab
      _navigateToPage(1);
    } else if (target == 'orders' || cat == 'orders') {
      _ordersAndDeliveriesInitialTab = 0; // Orders Management tab
      _navigateToPage(1);
    } else if (target == 'gallons' || cat == 'gallons') {
      _navigateToPage(8);
    } else if (target == 'sales' || cat == 'sales') {
      _navigateToPage(10);
    } else if (target == 'accounts' || cat == 'accounts') {
      _navigateToPage(5);
    } else {
      _navigateToPage(0); // Dashboard Overview
    }
  }

  void _openNotificationPanel() {
    NotificationPanelOverlay.show(
      context,
      notifications: _systemNotifications,
      onMarkAsRead: (id) {
        setState(() {
          _readNotificationIds.add(id);
          _buildNotificationsFromData();
        });
      },
      onMarkAllAsRead: () {
        setState(() {
          for (var n in _systemNotifications) {
            _readNotificationIds.add(n.id);
          }
          _buildNotificationsFromData();
        });
      },
      onClearAll: () {
        setState(() {
          for (var n in _systemNotifications) {
            _readNotificationIds.add(n.id);
          }
          _systemNotifications.clear();
        });
      },
      onNotificationTap: _handleNotificationTap,
    );
  }


  void _showToast(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('failed') || lower.contains('error') || lower.contains('cannot') || lower.contains('invalid')) {
      SweetAlert.showGlobalError(message);
    } else {
      SweetAlert.showGlobalSuccess(message);
    }
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedPageIndex = index;
      _initialFocusCustomerMap = null; // Clear focus if navigated via sidebar or other means
    });
  }

  // Action & Modal Dialog Triggers
  final Set<String> _processingOrderIds = {};

  void _approveOrder(OrderItemModel order) async {
    if (_processingOrderIds.contains(order.id)) return;
    setState(() {
      _processingOrderIds.add(order.id);
    });
    try {
      await SupabaseService.updateOrderStatus(orderId: order.id, status: 'confirmed');
      _showToast('Order ${order.displayId} confirmed & approved successfully.');
      await _loadSupabaseData(silent: true);
    } catch (e) {
      SweetAlert.showToast(
        'Failed to approve order: $e',
        type: SweetAlertType.error,
        title: 'Approval Failed',
        autoDismiss: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingOrderIds.remove(order.id);
        });
      }
    }
  }

  void _rejectOrder(OrderItemModel order, String reason) async {
    if (_processingOrderIds.contains(order.id)) return;
    setState(() {
      _processingOrderIds.add(order.id);
    });
    try {
      await SupabaseService.rejectOrder(orderId: order.id, reason: reason);
      _showToast('Order ${order.displayId} rejected. Reason recorded.');
      await _loadSupabaseData(silent: true);
    } catch (e) {
      SweetAlert.showToast(
        'Failed to reject order: $e',
        type: SweetAlertType.error,
        title: 'Rejection Failed',
        autoDismiss: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingOrderIds.remove(order.id);
        });
      }
    }
  }

  void _openDriverModal(OrderItemModel order) {
    showDialog(
      context: context,
      builder: (context) => AssignDriverDialog(
        order: order,
        onSuccess: () {
          _showToast('Driver assigned successfully.');
          _loadSupabaseData(silent: true);
        },
        onError: (err) => SweetAlert.showToast(
          'Failed to assign driver: $err',
          type: SweetAlertType.error,
          title: 'Dispatch Failed',
          autoDismiss: false,
        ),
      ),
    );
  }

  void _openAuthorizeCashiersModal() {
    showDialog(
      context: context,
      builder: (context) => AuthorizeCashiersDialog(
        onRefresh: _loadSupabaseData,
      ),
    );
  }


  void _openAddCustomerModal() {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Customer registered successfully.');
        },
        onError: (err) => _showToast('Failed to register customer: $err'),
      ),
    );
  }

  void _openAddDriverModal() {
    showDialog(
      context: context,
      builder: (context) => AddDriverDialog(
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Driver registered successfully.');
        },
        onError: (err) => _showToast('Failed to register driver: $err'),
      ),
    );
  }

  void _openAddCashierModal() {
    showDialog(
      context: context,
      builder: (context) => AddCashierDialog(
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Cashier registered successfully.');
        },
        onError: (err) => _showToast('Failed to register cashier: $err'),
      ),
    );
  }

  void _openAddProductModal() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Product added to master catalog.');
        },
        onError: (err) => _showToast('Failed to add product: $err'),
      ),
    );
  }

  void _openEditProductModal(ProductModel prod) {
    showDialog(
      context: context,
      builder: (context) => EditProductDialog(
        product: prod,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Product "${prod.name}" updated.');
        },
        onError: (err) => _showToast('Failed to update product: $err'),
      ),
    );
  }

  void _openAddGallonModal() {
    showDialog(
      context: context,
      builder: (context) => AddGallonDialog(
        customers: _customers,
        products: _products,
        onOpenBatchMode: _openBatchGenerateQrModal,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Gallon registered in physical QR registry.');
        },
        onError: (err) => _showToast('Failed to register gallon: $err'),
      ),
    );
  }

  void _openBatchGenerateQrModal() {
    showDialog(
      context: context,
      builder: (context) => BatchGenerateQrDialog(
        customers: _customers,
        products: _products,
        gallons: _gallons,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Batch QR generation complete.');
        },
        onError: (err) => _showToast('Batch QR generation error: $err'),
      ),
    );
  }



  void _openEditGallonModal(GallonItemModel gallon) {
    showDialog(
      context: context,
      builder: (context) => EditGallonDialog(
        gallon: gallon,
        customers: _customers,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Container details updated for "${gallon.gallonCode}".');
        },
        onError: (err) => _showToast('Failed to update container: $err'),
      ),
    );
  }

  void _showQrDialog(GallonItemModel gallon) {
    showDialog(
      context: context,
      builder: (context) => QrViewDialog(gallon: gallon),
    );
  }

  void _generateQrForGallon(GallonItemModel gallon) async {
    try {
      await SupabaseService.generateQrForGallon(
        gallonId: gallon.id,
        gallonCode: gallon.gallonCode,
      );
      await _loadSupabaseData();
      final updatedGallon = _gallons.firstWhere((g) => g.id == gallon.id, orElse: () => gallon);
      _showQrDialog(updatedGallon);
      _showToast('Unique QR generated and linked to gallon ${gallon.gallonCode}.');
    } catch (e) {
      _showToast('Failed to generate QR: $e');
    }
  }

  void _openAssignCustomerRfidModal(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AssignCustomerRfidDialog(
        customers: _customers,
        initialCustomer: customer,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Loyalty RFID card assigned to ${customer.fullName}.');
        },
        onError: (err) => _showToast('Failed to assign RFID: $err'),
      ),
    );
  }

  void _openRegisterUnassignedRfidModal() {
    showDialog(
      context: context,
      builder: (context) => AddUnassignedRfidDialog(
        onSuccess: () {
          _loadSupabaseData();
          _showToast('New unassigned RFID card registered successfully.');
        },
        onError: (err) => _showToast('Registration failed: $err'),
      ),
    );
  }

  void _toggleCustomerRfidActiveStatus(CustomerModel customer) async {
    try {
      final newStatus = !customer.isRfidActive;
      await SupabaseService.toggleCustomerRfidStatus(
        customerId: customer.id,
        isActive: newStatus,
        currentRfidUid: customer.rfidUid,
      );
      _loadSupabaseData();
      _showToast('Loyalty card status updated to ${newStatus ? "Active" : "Inactive"}.');
    } catch (e) {
      _showToast('Failed to update RFID status: $e');
    }
  }

  void _showCustomerDetailsModal(CustomerModel cust) {
    final purchasedGallons = _getGallonsPurchasedForCustomer(cust);
    final customerOrders = _orders.where((o) => o.customer == cust.fullName || o.customer.toLowerCase().contains(cust.fullName.toLowerCase())).toList();
    final completedOrders = customerOrders.where((o) => o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed').length;

    // Smart address fallback from order history if profiles.address is empty
    String resolvedAddress = cust.address;
    if ((resolvedAddress == '—' || resolvedAddress.trim().isEmpty) && customerOrders.isNotEmpty) {
      final orderWithAddress = customerOrders.firstWhere((o) => o.address.isNotEmpty && o.address != '—', orElse: () => customerOrders.first);
      if (orderWithAddress.address.isNotEmpty && orderWithAddress.address != '—') {
        resolvedAddress = orderWithAddress.address;
      }
    }

    final updatedCust = CustomerModel(
      id: cust.id,
      fullName: cust.fullName,
      email: cust.email,
      phone: cust.phone,
      address: resolvedAddress,
      avatarUrl: cust.avatarUrl,
      rfidUid: cust.rfidUid,
      isRfidActive: cust.isRfidActive,
      isActive: cust.isActive,
      createdAt: cust.createdAt,
    );

    showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(
        customer: updatedCust,
        purchasedGallons: purchasedGallons,
        totalOrders: customerOrders.length,
        completedOrders: completedOrders,
      ),
    );
  }

  void _showDriverDetailsModal(DriverModel drv) {
    int totalDel = _deliveries.where((d) => d.driverName == drv.fullName).length;
    int completedDel = _deliveries.where((d) => d.driverName == drv.fullName && d.status.toLowerCase() == 'delivered').length;
    int activeDel = _deliveries.where((d) => d.driverName == drv.fullName && (d.status.toLowerCase() == 'assigned' || d.status.toLowerCase() == 'accepted' || d.status.toLowerCase() == 'out_for_delivery')).length;

    showDialog(
      context: context,
      builder: (context) => DriverDetailsDialog(
        driver: drv,
        totalDeliveries: totalDel,
        completedDeliveries: completedDel,
        activeDeliveries: activeDel,
      ),
    );
  }

  void _showCashierDetailsModal(CashierModel cashier) async {
    try {
      final cashierSales = await SupabaseService.client
          .from('sales')
          .select('total_amount, payment_method')
          .eq('cashier_id', cashier.id);
          
      int totalTransactions = cashierSales.length;
      double totalRev = 0;
      double cashRev = 0;
      double gcashRev = 0;

      for (var sale in cashierSales) {
        final amt = sale['total_amount'] ?? 0;
        final val = (amt is num) ? amt.toDouble() : (double.tryParse(amt.toString()) ?? 0.0);
        totalRev += val;

        final pm = sale['payment_method']?.toString().toLowerCase() ?? '';
        if (pm.contains('gcash')) {
          gcashRev += val;
        } else {
          cashRev += val;
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => CashierDetailsDialog(
            cashier: cashier,
            totalTransactions: totalTransactions,
            totalRevenueHandled: totalRev,
            cashSalesHandled: cashRev,
            gcashSalesHandled: gcashRev,
          ),
        );
      }
    } catch (e) {
      _showToast('Failed to fetch cashier sales history.');
    }
  }

  void _showViewAccountDetailsModal(Map<String, dynamic> profile) {
    final role = (profile['role'] ?? '').toString().toLowerCase().trim();
    if (role == 'customer') {
      _showCustomerDetailsModal(CustomerModel.fromSupabase(profile));
    } else if (role == 'driver') {
      _showDriverDetailsModal(DriverModel.fromSupabase(profile));
    } else if (role == 'cashier') {
      _showCashierDetailsModal(CashierModel.fromSupabase(profile));
    }
  }

  void _openEditAccountModal(Map<String, dynamic> profile) {
    final role = (profile['role'] ?? '').toString().toLowerCase().trim();
    if (role == 'customer') {
      _openEditCustomerModal(CustomerModel.fromSupabase(profile));
    } else if (role == 'driver') {
      _openEditDriverModal(DriverModel.fromSupabase(profile));
    } else if (role == 'cashier') {
      showDialog(
        context: context,
        builder: (context) => EditCashierDialog(
          cashier: CashierModel.fromSupabase(profile),
          onSuccess: () {
            _loadSupabaseData();
            _showToast('Cashier profile updated.');
          },
          onError: (err) => _showToast('Failed to update cashier: $err'),
        ),
      );
    }
  }

  void _openEditCustomerModal(CustomerModel cust) {
    showDialog(
      context: context,
      builder: (context) => EditCustomerDialog(
        customer: cust,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Customer profile updated.');
        },
        onError: (err) => _showToast('Failed to update profile: $err'),
      ),
    );
  }

  void _openEditDriverModal(DriverModel drv) {
    showDialog(
      context: context,
      builder: (context) => EditDriverDialog(
        driver: drv,
        onSuccess: () {
          _loadSupabaseData();
          _showToast('Driver profile updated.');
        },
        onError: (err) => _showToast('Failed to update driver: $err'),
      ),
    );
  }

  void _openCancelDeliveryModal(DeliveryModel delivery) {
    final reasonController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F2942),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0x3838BDF8)),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Color(0xFFF87171), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cancel Delivery & Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to cancel dispatch for order ${delivery.orderNumber}?',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Customer:', style: TextStyle(fontSize: 12, color: Color(0xFF93C5FD))),
                            Text(delivery.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Assigned Driver:', style: TextStyle(fontSize: 12, color: Color(0xFF93C5FD))),
                            Text(delivery.driverName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Current Status:', style: TextStyle(fontSize: 12, color: Color(0xFF93C5FD))),
                            OrderStatusBadge(status: delivery.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for Cancellation (Optional):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. Customer cancelled order, out of stock, address invalid...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x3838BDF8))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x3838BDF8))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Back', style: TextStyle(color: Color(0xFFBAE6FD))),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          try {
                            final targetId = delivery.orderId.isNotEmpty ? delivery.orderId : delivery.orderNumber;
                            final reason = reasonController.text.trim().isNotEmpty
                                ? reasonController.text.trim()
                                : 'Cancelled by admin from delivery dispatch';

                            await SupabaseService.cancelOrder(
                              orderId: targetId,
                              reason: reason,
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              _loadSupabaseData();
                              SweetAlert.showToast(
                                'Order ${delivery.orderNumber} has been cancelled.',
                                type: SweetAlertType.success,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isSaving = false);
                              SweetAlert.showToast(
                                'Failed to cancel order: $e',
                                type: SweetAlertType.error,
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cancel_outlined, size: 16),
                  label: Text(isSaving ? 'Cancelling...' : 'Cancel Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openOverrideDeliveryStatusModal(DeliveryModel delivery) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedStatus = delivery.status;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Admin Override: Delivery Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warning: Manually changing a delivery status may skip driver application workflows.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus.toLowerCase(),
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                      DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                      DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery')),
                      DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStatus = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    setModalState(() => isSaving = true);
                    try {
                      await SupabaseService.updateDeliveryStatus(
                        deliveryId: delivery.id,
                        status: selectedStatus,
                        orderId: delivery.orderId,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        _loadSupabaseData();
                        _showToast('Delivery status overridden to $selectedStatus.');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setModalState(() => isSaving = false);
                        _showToast('Failed to override status: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                  child: isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Override Status'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGallonHistoryDialog(GallonItemModel gallon) {
    showDialog(
      context: context,
      builder: (context) => GallonHistoryDialog(
        gallonId: gallon.id,
        gallonCode: gallon.gallonCode,
      ),
    );
  }

  void _viewOrderDetails(OrderItemModel order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(
        order: order,
        onApprove: () => _approveOrder(order),
        onReject: (reason) => _rejectOrder(order, reason),
        onAssignDriver: () => _openDriverModal(order),
        onDelete: () => _deleteOrder(order),
        isProcessing: _processingOrderIds.contains(order.id),
      ),
    );
  }

  void _deleteOrder(OrderItemModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFA082A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x3838BDF8))),
        title: const Text('Permanently Delete Order?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Are you sure you want to PERMANENTLY delete order "${order.orderNumber}" (${order.customer})? This action cannot be undone.', style: const TextStyle(fontSize: 13, color: Color(0xFFBAE6FD))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD)))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await SupabaseService.deleteOrder(order.id);
                SweetAlert.showGlobalSuccess('Order "${order.orderNumber}" permanently deleted!');
                _loadSupabaseData();
              } catch (e) {
                SweetAlert.showGlobalError('Failed to delete order: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _locateCustomerOnMap(OrderItemModel order) {
    // Find customer by name. In a real app, you might want to use customer UUID if available in OrderItemModel
    final customer = _customers.firstWhere(
      (c) => c.fullName.toLowerCase() == order.customer.toLowerCase(),
      orElse: () => CustomerModel(
        id: '',
        fullName: order.customer,
        phone: order.customerPhone,
        address: order.address,
        latitude: SupabaseService.stationLatitude,
        longitude: SupabaseService.stationLongitude,
        rfidUid: '',
        isRfidActive: false,
        isActive: true,
        createdAt: '',
      ),
    );

    setState(() {
      _initialFocusCustomerMap = customer;
      _selectedPageIndex = 2; // Live Map
    });
  }

  void _locateGallonOnMap(GallonItemModel gallon) {
    CustomerModel? customer;
    if (gallon.customerId != null && gallon.customerId!.isNotEmpty) {
      customer = _customers.where((c) => c.id == gallon.customerId).firstOrNull;
    }
    if (customer == null && gallon.assigned.isNotEmpty && !gallon.assigned.toLowerCase().contains('available') && gallon.assigned != '—') {
      customer = _customers.where((c) => c.fullName.toLowerCase() == gallon.assigned.toLowerCase()).firstOrNull;
    }

    if (customer == null) {
      customer = CustomerModel(
        id: gallon.customerId ?? '',
        fullName: gallon.assigned.isNotEmpty && gallon.assigned != '—' ? gallon.assigned : 'Station Stock (${gallon.gallonCode})',
        phone: '',
        address: gallon.location,
        latitude: SupabaseService.stationLatitude,
        longitude: SupabaseService.stationLongitude,
        rfidUid: '',
        isRfidActive: false,
        isActive: true,
        createdAt: '',
      );
    }

    setState(() {
      _initialFocusCustomerMap = customer;
      _selectedPageIndex = 2; // Live Map
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFA082A45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x3838BDF8)),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: const Text(
            'Are you sure you want to end your master admin session?',
            style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFBAE6FD))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  int _pendingCount = 0;
  int _activeDeliveriesCount = 0;
  Map<String, int> _customerGallonPurchasesLookup = {};

  void _recomputeLookups() {
    int pending = 0;
    int activeDel = 0;
    final lookup = <String, int>{};

    for (var o in _orders) {
      final s = o.status.toLowerCase();
      if (s == 'pending') {
        pending++;
      } else if (s == 'assigned' || s == 'accepted' || s == 'out_for_delivery') {
        activeDel++;
      }

      if (s == 'delivered' || s == 'completed') {
        final key = o.customer.toLowerCase().trim();
        lookup[key] = (lookup[key] ?? 0) + o.qty;
      }
    }

    _pendingCount = pending;
    _activeDeliveriesCount = activeDel;
    _customerGallonPurchasesLookup = lookup;
  }

  int _getGallonsPurchasedForCustomer(CustomerModel cust) {
    final key = cust.fullName.toLowerCase().trim();
    return _customerGallonPurchasesLookup[key] ?? 0;
  }

  Widget _buildCurrentPage() {
    switch (_selectedPageIndex) {
      case 0:
        return OverviewPage(
          adminName: widget.adminName,
          totalSalesToday: _totalSalesToday,
          cashSalesToday: _cashSalesToday,
          gcashSalesToday: _gcashSalesToday,
          transactionCountToday: _transactionCountToday,
          pendingCount: _pendingCount,
          activeDeliveriesCount: _activeDeliveriesCount,
          customers: _customers,
          drivers: _drivers,
          products: _products,
          gallons: _gallons,
          orders: _orders,
          deliveries: _deliveries,
          reviews: _reviews,
          processingOrderIds: _processingOrderIds,
          onApproveOrder: _approveOrder,
          onAssignDriver: _openDriverModal,
          onNavigate: _navigateToPage,
        );
      case 1:
        return OrdersAndDeliveriesPage(
          orders: _orders,
          deliveries: _deliveries,
          processingOrderIds: _processingOrderIds,
          onApprove: _approveOrder,
          onReject: (order, reason) => _rejectOrder(order, reason),
          onAssignDriver: _openDriverModal,
          onViewDetails: _viewOrderDetails,
          onDeleteOrder: _deleteOrder,
          onCancelDelivery: _openCancelDeliveryModal,
          onOverrideStatus: _openOverrideDeliveryStatusModal,
          onAuthorizeCashiers: _openAuthorizeCashiersModal,
          onRefresh: _loadSupabaseData,
          initialTab: _ordersAndDeliveriesInitialTab,
          highlightQuery: _highlightQuery,
          onClearHighlight: _clearHighlight,
          onLocateCustomer: _locateCustomerOnMap,
        );
      case 2:
        return LiveTrackingPage(
          customers: _customers,
          drivers: _drivers,
          orders: _orders,
          deliveries: _deliveries,
          onRefresh: _loadSupabaseData,
          initialFocusCustomer: _initialFocusCustomerMap,
        );
      case 3:
        return AnnouncementsPage(
          onRefresh: _loadSupabaseData,
        );
      case 4:
        return ReviewsPage(
          reviews: _reviews,
          onRefresh: _loadSupabaseData,
        );
      case 5:
        return AccountManagementPage(
          customers: _customers,
          drivers: _drivers,
          onAddCustomer: _openAddCustomerModal,
          onAddDriver: _openAddDriverModal,
          onAddCashier: _openAddCashierModal,
          onViewGenericAccount: _showViewAccountDetailsModal,
          onEditGenericAccount: _openEditAccountModal,
          onRefresh: _loadSupabaseData,
          highlightQuery: _highlightQuery,
          onClearHighlight: _clearHighlight,
        );
      case 6:
        return LoyaltyRfidPage(
          customers: _customers,
          getGallonsPurchased: _getGallonsPurchasedForCustomer,
          onAssignRfid: _openAssignCustomerRfidModal,
          onToggleRfidStatus: _toggleCustomerRfidActiveStatus,
          onRegisterUnassignedRfid: _openRegisterUnassignedRfidModal,
        );
      case 7:
        return ProductsPage(
          products: _products,
          onAddProduct: _openAddProductModal,
          onEditProduct: _openEditProductModal,
          onRefresh: _loadSupabaseData,
        );
      case 8:
        return GallonsQrPage(
          gallons: _gallons,
          customers: _customers,
          onAddGallon: _openAddGallonModal,
          onBatchGenerateQr: _openBatchGenerateQrModal,
          onEditGallon: _openEditGallonModal,
          onViewQr: _showQrDialog,
          onGenerateQr: _generateQrForGallon,
          onViewHistory: _showGallonHistoryDialog,
          onRefresh: _loadSupabaseData,
          highlightQuery: _highlightQuery,
          onClearHighlight: _clearHighlight,
          onLocateCustomer: _locateGallonOnMap,
        );
      case 9:
        return PromosPage(
          onRefresh: _loadSupabaseData,
        );
      case 10:
        return SalesPage(
          totalSalesToday: _totalSalesToday,
          cashSalesToday: _cashSalesToday,
          gcashSalesToday: _gcashSalesToday,
          transactionCountToday: _transactionCountToday,
          sales: _recentSales,
          highlightQuery: _highlightQuery,
          onClearHighlight: _clearHighlight,
        );
      case 11:
        return SettingsPage(
          adminName: widget.adminName,
          lastSyncTime: _lastSyncTime,
          onRefresh: _loadSupabaseData,
        );
      case 12:
        return NotificationsPage(
          notifications: _systemNotifications,
          onMarkAsRead: (id) {
            setState(() {
              _readNotificationIds.add(id);
              _buildNotificationsFromData();
            });
          },
          onMarkAllAsRead: () {
            setState(() {
              for (var n in _systemNotifications) {
                _readNotificationIds.add(n.id);
              }
              _buildNotificationsFromData();
            });
          },
          onClearAll: () {
            setState(() {
              for (var n in _systemNotifications) {
                _readNotificationIds.add(n.id);
              }
              _systemNotifications.clear();
            });
          },
          onRefresh: _loadSupabaseData,
          onNotificationTap: _handleNotificationTap,
        );
      default:
        return OverviewPage(
          adminName: widget.adminName,
          totalSalesToday: _totalSalesToday,
          cashSalesToday: _cashSalesToday,
          gcashSalesToday: _gcashSalesToday,
          transactionCountToday: _transactionCountToday,
          pendingCount: _pendingCount,
          activeDeliveriesCount: _activeDeliveriesCount,
          customers: _customers,
          drivers: _drivers,
          products: _products,
          gallons: _gallons,
          orders: _orders,
          deliveries: _deliveries,
          reviews: _reviews,
          onApproveOrder: _approveOrder,
          onAssignDriver: _openDriverModal,
          onNavigate: _navigateToPage,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    final mainContentArea = Column(
      children: [
        AppTopbar(
          isDesktop: isDesktop,
          selectedPageIndex: _selectedPageIndex,
          adminName: widget.adminName,
          onRefresh: _loadSupabaseData,
          unreadNotificationCount: _unreadNotificationCount,
          onOpenNotifications: _openNotificationPanel,
        ),
        if (_isLoading)
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFE0F2FE),
            color: Color(0xFF0284C7),
          ),
        Expanded(
          child: _buildCurrentPage(),
        ),
      ],
    );

    return Scaffold(
      drawer: !isDesktop
          ? Drawer(
              child: AppSidebar(
                selectedIndex: _selectedPageIndex,
                pendingCount: _pendingCount,
                driversCount: _drivers.length,
                customersCount: _customers.length,
                productsCount: _products.length,
                unreadNotificationCount: _unreadNotificationCount,
                onNavigate: _navigateToPage,
                onLogout: _confirmLogout,
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0F9FF),
              Color(0xFFE0F2FE),
              Color(0xFFEBF8FF),
            ],
          ),
        ),
        child: isDesktop
            ? Stack(
                children: [
                  Positioned(
                    top: -120,
                    right: 180,
                    child: Container(
                      width: 600,
                      height: 600,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0284C7).withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: 200,
                    child: Container(
                      width: 700,
                      height: 700,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0369A1).withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  // Main Content Layer - Anchored starting at left: 280px, clipped to bounds
                  Positioned(
                    left: 280,
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRect(
                      child: mainContentArea,
                    ),
                  ),
                  // Sidebar Layer - Physically anchored left: 0, top: 0, bottom: 0, width: 280px
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 280,
                    child: AppSidebar(
                      selectedIndex: _selectedPageIndex,
                      pendingCount: _pendingCount,
                      driversCount: _drivers.length,
                      customersCount: _customers.length,
                      productsCount: _products.length,
                      unreadNotificationCount: _unreadNotificationCount,
                      onNavigate: _navigateToPage,
                      onLogout: _confirmLogout,
                    ),
                  ),
                ],
              )
            : mainContentArea,
      ),
    );
  }
}

