import '../services/supabase_service.dart';

class CustomerModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? avatarUrl;
  final String rfidUid;
  final bool isRfidActive;
  final bool isActive;
  final String createdAt;
  final double latitude;
  final double longitude;

  CustomerModel({
    required this.id,
    required this.fullName,
    this.email = '—',
    required this.phone,
    required this.address,
    this.avatarUrl,
    required this.rfidUid,
    required this.isRfidActive,
    required this.isActive,
    required this.createdAt,
    this.latitude = 14.2289,
    this.longitude = 121.3283,
  });

  factory CustomerModel.fromSupabase(Map<String, dynamic> map) {
    String uid = '';
    bool rfidActive = false;

    if (map['rfid_qr_records'] is List && (map['rfid_qr_records'] as List).isNotEmpty) {
      final records = map['rfid_qr_records'] as List;
      final rfidRecord = records.firstWhere(
        (r) => (r['code_type'] ?? '').toString().toUpperCase() == 'RFID',
        orElse: () => null,
      );
      if (rfidRecord != null) {
        uid = rfidRecord['code']?.toString().trim() ?? '';
        rfidActive = rfidRecord['is_active'] ?? false;
      }
    } else if (map['rfid_qr_records'] is Map) {
      final r = map['rfid_qr_records'] as Map;
      if ((r['code_type'] ?? '').toString().toUpperCase() == 'RFID') {
        uid = r['code']?.toString().trim() ?? '';
        rfidActive = r['is_active'] ?? false;
      }
    }

    bool active = map['is_archived'] != true;
    final idStr = map['id']?.toString() ?? '';

    // Coordinates parsing with fallback
    double lat = 14.2289;
    double lng = 121.3283;

    final parsedLat = map['latitude'] is num
        ? (map['latitude'] as num).toDouble()
        : double.tryParse(map['latitude']?.toString() ?? '');
    if (parsedLat != null) {
      lat = parsedLat;
    } else if (idStr.isNotEmpty) {
      final hash = idStr.codeUnits.fold<int>(0, (acc, c) => acc + c);
      lat = 14.2180 + ((hash % 200) / 10000.0);
    }

    final parsedLng = map['longitude'] is num
        ? (map['longitude'] as num).toDouble()
        : double.tryParse(map['longitude']?.toString() ?? '');
    if (parsedLng != null) {
      lng = parsedLng;
    } else if (idStr.isNotEmpty) {
      final hash = idStr.codeUnits.fold<int>(0, (acc, c) => acc + c);
      lng = 121.3180 + (((hash * 7) % 200) / 10000.0);
    }

    return CustomerModel(
      id: idStr,
      fullName: map['full_name']?.toString() ?? map['name']?.toString() ?? 'Customer',
      email: map['email']?.toString() ?? '—',
      phone: map['phone']?.toString() ?? '—',
      address: map['address']?.toString() ?? map['delivery_address']?.toString() ?? '—',
      avatarUrl: map['avatar_url']?.toString() ?? map['image_url']?.toString() ?? map['photo_url']?.toString(),
      rfidUid: uid,
      isRfidActive: rfidActive,
      isActive: active,
      createdAt: map['created_at']?.toString().split('T').first ?? '—',
      latitude: lat,
      longitude: lng,
    );
  }
}

class DriverModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final String createdAt;
  final double latitude;
  final double longitude;

  DriverModel({
    required this.id,
    required this.fullName,
    this.email = '—',
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
    this.latitude = 14.2289,
    this.longitude = 121.3283,
  });

  factory DriverModel.fromSupabase(Map<String, dynamic> map) {
    bool active = map['is_archived'] != true;
    final idStr = map['id']?.toString() ?? '';

    double lat = 14.2289;
    double lng = 121.3283;

    final parsedLat = map['latitude'] is num
        ? (map['latitude'] as num).toDouble()
        : double.tryParse(map['latitude']?.toString() ?? '');
    if (parsedLat != null) {
      lat = parsedLat;
    }

    final parsedLng = map['longitude'] is num
        ? (map['longitude'] as num).toDouble()
        : double.tryParse(map['longitude']?.toString() ?? '');
    if (parsedLng != null) {
      lng = parsedLng;
    }

    return DriverModel(
      id: idStr,
      fullName: map['full_name']?.toString() ?? map['name']?.toString() ?? 'Driver',
      email: map['email']?.toString() ?? '—',
      phone: map['phone']?.toString() ?? '—',
      avatarUrl: map['avatar_url']?.toString() ?? map['image_url']?.toString() ?? map['photo_url']?.toString(),
      isActive: active,
      createdAt: map['created_at']?.toString().split('T').first ?? '—',
      latitude: lat,
      longitude: lng,
    );
  }
}

class DriverLocationModel {
  final String driverId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final bool isOnline;
  final DateTime? updatedAt;

  DriverLocationModel({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.heading = 0.0,
    this.speed = 0.0,
    this.isOnline = true,
    this.updatedAt,
  });

  factory DriverLocationModel.fromSupabase(Map<String, dynamic> map) {
    double lat = 14.2289;
    double lng = 121.3283;

    final parsedLat = map['latitude'] is num
        ? (map['latitude'] as num).toDouble()
        : double.tryParse(map['latitude']?.toString() ?? '');
    if (parsedLat != null) lat = parsedLat;

    final parsedLng = map['longitude'] is num
        ? (map['longitude'] as num).toDouble()
        : double.tryParse(map['longitude']?.toString() ?? '');
    if (parsedLng != null) lng = parsedLng;

    DateTime? updated;
    if (map['updated_at'] != null) {
      updated = DateTime.tryParse(map['updated_at'].toString());
    } else if (map['created_at'] != null) {
      updated = DateTime.tryParse(map['created_at'].toString());
    }

    return DriverLocationModel(
      driverId: map['driver_id']?.toString() ?? map['id']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      heading: (map['heading'] as num?)?.toDouble() ?? double.tryParse(map['heading']?.toString() ?? '') ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? double.tryParse(map['speed']?.toString() ?? '') ?? 0.0,
      isOnline: map['is_online'] == true || map['is_online']?.toString().toLowerCase() == 'true',
      updatedAt: updated,
    );
  }
}

class CashierModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String role;
  final bool canAssignDrivers;
  final bool isActive;
  final String createdAt;

  CashierModel({
    required this.id,
    required this.fullName,
    this.email = '—',
    this.phone,
    this.address,
    this.avatarUrl,
    required this.role,
    this.canAssignDrivers = false,
    required this.isActive,
    required this.createdAt,
  });

  factory CashierModel.fromSupabase(Map<String, dynamic> map) {
    bool active = map['is_archived'] != true;
    bool canAssign = map['can_assign_drivers'] == true || map['can_assign_driver'] == true || map['allow_driver_assignment'] == true || map['can_accept_orders'] == true;
    return CashierModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? map['name']?.toString() ?? 'Cashier',
      email: map['email']?.toString() ?? '—',
      phone: map['phone']?.toString() ?? '—',
      address: map['address']?.toString() ?? '—',
      avatarUrl: map['avatar_url']?.toString() ?? map['image_url']?.toString() ?? map['photo_url']?.toString(),
      role: map['role']?.toString() ?? 'cashier',
      canAssignDrivers: canAssign,
      isActive: active,
      createdAt: map['created_at']?.toString().split('T').first ?? '—',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String description;
  final String? imageUrl;
  final bool isActive;
  final bool isAvailable;
  final String createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.stock = 0,
    required this.description,
    this.imageUrl,
    required this.isActive,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory ProductModel.fromSupabase(Map<String, dynamic> map) {
    double p = 0.0;
    if (map['price'] is num) p = (map['price'] as num).toDouble();

    int st = 0;
    if (map['stock'] is num) st = (map['stock'] as num).toInt();

    bool active = map['is_active'] ?? true;
    bool available = map['is_available'] ?? (map['stock'] != null ? (st > 0) : true);

    return ProductModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Product',
      category: map['category']?.toString() ?? map['type']?.toString() ?? 'Refill',
      price: p,
      stock: st,
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
      isActive: active,
      isAvailable: available,
      createdAt: map['created_at']?.toString().split('T').first ?? '—',
    );
  }
}

class OrderItemModel {
  String id;
  String orderNumber;
  String customer;
  String address;
  int qty;
  String payment;
  String status;
  String driver;
  double totalAmount;
  bool isPos;
  String customerPhone;
  String customerEmail;
  String referenceNumber;
  String receiptUrl;
  String proofUrl;
  String rejectionReason;
  String createdAt;
  List<Map<String, dynamic>> itemsList;

  // Canonical order fields used by Cashier -> Admin Walk-In flow.
  String fulfillmentType;
  bool isWalkIn;
  String orderType;
  double subtotal;
  double deliveryFee;
  double discountAmount;
  String notes;
  String deliverySchedule;
  String customerName;
  String customerPhoneDb;
  String deliveryAddress;
  String paymentStatus;
  String gcashReference;

  OrderItemModel({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.address,
    required this.qty,
    required this.payment,
    required this.status,
    required this.driver,
    required this.totalAmount,
    this.isPos = false,
    this.customerPhone = '—',
    this.customerEmail = '—',
    this.referenceNumber = '',
    this.receiptUrl = '',
    this.proofUrl = '',
    this.rejectionReason = '',
    this.createdAt = '',
    this.itemsList = const [],
    this.fulfillmentType = '',
    this.isWalkIn = false,
    this.orderType = '',
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.discountAmount = 0.0,
    this.notes = '',
    this.deliverySchedule = '',
    this.customerName = '',
    this.customerPhoneDb = '',
    this.deliveryAddress = '',
    this.paymentStatus = '',
    this.gcashReference = '',
  });

  static String formatLegitOrderNumber(String rawOrd, {String? createdAtIso, String? id}) {
    final clean = rawOrd.trim();
    if (clean.isNotEmpty) return clean;
    if (id != null && id.trim().isNotEmpty) return id.trim();
    return 'Order';
  }

  String get displayId => formatLegitOrderNumber(orderNumber, createdAtIso: createdAt, id: id);

  String get displayStatus {
    switch (status.toLowerCase().trim()) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'assigned': return 'Driver Assigned';
      case 'accepted': return 'Accepted';
      case 'out_for_delivery': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  factory OrderItemModel.fromSupabase(Map<String, dynamic> map) {
    int totalQty = 0;
    final parsedItems = <Map<String, dynamic>>[];

    final rawItems = map['order_items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final q = item['quantity'] is num ? (item['quantity'] as num).toInt() : 0;
        final unitRaw = item['unit_price'] ?? item['price'];
        final unitPrice = unitRaw is num ? unitRaw.toDouble() : double.tryParse('$unitRaw') ?? 0.0;
        totalQty += q;

        String productName = item['product_name']?.toString() ?? '';
        final product = item['products'];
        if (product is Map && product['name'] != null) {
          productName = product['name'].toString();
        }
        if (productName.isEmpty) productName = 'Product';

        parsedItems.add({
          'name': productName,
          'qty': q,
          'unit_price': unitPrice,
          'total': unitPrice * q,
          'gallon_type': item['gallon_type']?.toString(),
        });
      }
    }

    if (totalQty == 0 && map['quantity'] is num) totalQty = (map['quantity'] as num).toInt();

    double amount = 0.0;
    final totalRaw = map['total_amount'] ?? map['amount'];
    if (totalRaw is num) amount = totalRaw.toDouble();

    String statusStr = (map['order_status'] ?? map['status'] ?? 'pending').toString().toLowerCase().trim();
    String rawFulfillment = (map['fulfillment_type'] ?? '').toString().toLowerCase().trim();
    String fulfillment = 'Store Pick-up';
    if (rawFulfillment.contains('delivery') || rawFulfillment.contains('for_delivery')) {
      fulfillment = 'Store Delivery';
    } else if (rawFulfillment.contains('pickup') || rawFulfillment.contains('pick_up')) {
      fulfillment = 'Store Pick-up';
    } else if (statusStr == 'completed') {
      fulfillment = 'Store Pick-up';
    } else {
      fulfillment = 'Store Delivery';
    }

    final dbUuid = map['id']?.toString() ?? '';
    final orderNum = map['order_number']?.toString() ?? dbUuid;
    final orderType = (map['order_type'] ?? '').toString().trim();
    final isWalkIn = map['is_walk_in'] == true || orderType.toLowerCase() == 'walk_in';
    final isPosOrder = isWalkIn || orderType.toLowerCase() == 'pos' || orderNum.toUpperCase().startsWith('POS-');

    String rawCust = (map['customer_name'] ?? '').toString().trim();
    final profile = map['profiles'];
    if (rawCust.isEmpty || rawCust.toLowerCase() == 'customer' || rawCust.toLowerCase() == 'walk-in customer') {
      if (profile is Map && profile['full_name'] != null && profile['full_name'].toString().trim().isNotEmpty) {
        rawCust = profile['full_name'].toString().trim();
      }
    }
    if (rawCust.isEmpty) rawCust = 'Customer';

    String rawAddr = (map['delivery_address'] ?? '').toString().trim();
    if (rawAddr.isEmpty && profile is Map) {
      rawAddr = profile['address']?.toString().trim() ?? '';
    }
    if (rawAddr.isEmpty) rawAddr = '—';

    String custPhone = (map['customer_phone'] ?? '').toString().trim();
    if ((custPhone.isEmpty || custPhone == '—') && profile is Map) {
      custPhone = profile['phone']?.toString().trim() ?? '—';
    }
    if (custPhone.isEmpty) custPhone = '—';

    String custEmail = '—';
    if (profile is Map) {
      custEmail = profile['email']?.toString().trim() ?? '—';
      if (custEmail.isEmpty) custEmail = '—';
    }

    String pUrl = (map['pod_image_url'] ??
            map['proof_url'] ??
            map['proof_of_delivery'] ??
            map['proof_of_delivery_url'] ??
            map['proof_image_url'] ??
            map['proof_photo_url'] ??
            map['proof_photo'] ??
            map['proof_image'] ??
            map['delivery_proof'] ??
            map['delivery_proof_url'] ??
            map['pod_url'] ??
            map['pod_photo'] ??
            map['pod_image'] ??
            '').toString().trim();

    String driverName = '';
    final deliveries = map['deliveries'];
    if (deliveries is List && deliveries.isNotEmpty && deliveries.first is Map) {
      final delivery = Map<String, dynamic>.from(deliveries.first as Map);
      final driverProfile = delivery['profiles'];
      if (driverProfile is Map) {
        driverName = driverProfile['full_name']?.toString() ?? '';
      }
      if (driverName.isEmpty) driverName = delivery['driver_id']?.toString() ?? '';
      if (pUrl.isEmpty) {
        pUrl = (delivery['pod_image_url'] ??
                delivery['proof_url'] ??
                delivery['proof_of_delivery'] ??
                delivery['proof_of_delivery_url'] ??
                delivery['proof_image_url'] ??
                delivery['proof_photo_url'] ??
                delivery['proof_photo'] ??
                delivery['proof_image'] ??
                delivery['delivery_proof'] ??
                delivery['delivery_proof_url'] ??
                delivery['pod_url'] ??
                delivery['pod_photo'] ??
                delivery['pod_image'] ??
                '').toString().trim();
      }
    }

    final rawNotes = (map['notes'] ?? '').toString().trim();

    String receiptUrl = '';
    if (rawNotes.isNotEmpty) {
      final receiptImgMatch = RegExp(r'Receipt Image:\s*(https?://[^\s\|]+)', caseSensitive: false).firstMatch(rawNotes);
      if (receiptImgMatch != null && receiptImgMatch.groupCount >= 1) {
        receiptUrl = receiptImgMatch.group(1)?.trim() ?? '';
      }
    }

    String paymentMethod = (map['payment_method'] ?? map['payment'] ?? map['method'] ?? map['payment_type'] ?? map['payment_mode'] ?? '').toString().trim();

    String reference = (map['gcash_reference'] ?? map['reference_number'] ?? map['payment_reference'] ?? map['ref_no'] ?? map['gcash_ref'] ?? map['reference'] ?? map['ocr_ref'] ?? map['ocr_number'] ?? map['transaction_ref'] ?? map['ref'] ?? '').toString().trim();
    if (reference.isEmpty && rawNotes.isNotEmpty) {
      final refMatch = RegExp(r'(?:ref|reference|gcash ref|transaction ref)[:\s#]*([a-zA-Z0-9\-]+)', caseSensitive: false).firstMatch(rawNotes);
      if (refMatch != null && refMatch.groupCount >= 1) {
        reference = refMatch.group(1)?.trim() ?? '';
      }
    }

    if (receiptUrl.isEmpty) {
      receiptUrl = (map['receipt_url'] ?? 
                           map['payment_receipt_url'] ?? 
                           map['payment_receipt'] ?? 
                           map['receipt_image_url'] ?? 
                           map['receipt_image'] ?? 
                           map['receipt_photo_url'] ?? 
                           map['receipt_photo'] ?? 
                           map['receipt'] ?? 
                           map['proof_of_payment'] ?? 
                           map['proof_of_payment_url'] ?? 
                           map['payment_proof'] ?? 
                           map['payment_proof_url'] ?? 
                           map['gcash_receipt'] ?? 
                           map['gcash_receipt_url'] ?? 
                           map['gcash_image_url'] ?? 
                           map['gcash_image'] ?? 
                           map['gcash_screenshot'] ?? 
                           map['gcash_screenshot_url'] ?? 
                           map['screenshot_url'] ?? 
                           map['screenshot'] ?? 
                           map['ocr_image_url'] ?? 
                           map['proof_url'] ?? 
                           map['image_url'] ?? 
                           map['attachment_url'] ?? 
                           map['media_url'] ?? 
                           '').toString().trim();
    }

    // Broad fuzzy search over all map keys for real receipt image URLs
    if (receiptUrl.isEmpty) {
      for (var entry in map.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value?.toString().trim() ?? '';
        if (v.isNotEmpty && v != 'null' && v != '—' && v != 'N/A' && v != 'none' && v != 'COD' && v != 'Cash') {
          if (!k.contains('method') && !k.contains('status') && !k.contains('type') && !k.contains('mode')) {
            if (v.startsWith('http://') || v.startsWith('https://') || v.startsWith('data:image') || v.endsWith('.jpg') || v.endsWith('.jpeg') || v.endsWith('.png') || v.endsWith('.webp') || v.contains('/storage/v1/object/public/')) {
              if (k.contains('receipt') ||
                  k.contains('proof') ||
                  k.contains('gcash') ||
                  k.contains('image') ||
                  k.contains('screenshot') ||
                  k.contains('attach') ||
                  k.contains('media') ||
                  k.contains('ocr') ||
                  k.contains('photo') ||
                  k.contains('file') ||
                  k.contains('pic')) {
                if (!k.contains('avatar') && !k.contains('profile') && !k.contains('product') && !k.contains('user') && !k.contains('driver')) {
                  receiptUrl = v;
                  break;
                }
              }
            }
          }
        }
      }
    }

    if (receiptUrl.isEmpty && rawNotes.isNotEmpty) {
      final urlMatch = RegExp(r'https?://[^\s\|]+', caseSensitive: false).firstMatch(rawNotes);
      if (urlMatch != null) {
        final cand = urlMatch.group(0)?.trim() ?? '';
        if (!cand.contains('openstreetmap.org')) {
          receiptUrl = cand;
        }
      }
    }

    // Check joined payments array
    if (receiptUrl.isEmpty && map['payments'] != null && map['payments'] is List) {
      final pmts = map['payments'] as List;
      for (var p in pmts) {
        if (p is Map) {
          final pMap = Map<String, dynamic>.from(p);
          String pUrl = (pMap['receipt_url'] ?? pMap['payment_receipt_url'] ?? pMap['payment_receipt'] ?? pMap['proof_of_payment'] ?? pMap['proof_of_payment_url'] ?? pMap['payment_proof'] ?? pMap['gcash_receipt_url'] ?? pMap['image_url'] ?? pMap['proof_url'] ?? pMap['screenshot_url'] ?? pMap['url'] ?? '').toString().trim();
          if (pUrl.isEmpty) {
            for (var entry in pMap.entries) {
              final k = entry.key.toString().toLowerCase();
              final v = entry.value?.toString().trim() ?? '';
              if (v.isNotEmpty && v != 'null' && v != '—') {
                if (v.startsWith('http://') || v.startsWith('https://') || v.startsWith('data:image') || v.endsWith('.jpg') || v.endsWith('.png')) {
                  if (k.contains('receipt') || k.contains('proof') || k.contains('gcash') || k.contains('image') || k.contains('pay') || k.contains('screenshot') || k.contains('url') || k.contains('file')) {
                    pUrl = v;
                    break;
                  }
                }
              }
            }
          }
          if (pUrl.isNotEmpty) {
            receiptUrl = pUrl;
            break;
          }
        }
      }
    }

    if (receiptUrl.isEmpty && rawNotes.isNotEmpty) {
      final urlMatch = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(rawNotes);
      if (urlMatch != null) {
        receiptUrl = urlMatch.group(0)?.trim() ?? '';
      }
    }

    // Convert relative storage paths
    if (receiptUrl.isNotEmpty && !receiptUrl.startsWith('http://') && !receiptUrl.startsWith('https://') && !receiptUrl.startsWith('data:image')) {
      final bucket = receiptUrl.contains('/') ? receiptUrl.split('/').first : 'receipts';
      final path = receiptUrl.contains('/') ? receiptUrl.substring(receiptUrl.indexOf('/') + 1) : receiptUrl;
      try {
        receiptUrl = SupabaseService.client.storage.from(bucket).getPublicUrl(path);
      } catch (_) {}
    }

    String rawPayment = (map['payment_method'] ?? map['payment'] ?? map['method'] ?? map['payment_type'] ?? map['payment_mode'] ?? map['payment_option'] ?? '').toString().trim();
    if (rawPayment.isEmpty && rawNotes.isNotEmpty) {
      final upperNotes = rawNotes.toUpperCase();
      if (upperNotes.contains('GCASH')) {
        rawPayment = 'GCash';
      } else if (upperNotes.contains('COD') || upperNotes.contains('CASH')) {
        rawPayment = 'COD';
      }
    }

    final rawPaymentUpper = rawPayment.toUpperCase();

    final isGcash = rawPaymentUpper.contains('GCASH') ||
                    rawPaymentUpper.contains('ONLINE') || 
                    rawPaymentUpper.contains('PAYMONGO') || 
                    rawPaymentUpper.contains('MAYA') || 
                    rawPaymentUpper.contains('E-WALLET') ||
                    rawPaymentUpper.contains('DIGITAL');

    final isExplicitCod = rawPaymentUpper.contains('COD') ||
                          rawPaymentUpper.contains('CASH') ||
                          rawPaymentUpper.contains('DELIVERY') ||
                          rawPaymentUpper.contains('HAND') ||
                          rawPaymentUpper.contains('OFFLINE') ||
                          rawPaymentUpper.contains('PERSON');

    if (isGcash) {
      paymentMethod = 'GCash';
    } else if (isExplicitCod) {
      paymentMethod = 'COD';
    } else if (rawPayment.isEmpty || rawPayment == '—' || rawPayment == 'null') {
      if (reference.isNotEmpty && (receiptUrl.isNotEmpty || rawNotes.toUpperCase().contains('GCASH'))) {
        paymentMethod = 'GCash';
      } else {
        paymentMethod = 'COD';
      }
    } else {
      paymentMethod = rawPayment;
    }

    if (parsedItems.isEmpty && totalQty > 0) {
      final unitPrice = amount / totalQty;
      parsedItems.add({
        'name': 'Product',
        'qty': totalQty,
        'unit_price': unitPrice,
        'total': amount,
      });
    }

    final subtotalRaw = map['subtotal'];
    final deliveryFeeRaw = map['delivery_fee'];
    final discountRaw = map['discount_amount'];

    String schedule = '';
    if (rawNotes.contains('Schedule:')) {
      final match = RegExp(r'Schedule:\s*([^\|]+)', caseSensitive: false).firstMatch(rawNotes);
      if (match != null && match.groupCount >= 1) {
        schedule = match.group(1)?.trim() ?? '';
      }
    }

    String cleanNotes = rawNotes;
    if (cleanNotes.startsWith('Recipient:')) {
      final parts = cleanNotes.split('|');
      if (parts.length > 2) {
        final lastPart = parts.last.trim();
        if (lastPart.toUpperCase() != 'COD' && lastPart.toUpperCase() != 'GCASH' && !lastPart.contains('Schedule:')) {
          cleanNotes = lastPart;
        } else {
          cleanNotes = '';
        }
      } else {
        cleanNotes = '';
      }
    }

    return OrderItemModel(
      id: dbUuid.isNotEmpty ? dbUuid : orderNum,
      orderNumber: orderNum,
      customer: rawCust,
      address: rawAddr,
      qty: totalQty,
      payment: paymentMethod,
      status: statusStr,
      driver: driverName,
      totalAmount: amount,
      isPos: isPosOrder,
      customerPhone: custPhone,
      customerEmail: custEmail,
      referenceNumber: reference,
      receiptUrl: receiptUrl,
      proofUrl: pUrl,
      rejectionReason: (map['rejection_reason'] ?? map['cancel_reason'] ?? '').toString(),
      createdAt: map['created_at']?.toString() ?? '',
      itemsList: parsedItems,
      fulfillmentType: fulfillment,
      isWalkIn: isWalkIn,
      orderType: orderType,
      subtotal: subtotalRaw is num ? subtotalRaw.toDouble() : 0.0,
      deliveryFee: deliveryFeeRaw is num ? deliveryFeeRaw.toDouble() : 0.0,
      discountAmount: discountRaw is num ? discountRaw.toDouble() : 0.0,
      notes: cleanNotes,
      deliverySchedule: schedule,
      customerName: rawCust,
      customerPhoneDb: custPhone,
      deliveryAddress: rawAddr,
      paymentStatus: (map['payment_status'] ?? '').toString(),
      gcashReference: reference,
    );
  }
}

class DeliveryModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String driverName;
  final String status;
  final String assignedAt;
  final String acceptedAt;
  final String startedAt;
  final String deliveredAt;
  final String paymentMethod;
  final String receiptUrl;
  final String gcashReference;
  final double totalAmount;
  final String proofUrl;
  final String notes;

  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.driverName,
    required this.status,
    required this.assignedAt,
    required this.acceptedAt,
    required this.startedAt,
    required this.deliveredAt,
    this.paymentMethod = 'COD',
    this.receiptUrl = '',
    this.gcashReference = '',
    this.totalAmount = 0.0,
    this.proofUrl = '',
    this.notes = '',
  });

  DeliveryModel copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? customerName,
    String? driverName,
    String? status,
    String? assignedAt,
    String? acceptedAt,
    String? startedAt,
    String? deliveredAt,
    String? paymentMethod,
    String? receiptUrl,
    String? gcashReference,
    double? totalAmount,
    String? proofUrl,
    String? notes,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      gcashReference: gcashReference ?? this.gcashReference,
      totalAmount: totalAmount ?? this.totalAmount,
      proofUrl: proofUrl ?? this.proofUrl,
      notes: notes ?? this.notes,
    );
  }

  factory DeliveryModel.fromSupabase(Map<String, dynamic> map) {
    String ordNum = 'ORD-001';
    String custName = 'Customer';
    String pMethod = 'COD';
    String rUrl = '';
    String gRef = '';
    double totalAmt = 0.0;

    if (map['orders'] != null && map['orders'] is Map) {
      final ord = map['orders'] as Map;
      ordNum = ord['order_number']?.toString() ?? ordNum;
      if (ord['customer_name'] != null) {
        custName = ord['customer_name'].toString();
      } else if (ord['profiles'] != null && ord['profiles'] is Map) {
        custName = ord['profiles']['full_name']?.toString() ?? custName;
      }
      pMethod = (ord['payment_method'] ?? ord['payment'] ?? 'COD').toString();

      final ordNotes = (ord['notes'] ?? '').toString();
      if (ordNotes.isNotEmpty) {
        final receiptImgMatch = RegExp(r'Receipt Image:\s*(https?://[^\s\|]+)', caseSensitive: false).firstMatch(ordNotes);
        if (receiptImgMatch != null && receiptImgMatch.groupCount >= 1) {
          rUrl = receiptImgMatch.group(1)?.trim() ?? '';
        }
      }

      if (rUrl.isEmpty) {
        rUrl = (ord['receipt_url'] ?? 
                ord['payment_receipt_url'] ?? 
                ord['payment_receipt'] ?? 
                ord['receipt_image_url'] ?? 
                ord['receipt_image'] ?? 
                ord['receipt_photo_url'] ?? 
                ord['receipt_photo'] ?? 
                ord['receipt'] ?? 
                ord['proof_of_payment'] ?? 
                ord['proof_of_payment_url'] ?? 
                ord['payment_proof'] ?? 
                ord['payment_proof_url'] ?? 
                ord['gcash_receipt'] ?? 
                ord['gcash_receipt_url'] ?? 
                ord['gcash_image_url'] ?? 
                ord['gcash_image'] ?? 
                ord['gcash_screenshot'] ?? 
                ord['gcash_screenshot_url'] ?? 
                ord['screenshot_url'] ?? 
                ord['screenshot'] ?? 
                ord['ocr_image_url'] ?? 
                ord['proof_url'] ?? 
                ord['image_url'] ?? 
                ord['attachment_url'] ?? 
                ord['media_url'] ?? 
                '').toString().trim();
      }

      if (rUrl.isEmpty) {
        for (var entry in ord.entries) {
          final k = entry.key.toString().toLowerCase();
          final v = entry.value?.toString().trim() ?? '';
          if (v.startsWith('http://') || v.startsWith('https://') || v.endsWith('.jpg') || v.endsWith('.jpeg') || v.endsWith('.png') || v.endsWith('.webp')) {
            if (k.contains('receipt') || k.contains('proof') || k.contains('gcash') || k.contains('image') || k.contains('pay') || k.contains('screenshot') || k.contains('attach') || k.contains('media') || k.contains('ocr') || k.contains('photo')) {
              rUrl = v;
              break;
            }
          }
        }
      }

      gRef = (ord['gcash_reference'] ?? ord['reference_number'] ?? ord['payment_reference'] ?? ord['ref_no'] ?? ord['gcash_ref'] ?? ord['reference'] ?? ord['ocr_ref'] ?? ord['ocr_number'] ?? ord['transaction_ref'] ?? ord['ref'] ?? '').toString().trim();

      if (rUrl.isEmpty && ord['notes'] != null) {
        final notesStr = ord['notes'].toString();
        final urlMatch = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(notesStr);
        if (urlMatch != null) {
          rUrl = urlMatch.group(0)?.trim() ?? '';
        }
      }

      if (rUrl.isNotEmpty && !rUrl.startsWith('http://') && !rUrl.startsWith('https://') && !rUrl.startsWith('data:image')) {
        final bucket = rUrl.contains('/') ? rUrl.split('/').first : 'receipts';
        final path = rUrl.contains('/') ? rUrl.substring(rUrl.indexOf('/') + 1) : rUrl;
        try {
          rUrl = SupabaseService.client.storage.from(bucket).getPublicUrl(path);
        } catch (_) {}
      }
      if (gRef.isEmpty && ord['notes'] != null) {
        final notesStr = ord['notes'].toString();
        final refMatch = RegExp(r'(?:ref|reference|gcash ref|transaction ref)[:\s#]*([a-zA-Z0-9\-]+)', caseSensitive: false).firstMatch(notesStr);
        if (refMatch != null && refMatch.groupCount >= 1) {
          gRef = refMatch.group(1)?.trim() ?? '';
        }
      }
      String dbPayment = (ord['payment_method'] ?? ord['payment'] ?? ord['method'] ?? ord['payment_type'] ?? ord['payment_mode'] ?? ord['payment_option'] ?? '').toString().trim();
      if (dbPayment.isEmpty && ord['notes'] != null) {
        final nStr = ord['notes'].toString().toUpperCase();
        if (nStr.contains('GCASH')) {
          dbPayment = 'GCash';
        } else if (nStr.contains('COD') || nStr.contains('CASH')) {
          dbPayment = 'COD';
        }
      }

      final dbPaymentUpper = dbPayment.toUpperCase();

      final isG = dbPaymentUpper.contains('GCASH') ||
                  dbPaymentUpper.contains('ONLINE') || 
                  dbPaymentUpper.contains('PAYMONGO') || 
                  dbPaymentUpper.contains('MAYA') || 
                  dbPaymentUpper.contains('E-WALLET') ||
                  dbPaymentUpper.contains('DIGITAL');

      final isC = dbPaymentUpper.contains('COD') ||
                  dbPaymentUpper.contains('CASH') ||
                  dbPaymentUpper.contains('DELIVERY') ||
                  dbPaymentUpper.contains('HAND') ||
                  dbPaymentUpper.contains('OFFLINE') ||
                  dbPaymentUpper.contains('PERSON');

      if (isG) {
        pMethod = 'GCash';
      } else if (isC) {
        pMethod = 'COD';
      } else if (dbPayment.isEmpty || dbPayment == '—' || dbPayment == 'null') {
        if (gRef.isNotEmpty && (rUrl.isNotEmpty || ord['notes']?.toString().toUpperCase().contains('GCASH') == true)) {
          pMethod = 'GCash';
        } else {
          pMethod = 'COD';
        }
      } else {
        pMethod = dbPayment;
      }

      totalAmt = (ord['total_amount'] is num) ? (ord['total_amount'] as num).toDouble() : 0.0;
    }
    String drv = 'Driver';
    if (map['profiles'] != null && map['profiles'] is Map) {
      drv = map['profiles']['full_name']?.toString() ?? drv;
    } else if (map['driver_id'] != null) {
      drv = map['driver_id'].toString();
    }

    String delStatus = map['status']?.toString().toLowerCase().trim() ?? 'assigned';
    if (map['orders'] != null && map['orders'] is Map) {
      final ordStatus = map['orders']['order_status']?.toString().toLowerCase().trim();
      if (ordStatus == 'cancelled' || ordStatus == 'rejected') {
        delStatus = 'cancelled';
      }
    }

    String formatTime(dynamic val) {
      if (val == null || val.toString().isEmpty) return 'Not yet recorded';
      final str = val.toString();
      if (str.contains('T')) {
        final parts = str.split('T');
        final timePart = parts[1].split('.').first;
        return '${parts[0]} $timePart';
      }
      return str;
    }

    String pUrl = (map['pod_image_url'] ??
            map['proof_url'] ??
            map['proof_of_delivery'] ??
            map['proof_of_delivery_url'] ??
            map['proof_image_url'] ??
            map['proof_photo_url'] ??
            map['proof_photo'] ??
            map['proof_image'] ??
            map['delivery_proof'] ??
            map['delivery_proof_url'] ??
            map['delivered_photo'] ??
            map['delivery_photo'] ??
            map['pod_url'] ??
            map['pod_photo'] ??
            map['pod_image'] ??
            map['fulfillment_image'] ??
            map['fulfillment_url'] ??
            map['completion_photo'] ??
            map['signature_url'] ??
            map['photo_url'] ??
            map['image_url'] ??
            '')
        .toString()
        .trim();

    if (pUrl.isEmpty) {
      for (var entry in map.entries) {
        final k = entry.key.toString().toLowerCase();
        final v = entry.value?.toString().trim() ?? '';
        if (v.isNotEmpty && v.toLowerCase() != 'null') {
          if (k.contains('proof') || k.contains('pod') || k.contains('delivery_photo') || k.contains('delivered_photo') || k.contains('completion') || k.contains('signature')) {
            pUrl = v;
            break;
          }
        }
      }
    }

    if (pUrl.isEmpty && map['orders'] != null && map['orders'] is Map) {
      final ord = map['orders'] as Map;
      pUrl = (ord['pod_image_url'] ??
              ord['proof_url'] ??
              ord['proof_of_delivery'] ??
              ord['proof_of_delivery_url'] ??
              ord['proof_image_url'] ??
              ord['proof_photo_url'] ??
              ord['proof_photo'] ??
              ord['proof_image'] ??
              ord['delivery_proof'] ??
              ord['delivery_proof_url'] ??
              ord['delivered_photo'] ??
              ord['delivery_photo'] ??
              ord['pod_url'] ??
              ord['pod_photo'] ??
              ord['pod_image'] ??
              ord['fulfillment_image'] ??
              ord['fulfillment_url'] ??
              ord['completion_photo'] ??
              ord['signature_url'] ??
              ord['photo_url'] ??
              ord['image_url'] ??
              '')
          .toString()
          .trim();

      if (pUrl.isEmpty) {
        for (var entry in ord.entries) {
          final k = entry.key.toString().toLowerCase();
          final v = entry.value?.toString().trim() ?? '';
          if (v.isNotEmpty && v.toLowerCase() != 'null') {
            if (k.contains('proof') || k.contains('pod') || k.contains('delivery_photo') || k.contains('delivered_photo') || k.contains('completion')) {
              pUrl = v;
              break;
            }
          }
        }
      }
    }

    if (pUrl.isEmpty && map['notes'] != null) {
      final notesStr = map['notes'].toString();
      final urlMatch = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(notesStr);
      if (urlMatch != null) {
        pUrl = urlMatch.group(0)?.trim() ?? '';
      }
    }

    if (pUrl.isEmpty && map['orders'] != null && map['orders'] is Map && map['orders']['notes'] != null) {
      final notesStr = map['orders']['notes'].toString();
      final urlMatch = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(notesStr);
      if (urlMatch != null) {
        pUrl = urlMatch.group(0)?.trim() ?? '';
      }
    }

    // Convert relative storage paths to full public Supabase Storage URLs
    if (pUrl.isNotEmpty && !pUrl.startsWith('http://') && !pUrl.startsWith('https://') && !pUrl.startsWith('data:image')) {
      final bucket = pUrl.contains('/') ? pUrl.split('/').first : 'deliveries';
      final path = pUrl.contains('/') ? pUrl.substring(pUrl.indexOf('/') + 1) : pUrl;
      try {
        pUrl = SupabaseService.client.storage.from(bucket).getPublicUrl(path);
      } catch (_) {
        try {
          pUrl = SupabaseService.client.storage.from('proofs').getPublicUrl(pUrl);
        } catch (_) {}
      }
    }

    if (pUrl.isEmpty && rUrl.isNotEmpty) {
      pUrl = rUrl;
    }

    String delNotes = (map['notes'] ?? map['delivery_notes'] ?? map['comments'] ?? map['driver_notes'] ?? '').toString().trim();
    if (delNotes.isEmpty && map['orders'] != null && map['orders'] is Map) {
      delNotes = (map['orders']['notes'] ?? '').toString().trim();
    }

    return DeliveryModel(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      orderNumber: ordNum,
      customerName: custName,
      driverName: drv,
      status: delStatus,
      assignedAt: formatTime(map['assigned_at']),
      acceptedAt: formatTime(map['accepted_at']),
      startedAt: formatTime(map['started_at'] ?? map['out_for_delivery_at']),
      deliveredAt: formatTime(map['delivered_at']),
      paymentMethod: pMethod,
      receiptUrl: rUrl,
      gcashReference: gRef,
      totalAmount: totalAmt,
      proofUrl: pUrl,
      notes: delNotes,
    );
  }
}

class GallonItemModel {
  final String id;
  final String gallonCode;
  final String status;
  final String location;
  final String assigned;
  final String? customerId;
  final String containerType;
  final String borrowedAt;
  final String returnedAt;
  final String createdAt;
  final bool hasQr;
  final String? qrCode;
  final String? qrId;
  final String? qrCreatedAt;
  final bool isQrActive;

  GallonItemModel({
    required this.id,
    required this.gallonCode,
    required this.status,
    required this.location,
    required this.assigned,
    this.customerId,
    required this.containerType,
    required this.borrowedAt,
    required this.returnedAt,
    required this.createdAt,
    this.hasQr = false,
    this.qrCode,
    this.qrId,
    this.qrCreatedAt,
    this.isQrActive = false,
  });

  factory GallonItemModel.fromSupabase(Map<String, dynamic> map) {
    String realId = map['id']?.toString() ?? '';
    String gCode = map['gallon_code']?.toString() ?? (realId.length >= 8 ? 'AQS-G-${realId.substring(0, 6)}' : 'AQS-G-000001');
    
    String formatTime(dynamic val) {
      if (val == null || val.toString().isEmpty) return 'Not yet recorded';
      final str = val.toString();
      if (str.contains('T')) {
        final parts = str.split('T');
        final timePart = parts[1].split('.').first;
        return '${parts[0]} $timePart';
      }
      return str;
    }

    String custName = 'Available in Station';
    String? custId = map['customer_id']?.toString();
    String location = 'Aqua Pure Water Station';
    String rawStatus = map['status']?.toString().toLowerCase().trim().replaceAll(' ', '_') ?? 'available';

    bool isBorrowed = (rawStatus == 'borrowed' || rawStatus == 'out_for_delivery');

    Map<String, dynamic>? profileMap;
    if (map['profiles'] is Map) {
      profileMap = Map<String, dynamic>.from(map['profiles']);
    } else if (map['profiles'] is List && (map['profiles'] as List).isNotEmpty) {
      final first = (map['profiles'] as List).first;
      if (first is Map) {
        profileMap = Map<String, dynamic>.from(first);
      }
    }

    if (profileMap != null) {
      final pName = profileMap['full_name']?.toString() ?? profileMap['name']?.toString();
      if (pName != null && pName.isNotEmpty) {
        custName = pName;
      }
      final addr = profileMap['address']?.toString();
      if (addr != null && addr.isNotEmpty && addr != '—') {
        location = addr;
      } else if (isBorrowed) {
        location = 'Customer Residence';
      }
      if (profileMap['id'] != null) {
        custId = profileMap['id'].toString();
      }
    } else if (custId != null && custId.isNotEmpty) {
      custName = 'Assigned Customer';
      if (isBorrowed) {
        location = 'Customer Residence';
      }
    }

    bool isArchived = map['is_archived'] == true || (map['status']?.toString().toLowerCase().trim() == 'retired');
    if (isArchived) {
      custName = '—';
      location = 'Archived Storage';
    }

    return GallonItemModel(
      id: realId,
      gallonCode: gCode,
      status: isArchived ? 'retired' : rawStatus,
      location: location,
      assigned: custName,
      customerId: custId,
      containerType: 'Standard 5-Gallon Container',
      borrowedAt: formatTime(map['borrowed_at']),
      returnedAt: formatTime(map['returned_at']),
      createdAt: formatTime(map['created_at']),
      hasQr: false,
      qrCode: null,
      qrId: null,
      qrCreatedAt: null,
      isQrActive: false,
    );
  }
}

class RfidQrModel {
  final String id;
  final String gallonId;
  final String code;
  final String codeType;
  final bool isActive;

  RfidQrModel({
    required this.id,
    required this.gallonId,
    required this.code,
    required this.codeType,
    required this.isActive,
  });

  factory RfidQrModel.fromSupabase(Map<String, dynamic> map) {
    return RfidQrModel(
      id: map['id']?.toString() ?? '',
      gallonId: map['gallon_id']?.toString() ?? '',
      code: map['code']?.toString() ?? map['gallon_id']?.toString() ?? 'G-001',
      codeType: map['code_type']?.toString().toUpperCase() ?? 'QR',
      isActive: map['is_active'] ?? true,
    );
  }
}

class DebtItemModel {
  final String id;
  final String customerId;
  final String customerName;
  final String? orderId;
  final String? orderNumber;
  final String description;
  final double amount;
  final double paidAmount;
  final String status;
  final String dueDate;
  final String createdAt;

  DebtItemModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.orderId,
    this.orderNumber,
    required this.description,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.dueDate,
    required this.createdAt,
  });

  double get remainingBalance => (amount - paidAmount).clamp(0.0, double.infinity);

  factory DebtItemModel.fromSupabase(Map<String, dynamic> map) {
    double amt = 0.0;
    if (map['amount'] is num) amt = (map['amount'] as num).toDouble();

    double paid = 0.0;
    if (map['paid_amount'] is num) paid = (map['paid_amount'] as num).toDouble();
    if (paid > amt) paid = amt;

    String custName = 'Customer';
    if (map['profiles'] != null && map['profiles'] is Map) {
      custName = map['profiles']['full_name']?.toString() ?? custName;
    } else if (map['customer_name'] != null) {
      custName = map['customer_name'].toString();
    }

    String? ordNum;
    if (map['orders'] != null && map['orders'] is Map) {
      ordNum = map['orders']['order_number']?.toString();
    }

    String dbStatus = map['status']?.toString().toLowerCase().trim() ?? '';
    String computedStatus;
    if (dbStatus == 'paid' || paid >= amt) {
      computedStatus = 'paid';
    } else if (dbStatus == 'partial' || dbStatus == 'partially_paid' || (paid > 0 && paid < amt)) {
      computedStatus = 'partial';
    } else {
      computedStatus = 'unpaid';
    }

    return DebtItemModel(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerName: custName,
      orderId: map['order_id']?.toString(),
      orderNumber: ordNum,
      description: map['description']?.toString() ?? map['notes']?.toString() ?? 'Unpaid container refills',
      amount: amt,
      paidAmount: paid,
      status: computedStatus,
      dueDate: map['due_date']?.toString().split('T').first ?? '—',
      createdAt: map['created_at']?.toString().split('T').first ?? '—',
    );
  }
}

class PaymentItemModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String method;
  final double amount;
  final String referenceNumber;
  final String receiptUrl;
  final String status;
  final String paidAt;
  final String createdAt;

  PaymentItemModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.method,
    required this.amount,
    required this.referenceNumber,
    this.receiptUrl = '',
    required this.status,
    required this.paidAt,
    required this.createdAt,
  });

  factory PaymentItemModel.fromSupabase(Map<String, dynamic> map) {
    double amt = 0.0;
    if (map['amount'] is num) amt = (map['amount'] as num).toDouble();

    String ordNum = 'ORD-001';
    String custName = 'Customer';
    String rUrl = (map['receipt_url'] ?? map['payment_receipt_url'] ?? '').toString();

    if (map['orders'] != null && map['orders'] is Map) {
      final ord = map['orders'] as Map;
      ordNum = ord['order_number']?.toString() ?? ordNum;
      if (ord['customer_name'] != null) {
        custName = ord['customer_name'].toString();
      } else if (ord['profiles'] != null && ord['profiles'] is Map) {
        custName = ord['profiles']['full_name']?.toString() ?? custName;
      }
      if (rUrl.isEmpty) {
        rUrl = (ord['receipt_url'] ?? ord['payment_receipt_url'] ?? '').toString();
      }
    }

    String formatTime(dynamic val) {
      if (val == null || val.toString().isEmpty) return 'Not yet recorded';
      final str = val.toString();
      if (str.contains('T')) {
        final parts = str.split('T');
        final timePart = parts[1].split('.').first;
        return '${parts[0]} $timePart';
      }
      return str;
    }

    String pStatus = map['status']?.toString().toLowerCase().trim() ?? 'paid';
    if (pStatus == 'completed' || pStatus == 'success' || pStatus == 'successful') {
      pStatus = 'paid';
    }

    String rawPMethod = (map['payment_method'] ?? map['method'] ?? map['payment_type'] ?? map['payment_mode'] ?? '').toString().trim();
    final upperPMethod = rawPMethod.toUpperCase();
    String pMethod = 'COD';
    if (upperPMethod.contains('GCASH') || upperPMethod.contains('ONLINE') || upperPMethod.contains('PAYMONGO') || upperPMethod.contains('MAYA') || upperPMethod.contains('E-WALLET') || upperPMethod.contains('DIGITAL')) {
      pMethod = 'GCash';
    } else if (upperPMethod.contains('COD') || upperPMethod.contains('CASH') || upperPMethod.contains('DELIVERY') || upperPMethod.contains('HAND')) {
      pMethod = 'COD';
    } else if (rawPMethod.isEmpty || rawPMethod == '—' || rawPMethod == 'null') {
      if (rUrl.isNotEmpty && (map['reference_number']?.toString().isNotEmpty == true || map['gcash_reference']?.toString().isNotEmpty == true)) {
        pMethod = 'GCash';
      } else {
        pMethod = 'COD';
      }
    } else {
      pMethod = rawPMethod;
    }

    return PaymentItemModel(
      id: map['id']?.toString() ?? '',
      orderId: map['order_id']?.toString() ?? '',
      orderNumber: ordNum,
      customerName: custName,
      method: pMethod,
      amount: amt,
      referenceNumber: map['reference_number']?.toString() ?? '—',
      receiptUrl: rUrl,
      status: pStatus,
      paidAt: formatTime(map['paid_at']),
      createdAt: formatTime(map['created_at']),
    );
  }
}

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isActive;
  final String createdAt;
  final DateTime? startsAt;
  final DateTime? endsAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    required this.createdAt,
    this.startsAt,
    this.endsAt,
  });

  factory AnnouncementModel.fromSupabase(Map<String, dynamic> map) {
    String formatTime(dynamic val) {
      if (val == null || val.toString().isEmpty) return '—';
      final str = val.toString();
      if (str.contains('T')) {
        final parts = str.split('T');
        final timePart = parts[1].split('.').first;
        return '${parts[0]} $timePart';
      }
      return str;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null || val.toString().isEmpty) return null;
      return DateTime.tryParse(val.toString());
    }

    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Announcement',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString().toLowerCase().trim() ?? 'info',
      isActive: map['is_active'] ?? true,
      createdAt: formatTime(map['created_at']),
      startsAt: parseDate(map['starts_at'] ?? map['start_at'] ?? map['startsAt']),
      endsAt: parseDate(map['ends_at'] ?? map['end_at'] ?? map['endsAt']),
    );
  }
}

class ReviewModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String driverId;
  final String driverName;
  final int rating;
  final String review;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    this.driverId = '',
    this.driverName = '—',
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory ReviewModel.fromSupabase(Map<String, dynamic> map) {
    int r = 5;
    if (map['rating'] is num) {
      r = (map['rating'] as num).toInt();
    }

    String custName = 'Customer';
    if (map['profiles'] != null && map['profiles'] is Map) {
      custName = map['profiles']['full_name']?.toString() ?? custName;
    } else if (map['customer_name'] != null) {
      custName = map['customer_name'].toString();
    }

    String drvName = '—';
    if (map['drivers'] != null && map['drivers'] is Map) {
      drvName = map['drivers']['full_name']?.toString() ?? drvName;
    } else if (map['driver'] != null && map['driver'] is Map) {
      drvName = map['driver']['full_name']?.toString() ?? drvName;
    }

    String ordNum = 'ORD-001';
    final ordId = map['order_id']?.toString() ?? '';
    if (map['orders'] != null && map['orders'] is Map) {
      ordNum = map['orders']['order_number']?.toString() ?? (ordId.length >= 8 ? ordId.substring(0, 8) : ordId);
    } else if (map['order_number'] != null) {
      ordNum = map['order_number'].toString();
    } else if (ordId.isNotEmpty) {
      ordNum = ordId.length >= 8 ? ordId.substring(0, 8) : ordId;
    }

    String formatTime(dynamic val) {
      if (val == null || val.toString().isEmpty) return '—';
      final str = val.toString();
      if (str.contains('T')) {
        final parts = str.split('T');
        final timePart = parts[1].split('.').first;
        return '${parts[0]} $timePart';
      }
      return str;
    }

    return ReviewModel(
      id: map['id']?.toString() ?? '',
      orderId: ordId,
      orderNumber: ordNum,
      customerId: map['customer_id']?.toString() ?? '',
      customerName: custName,
      rating: r,
      review: map['review']?.toString() ?? '',
      createdAt: formatTime(map['created_at']),
    );
  }
}


class PromoModel {
  final String id;
  final String code;
  final double discountValue;
  final String discountType; // 'fixed' or 'percentage'
  final double minSpend;
  final bool isActive;
  final String validFrom;
  final String validUntil;
  final String createdAt;
  final int maxUses;   // 0 means unlimited
  final int usedCount; // current number of usages

  PromoModel({
    required this.id,
    required this.code,
    required this.discountValue,
    required this.discountType,
    required this.minSpend,
    required this.isActive,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
    this.maxUses = 0,
    this.usedCount = 0,
  });

  static DateTime? parseDateTime(String? str) {
    if (str == null || str.isEmpty || str == 'No Expiry') return null;
    try {
      final formatted = str.contains(' ') && !str.contains('T')
          ? str.replaceFirst(' ', 'T')
          : str;
      return DateTime.parse(formatted);
    } catch (_) {
      return null;
    }
  }

  DateTime? get validFromDateTime => parseDateTime(validFrom);
  DateTime? get validUntilDateTime => parseDateTime(validUntil);

  bool get isNotStarted {
    final start = validFromDateTime;
    if (start == null) return false;
    return DateTime.now().isBefore(start);
  }

  bool get isExpired {
    final end = validUntilDateTime;
    if (end == null) return false;
    return DateTime.now().isAfter(end);
  }

  bool get isLimitReached {
    if (maxUses <= 0) return false;
    return usedCount >= maxUses;
  }

  /// Evaluates whether the promo code is active AND within date/time AND under max usage limit.
  bool get isCurrentlyValid {
    return isActive && !isNotStarted && !isExpired && !isLimitReached;
  }

  /// Status badge string: 'ACTIVE', 'INACTIVE', 'EXPIRED', 'UPCOMING', 'LIMIT REACHED'
  String get status {
    if (!isActive) return 'INACTIVE';
    if (isNotStarted) return 'UPCOMING';
    if (isExpired) return 'EXPIRED';
    if (isLimitReached) return 'LIMIT REACHED';
    return 'ACTIVE';
  }

  factory PromoModel.fromSupabase(Map<String, dynamic> map) {
    double val = 0.0;
    if (map['discount_value'] is num) {
      val = (map['discount_value'] as num).toDouble();
    } else if (map['discount'] is num) {
      val = (map['discount'] as num).toDouble();
    } else if (map['value'] is num) {
      val = (map['value'] as num).toDouble();
    }

    double minS = 0.0;
    if (map['min_spend'] is num) {
      minS = (map['min_spend'] as num).toDouble();
    }

    int maxU = 0;
    if (map['max_uses'] is num) {
      maxU = (map['max_uses'] as num).toInt();
    } else if (map['max_usage'] is num) {
      maxU = (map['max_usage'] as num).toInt();
    } else if (map['usage_limit'] is num) {
      maxU = (map['usage_limit'] as num).toInt();
    }

    int usedC = 0;
    if (map['used_count'] is num) {
      usedC = (map['used_count'] as num).toInt();
    } else if (map['uses_count'] is num) {
      usedC = (map['uses_count'] as num).toInt();
    } else if (map['times_used'] is num) {
      usedC = (map['times_used'] as num).toInt();
    }

    String formatTime(dynamic val) {
      if (val == null || val.toString().isEmpty) return 'No Expiry';
      final str = val.toString();
      if (str.contains('T')) {
        return str.replaceFirst('T', ' ').split('.').first;
      }
      return str;
    }

    return PromoModel(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? map['promo_code']?.toString() ?? 'PROMO100',
      discountValue: val,
      discountType: map['discount_type']?.toString().toLowerCase().trim() ?? 'fixed',
      minSpend: minS,
      isActive: map['is_active'] ?? true,
      validFrom: formatTime(map['valid_from'] ?? map['start_at'] ?? map['created_at']),
      validUntil: formatTime(map['valid_until'] ?? map['expiry_date']),
      createdAt: formatTime(map['created_at']),
      maxUses: maxU,
      usedCount: usedC,
    );
  }
}

class PromoValidationResult {
  final bool isValid;
  final PromoModel? promo;
  final double discountAmount;
  final String errorMessage;

  PromoValidationResult({
    required this.isValid,
    this.promo,
    this.discountAmount = 0.0,
    this.errorMessage = '',
  });

  factory PromoValidationResult.success({
    required PromoModel promo,
    required double discountAmount,
  }) {
    return PromoValidationResult(
      isValid: true,
      promo: promo,
      discountAmount: discountAmount,
    );
  }

  factory PromoValidationResult.error(String message) {
    return PromoValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

class SystemNotificationModel {
  final String id;
  final String title;
  final String message;
  final String category; // 'Orders', 'Deliveries', 'Gallons', 'Sales', 'Accounts'
  final String timestamp;
  final String? relatedId;
  final String? targetPage;
  bool isRead;

  SystemNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.relatedId,
    this.targetPage,
    this.isRead = false,
  });
}
