import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://qxruxonusvoxshuwxrah.supabase.co';
  static const String publishableKey =
      'sb_publishable_MbMRR6syNwtezcWMke6yXw_Y1cozFRo';

  static SupabaseClient get client => Supabase.instance.client;

  // Station & Operational Configuration
  static double stationLatitude = 14.2289;
  static double stationLongitude = 121.3283;
  static double stationGeofenceRadiusKm = 8.0;
  static String stationName = 'Aqua Pure Water Station';
  static String stationAddress = 'Victoria, Laguna';
  static String stationPhone = '+63 917 888 9999';
  static String stationHours = '07:00 AM - 06:00 PM';

  // Security, Geofence & GCash Settings
  static bool enforceGeofenceRadius = true;
  static bool enableGcashPayment = true;
  static String gcashName = 'Aqua Pure Water Station';
  static String gcashNumber = '+63 917 888 9999';
  static String gcashQrImageUrl = '';
  static String gcashQrRawString = '';

  // Delivery & POS Operational Rules
  static double baseDeliveryFee = 15.0;
  static int minFreeDeliveryQty = 5;
  static int maxDriverOrdersPerTrip = 5;
  static int lowGallonThreshold = 20;
  static bool allowCOD = true;
  static bool autoAssignDrivers = true;
  static bool allowDebtPurchase = true;

  // Receipt & Printing Preferences
  static String receiptHeader = 'Aqua Pure Water Refilling Station';
  static String receiptFooter = 'Thank you for choosing AquaSync! Safe & Clean Water Always.';
  static bool autoPrintReceipt = true;
  static bool showQrOnReceipt = true;

  // Notifications & Alert Audio
  static bool newOrderSound = true;
  static bool lowStockSound = true;
  static bool driverEmergencySound = true;
  static int autoRefreshIntervalSec = 30;

  // Security & Staff Dispatch Permissions
  static bool requireAdminForDebt = false;
  static bool allowCashierDriverAssign = true;
  static double maxCashierRefundLimit = 1000.0;
  static bool requireRfidGallonRelease = true;

  static double getGeofenceRadiusKm() {
    return stationGeofenceRadiusKm;
  }

  static void setGeofenceRadiusKm(double radiusKm) {
    stationGeofenceRadiusKm = radiusKm;
  }

  static void _saveToLocalStorage(Map<String, dynamic> data) {
    try {
      if (kIsWeb) {
        html.window.localStorage['aquasync_station_settings'] = jsonEncode(data);
      }
    } catch (e) {
      debugPrint('Note: local storage save: $e');
    }
  }

  static Map<String, dynamic>? _loadFromLocalStorage() {
    try {
      if (kIsWeb) {
        final raw = html.window.localStorage['aquasync_station_settings'];
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      }
    } catch (e) {
      debugPrint('Note: local storage load: $e');
    }
    return null;
  }

  static void _applySettingsFromMap(Map<String, dynamic> map) {
    if (map['latitude'] != null) {
      stationLatitude = (map['latitude'] as num).toDouble();
    } else if (map['lat'] != null) {
      stationLatitude = (map['lat'] as num).toDouble();
    } else if (map['station_latitude'] != null) {
      stationLatitude = (map['station_latitude'] as num).toDouble();
    }

    if (map['longitude'] != null) {
      stationLongitude = (map['longitude'] as num).toDouble();
    } else if (map['lng'] != null) {
      stationLongitude = (map['lng'] as num).toDouble();
    } else if (map['lon'] != null) {
      stationLongitude = (map['lon'] as num).toDouble();
    } else if (map['station_longitude'] != null) {
      stationLongitude = (map['station_longitude'] as num).toDouble();
    }

    if (map['geofence_radius_km'] != null) {
      stationGeofenceRadiusKm = (map['geofence_radius_km'] as num).toDouble();
    } else if (map['radius_km'] != null) {
      stationGeofenceRadiusKm = (map['radius_km'] as num).toDouble();
    } else if (map['geofence_radius'] != null) {
      stationGeofenceRadiusKm = (map['geofence_radius'] as num).toDouble();
    } else if (map['proximity_radius_km'] != null) {
      stationGeofenceRadiusKm = (map['proximity_radius_km'] as num).toDouble();
    } else if (map['perimeter_km'] != null) {
      stationGeofenceRadiusKm = (map['perimeter_km'] as num).toDouble();
    } else if (map['service_radius_km'] != null) {
      stationGeofenceRadiusKm = (map['service_radius_km'] as num).toDouble();
    }

    if (map['station_name'] != null && map['station_name'].toString().isNotEmpty) {
      stationName = map['station_name'].toString();
    } else if (map['name'] != null && map['name'].toString().isNotEmpty) {
      stationName = map['name'].toString();
    } else if (map['business_name'] != null && map['business_name'].toString().isNotEmpty) {
      stationName = map['business_name'].toString();
    }

    if (map['address'] != null && map['address'].toString().isNotEmpty) {
      stationAddress = map['address'].toString();
    } else if (map['station_address'] != null && map['station_address'].toString().isNotEmpty) {
      stationAddress = map['station_address'].toString();
    }

    if (map['phone'] != null && map['phone'].toString().isNotEmpty) {
      stationPhone = map['phone'].toString();
    } else if (map['station_phone'] != null && map['station_phone'].toString().isNotEmpty) {
      stationPhone = map['station_phone'].toString();
    }

    if (map['hours'] != null && map['hours'].toString().isNotEmpty) {
      stationHours = map['hours'].toString();
    } else if (map['station_hours'] != null && map['station_hours'].toString().isNotEmpty) {
      stationHours = map['station_hours'].toString();
    } else if (map['business_hours'] != null && map['business_hours'].toString().isNotEmpty) {
      stationHours = map['business_hours'].toString();
    }

    if (map['base_delivery_fee'] != null) baseDeliveryFee = (map['base_delivery_fee'] as num).toDouble();
    if (map['min_free_delivery_qty'] != null) minFreeDeliveryQty = (map['min_free_delivery_qty'] as num).toInt();
    if (map['max_driver_orders_per_trip'] != null) maxDriverOrdersPerTrip = (map['max_driver_orders_per_trip'] as num).toInt();
    if (map['low_gallon_threshold'] != null) lowGallonThreshold = (map['low_gallon_threshold'] as num).toInt();
    if (map['allow_cod'] != null) allowCOD = map['allow_cod'] == true || map['allow_cod'].toString() == 'true';
    if (map['auto_assign_drivers'] != null) autoAssignDrivers = map['auto_assign_drivers'] == true || map['auto_assign_drivers'].toString() == 'true';
    if (map['allow_debt_purchase'] != null) allowDebtPurchase = map['allow_debt_purchase'] == true || map['allow_debt_purchase'].toString() == 'true';
    if (map['receipt_header'] != null && map['receipt_header'].toString().isNotEmpty) receiptHeader = map['receipt_header'].toString();
    if (map['receipt_footer'] != null && map['receipt_footer'].toString().isNotEmpty) receiptFooter = map['receipt_footer'].toString();
    if (map['auto_print_receipt'] != null) autoPrintReceipt = map['auto_print_receipt'] == true || map['auto_print_receipt'].toString() == 'true';
    if (map['show_qr_on_receipt'] != null) showQrOnReceipt = map['show_qr_on_receipt'] == true || map['show_qr_on_receipt'].toString() == 'true';
    if (map['new_order_sound'] != null) newOrderSound = map['new_order_sound'] == true || map['new_order_sound'].toString() == 'true';
    if (map['low_stock_sound'] != null) lowStockSound = map['low_stock_sound'] == true || map['low_stock_sound'].toString() == 'true';
    if (map['driver_emergency_sound'] != null) driverEmergencySound = map['driver_emergency_sound'] == true || map['driver_emergency_sound'].toString() == 'true';
    if (map['auto_refresh_interval_sec'] != null) autoRefreshIntervalSec = (map['auto_refresh_interval_sec'] as num).toInt();
    if (map['require_admin_for_debt'] != null) requireAdminForDebt = map['require_admin_for_debt'] == true || map['require_admin_for_debt'].toString() == 'true';
    if (map['allow_cashier_driver_assign'] != null) allowCashierDriverAssign = map['allow_cashier_driver_assign'] == true || map['allow_cashier_driver_assign'].toString() == 'true';
    if (map['max_cashier_refund_limit'] != null) maxCashierRefundLimit = (map['max_cashier_refund_limit'] as num).toDouble();
    if (map['require_rfid_gallon_release'] != null) requireRfidGallonRelease = map['require_rfid_gallon_release'] == true || map['require_rfid_gallon_release'].toString() == 'true';
    if (map['enforce_geofence_radius'] != null) {
      enforceGeofenceRadius = map['enforce_geofence_radius'] == true || map['enforce_geofence_radius'].toString() == 'true';
    } else if (map['enforce_geofence'] != null) {
      enforceGeofenceRadius = map['enforce_geofence'] == true || map['enforce_geofence'].toString() == 'true';
    }
    if (map['enable_gcash_payment'] != null) enableGcashPayment = map['enable_gcash_payment'] == true || map['enable_gcash_payment'].toString() == 'true';
    if (map['gcash_name'] != null) gcashName = map['gcash_name'].toString();
    if (map['gcash_number'] != null) gcashNumber = map['gcash_number'].toString();
    if (map['gcash_qr_image_url'] != null) gcashQrImageUrl = map['gcash_qr_image_url'].toString();
    if (map['gcash_qr_raw_string'] != null) gcashQrRawString = map['gcash_qr_raw_string'].toString();
  }

  /// Fetches station settings (location coordinates, name, address, geofence radius & operational rules) from Supabase & local storage
  static Future<Map<String, dynamic>> fetchStationSettings() async {
    Map<String, dynamic> merged = {};

    // 1. Priority check: system_settings key-value store (where Admin saves complete JSON config)
    try {
      final sysKeys = ['station_config', 'station_settings', 'business_config', 'geofence_config'];
      for (final sysKey in sysKeys) {
        final sysRes = await client
            .from('system_settings')
            .select()
            .eq('key', sysKey)
            .maybeSingle();
        if (sysRes != null && sysRes['value'] is Map) {
          final val = Map<String, dynamic>.from(sysRes['value'] as Map);
          val.forEach((k, v) {
            merged[k] = v;
          });
        }
      }
    } catch (e) {
      debugPrint('Note: fetchStationSettings from system_settings table: $e');
    }

    // 1.5. Priority check: profiles table (where admin/owner profile stores lat, lng, radius)
    try {
      final adminProfile = await client
          .from('profiles')
          .select()
          .or('role.eq.admin,role.eq.cashier,role.eq.owner,role.eq.station')
          .not('latitude', 'is', null)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (adminProfile != null) {
        Map<String, dynamic>.from(adminProfile).forEach((k, v) {
          if (v != null) merged[k] = v;
        });
      }
    } catch (e) {
      debugPrint('Note: fetchStationSettings from profiles table: $e');
    }

    // 2. Priority check: local browser storage
    final localData = _loadFromLocalStorage();
    if (localData != null) {
      localData.forEach((k, v) {
        merged[k] = v;
      });
    }

    // 3. Fallback check: station_settings table (only fill missing keys)
    try {
      final response = await client
          .from('station_settings')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        Map<String, dynamic>.from(response).forEach((k, v) {
          merged.putIfAbsent(k, () => v);
        });
      }
    } catch (e) {
      debugPrint('Note: fetchStationSettings from station_settings table: $e');
    }

    // 4. Fallback check: stores / stations tables if present
    try {
      final storeRes = await client.from('stores').select().limit(1).maybeSingle();
      if (storeRes != null) {
        Map<String, dynamic>.from(storeRes).forEach((k, v) {
          merged.putIfAbsent(k, () => v);
        });
      }
    } catch (_) {}

    try {
      final stationRes = await client.from('stations').select().limit(1).maybeSingle();
      if (stationRes != null) {
        Map<String, dynamic>.from(stationRes).forEach((k, v) {
          merged.putIfAbsent(k, () => v);
        });
      }
    } catch (_) {}

    _applySettingsFromMap(merged);

    final finalMap = {
      'latitude': stationLatitude,
      'lat': stationLatitude,
      'station_latitude': stationLatitude,
      'longitude': stationLongitude,
      'lng': stationLongitude,
      'lon': stationLongitude,
      'station_longitude': stationLongitude,
      'geofence_radius_km': stationGeofenceRadiusKm,
      'radius_km': stationGeofenceRadiusKm,
      'geofence_radius': stationGeofenceRadiusKm,
      'perimeter_km': stationGeofenceRadiusKm,
      'proximity_radius_km': stationGeofenceRadiusKm,
      'station_name': stationName,
      'name': stationName,
      'business_name': stationName,
      'address': stationAddress,
      'station_address': stationAddress,
      'phone': stationPhone,
      'station_phone': stationPhone,
      'hours': stationHours,
      'station_hours': stationHours,
      'business_hours': stationHours,
      'base_delivery_fee': baseDeliveryFee,
      'min_free_delivery_qty': minFreeDeliveryQty,
      'max_driver_orders_per_trip': maxDriverOrdersPerTrip,
      'low_gallon_threshold': lowGallonThreshold,
      'allow_cod': allowCOD,
      'auto_assign_drivers': autoAssignDrivers,
      'allow_debt_purchase': allowDebtPurchase,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'auto_print_receipt': autoPrintReceipt,
      'show_qr_on_receipt': showQrOnReceipt,
      'new_order_sound': newOrderSound,
      'low_stock_sound': lowStockSound,
      'driver_emergency_sound': driverEmergencySound,
      'auto_refresh_interval_sec': autoRefreshIntervalSec,
      'require_admin_for_debt': requireAdminForDebt,
      'allow_cashier_driver_assign': allowCashierDriverAssign,
      'max_cashier_refund_limit': maxCashierRefundLimit,
      'require_rfid_gallon_release': requireRfidGallonRelease,
      'enforce_geofence_radius': enforceGeofenceRadius,
      'enforce_geofence': enforceGeofenceRadius,
      'enable_gcash_payment': enableGcashPayment,
      'gcash_name': gcashName,
      'gcash_number': gcashNumber,
      'gcash_qr_image_url': gcashQrImageUrl,
      'gcash_qr_raw_string': gcashQrRawString,
    };

    _saveToLocalStorage(finalMap);
    return finalMap;
  }

  /// Saves station configuration and operational parameters to local storage & Supabase database
  static Future<bool> saveStationSettings({
    required double latitude,
    required double longitude,
    required double geofenceRadiusKm,
    required String name,
    required String address,
    String? phone,
    String? hours,
    double? deliveryFee,
    int? minFreeQty,
    int? maxTripOrders,
    int? lowStockLimit,
    bool? cod,
    bool? autoAssign,
    bool? debtPurchase,
    String? recHeader,
    String? recFooter,
    bool? autoPrint,
    bool? showQr,
    bool? soundOrder,
    bool? soundStock,
    bool? soundSos,
    int? refreshInterval,
    bool? adminDebt,
    bool? cashierDriverAssign,
    double? cashierRefund,
    bool? rfidGallonRelease,
    bool? enforceGeofence,
    bool? enableGcash,
    String? gcashAccName,
    String? gcashAccNumber,
    String? gcashQrUrl,
    String? gcashQrImage,
    String? gcashQrRaw,
  }) async {
    stationLatitude = latitude;
    stationLongitude = longitude;
    stationGeofenceRadiusKm = geofenceRadiusKm;
    stationName = name;
    stationAddress = address;

    if (phone != null) stationPhone = phone;
    if (hours != null) stationHours = hours;
    if (deliveryFee != null) baseDeliveryFee = deliveryFee;
    if (minFreeQty != null) minFreeDeliveryQty = minFreeQty;
    if (maxTripOrders != null) maxDriverOrdersPerTrip = maxTripOrders;
    if (lowStockLimit != null) lowGallonThreshold = lowStockLimit;
    if (cod != null) allowCOD = cod;
    if (autoAssign != null) autoAssignDrivers = autoAssign;
    if (debtPurchase != null) allowDebtPurchase = debtPurchase;
    if (recHeader != null) receiptHeader = recHeader;
    if (recFooter != null) receiptFooter = recFooter;
    if (autoPrint != null) autoPrintReceipt = autoPrint;
    if (showQr != null) showQrOnReceipt = showQr;
    if (soundOrder != null) newOrderSound = soundOrder;
    if (soundStock != null) lowStockSound = soundStock;
    if (soundSos != null) driverEmergencySound = soundSos;
    if (refreshInterval != null) autoRefreshIntervalSec = refreshInterval;
    if (adminDebt != null) requireAdminForDebt = adminDebt;
    if (cashierDriverAssign != null) allowCashierDriverAssign = cashierDriverAssign;
    if (cashierRefund != null) maxCashierRefundLimit = cashierRefund;
    if (rfidGallonRelease != null) requireRfidGallonRelease = rfidGallonRelease;
    if (enforceGeofence != null) enforceGeofenceRadius = enforceGeofence;
    if (enableGcash != null) enableGcashPayment = enableGcash;
    if (gcashAccName != null) gcashName = gcashAccName;
    if (gcashAccNumber != null) gcashNumber = gcashAccNumber;
    final finalGcashQrUrl = gcashQrImage ?? gcashQrUrl;
    if (finalGcashQrUrl != null) gcashQrImageUrl = finalGcashQrUrl;
    if (gcashQrRaw != null) gcashQrRawString = gcashQrRaw;

    final fullSettingsMap = {
      'latitude': stationLatitude,
      'lat': stationLatitude,
      'station_latitude': stationLatitude,
      'longitude': stationLongitude,
      'lng': stationLongitude,
      'lon': stationLongitude,
      'station_longitude': stationLongitude,
      'coverage_radius_km': stationGeofenceRadiusKm,
      'coverage_radius': stationGeofenceRadiusKm,
      'geofence_radius_km': stationGeofenceRadiusKm,
      'radius_km': stationGeofenceRadiusKm,
      'geofence_radius': stationGeofenceRadiusKm,
      'delivery_radius': stationGeofenceRadiusKm,
      'perimeter_km': stationGeofenceRadiusKm,
      'proximity_radius_km': stationGeofenceRadiusKm,
      'max_distance_km': stationGeofenceRadiusKm,
      'station_name': stationName,
      'name': stationName,
      'full_name': stationName,
      'business_name': stationName,
      'address': stationAddress,
      'station_address': stationAddress,
      'phone': stationPhone,
      'station_phone': stationPhone,
      'hours': stationHours,
      'station_hours': stationHours,
      'business_hours': stationHours,
      'base_delivery_fee': baseDeliveryFee,
      'min_free_delivery_qty': minFreeDeliveryQty,
      'max_driver_orders_per_trip': maxDriverOrdersPerTrip,
      'low_gallon_threshold': lowGallonThreshold,
      'allow_cod': allowCOD,
      'auto_assign_drivers': autoAssignDrivers,
      'allow_debt_purchase': allowDebtPurchase,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'auto_print_receipt': autoPrintReceipt,
      'show_qr_on_receipt': showQrOnReceipt,
      'new_order_sound': newOrderSound,
      'low_stock_sound': lowStockSound,
      'driver_emergency_sound': driverEmergencySound,
      'auto_refresh_interval_sec': autoRefreshIntervalSec,
      'require_admin_for_debt': requireAdminForDebt,
      'allow_cashier_driver_assign': allowCashierDriverAssign,
      'max_cashier_refund_limit': maxCashierRefundLimit,
      'require_rfid_gallon_release': requireRfidGallonRelease,
      'enforce_geofence_radius': enforceGeofenceRadius,
      'enforce_geofence': enforceGeofenceRadius,
      'enable_gcash_payment': enableGcashPayment,
      'gcash_name': gcashName,
      'gcash_number': gcashNumber,
      'gcash_qr_image_url': gcashQrImageUrl,
      'gcash_qr_raw_string': gcashQrRawString,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Always persist to local browser storage first!
    _saveToLocalStorage(fullSettingsMap);
    bool savedInDb = true;

    // Standard payload for station_settings table (matching standard columns)
    final cleanStationPayload = {
      'id': 'main_station',
      'station_name': name,
      'full_name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'coverage_radius_km': geofenceRadiusKm,
      'geofence_radius_km': geofenceRadiusKm,
      'radius_km': geofenceRadiusKm,
      'coverage_radius': geofenceRadiusKm,
      'phone': stationPhone,
      'hours': stationHours,
      'base_delivery_fee': baseDeliveryFee,
      'min_free_delivery_qty': minFreeDeliveryQty,
      'max_driver_orders_per_trip': maxDriverOrdersPerTrip,
      'low_gallon_threshold': lowGallonThreshold,
      'allow_cod': allowCOD,
      'auto_assign_drivers': autoAssignDrivers,
      'allow_debt_purchase': allowDebtPurchase,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'auto_print_receipt': autoPrintReceipt,
      'show_qr_on_receipt': showQrOnReceipt,
      'new_order_sound': newOrderSound,
      'low_stock_sound': lowStockSound,
      'driver_emergency_sound': driverEmergencySound,
      'auto_refresh_interval_sec': autoRefreshIntervalSec,
      'require_admin_for_debt': requireAdminForDebt,
      'allow_cashier_driver_assign': allowCashierDriverAssign,
      'max_cashier_refund_limit': maxCashierRefundLimit,
      'require_rfid_gallon_release': requireRfidGallonRelease,
      'enforce_geofence_radius': enforceGeofenceRadius,
      'enable_gcash_payment': enableGcashPayment,
      'gcash_name': gcashName,
      'gcash_number': gcashNumber,
      'gcash_qr_image_url': gcashQrImageUrl,
      'gcash_qr_raw_string': gcashQrRawString,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final coreStationPayload = {
      'station_name': name,
      'full_name': name,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'coverage_radius_km': geofenceRadiusKm,
      'geofence_radius_km': geofenceRadiusKm,
      'radius_km': geofenceRadiusKm,
      'geofence_radius': geofenceRadiusKm,
      'coverage_radius': geofenceRadiusKm,
      'enforce_geofence_radius': enforceGeofenceRadius,
      'enforce_geofence': enforceGeofenceRadius,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // 1. Resilient save to 'station_settings' table (auto-detects existing table row ID type)
    try {
      final existing = await client.from('station_settings').select('id').limit(1).maybeSingle();
      final payloadToSave = Map<String, dynamic>.from(cleanStationPayload);

      if (existing != null && existing['id'] != null) {
        // Retain the existing table's primary key ID (whether int, uuid, or text)
        payloadToSave['id'] = existing['id'];
        await client.from('station_settings').update(payloadToSave).eq('id', existing['id']);
        debugPrint('Station settings updated in station_settings table using existing id: ${existing['id']}.');
      } else {
        try {
          await client.from('station_settings').upsert(payloadToSave);
          debugPrint('Station settings upserted into station_settings table.');
        } catch (_) {
          payloadToSave.remove('id');
          await client.from('station_settings').insert(payloadToSave);
          debugPrint('Station settings inserted into station_settings table without id.');
        }
      }
    } catch (e) {
      debugPrint('Note on station_settings save: $e. Proceeding with system_settings & local storage.');
      // Fallback core update without id constraint
      try {
        await client.from('station_settings').update({
          'station_name': name,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
          'coverage_radius_km': geofenceRadiusKm,
          'geofence_radius_km': geofenceRadiusKm,
          'radius_km': geofenceRadiusKm,
          'updated_at': DateTime.now().toIso8601String(),
        }).neq('updated_at', '1970-01-01');
      } catch (_) {}
    }

    // 2. Upsert into 'system_settings' table under multiple key aliases
    final sysKeys = ['station_config', 'station_settings', 'business_config', 'geofence_config'];
    for (final sysKey in sysKeys) {
      try {
        final sysPayload = {
          'key': sysKey,
          'value': fullSettingsMap,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await client.from('system_settings').upsert(sysPayload, onConflict: 'key');
        debugPrint('Station settings saved to system_settings ($sysKey) in Supabase.');
      } catch (e) {
        debugPrint('Upsert to system_settings ($sysKey) table failed ($e).');
      }
    }

    // 3. Sync to optional fallback tables ('stores' / 'stations' / 'business_settings') if existing
    try {
      final storePayload = {
        'name': name,
        'full_name': name,
        'station_name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'coverage_radius_km': geofenceRadiusKm,
        'geofence_radius_km': geofenceRadiusKm,
        'radius_km': geofenceRadiusKm,
        'phone': stationPhone,
        'hours': stationHours,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client.from('stores').update(storePayload).select();
    } catch (_) {}

    try {
      final stationPayload = {
        'name': name,
        'full_name': name,
        'station_name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'coverage_radius_km': geofenceRadiusKm,
        'geofence_radius_km': geofenceRadiusKm,
        'radius_km': geofenceRadiusKm,
        'phone': stationPhone,
        'hours': stationHours,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client.from('stations').update(stationPayload).select();
    } catch (_) {}

    try {
      final bizPayload = {
        'station_name': name,
        'full_name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'coverage_radius_km': geofenceRadiusKm,
        'geofence_radius_km': geofenceRadiusKm,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client.from('business_settings').update(bizPayload).select();
    } catch (_) {}

    // 4. Update logged in Admin/Owner/Station profile in 'profiles' table (User App fallback)
    if (currentUser != null) {
      try {
        await client.from('profiles').update({
          'latitude': latitude,
          'longitude': longitude,
          'coverage_radius_km': geofenceRadiusKm,
          'geofence_radius_km': geofenceRadiusKm,
          'radius_km': geofenceRadiusKm,
          'station_name': name,
          'full_name': name,
          'address': address,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentUser!.id);
      } catch (_) {}
    }

    try {
      await client.from('profiles').update({
        'latitude': latitude,
        'longitude': longitude,
        'coverage_radius_km': geofenceRadiusKm,
        'geofence_radius_km': geofenceRadiusKm,
        'radius_km': geofenceRadiusKm,
        'station_name': name,
        'full_name': name,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      }).or('role.eq.admin,role.eq.owner,role.eq.station');
    } catch (_) {}

    return savedInDb;
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // Initialize Supabase SDK
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: publishableKey,
    );
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION & PROFILES
  // ---------------------------------------------------------------------------

  /// Signs in admin user with email/password and verifies admin role
  static Future<Map<String, dynamic>> adminLogin({
    required String usernameOrEmail,
    required String password,
  }) async {
    String email = usernameOrEmail.trim();
    if (!email.contains('@')) {
      email = '$email@aquasync.com';
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Authentication failed. User is null.');
      }

      debugPrint('AUTH USER ID: ${user.id}');
      final profile = await fetchProfile(user.id);
      debugPrint('PROFILE: $profile');

      if (profile == null) {
        await client.auth.signOut();
        throw Exception('Admin profile not found.');
      }

      final role = profile['role']?.toString().trim().toLowerCase();
      debugPrint('PROFILE ROLE: $role');

      if (role == null || role.isEmpty) {
        await client.auth.signOut();
        throw Exception('Admin role is missing from your profile.');
      }

      if (role != 'admin') {
        await client.auth.signOut();
        throw Exception(
            'Access denied. Account role is "$role". Admin privileges required.');
      }

      return {
        'user': user,
        'profile': profile,
        'name': profile['full_name'] ??
            profile['name'] ??
            profile['username'] ??
            user.email?.split('@').first ??
            'Admin',
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Approve user account in both auth.users and public.profiles
  static Future<void> approveUserAccount(String userId) async {
    try {
      await client.rpc('approve_user_account', params: {'p_target_user_id': userId});
    } catch (e) {
      debugPrint('approve_user_account RPC failed: $e. Falling back to direct profile update.');
      await client.from('profiles').update({
        'is_approved': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }
  }

  /// Send real password reset email via Supabase Auth
  static Future<void> resetPasswordForEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    await client.auth.resetPasswordForEmail(trimmed);
  }

  /// Verifies current admin password by attempting auth re-authentication
  static Future<bool> verifyAdminPassword(String password) async {
    final user = currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      throw Exception('No active admin session found.');
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } on AuthException catch (e) {
      debugPrint('Admin password verification failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Admin password verification error: $e');
      return false;
    }
  }

  /// Sign out current user session
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Fetch user profile from public.profiles
  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update editable profile fields in public.profiles (full_name, phone, address, latitude, longitude)
  static Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> updates,
    String? rfidUid,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final cleanUpdates = Map<String, dynamic>.from(updates);
    cleanUpdates['updated_at'] = nowIso;

    if (cleanUpdates.containsKey('email') && (cleanUpdates['email'] == null || (cleanUpdates['email'] as String).isEmpty)) {
      cleanUpdates.remove('email');
    }

    await client.from('profiles').update(cleanUpdates).eq('id', userId);

    if (rfidUid != null) {
      if (rfidUid.trim().isNotEmpty) {
        await assignCustomerRfid(customerId: userId, rfidUid: rfidUid);
      } else {
        await client.from('rfid_qr_records').delete().eq('customer_id', userId).eq('code_type', 'RFID');
      }
    }
  }

  /// Fetch customers from public.profiles joined with public.rfid_qr_records
  static Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final response = await client
        .from('profiles')
        .select('*, rfid_qr_records(*)')
        .eq('role', 'customer')
        .order('full_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Assign Customer Loyalty RFID card UID to customer in public.rfid_qr_records
  static Future<void> assignCustomerRfid({
    required String customerId,
    required String rfidUid,
    bool isActive = true,
  }) async {
    final trimmedUid = rfidUid.trim();
    if (trimmedUid.isEmpty) {
      throw Exception('RFID UID cannot be empty.');
    }

    // 1. Duplicate check in public.rfid_qr_records
    try {
      final existing = await client
          .from('rfid_qr_records')
          .select('customer_id')
          .eq('code', trimmedUid)
          .eq('code_type', 'RFID')
          .maybeSingle();

      if (existing != null &&
          existing['customer_id'] != null &&
          existing['customer_id'] != customerId) {
        throw Exception('RFID UID "$trimmedUid" is already registered to another customer.');
      }
    } catch (e) {
      if (e.toString().contains('already registered')) rethrow;
    }

    // 2. Upsert in public.rfid_qr_records (the actual schema table for RFID)
    try {
      final existingRecord = await client
          .from('rfid_qr_records')
          .select('id')
          .eq('customer_id', customerId)
          .eq('code_type', 'RFID')
          .maybeSingle();

      if (existingRecord != null) {
        await client.from('rfid_qr_records').update({
          'code': trimmedUid,
          'is_active': isActive,
        }).eq('id', existingRecord['id']);
      } else {
        await client.from('rfid_qr_records').insert({
          'customer_id': customerId,
          'code': trimmedUid,
          'code_type': 'RFID',
          'is_active': isActive,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Register a new unassigned RFID card to public.rfid_qr_records inventory
  static Future<void> addUnassignedRfid({
    required String rfidUid,
  }) async {
    final trimmedUid = rfidUid.trim();
    if (trimmedUid.isEmpty) {
      throw Exception('RFID UID cannot be empty.');
    }

    // Duplicate check
    try {
      final existing = await client
          .from('rfid_qr_records')
          .select('id')
          .eq('code', trimmedUid)
          .eq('code_type', 'RFID')
          .maybeSingle();

      if (existing != null) {
        throw Exception('RFID UID "$trimmedUid" is already registered in the system.');
      }
    } catch (e) {
      if (e.toString().contains('already registered')) rethrow;
    }

    try {
      await client.from('rfid_qr_records').insert({
        'code': trimmedUid,
        'code_type': 'RFID',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        // customer_id remains NULL
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle Customer Loyalty RFID active status in public.rfid_qr_records
  static Future<void> toggleCustomerRfidStatus({
    required String customerId,
    required bool isActive,
    String? currentRfidUid,
  }) async {
    try {
      await client
          .from('rfid_qr_records')
          .update({'is_active': isActive})
          .eq('customer_id', customerId)
          .eq('code_type', 'RFID');
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle profile active status (Archive / Restore) using actual schema columns is_archived & archived_at
  static Future<void> toggleProfileArchiveStatus({
    required String userId,
    required bool isArchived,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await client.from('profiles').update({
      'is_archived': isArchived,
      'archived_at': isArchived ? nowIso : null,
      'updated_at': nowIso,
    }).eq('id', userId);
  }

  /// Permanently delete a profile from public.profiles
  static Future<void> deleteProfile(String userId) async {
    try {
      // 1. Subukang gamitin ang custom cascade delete para burahin lahat kasama ang historical orders/messages
      await client.rpc('delete_user_cascade', params: {'p_target_user_id': userId});
    } catch (rpcError) {
      // 2. Kung wala pa yung function o nag-error (tulad ng permission error), fallback sa standard direct delete
      try {
        await client.from('rfid_qr_records').delete().eq('customer_id', userId);
        await client.from('profiles').delete().eq('id', userId);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('foreign key') || errStr.contains('23503')) {
          final nowIso = DateTime.now().toIso8601String();
          // Fallback: archive instead of delete if the user has historical orders or deliveries
          await client.from('profiles').update({
            'is_archived': true,
            'archived_at': nowIso,
            'updated_at': nowIso,
          }).eq('id', userId);
          throw 'This user is linked to historical customer orders or delivery records and cannot be deleted from database history. It has been safely archived instead.';
        }
        rethrow;
      }
    }
  }

  /// Verify if current user session is a valid Admin
  static Future<void> _verifyAdminSession() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Unauthorized: Active authentication session required.');
    }
    final profile = await fetchProfile(user.id);
    if (profile == null || (profile['role']?.toString().toLowerCase().trim() != 'admin')) {
      throw Exception('Access Denied: Admin privileges required.');
    }
  }

  /// Create a new customer account via secure database RPC function with complete profile data
  static Future<void> createCustomer({
    required String fullName,
    required String phone,
    required String address,
    String? email,
    double? latitude,
    double? longitude,
    String? rfidUid,
  }) async {
    await _verifyAdminSession();
    final cleanEmail = (email != null && email.trim().isNotEmpty && email.contains('@'))
        ? email.trim()
        : '${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}_${DateTime.now().millisecondsSinceEpoch % 10000}@aquasync.com';
    const cleanPass = 'AquaSync2026!';

    try {
      final newUserId = await client.rpc(
        'create_user_account',
        params: {
          'p_email': cleanEmail,
          'p_password': cleanPass,
          'p_full_name': fullName,
          'p_role': 'customer',
          'p_phone': phone,
          'p_address': address,
        },
      );

      final targetId = newUserId?.toString();
      if (targetId != null && targetId.isNotEmpty) {
        final profileUpdates = <String, dynamic>{
          'email': cleanEmail,
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (latitude != null) profileUpdates['latitude'] = latitude;
        if (longitude != null) profileUpdates['longitude'] = longitude;

        await client.from('profiles').update(profileUpdates).eq('id', targetId);

        if (rfidUid != null && rfidUid.trim().isNotEmpty) {
          await assignCustomerRfid(customerId: targetId, rfidUid: rfidUid);
        }
      }
    } catch (e) {
      throw Exception('Failed to create customer account: $e');
    }
  }

  /// Create a new driver account via secure database RPC function
  static Future<void> createDriver({
    required String fullName,
    required String phone,
  }) async {
    await _verifyAdminSession();
    final cleanEmail = 'driver_${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}_${DateTime.now().millisecondsSinceEpoch % 10000}@aquasync.com';
    const cleanPass = 'AquaSync2026!';

    try {
      await client.rpc(
        'create_user_account',
        params: {
          'p_email': cleanEmail,
          'p_password': cleanPass,
          'p_full_name': fullName,
          'p_role': 'driver',
          'p_phone': phone,
          'p_address': 'Aqua Pure Water Station',
        },
      );
    } catch (e) {
      throw Exception('Failed to create driver account: $e');
    }
  }

  /// Create a new cashier account via secure database RPC function
  static Future<void> createCashier({
    required String fullName,
    required String phone,
    required String address,
    bool canAssignDrivers = true,
  }) async {
    await _verifyAdminSession();
    final cleanEmail = 'cashier_${fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}_${DateTime.now().millisecondsSinceEpoch % 10000}@aquasync.com';
    const cleanPass = 'AquaSync2026!';

    try {
      final newUserId = await client.rpc(
        'create_user_account',
        params: {
          'p_email': cleanEmail,
          'p_password': cleanPass,
          'p_full_name': fullName,
          'p_role': 'cashier',
          'p_phone': phone,
          'p_address': address,
        },
      );
      if (newUserId != null) {
        await client.from('profiles').update({
          'can_assign_drivers': canAssignDrivers,
        }).eq('id', newUserId);
      }
    } catch (e) {
      throw Exception('Failed to create cashier account: $e');
    }
  }

  /// Fetch all manageable profiles (customer, driver, cashier) from public.profiles
  static Future<List<Map<String, dynamic>>> fetchManageableProfiles() async {
    final response = await client
        .from('profiles')
        .select('*, rfid_qr_records(*)')
        .inFilter('role', ['customer', 'driver', 'cashier'])
        .order('full_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch drivers from public.profiles where role = 'driver'
  static Future<List<Map<String, dynamic>>> fetchDrivers() async {
    try {
      final response = await client
          .from('profiles')
          .select('id, full_name, phone, role, is_archived, created_at, updated_at, latitude, longitude')
          .eq('role', 'driver')
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch drivers: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PRODUCTS MASTER DATA
  // ---------------------------------------------------------------------------

  /// Upload product image to Supabase Storage bucket 'products'
  static Future<String> uploadProductImage(dynamic pickedFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    final filePath = 'products/$fileName';

    if (pickedFile.bytes != null) {
      await client.storage.from('products').uploadBinary(
            filePath,
            pickedFile.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      throw 'No image data available from selected file.';
    }

    final publicUrl = client.storage.from('products').getPublicUrl(filePath);
    return publicUrl;
  }

  /// Upload GCash QR image to Supabase Storage
  static Future<String> uploadGcashQrImage(dynamic pickedFile) async {
    final fileName = 'gcash_qr_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    final filePath = 'qr_codes/$fileName';

    if (pickedFile.bytes != null) {
      await client.storage.from('products').uploadBinary(
            filePath,
            pickedFile.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      throw 'No image data available from selected file.';
    }

    final publicUrl = client.storage.from('products').getPublicUrl(filePath);
    return publicUrl;
  }

  /// Upload Proof of Delivery image to Supabase Storage and save to deliveries/orders tables
  static Future<String> uploadProofOfDelivery({
    required String deliveryId,
    required String orderId,
    required dynamic pickedFile,
  }) async {
    final fileName = 'pod_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
    final filePath = 'proofs/$fileName';

    String publicUrl = '';
    if (pickedFile.bytes != null) {
      try {
        await client.storage.from('products').uploadBinary(
              filePath,
              pickedFile.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );
        publicUrl = client.storage.from('products').getPublicUrl(filePath);
      } catch (_) {
        try {
          await client.storage.from('deliveries').uploadBinary(
                filePath,
                pickedFile.bytes!,
                fileOptions: const FileOptions(upsert: true),
              );
          publicUrl = client.storage.from('deliveries').getPublicUrl(filePath);
        } catch (e) {
          throw 'Failed to upload proof image: $e';
        }
      }
    } else {
      throw 'No image data available from selected file.';
    }

    if (publicUrl.isEmpty) throw 'Failed to generate image public URL.';

    await saveProofUrl(deliveryId: deliveryId, orderId: orderId, proofUrl: publicUrl);
    return publicUrl;
  }

  /// Save Proof of Delivery URL to deliveries and orders tables
  static Future<void> saveProofUrl({
    required String deliveryId,
    required String orderId,
    required String proofUrl,
  }) async {
    if (deliveryId.isNotEmpty) {
      try {
        await client.from('deliveries').update({
          'proof_url': proofUrl,
          'proof_of_delivery': proofUrl,
        }).eq('id', deliveryId);
      } catch (_) {
        try {
          await client.from('deliveries').update({
            'proof_url': proofUrl,
          }).eq('id', deliveryId);
        } catch (_) {}
      }
    }

    if (orderId.isNotEmpty) {
      try {
        final orderUuid = await _resolveOrderUuid(orderId);
        await client.from('orders').update({
          'proof_url': proofUrl,
          'proof_of_delivery': proofUrl,
        }).eq('id', orderUuid);
      } catch (_) {
        try {
          final orderUuid = await _resolveOrderUuid(orderId);
          await client.from('orders').update({
            'proof_url': proofUrl,
          }).eq('id', orderUuid);
        } catch (_) {}
      }
    }
  }

  /// Fetch products from public.products
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await client
        .from('products')
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Helper to extract missing column name from PostgrestException (code PGRST204)
  static String? _extractMissingColumnFromError(dynamic e) {
    final str = e.toString();
    if (!str.contains('PGRST204') &&
        !str.contains('schema cache') &&
        !str.contains('Could not find')) {
      return null;
    }
    final RegExp regExp = RegExp(r"Could not find the '([^']+)' column");
    final match = regExp.firstMatch(str);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  /// Insert new product into public.products
  static Future<Map<String, dynamic>> addProduct(
      Map<String, dynamic> productData) async {
    final nowIso = DateTime.now().toIso8601String();
    final cleanData = Map<String, dynamic>.from(productData);
    cleanData['created_at'] = nowIso;
    cleanData['updated_at'] = nowIso;
    cleanData['is_archived'] = false;
    if (!cleanData.containsKey('is_active')) cleanData['is_active'] = true;
    if (!cleanData.containsKey('is_available')) cleanData['is_available'] = true;

    while (true) {
      try {
        final response = await client
            .from('products')
            .insert(cleanData)
            .select()
            .single();
        return response;
      } catch (e) {
        final missingCol = _extractMissingColumnFromError(e);
        if (missingCol != null && cleanData.containsKey(missingCol)) {
          cleanData.remove(missingCol);
          continue;
        }
        rethrow;
      }
    }
  }

  /// Update product in public.products
  static Future<void> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    final cleanUpdates = Map<String, dynamic>.from(updates);
    cleanUpdates['updated_at'] = DateTime.now().toIso8601String();

    while (true) {
      try {
        await client.from('products').update(cleanUpdates).eq('id', id);
        break;
      } catch (e) {
        final missingCol = _extractMissingColumnFromError(e);
        if (missingCol != null && cleanUpdates.containsKey(missingCol)) {
          cleanUpdates.remove(missingCol);
          if (cleanUpdates.isEmpty) break;
          continue;
        }
        rethrow;
      }
    }
  }

  /// Toggle product availability (Available / Not Available)
  static Future<void> toggleProductAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    Map<String, dynamic> updatePayload = {
      'is_available': isAvailable,
      'stock': isAvailable ? 100 : 0,
      'updated_at': nowIso,
    };

    while (true) {
      try {
        await client.from('products').update(updatePayload).eq('id', id);
        break;
      } catch (e) {
        final missingCol = _extractMissingColumnFromError(e);
        if (missingCol != null && updatePayload.containsKey(missingCol)) {
          updatePayload.remove(missingCol);
          if (updatePayload.isEmpty) break;
          continue;
        }
        rethrow;
      }
    }
  }

  /// Toggle product active status / archive status in public.products
  static Future<void> toggleProductActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final isArchived = !isActive;
    Map<String, dynamic> updatePayload = {
      'is_active': isActive,
      'is_archived': isArchived,
      'archived_at': isArchived ? nowIso : null,
      'updated_at': nowIso,
    };

    while (true) {
      try {
        await client.from('products').update(updatePayload).eq('id', id);
        break;
      } catch (e) {
        final missingCol = _extractMissingColumnFromError(e);
        if (missingCol != null && updatePayload.containsKey(missingCol)) {
          updatePayload.remove(missingCol);
          if (updatePayload.isEmpty) break;
          continue;
        }
        rethrow;
      }
    }
  }

  /// Permanently delete an archived product from public.products
  static Future<void> deleteProduct(String id) async {
    try {
      // Subukang gamitin ang custom cascade delete na ginawa natin sa Supabase
      await client.rpc('delete_product_cascade', params: {'p_target_product_id': id});
    } catch (rpcError) {
      // Kung wala pa yung function o nag-error, fallback sa standard direct delete
      try {
        await client.from('products').delete().eq('id', id);
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('foreign key') || errStr.contains('23503')) {
          // Fallback: archive instead of delete if the product is linked to orders
          await toggleProductActiveStatus(id: id, isActive: false);
          throw 'This product is linked to historical customer orders and cannot be deleted from database history. It has been safely archived instead.';
        }
        rethrow;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ORDERS & DELIVERIES
  // ---------------------------------------------------------------------------

  /// Fetch all orders from public.orders with order_items, customer profile, and delivery driver info
  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    List<dynamic> response;
    try {
      response = await client
          .from('orders')
          .select('*, order_items(*, products(*)), profiles:customer_id(full_name, phone, address), deliveries(*, profiles:driver_id(full_name)), payments(*)')
          .order('created_at', ascending: false);
    } catch (_) {
      response = await client
          .from('orders')
          .select('*, order_items(*, products(*)), profiles:customer_id(full_name, phone, address), deliveries(*, profiles:driver_id(full_name))')
          .order('created_at', ascending: false);
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all delivery records from public.deliveries
  static Future<List<Map<String, dynamic>>> fetchDeliveries() async {
    final response = await client
        .from('deliveries')
        .select('*, orders(*, profiles:customer_id(full_name, phone)), profiles:driver_id(full_name, phone)')
        .order('assigned_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Helper to resolve an order identifier (either UUID or order_number) to its UUID primary key
  static Future<String> _resolveOrderUuid(String identifier) async {
    final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(identifier);
    if (isUuid) {
      return identifier;
    }

    try {
      final row = await client
          .from('orders')
          .select('id')
          .eq('order_number', identifier)
          .maybeSingle();
      if (row != null && row['id'] != null) {
        return row['id'].toString();
      }
    } catch (_) {}

    return identifier;
  }

  /// Update order status in public.orders and record status history
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final targetUuid = await _resolveOrderUuid(orderId);
    final canonicalStatus = status.toLowerCase().trim();
    final nowIso = DateTime.now().toIso8601String();

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(targetUuid);
    if (!isUuid) throw Exception('Unable to resolve order ID "$orderId" to a database UUID.');

    final current = await client
        .from('orders')
        .select('id, order_status, fulfillment_type, is_walk_in, order_type')
        .eq('id', targetUuid)
        .maybeSingle();

    if (current == null) throw Exception('Order not found.');

    final currentStatus = (current['order_status'] ?? '').toString().toLowerCase().trim();
    final fulfillment = (current['fulfillment_type'] ?? '').toString().toLowerCase().trim();
    final isDelivery = fulfillment.contains('delivery');

    // The Admin approval action moves pending -> confirmed.
    if (canonicalStatus == 'confirmed') {
      if (currentStatus != 'pending') {
        throw Exception('Only pending orders can be approved. Current status: $currentStatus');
      }
    }

    await client.from('orders').update({
      'order_status': canonicalStatus,
      'status': canonicalStatus,
      'updated_at': nowIso,
    }).eq('id', targetUuid);

    await client.from('order_status_history').insert({
      'order_id': targetUuid,
      'status': canonicalStatus,
      'changed_by': currentUser?.id,
      'notes': canonicalStatus == 'confirmed'
          ? (isDelivery ? 'Delivery order approved by Admin.' : 'Store pick-up order approved by Admin.')
          : 'Order status updated by Admin.',
      'created_at': nowIso,
    });
  }

  /// Reject / Cancel an order with an admin rejection comment / reason
  static Future<void> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      final targetUuid = await _resolveOrderUuid(orderId);
      final nowIso = DateTime.now().toIso8601String();
      final isUuid = RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(targetUuid);

      final updateMap = <String, dynamic>{
        'order_status': 'cancelled',
        'rejection_reason': reason,
        'cancel_reason': reason,
        'notes': 'Order rejected by Admin. Reason: $reason',
        'updated_at': nowIso,
      };

      try {
        if (isUuid) {
          await client.from('orders').update(updateMap).eq('id', targetUuid);
        } else {
          await client.from('orders').update(updateMap).eq('order_number', orderId);
        }
      } catch (_) {
        final fallbackMap = <String, dynamic>{
          'order_status': 'cancelled',
          'notes': 'Order rejected by Admin. Reason: $reason',
          'updated_at': nowIso,
        };
        try {
          if (isUuid) {
            await client.from('orders').update(fallbackMap).eq('id', targetUuid);
          } else {
            await client.from('orders').update(fallbackMap).eq('order_number', orderId);
          }
        } catch (_) {
          final minMap = <String, dynamic>{
            'order_status': 'cancelled',
            'updated_at': nowIso,
          };
          if (isUuid) {
            await client.from('orders').update(minMap).eq('id', targetUuid);
          } else {
            await client.from('orders').update(minMap).eq('order_number', orderId);
          }
        }
      }

      if (isUuid) {
        await client.from('order_status_history').insert({
          'order_id': targetUuid,
          'status': 'cancelled',
          'notes': 'Order rejected by Admin. Reason: $reason',
          'changed_by': currentUser?.id,
          'created_at': nowIso,
        });
      }

      // Also mark associated delivery as cancelled if exists
      try {
        await client.from('deliveries').update({
          'status': 'cancelled',
          'updated_at': nowIso,
        }).eq('order_id', targetUuid);
      } catch (_) {}
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel an order and its associated delivery
  static Future<void> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    final cleanReason = reason ?? 'Order cancelled by admin';
    await rejectOrder(orderId: orderId, reason: cleanReason);

    // Try updating associated delivery status as well
    try {
      final targetUuid = await _resolveOrderUuid(orderId);
      final nowIso = DateTime.now().toIso8601String();
      await client.from('deliveries').update({
        'status': 'cancelled',
        'updated_at': nowIso,
      }).eq('order_id', targetUuid);
    } catch (_) {
      // Ignored if deliveries table status check constraint does not include cancelled
    }
  }

  /// Fetch history records for an order from public.order_status_history
  static Future<List<Map<String, dynamic>>> fetchOrderStatusHistory(String orderId) async {
    final targetUuid = await _resolveOrderUuid(orderId);
    final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(targetUuid);
    if (!isUuid) return [];

    final response = await client
        .from('order_status_history')
        .select('*, profiles:changed_by(full_name)')
        .eq('order_id', targetUuid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Assign driver to an order using public.deliveries and public.orders
  static Future<void> assignDriver({
    required String orderId,
    required String driverId,
  }) async {
    final targetUuid = await _resolveOrderUuid(orderId);
    final nowIso = DateTime.now().toIso8601String();

    final orderRes = await client
        .from('orders')
        .select('order_status, fulfillment_type, is_walk_in, order_type')
        .eq('id', targetUuid)
        .maybeSingle();

    if (orderRes == null) throw Exception('Order not found.');

    final orderStatus = orderRes['order_status']?.toString().toLowerCase().trim() ?? '';
    final fulfillment = orderRes['fulfillment_type']?.toString().toLowerCase().trim() ?? '';

    if (fulfillment.contains('pickup') || fulfillment.contains('pick_up')) {
      throw Exception('Store pick-up orders do not require a delivery driver.');
    }

    if (orderStatus == 'pending') {
      await client.from('orders').update({
        'order_status': 'confirmed',
        'status': 'confirmed',
        'updated_at': nowIso,
      }).eq('id', targetUuid);
    } else if (orderStatus != 'confirmed') {
      throw Exception('Admin must approve the order first. Current status: $orderStatus');
    }

    final driverRes = await client
        .from('profiles')
        .select('id')
        .eq('id', driverId)
        .eq('role', 'driver')
        .eq('is_archived', false)
        .maybeSingle();

    if (driverRes == null) {
      throw Exception('Selected driver is invalid or no longer active.');
    }

    final existingDelivery = await client
        .from('deliveries')
        .select('id, status')
        .eq('order_id', targetUuid)
        .maybeSingle();

    if (existingDelivery != null) {
      final deliveryStatus = existingDelivery['status']?.toString().toLowerCase().trim();
      if (deliveryStatus != 'assigned') {
        throw Exception('This delivery is already $deliveryStatus and cannot be reassigned from this screen.');
      }

      await client.from('deliveries').update({
        'driver_id': driverId,
        'status': 'assigned',
        'assigned_at': nowIso,
        'updated_at': nowIso,
      }).eq('id', existingDelivery['id']);
      return;
    }

    await client.from('deliveries').insert({
      'order_id': targetUuid,
      'driver_id': driverId,
      'status': 'assigned',
      'assigned_at': nowIso,
      'created_at': nowIso,
      'updated_at': nowIso,
    });

    await client.from('orders').update({
      'order_status': 'assigned',
      'status': 'assigned',
      'updated_at': nowIso,
    }).eq('id', targetUuid);

    await client.from('order_status_history').insert({
      'order_id': targetUuid,
      'status': 'assigned',
      'notes': 'Driver assigned by Admin.',
      'changed_by': currentUser?.id,
      'created_at': nowIso,
    });
  }

  /// Admin update for delivery status in public.deliveries.
  /// The database BEFORE UPDATE trigger on deliveries synchronizes orders.order_status
  /// and logs order_status_history automatically.
  static Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    String? orderId,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final canonicalStatus = status.toLowerCase().trim();

    final allowedStatuses = ['assigned', 'accepted', 'out_for_delivery', 'delivered'];
    if (!allowedStatuses.contains(canonicalStatus)) {
      throw Exception('Invalid delivery status "$canonicalStatus". Must be assigned, accepted, out_for_delivery, or delivered.');
    }

    final updates = <String, dynamic>{
      'status': canonicalStatus,
      'updated_at': nowIso,
    };

    if (canonicalStatus == 'accepted') {
      updates['accepted_at'] = nowIso;
    } else if (canonicalStatus == 'out_for_delivery') {
      updates['started_at'] = nowIso;
    } else if (canonicalStatus == 'delivered') {
      updates['delivered_at'] = nowIso;
    }

    await client.from('deliveries').update(updates).eq('id', deliveryId);
  }

  // ---------------------------------------------------------------------------
  // GALLONS & PHYSICAL QR REGISTRY (ACTUAL SCHEMA ALIGNED)
  // ---------------------------------------------------------------------------

  /// Fetch gallons from public.gallons with profiles:customer_id
  static Future<List<Map<String, dynamic>>> fetchGallons() async {
    final response = await client
        .from('gallons')
        .select('*, profiles:customer_id(full_name, address)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch physical gallon QR registry records from public.rfid_qr_records where code_type = 'QR'
  static Future<List<Map<String, dynamic>>> fetchGallonQrRecords() async {
    final response = await client
        .from('rfid_qr_records')
        .select('*, gallons(*)')
        .eq('code_type', 'QR')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add new gallon container and automatically generate matching physical QR record in public.rfid_qr_records
  static Future<void> addGallonWithQr({
    required String gallonCode,
    required String status,
    String? customerId,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final cleanStatus = status.toLowerCase().trim().replaceAll(' ', '_');

    // 1. Duplicate gallon_code check
    final existingGallon = await client
        .from('gallons')
        .select('id')
        .eq('gallon_code', gallonCode)
        .maybeSingle();
    if (existingGallon != null) {
      throw 'Gallon code "$gallonCode" is already assigned to an existing container. QR codes must be strictly 1-to-1 unique per gallon container!';
    }

    // 2. Insert into public.gallons
    final gallonInsertData = <String, dynamic>{
      'gallon_code': gallonCode,
      'status': cleanStatus,
      'customer_id': (customerId != null && customerId.isNotEmpty) ? customerId : null,
      'borrowed_at': (customerId != null && customerId.isNotEmpty) ? nowIso : null,
      'is_archived': false,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    final Map<String, dynamic> insertedGallon = await client
        .from('gallons')
        .insert(gallonInsertData)
        .select('id, gallon_code')
        .single();

    final String gallonUuid = insertedGallon['id'].toString();

    // 3. Create 1-to-1 unique physical QR record in public.rfid_qr_records
    await client.from('rfid_qr_records').insert({
      'gallon_id': gallonUuid,
      'code': gallonCode,
      'code_type': 'QR',
      'is_active': true,
      'created_at': nowIso,
    });

    // 4. Log initial gallon transaction in public.gallon_transactions
    await client.from('gallon_transactions').insert({
      'gallon_id': gallonUuid,
      'customer_id': (customerId != null && customerId.isNotEmpty) ? customerId : null,
      'action': 'registered',
      'notes': 'Gallon registered in master physical QR registry',
      'created_at': nowIso,
    });
  }

  /// Generate or retrieve 1-to-1 unique physical QR record in public.rfid_qr_records for a specific gallon
  static Future<Map<String, dynamic>> generateQrForGallon({
    required String gallonId,
    required String gallonCode,
  }) async {
    final nowIso = DateTime.now().toIso8601String();

    // 1. Check if an active QR already exists for this gallon_id
    final existingQr = await client
        .from('rfid_qr_records')
        .select()
        .eq('gallon_id', gallonId)
        .eq('code_type', 'QR')
        .maybeSingle();

    if (existingQr != null) {
      return existingQr;
    }

    // 2. Check if code already exists globally in rfid_qr_records
    final existingCode = await client
        .from('rfid_qr_records')
        .select()
        .eq('code', gallonCode)
        .maybeSingle();

    if (existingCode != null) {
      final existingGallonId = existingCode['gallon_id']?.toString();
      if (existingGallonId != gallonId) {
        throw 'QR code "$gallonCode" is already registered to another gallon container.';
      }
      return existingCode;
    }

    // 3. Insert new unique QR record linking gallon_id = gallonId
    final insertData = {
      'gallon_id': gallonId,
      'code': gallonCode,
      'code_type': 'QR',
      'is_active': true,
      'created_at': nowIso,
    };

    final inserted = await client
        .from('rfid_qr_records')
        .insert(insertData)
        .select()
        .single();

    return inserted;
  }

  /// Batch Add Gallons and automatically generate matching physical QR records
  static Future<List<Map<String, String>>> batchAddGallonsWithQr({
    required int count,
    required String status,
    required String containerType,
    String? customerId,
    String location = 'AQUAZONE Water Refill Station',
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final cleanStatus = status.toLowerCase().trim().replaceAll(' ', '_');

    final List<Map<String, dynamic>> gallonsInsert = [];
    final List<String> generatedCodes = [];

    final baseMs = DateTime.now().millisecondsSinceEpoch % 900000;
    for (int i = 0; i < count; i++) {
      final code = 'AQS-G-${baseMs + i + 100000}';
      generatedCodes.add(code);
      gallonsInsert.add({
        'gallon_code': code,
        'status': cleanStatus,
        'customer_id': (customerId != null && customerId.isNotEmpty) ? customerId : null,
        'borrowed_at': (customerId != null && customerId.isNotEmpty) ? nowIso : null,
        'is_archived': false,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
    }

    final List<dynamic> insertedGallons = await client
        .from('gallons')
        .insert(gallonsInsert)
        .select('id, gallon_code');

    final List<Map<String, dynamic>> qrInsert = [];
    final List<Map<String, dynamic>> txInsert = [];
    final List<Map<String, String>> resultSummary = [];

    for (var g in insertedGallons) {
      final String gId = g['id'].toString();
      final String gCode = g['gallon_code'].toString();

      qrInsert.add({
        'gallon_id': gId,
        'code': gCode,
        'code_type': 'QR',
        'is_active': true,
        'created_at': nowIso,
      });

      txInsert.add({
        'gallon_id': gId,
        'customer_id': (customerId != null && customerId.isNotEmpty) ? customerId : null,
        'action': 'registered',
        'notes': 'Gallon registered in batch physical QR registry',
        'created_at': nowIso,
      });

      resultSummary.add({
        'id': gId,
        'code': gCode,
      });
    }

    if (qrInsert.isNotEmpty) {
      await client.from('rfid_qr_records').insert(qrInsert);
    }
    if (txInsert.isNotEmpty) {
      await client.from('gallon_transactions').insert(txInsert);
    }

    return resultSummary;
  }

  /// Batch generate QR records for existing gallons that don't have QR code yet
  static Future<int> batchGenerateQrForGallons(List<String> gallonIds, List<String> gallonCodes) async {
    final nowIso = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> qrInsert = [];

    for (int i = 0; i < gallonIds.length; i++) {
      final gId = gallonIds[i];
      final gCode = gallonCodes[i];

      // Check if QR already exists
      final existingQr = await client
          .from('rfid_qr_records')
          .select('id')
          .eq('gallon_id', gId)
          .eq('code_type', 'QR')
          .maybeSingle();

      if (existingQr == null) {
        qrInsert.add({
          'gallon_id': gId,
          'code': gCode,
          'code_type': 'QR',
          'is_active': true,
          'created_at': nowIso,
        });
      }
    }

    if (qrInsert.isNotEmpty) {
      await client.from('rfid_qr_records').insert(qrInsert);
    }
    return qrInsert.length;
  }

  /// Toggle Gallon Retired/Archived status in public.gallons
  static Future<void> toggleGallonRetiredStatus({
    required String gallonId,
    required bool isRetired,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final newStatus = isRetired ? 'retired' : 'available';

    await client.from('gallons').update({
      'status': newStatus,
      'is_archived': isRetired,
      'archived_at': isRetired ? nowIso : null,
      'updated_at': nowIso,
    }).eq('id', gallonId);

    await client
        .from('rfid_qr_records')
        .update({'is_active': !isRetired})
        .eq('gallon_id', gallonId)
        .eq('code_type', 'QR');

    await client.from('gallon_transactions').insert({
      'gallon_id': gallonId,
      'action': isRetired ? 'retired' : 'restored',
      'notes': isRetired ? 'Container retired and archived' : 'Container restored to available stock',
      'created_at': nowIso,
    });
  }

  /// Permanently delete an archived gallon container from public.gallons
  static Future<void> deleteGallon(String gallonId) async {
    try {
      // 1. Delete associated RFID/QR records linked to this gallon container
      await client.from('rfid_qr_records').delete().eq('gallon_id', gallonId);

      // 2. Delete associated transaction history linked to this gallon container
      await client.from('gallon_transactions').delete().eq('gallon_id', gallonId);

      // 3. Delete the gallon container record itself
      await client.from('gallons').delete().eq('id', gallonId);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('foreign key') || errStr.contains('23503')) {
        final nowIso = DateTime.now().toIso8601String();
        // Soft fallback to archive if cascaded delete failed for some reason
        await client.from('gallons').update({
          'status': 'retired',
          'is_archived': true,
          'archived_at': nowIso,
          'updated_at': nowIso,
        }).eq('id', gallonId);
        throw 'Container is referenced in other critical records and cannot be permanently deleted. It remains safely retired/archived.';
      }
      rethrow;
    }
  }

  /// Update gallon status in public.gallons and log in public.gallon_transactions
  static Future<void> updateGallonStatus({
    required String gallonId,
    required String newStatus,
    String? customerId,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final cleanStatus = newStatus.toLowerCase().trim().replaceAll(' ', '_');

    final updates = <String, dynamic>{
      'status': cleanStatus,
      'updated_at': nowIso,
    };

    // Logic: If status is available or returned, clear the customer_id
    if (cleanStatus == 'available' || cleanStatus == 'returned' || cleanStatus == 'retired') {
      updates['customer_id'] = null;
      updates['returned_at'] = nowIso;
    } else if (customerId != null && customerId.isNotEmpty) {
      updates['customer_id'] = customerId;
      if (cleanStatus == 'borrowed' || cleanStatus == 'out_for_delivery') {
        updates['borrowed_at'] = nowIso;
      }
    }

    await client.from('gallons').update(updates).eq('id', gallonId);

    await client.from('gallon_transactions').insert({
      'gallon_id': gallonId,
      'customer_id': updates['customer_id'],
      'action': cleanStatus,
      'notes': 'Status updated to $cleanStatus.',
      'created_at': nowIso,
    });
  }

  /// Fetch history records for a gallon from public.gallon_transactions
  static Future<List<Map<String, dynamic>>> fetchGallonHistory(
      String gallonId) async {
    final response = await client
        .from('gallon_transactions')
        .select('*, profiles:customer_id(full_name)')
        .eq('gallon_id', gallonId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // DEBTS & PAYMENTS (ACTUAL SCHEMA ALIGNED)
  // ---------------------------------------------------------------------------

  /// Fetch all customer debts from public.debts joined with profiles and orders
  static Future<List<Map<String, dynamic>>> fetchDebts() async {
    final response = await client
        .from('debts')
        .select('*, profiles:customer_id(full_name), orders:order_id(order_number)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add new customer debt to public.debts
  static Future<void> createDebt({
    required String customerId,
    String? orderId,
    required String description,
    required double amount,
    String? dueDate,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await client.from('debts').insert({
      'customer_id': customerId,
      'order_id': (orderId != null && orderId.isNotEmpty) ? orderId : null,
      'description': description,
      'amount': amount,
      'paid_amount': 0.0,
      'status': 'unpaid',
      'due_date': (dueDate != null && dueDate.isNotEmpty) ? dueDate : null,
      'created_at': nowIso,
      'updated_at': nowIso,
    });
  }

  /// Update debt details in public.debts
  static Future<void> updateDebt({
    required String debtId,
    required String description,
    required double amount,
    required double paidAmount,
    required String status,
    String? dueDate,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    double cleanPaid = paidAmount;
    if (cleanPaid > amount) cleanPaid = amount;

    String cleanStatus;
    if (cleanPaid >= amount) {
      cleanStatus = 'paid';
      cleanPaid = amount;
    } else if (cleanPaid > 0) {
      cleanStatus = 'partial';
    } else {
      cleanStatus = 'unpaid';
    }

    await client.from('debts').update({
      'description': description,
      'amount': amount,
      'paid_amount': cleanPaid,
      'status': cleanStatus,
      'due_date': (dueDate != null && dueDate.isNotEmpty) ? dueDate : null,
      'updated_at': nowIso,
    }).eq('id', debtId);
  }

  /// Mark debt as fully paid in public.debts
  static Future<void> markDebtAsPaid({
    required String debtId,
    required double totalAmount,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await client.from('debts').update({
      'paid_amount': totalAmount,
      'status': 'paid',
      'updated_at': nowIso,
    }).eq('id', debtId);
  }

  /// Settles debt fully by updating paid_amount to total amount and status to paid
  static Future<void> settleDebtFully({
    required String debtId,
    required double remainingBalance,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final response = await client.from('debts').select('amount').eq('id', debtId).maybeSingle();
    final totalAmount = (response != null && response['amount'] != null)
        ? (response['amount'] as num).toDouble()
        : remainingBalance;
    await client.from('debts').update({
      'paid_amount': totalAmount,
      'status': 'paid',
      'updated_at': nowIso,
    }).eq('id', debtId);
  }

  /// Delete debt record from public.debts
  static Future<void> deleteDebt(String debtId) async {
    await client.from('debts').delete().eq('id', debtId);
  }

  /// Fetch payment audit records from public.payments (READ ONLY - Admin has SELECT policy)
  static Future<List<Map<String, dynamic>>> fetchPayments() async {
    final response = await client
        .from('payments')
        .select('*, orders(*, profiles:customer_id(full_name))')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // ANNOUNCEMENTS MANAGEMENT (ACTUAL SCHEMA ALIGNED)
  // ---------------------------------------------------------------------------

  /// Fetch all announcements from public.announcements sorted newest first
  static Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final response = await client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new announcement in public.announcements
  static Future<void> createAnnouncement({
    required String title,
    required String message,
    required String type,
    bool isActive = true,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final cleanTitle = title.trim();
    final cleanMessage = message.trim();

    if (cleanTitle.isEmpty) throw 'Announcement Title cannot be empty.';
    if (cleanTitle.length > 60) throw 'Announcement Title cannot exceed 60 characters.';
    if (cleanMessage.isEmpty) throw 'Announcement Message cannot be empty.';
    if (cleanMessage.length > 150) throw 'Announcement Message cannot exceed 150 characters.';

    final nowIso = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'title': cleanTitle,
      'message': cleanMessage,
      'type': type.toLowerCase().trim(),
      'is_active': isActive,
      'created_at': nowIso,
    };
    if (startsAt != null) {
      payload['starts_at'] = startsAt.toIso8601String();
    }
    if (endsAt != null) {
      payload['ends_at'] = endsAt.toIso8601String();
    }

    await client.from('announcements').insert(payload);
  }

  /// Update an existing announcement in public.announcements
  static Future<void> updateAnnouncement({
    required String announcementId,
    required String title,
    required String message,
    required String type,
    required bool isActive,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final cleanTitle = title.trim();
    final cleanMessage = message.trim();

    if (cleanTitle.isEmpty) throw 'Announcement Title cannot be empty.';
    if (cleanTitle.length > 60) throw 'Announcement Title cannot exceed 60 characters.';
    if (cleanMessage.isEmpty) throw 'Announcement Message cannot be empty.';
    if (cleanMessage.length > 150) throw 'Announcement Message cannot exceed 150 characters.';

    final payload = <String, dynamic>{
      'title': cleanTitle,
      'message': cleanMessage,
      'type': type.toLowerCase().trim(),
      'is_active': isActive,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
    };

    await client.from('announcements').update(payload).eq('id', announcementId);
  }

  /// Toggle announcement active status in public.announcements
  static Future<void> toggleAnnouncementStatus({
    required String announcementId,
    required bool isActive,
  }) async {
    await client.from('announcements').update({
      'is_active': isActive,
    }).eq('id', announcementId);
  }

  /// Permanently delete an announcement from public.announcements
  static Future<void> deleteAnnouncement(String announcementId) async {
    await client.from('announcements').delete().eq('id', announcementId);
  }

  // ---------------------------------------------------------------------------
  // SALES & POS
  // ---------------------------------------------------------------------------

  /// Determine classification (Walk-In vs Online) for any sales or order record
  static String determineClassification(Map<String, dynamic> item) {
    final invNum = (item['invoice_number'] ?? item['receipt_number'] ?? item['order_number'] ?? item['id'] ?? '').toString().toUpperCase();
    final orderType = (item['order_type'] ?? '').toString().trim().toLowerCase();
    final bool isWalkInFlag = item['is_walk_in'] == true;

    if (orderType == 'online' || orderType == 'app' || orderType == 'delivery' || invNum.contains('ORD-') || invNum.startsWith('ORD') || invNum.startsWith('APP-')) {
      return 'Online';
    }

    if (isWalkInFlag || orderType == 'pos' || orderType == 'walk_in' || orderType == 'walk-in' || invNum.contains('POS-') || invNum.startsWith('POS')) {
      return 'Walk-In';
    }

    final fulfillment = (item['fulfillment_type'] ?? item['notes'] ?? '').toString().toLowerCase();
    if (fulfillment.contains('delivery') || fulfillment.contains('online')) {
      return 'Online';
    }

    if (item['classification'] != null && item['classification'].toString().isNotEmpty) {
      final c = item['classification'].toString().trim().toLowerCase();
      if (c == 'online' || c == 'app' || c == 'delivery') return 'Online';
      if (c == 'walk-in' || c == 'walk_in' || c == 'pos') return 'Walk-In';
    }

    return item['is_online_order'] == true ? 'Online' : 'Walk-In';
  }

  /// Fetch sales analytics from public.sales and completed/delivered public.orders
  static Future<Map<String, dynamic>> fetchDailySalesSummary() async {
    try {
      final salesRes = await client
          .from('sales')
          .select('*, sale_items(*)')
          .order('created_at', ascending: false);

      List<dynamic> ordersRes = [];
      try {
        ordersRes = await client
            .from('orders')
            .select('*, order_items(*), profiles:customer_id(full_name, phone)')
            .order('created_at', ascending: false);
      } catch (_) {
        try {
          ordersRes = await client
              .from('orders')
              .select('*, order_items(*)')
              .order('created_at', ascending: false);
        } catch (_) {}
      }

      final List<Map<String, dynamic>> combinedList = [];

      for (var sale in List<Map<String, dynamic>>.from(salesRes)) {
        final map = Map<String, dynamic>.from(sale);
        final classStr = determineClassification(map);
        map['classification'] = classStr;
        map['is_online_order'] = classStr == 'Online';
        combinedList.add(map);
      }

      for (var order in List<Map<String, dynamic>>.from(ordersRes)) {
        final status = (order['order_status'] ?? order['status'] ?? '').toString().toLowerCase().trim();
        if (status == 'cancelled' || status == 'rejected') {
          continue;
        }

        final idStr = order['id']?.toString() ?? '';
        final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
        
        String custName = 'Online Customer';
        if (order['profiles'] != null && order['profiles']['full_name'] != null && order['profiles']['full_name'].toString().isNotEmpty) {
          custName = order['profiles']['full_name'].toString();
        } else if (order['customer_name'] != null && order['customer_name'].toString().isNotEmpty) {
          custName = order['customer_name'].toString();
        } else if (order['user_name'] != null && order['user_name'].toString().isNotEmpty) {
          custName = order['user_name'].toString();
        } else if (order['customer'] != null && order['customer']['full_name'] != null) {
          custName = order['customer']['full_name'].toString();
        }

        final String classification = determineClassification(order);

        combinedList.add({
          'id': order['id'],
          'invoice_number': order['invoice_number'] ?? order['order_number'] ?? 'INV-ORD-$shortId',
          'receipt_number': order['receipt_number'] ?? order['order_number'] ?? 'RCP-ORD-$shortId',
          'customer_name': custName,
          'notes': order['notes'] ?? order['delivery_address'] ?? 'Online Order',
          'total_amount': order['total_amount'] ?? order['amount'] ?? 0,
          'payment_method': order['payment_method'] ?? order['payment'] ?? 'COD',
          'created_at': order['created_at'],
          'sale_items': order['order_items'] ?? order['sale_items'] ?? [],
          'classification': classification,
          'is_online_order': classification == 'Online',
        });
      }

      combinedList.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      double totalSales = 0.0;
      double cashSales = 0.0;
      double gcashSales = 0.0;

      for (var item in combinedList) {
        final amt = item['total_amount'] ?? item['amount'] ?? 0;
        double parsedAmt = 0.0;
        if (amt is num) {
          parsedAmt = amt.toDouble();
        } else if (amt is String) {
          parsedAmt = double.tryParse(amt) ?? 0.0;
        }

        totalSales += parsedAmt;

        final method = (item['payment_method'] ?? item['payment'] ?? '').toString().toLowerCase();
        if (method.contains('gcash') || method.contains('online') || method.contains('paymongo')) {
          gcashSales += parsedAmt;
        } else {
          cashSales += parsedAmt;
        }
      }

      return {
        'totalSalesToday': totalSales,
        'cashSalesToday': cashSales,
        'gcashSalesToday': gcashSales,
        'transactionCount': combinedList.length,
        'sales': combinedList,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch sales analytics for a given range from public.sales and completed/delivered public.orders
  static Future<Map<String, dynamic>> fetchSalesSummary(String range) async {
    try {
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;

      switch (range.toLowerCase()) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'yesterday':
          final yest = now.subtract(const Duration(days: 1));
          startDate = DateTime(yest.year, yest.month, yest.day);
          endDate = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
          break;
        case 'week':
        case 'last 7 days':
          startDate = now.subtract(const Duration(days: 7));
          endDate = now;
          break;
        case 'month':
        case 'this month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = now;
          break;
        case 'all':
        case 'all time':
        default:
          startDate = null;
          endDate = null;
          break;
      }

      var salesQuery = client.from('sales').select('*, sale_items(*)');
      var ordersQuery = client.from('orders').select('*, order_items(*), profiles:customer_id(full_name, phone)');

      if (startDate != null && endDate != null) {
        salesQuery = salesQuery.gte('created_at', startDate.toIso8601String()).lte('created_at', endDate.toIso8601String());
        ordersQuery = ordersQuery.gte('created_at', startDate.toIso8601String()).lte('created_at', endDate.toIso8601String());
      }

      final salesRes = await salesQuery.order('created_at', ascending: false);
      List<dynamic> ordersRes = [];
      try {
        ordersRes = await ordersQuery.order('created_at', ascending: false);
      } catch (_) {
        try {
          var fallbackQuery = client.from('orders').select('*, order_items(*)');
          if (startDate != null && endDate != null) {
            fallbackQuery = fallbackQuery.gte('created_at', startDate.toIso8601String()).lte('created_at', endDate.toIso8601String());
          }
          ordersRes = await fallbackQuery.order('created_at', ascending: false);
        } catch (_) {}
      }

      final List<Map<String, dynamic>> combinedList = [];

      for (var sale in List<Map<String, dynamic>>.from(salesRes)) {
        final map = Map<String, dynamic>.from(sale);
        final classStr = determineClassification(map);
        map['classification'] = classStr;
        map['is_online_order'] = classStr == 'Online';
        combinedList.add(map);
      }

      for (var order in List<Map<String, dynamic>>.from(ordersRes)) {
        final status = (order['order_status'] ?? order['status'] ?? '').toString().toLowerCase().trim();
        if (status == 'cancelled' || status == 'rejected') {
          continue;
        }

        final idStr = order['id']?.toString() ?? '';
        final shortId = idStr.length >= 8 ? idStr.substring(0, 8).toUpperCase() : '001';
        
        String custName = 'Online Customer';
        if (order['profiles'] != null && order['profiles']['full_name'] != null && order['profiles']['full_name'].toString().isNotEmpty) {
          custName = order['profiles']['full_name'].toString();
        } else if (order['customer_name'] != null && order['customer_name'].toString().isNotEmpty) {
          custName = order['customer_name'].toString();
        } else if (order['user_name'] != null && order['user_name'].toString().isNotEmpty) {
          custName = order['user_name'].toString();
        } else if (order['customer'] != null && order['customer']['full_name'] != null) {
          custName = order['customer']['full_name'].toString();
        }

        final String classification = determineClassification(order);

        combinedList.add({
          'id': order['id'],
          'invoice_number': order['invoice_number'] ?? order['order_number'] ?? 'INV-ORD-$shortId',
          'receipt_number': order['receipt_number'] ?? order['order_number'] ?? 'RCP-ORD-$shortId',
          'customer_name': custName,
          'notes': order['notes'] ?? order['delivery_address'] ?? 'Online Order',
          'total_amount': order['total_amount'] ?? order['amount'] ?? 0,
          'payment_method': order['payment_method'] ?? order['payment'] ?? 'COD',
          'created_at': order['created_at'],
          'sale_items': order['order_items'] ?? order['sale_items'] ?? [],
          'classification': classification,
          'is_online_order': classification == 'Online',
        });
      }

      combinedList.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      double totalSales = 0.0;
      double cashSales = 0.0;
      double gcashSales = 0.0;

      for (var item in combinedList) {
        final amt = item['total_amount'] ?? item['amount'] ?? 0;
        double parsedAmt = 0.0;
        if (amt is num) {
          parsedAmt = amt.toDouble();
        } else if (amt is String) {
          parsedAmt = double.tryParse(amt) ?? 0.0;
        }

        totalSales += parsedAmt;

        final method = (item['payment_method'] ?? item['payment'] ?? '').toString().toLowerCase();
        if (method.contains('gcash') || method.contains('online') || method.contains('paymongo')) {
          gcashSales += parsedAmt;
        } else {
          cashSales += parsedAmt;
        }
      }

      return {
        'totalSales': totalSales,
        'cashSales': cashSales,
        'gcashSales': gcashSales,
        'transactionCount': combinedList.length,
        'sales': combinedList,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a sale and its items from public.sales and public.sale_items
  static Future<void> deleteSale(String saleId) async {
    try {
      final row = await client.from('sales').select('receipt_number').eq('id', saleId).maybeSingle();
      final receiptNum = row?['receipt_number']?.toString();

      await client.from('sale_items').delete().eq('sale_id', saleId);
      await client.from('sales').delete().eq('id', saleId);

      if (receiptNum != null && receiptNum.isNotEmpty) {
        try {
          await deleteOrder(receiptNum);
        } catch (_) {}
      }
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // REVIEWS MONITORING (READ ONLY)
  // ---------------------------------------------------------------------------

  /// Fetch all customer reviews from public.reviews ordered newest first
  static Future<List<Map<String, dynamic>>> fetchReviews() async {
    final response = await client
        .from('reviews')
        .select('*, profiles:customer_id(full_name), orders:order_id(order_number)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // ---------------------------------------------------------------------------
  // PROMOS & COUPONS (PUBLIC.PROMOS CRUD)
  // ---------------------------------------------------------------------------

  /// Fetch all promo codes from public.promos
  static Future<List<Map<String, dynamic>>> fetchPromos() async {
    final response = await client
        .from('promos')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new promo code in public.promos
  static Future<void> createPromo({
    required String code,
    required double discountValue,
    required String discountType,
    required double minSpend,
    required bool isActive,
    required String validFrom,
    required String validUntil,
    int maxUses = 0,
    int usedCount = 0,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'code': code.toUpperCase().trim(),
      'discount_value': discountValue,
      'discount_type': discountType.toLowerCase().trim(),
      'min_spend': minSpend,
      'is_active': isActive,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'max_uses': maxUses,
      'used_count': usedCount,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    try {
      await client.from('promos').insert(data);
    } catch (e) {
      if (e.toString().contains('max_uses') || e.toString().contains('used_count')) {
        data.remove('max_uses');
        data.remove('used_count');
        await client.from('promos').insert(data);
      } else {
        rethrow;
      }
    }
  }

  /// Update an existing promo code in public.promos
  static Future<void> updatePromo({
    required String promoId,
    required String code,
    required double discountValue,
    required String discountType,
    required double minSpend,
    required bool isActive,
    required String validFrom,
    required String validUntil,
    int maxUses = 0,
    int? usedCount,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'code': code.toUpperCase().trim(),
      'discount_value': discountValue,
      'discount_type': discountType.toLowerCase().trim(),
      'min_spend': minSpend,
      'is_active': isActive,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'max_uses': maxUses,
      'updated_at': nowIso,
    };
    if (usedCount != null) {
      data['used_count'] = usedCount;
    }

    try {
      await client.from('promos').update(data).eq('id', promoId);
    } catch (e) {
      if (e.toString().contains('max_uses') || e.toString().contains('used_count')) {
        data.remove('max_uses');
        data.remove('used_count');
        await client.from('promos').update(data).eq('id', promoId);
      } else {
        rethrow;
      }
    }
  }

  /// Validate a promo code against active status, date range, usage limits, and minimum spend.
  static Future<PromoValidationResult> validatePromoCode({
    required String code,
    double orderAmount = 0.0,
  }) async {
    final searchCode = code.trim().toUpperCase();
    if (searchCode.isEmpty) {
      return PromoValidationResult.error('Promo code cannot be empty.');
    }

    try {
      final res = await client
          .from('promos')
          .select()
          .eq('code', searchCode)
          .maybeSingle();

      if (res == null) {
        return PromoValidationResult.error('Invalid promo code. Code does not exist.');
      }

      final promo = PromoModel.fromSupabase(res);

      if (!promo.isActive) {
        return PromoValidationResult.error('This promo code is currently inactive.');
      }

      if (promo.isNotStarted) {
        return PromoValidationResult.error('This promo code is not active yet (starts on ${promo.validFrom}).');
      }

      if (promo.isExpired) {
        return PromoValidationResult.error('This promo code has expired (ended on ${promo.validUntil}).');
      }

      if (promo.isLimitReached) {
        return PromoValidationResult.error('This promo code has reached its maximum usage limit (${promo.maxUses} uses).');
      }

      if (orderAmount < promo.minSpend) {
        return PromoValidationResult.error('Minimum spend of ₱${promo.minSpend.toStringAsFixed(2)} is required to apply this promo code.');
      }

      double calculatedDiscount = 0.0;
      if (promo.discountType == 'percentage') {
        calculatedDiscount = (orderAmount * promo.discountValue) / 100.0;
      } else {
        calculatedDiscount = promo.discountValue;
      }

      return PromoValidationResult.success(
        promo: promo,
        discountAmount: calculatedDiscount,
      );
    } catch (e) {
      return PromoValidationResult.error('Error validating promo code: $e');
    }
  }

  /// Increment promo code usage count by 1
  static Future<void> incrementPromoUsage(String promoId) async {
    try {
      final res = await client.from('promos').select('used_count').eq('id', promoId).maybeSingle();
      final current = (res?['used_count'] as num?)?.toInt() ?? 0;
      await client.from('promos').update({
        'used_count': current + 1,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', promoId);
    } catch (_) {}
  }

  /// Toggle promo active status in public.promos
  static Future<void> togglePromoStatus({
    required String promoId,
    required bool isActive,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await client.from('promos').update({
      'is_active': isActive,
      'updated_at': nowIso,
    }).eq('id', promoId);
  }

  /// Delete a promo code from public.promos
  static Future<void> deletePromo(String id) async {
    await client.from('promos').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // REALTIME SUBSCRIPTIONS
  // ---------------------------------------------------------------------------

  /// Subscribe to realtime table changes
  static RealtimeChannel subscribeToTableChanges({
    required String channelName,
    required String table,
    required void Function(PostgresChangePayload payload) onData,
  }) {
    final channel = client.channel(channelName);
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: onData,
        )
        .subscribe();
    return channel;
  }

  /// Fetch real-time driver GPS locations from public.driver_locations table
  static Future<Map<String, DriverLocationModel>> fetchDriverLocations() async {
    final Map<String, DriverLocationModel> locations = {};
    try {
      final response = await client.from('driver_locations').select();
      for (var row in response) {
        final loc = DriverLocationModel.fromSupabase(Map<String, dynamic>.from(row));
        if (loc.driverId.isNotEmpty) {
          locations[loc.driverId] = loc;
        }
      }
    } catch (e) {
      debugPrint('Note: fetchDriverLocations from driver_locations table: $e');
    }
    return locations;
  }

  /// Subscribe to realtime driver location updates from public.driver_locations
  static RealtimeChannel subscribeToDriverLocations(
      void Function(DriverLocationModel location) onLocationUpdate) {
    final channel = client.channel('public:driver_locations_realtime');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_locations',
          callback: (payload) {
            final rec = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            if (rec.isNotEmpty) {
              final loc = DriverLocationModel.fromSupabase(Map<String, dynamic>.from(rec));
              if (loc.driverId.isNotEmpty) {
                onLocationUpdate(loc);
              }
            }
          },
        )
        .subscribe();
    return channel;
  }

  /// Permanently delete an order from public.orders
  static Future<void> deleteOrder(String orderId) async {
    final targetUuid = await _resolveOrderUuid(orderId);

    try { await client.from('order_messages').delete().eq('order_id', targetUuid); } catch (_) {}
    try { await client.from('order_items').delete().eq('order_id', targetUuid); } catch (_) {}
    try { await client.from('order_status_history').delete().eq('order_id', targetUuid); } catch (_) {}
    try { await client.from('deliveries').delete().eq('order_id', targetUuid); } catch (_) {}
    try { await client.from('debts').delete().eq('order_id', targetUuid); } catch (_) {}
    try { await client.from('reviews').delete().eq('order_id', targetUuid); } catch (_) {}
    try { await client.from('payments').delete().eq('order_id', targetUuid); } catch (_) {}

    await client.from('orders').delete().or('id.eq.$targetUuid,order_number.eq.$orderId');
  }
}
