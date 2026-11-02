import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dialogs/customer_details_dialog.dart';
import '../../dialogs/driver_details_dialog.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/location_helper.dart';
import '../../widgets/widgets.dart';

class LiveTrackingPage extends StatefulWidget {
  final List<CustomerModel> customers;
  final List<DriverModel> drivers;
  final List<OrderItemModel> orders;
  final List<DeliveryModel> deliveries;
  final VoidCallback onRefresh;
  final CustomerModel? initialFocusCustomer;

  const LiveTrackingPage({
    super.key,
    required this.customers,
    required this.drivers,
    required this.orders,
    required this.deliveries,
    required this.onRefresh,
    this.initialFocusCustomer,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Dynamic Station Configuration
  late LatLng _stationCenter;
  late String _stationName;
  late String _stationAddress;
  late double _geofenceRadiusKm;

  // Real-time Driver GPS State
  Map<String, DriverLocationModel> _liveDriverLocations = {};
  RealtimeChannel? _driverLocationsChannel;
  RealtimeChannel? _profilesChannel;
  bool _isConnectingRealtime = true;
  bool _isSavingGeofence = false;

  // Interactivity state
  String _customerSearchQuery = '';

  // Overlay Toggles
  bool _showCustomers = true;
  bool _showDrivers = true;
  bool _showGeofence = true;
  bool _showRoutes = true;

  // Selected Item details modal / drawer
  dynamic _selectedItem;
  String _selectedItemType = ''; // 'customer', 'driver', 'station'

  @override
  void initState() {
    super.initState();
    if (widget.initialFocusCustomer != null) {
      _selectedItem = widget.initialFocusCustomer;
      _selectedItemType = 'customer';
    }
    _loadInitialStationSettings();
    _fetchInitialDriverLocations();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _driverLocationsChannel?.unsubscribe();
    _profilesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadInitialStationSettings() async {
    setState(() {
      _stationCenter = LatLng(
        SupabaseService.stationLatitude,
        SupabaseService.stationLongitude,
      );
      _stationName = SupabaseService.stationName;
      _stationAddress = SupabaseService.stationAddress;
      _geofenceRadiusKm = SupabaseService.stationGeofenceRadiusKm;
    });

    try {
      final settings = await SupabaseService.fetchStationSettings();
      if (mounted) {
        setState(() {
          _stationCenter = LatLng(
            (settings['latitude'] as num?)?.toDouble() ?? SupabaseService.stationLatitude,
            (settings['longitude'] as num?)?.toDouble() ?? SupabaseService.stationLongitude,
          );
          _stationName = settings['station_name']?.toString() ?? SupabaseService.stationName;
          _stationAddress = settings['address']?.toString() ?? SupabaseService.stationAddress;
          _geofenceRadiusKm = (settings['geofence_radius_km'] as num?)?.toDouble() ??
              (settings['radius_km'] as num?)?.toDouble() ??
              SupabaseService.stationGeofenceRadiusKm;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchInitialDriverLocations() async {
    try {
      final locs = await SupabaseService.fetchDriverLocations();
      if (mounted) {
        setState(() {
          _liveDriverLocations = locs;
          _isConnectingRealtime = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnectingRealtime = false;
        });
      }
    }
  }

  void _setupRealtimeSubscriptions() {
    try {
      _driverLocationsChannel = SupabaseService.subscribeToDriverLocations((loc) {
        if (!mounted) return;
        setState(() {
          _liveDriverLocations[loc.driverId] = loc;
        });
      });

      _profilesChannel = SupabaseService.subscribeToTableChanges(
        channelName: 'public:profiles_live_map',
        table: 'profiles',
        onData: (payload) {
          if (!mounted) return;
          final rec = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
          if (rec.isNotEmpty && rec['role']?.toString().toLowerCase() == 'driver') {
            final driverId = rec['id']?.toString() ?? '';
            final lat = (rec['latitude'] as num?)?.toDouble() ?? double.tryParse(rec['latitude']?.toString() ?? '');
            final lng = (rec['longitude'] as num?)?.toDouble() ?? double.tryParse(rec['longitude']?.toString() ?? '');
            if (driverId.isNotEmpty && lat != null && lng != null) {
              setState(() {
                _liveDriverLocations[driverId] = DriverLocationModel(
                  driverId: driverId,
                  latitude: lat,
                  longitude: lng,
                  isOnline: rec['is_archived'] != true,
                  updatedAt: DateTime.now(),
                );
              });
            }
          }
        },
      );
    } catch (_) {}
  }

  LatLng _getDriverPosition(DriverModel driver) {
    if (_liveDriverLocations.containsKey(driver.id)) {
      final loc = _liveDriverLocations[driver.id]!;
      return LatLng(loc.latitude, loc.longitude);
    }
    if (driver.latitude != 14.2289 || driver.longitude != 121.3283) {
      return LatLng(driver.latitude, driver.longitude);
    }
    return _stationCenter;
  }

  double _calculateDistanceInKm(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, p1, p2);
  }

  Future<void> _saveStationConfigurationToDb({bool showSuccessToast = true}) async {
    if (_isSavingGeofence) return;
    if (mounted) setState(() => _isSavingGeofence = true);

    try {
      final saved = await SupabaseService.saveStationSettings(
        latitude: _stationCenter.latitude,
        longitude: _stationCenter.longitude,
        geofenceRadiusKm: _geofenceRadiusKm,
        name: _stationName,
        address: _stationAddress,
        enforceGeofence: SupabaseService.enforceGeofenceRadius,
      );

      if (mounted) {
        setState(() => _isSavingGeofence = false);
        if (saved) {
          if (showSuccessToast) {
            SweetAlert.showToast(
              'Station location & geofence radius (${_geofenceRadiusKm.toStringAsFixed(1)} km) saved to database!',
              type: SweetAlertType.success,
            );
          }
        } else {
          SweetAlert.showToast(
            'Updated in local station memory.',
            type: SweetAlertType.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingGeofence = false);
        SweetAlert.showToast('Failed to save settings: $e', type: SweetAlertType.error);
      }
    }
  }

  void _showCustomerDetailsDialog(CustomerModel customer) {
    final customerOrders = widget.orders.where((o) =>
        o.customer.toLowerCase().trim() == customer.fullName.toLowerCase().trim() ||
        customer.fullName.toLowerCase().contains(o.customer.toLowerCase()) ||
        o.customer.toLowerCase().contains(customer.fullName.toLowerCase())).toList();

    final totalOrders = customerOrders.length;
    final completedOrders = customerOrders.where((o) {
      final s = o.status.toLowerCase();
      return s == 'completed' || s == 'delivered';
    }).length;

    int purchasedGallons = 0;
    for (var o in customerOrders) {
      purchasedGallons += o.qty;
    }

    showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(
        customer: customer,
        purchasedGallons: purchasedGallons,
        totalOrders: totalOrders,
        completedOrders: completedOrders,
      ),
    );
  }

  void _showDriverDetailsDialog(DriverModel driver) {
    final driverDeliveries = widget.deliveries.where((d) =>
        d.driverName.toLowerCase().trim() == driver.fullName.toLowerCase().trim() ||
        driver.fullName.toLowerCase().contains(d.driverName.toLowerCase()) ||
        d.driverName.toLowerCase().contains(driver.fullName.toLowerCase())).toList();

    final totalDeliveries = driverDeliveries.length;
    final completedDeliveries = driverDeliveries.where((d) {
      final s = d.status.toLowerCase();
      return s == 'completed' || s == 'delivered';
    }).length;

    final activeDeliveries = driverDeliveries.where((d) {
      final s = d.status.toLowerCase();
      return s.contains('out') || s.contains('assigned') || s.contains('accepted') || s.contains('in progress');
    }).length;

    showDialog(
      context: context,
      builder: (context) => DriverDetailsDialog(
        driver: driver,
        totalDeliveries: totalDeliveries,
        completedDeliveries: completedDeliveries,
        activeDeliveries: activeDeliveries,
      ),
    );
  }

  void _openEditStationModal() {
    final nameCtrl = TextEditingController(text: _stationName);
    final addressCtrl = TextEditingController(text: _stationAddress);
    final latCtrl = TextEditingController(text: _stationCenter.latitude.toStringAsFixed(5));
    final lngCtrl = TextEditingController(text: _stationCenter.longitude.toStringAsFixed(5));
    final radiusCtrl = TextEditingController(text: _geofenceRadiusKm.toStringAsFixed(1));

    LatLng modalStationCenter = LatLng(_stationCenter.latitude, _stationCenter.longitude);
    double modalRadius = _geofenceRadiusKm;
    final MapController modalMapController = MapController();
    bool isGeocoding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dialogWidth = (MediaQuery.of(context).size.width * 0.75).clamp(550.0, 720.0);

            return AlertDialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
              ),
              title: const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Configure Station & Geofence',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: dialogWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set the main water refill station coordinates and operational service boundary radius. Click or tap anywhere on the map below to pin the station location.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                      ),
                      const SizedBox(height: 14),

                      // ENLARGED INTERACTIVE MAP PICKER FOR STATION LOCATION
                      Container(
                        height: 380,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: modalMapController,
                                options: MapOptions(
                                  initialCenter: modalStationCenter,
                                  initialZoom: 13.5,
                                  minZoom: 8.0,
                                  maxZoom: 18.0,
                                  onTap: (_, point) async {
                                    setModalState(() {
                                      modalStationCenter = point;
                                      latCtrl.text = point.latitude.toStringAsFixed(5);
                                      lngCtrl.text = point.longitude.toStringAsFixed(5);
                                      isGeocoding = true;
                                    });
                                    final revAddress = await LocationHelper.reverseGeocode(point.latitude, point.longitude);
                                    setModalState(() {
                                      isGeocoding = false;
                                      if (revAddress != null && revAddress.isNotEmpty) {
                                        addressCtrl.text = revAddress;
                                      }
                                    });
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.aquasync.admin',
                                  ),
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: modalStationCenter,
                                        radius: modalRadius * 1000,
                                        useRadiusInMeter: true,
                                        color: const Color(0x280284C7),
                                        borderColor: const Color(0xFF38BDF8),
                                        borderStrokeWidth: 2.0,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: modalStationCenter,
                                        width: 48,
                                        height: 48,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0284C7),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2.5),
                                            boxShadow: const [
                                              BoxShadow(color: Color(0x660284C7), blurRadius: 12, spreadRadius: 2),
                                            ],
                                          ),
                                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Map Instruction Overlay Badge
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFA082A45),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x3838BDF8)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF38BDF8)),
                                      const SizedBox(width: 6),
                                      Text(
                                        isGeocoding ? 'Fetching address...' : 'Click/Tap anywhere on map to pin station location',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Zoom Controls Overlay (+ / -)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        final currentZoom = modalMapController.camera.zoom;
                                        modalMapController.move(modalStationCenter, (currentZoom + 1.0).clamp(8.0, 18.0));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFA082A45),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          border: Border.all(color: const Color(0x3838BDF8)),
                                        ),
                                        child: const Icon(Icons.add, size: 18, color: Colors.white),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final currentZoom = modalMapController.camera.zoom;
                                        modalMapController.move(modalStationCenter, (currentZoom - 1.0).clamp(8.0, 18.0));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFA082A45),
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                          border: Border.all(color: const Color(0x3838BDF8)),
                                        ),
                                        child: const Icon(Icons.remove, size: 18, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Pinned Lat / Lng Badge
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFA082A45),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x3838BDF8)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.pin_drop_rounded, size: 13, color: Color(0xFF34D399)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pinned: ${modalStationCenter.latitude.toStringAsFixed(4)}, ${modalStationCenter.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildDialogTextField(
                        'Station Name',
                        nameCtrl,
                        Icons.business_rounded,
                        'e.g. Aqua Pure Water Station',
                      ),
                      const SizedBox(height: 12),
                      _buildDialogTextField(
                        'Station Address / Area',
                        addressCtrl,
                        Icons.location_on_rounded,
                        'e.g. Victoria, Laguna',
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDialogTextField(
                              'Latitude',
                              latCtrl,
                              Icons.my_location_rounded,
                              '14.2289',
                              isNumber: true,
                              onChanged: (val) {
                                final parsedLat = double.tryParse(val.trim());
                                if (parsedLat != null) {
                                  setModalState(() {
                                    modalStationCenter = LatLng(parsedLat, modalStationCenter.longitude);
                                  });
                                  modalMapController.move(modalStationCenter, modalMapController.camera.zoom);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDialogTextField(
                              'Longitude',
                              lngCtrl,
                              Icons.explore_rounded,
                              '121.3283',
                              isNumber: true,
                              onChanged: (val) {
                                final parsedLng = double.tryParse(val.trim());
                                if (parsedLng != null) {
                                  setModalState(() {
                                    modalStationCenter = LatLng(modalStationCenter.latitude, parsedLng);
                                  });
                                  modalMapController.move(modalStationCenter, modalMapController.camera.zoom);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Interactive Geofence Radius Slider with Live Map Circle Updates
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x801E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4D38BDF8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.radar_rounded, size: 18, color: Color(0xFF38BDF8)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Geofence Service Radius',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x400284C7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                                  ),
                                  child: Text(
                                    '${modalRadius.toStringAsFixed(1)} km (${(modalRadius * 1000).toInt()} m)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF38BDF8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  '0.5 km',
                                  style: TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: const SliderThemeData(
                                      activeTrackColor: Color(0xFF38BDF8),
                                      inactiveTrackColor: Color(0xFF334155),
                                      thumbColor: Color(0xFF38BDF8),
                                      overlayColor: Color(0x3338BDF8),
                                      valueIndicatorColor: Color(0xFF0284C7),
                                      valueIndicatorTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      trackHeight: 6,
                                    ),
                                    child: Slider(
                                      value: modalRadius.clamp(0.5, 30.0),
                                      min: 0.5,
                                      max: 30.0,
                                      divisions: 59,
                                      label: '${modalRadius.toStringAsFixed(1)} km',
                                      onChanged: (val) {
                                        setModalState(() {
                                          modalRadius = double.parse(val.toStringAsFixed(1));
                                          radiusCtrl.text = modalRadius.toStringAsFixed(1);
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const Text(
                                  '30.0 km',
                                  style: TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 80,
                                  height: 38,
                                  child: TextField(
                                    controller: radiusCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      suffixText: 'km',
                                      suffixStyle: const TextStyle(color: Color(0x80FFFFFF), fontSize: 10),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      filled: true,
                                      fillColor: const Color(0xFF0F172A),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF334155)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final parsedRad = double.tryParse(val.trim());
                                      if (parsedRad != null && parsedRad > 0) {
                                        setModalState(() {
                                          modalRadius = parsedRad.clamp(0.5, 50.0);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [0.5, 1.0, 2.0, 3.0, 5.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0].map((preset) {
                                  final isSelected = (modalRadius - preset).abs() < 0.05;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          modalRadius = preset;
                                          radiusCtrl.text = preset.toStringAsFixed(1);
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                                          ),
                                        ),
                                        child: Text(
                                          '${preset < 1 ? preset.toStringAsFixed(1) : preset.toInt()} km',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Apply & Save DB'),
                  onPressed: () async {
                    final lat = double.tryParse(latCtrl.text.trim()) ?? modalStationCenter.latitude;
                    final lng = double.tryParse(lngCtrl.text.trim()) ?? modalStationCenter.longitude;
                    final rad = double.tryParse(radiusCtrl.text.trim()) ?? modalRadius;

                    setState(() {
                      _stationName = nameCtrl.text.trim().isEmpty ? 'Aqua Pure Water Station' : nameCtrl.text.trim();
                      _stationAddress = addressCtrl.text.trim().isEmpty ? 'Victoria, Laguna' : addressCtrl.text.trim();
                      _stationCenter = LatLng(lat, lng);
                      _geofenceRadiusKm = rad.clamp(0.5, 50.0);
                      SupabaseService.setGeofenceRadiusKm(_geofenceRadiusKm);
                    });

                    _mapController.move(_stationCenter, 13.5);
                    Navigator.pop(context);
                    await _saveStationConfigurationToDb(showSuccessToast: true);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isNumber = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFF38BDF8), size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
          ),
        ),
      ],
    );
  }


  Widget _buildPremiumFilterChip(String label, bool value, IconData icon, ValueChanged<bool> onChanged) {
    return FilterChip(
      selected: value,
      showCheckmark: false,
      avatar: Icon(icon, size: 16, color: value ? Colors.white : const Color(0xFF38BDF8)),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: value ? FontWeight.bold : FontWeight.w500, color: value ? Colors.white : const Color(0xFFBAE6FD))),
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: value ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.15), width: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onChanged,
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return AppSummaryCard(
      label: label,
      value: value,
      icon: icon,
      accentColor: const Color(0xFF38BDF8),
      onTap: onTap,
    );
  }

  List<Marker> _buildMapMarkers() {
    final List<Marker> markers = [];

    // 1. Main Water Station Center Marker
    markers.add(
      Marker(
        point: _stationCenter,
        width: 65,
        height: 65,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedItem = null;
              _selectedItemType = 'station';
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.0),
              boxShadow: const [
                BoxShadow(color: Color(0x800284C7), blurRadius: 18, spreadRadius: 3, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );

    // 2. Customer Residence Markers
    if (_showCustomers) {
      for (var cust in widget.customers) {
        final custPos = LatLng(cust.latitude, cust.longitude);
        final distFromStation = _calculateDistanceInKm(_stationCenter, custPos);
        final isWithinGeofence = distFromStation <= _geofenceRadiusKm;

        markers.add(
          Marker(
            point: custPos,
            width: 42,
            height: 42,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedItem = cust;
                  _selectedItemType = 'customer';
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isWithinGeofence ? const Color(0xFF10B981) : const Color(0xFFD97706),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        );
      }
    }

    // 3. Driver Real-time GPS Pins
    if (_showDrivers) {
      final Set<String> processedDriverIds = {};

      for (var driver in widget.drivers) {
        processedDriverIds.add(driver.id);
        final liveLoc = _liveDriverLocations[driver.id];
        final livePos = _getDriverPosition(driver);
        final hasLiveFix = liveLoc != null;

        DeliveryModel? activeDelivery;
        CustomerModel? activeCustomer;

        for (var del in widget.deliveries) {
          final isOut = del.status.toLowerCase().contains('out') ||
              del.status.toLowerCase().contains('accepted') ||
              del.status.toLowerCase().contains('assigned');
          if (!isOut) continue;

          if (del.driverName.toLowerCase().contains(driver.fullName.toLowerCase()) ||
              driver.fullName.toLowerCase().contains(del.driverName.toLowerCase())) {
            activeDelivery = del;
            activeCustomer = widget.customers.firstWhere(
              (c) => c.fullName.toLowerCase().contains(del.customerName.toLowerCase()) ||
                  del.customerName.toLowerCase().contains(c.fullName.toLowerCase()),
              orElse: () => CustomerModel(
                id: 'c1',
                fullName: del.customerName,
                phone: '—',
                address: 'Victoria, Laguna',
                rfidUid: '',
                isRfidActive: false,
                isActive: true,
                createdAt: '',
                latitude: _stationCenter.latitude + 0.005,
                longitude: _stationCenter.longitude + 0.005,
              ),
            );
            break;
          }
        }

        markers.add(
          Marker(
            point: livePos,
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedItem = {
                    'driver': driver,
                    'liveLocation': liveLoc,
                    'position': livePos,
                    'delivery': activeDelivery,
                    'customer': activeCustomer,
                  };
                  _selectedItemType = 'driver';
                });
              },
              child: Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: activeDelivery != null ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: hasLiveFix ? const Color(0x9910B981) : const Color(0x660284C7),
                          blurRadius: hasLiveFix ? 16 : 10,
                          spreadRadius: hasLiveFix ? 2 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: hasLiveFix ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Render fallback for any live driver location entries in Supabase not in widget.drivers list
      for (var entry in _liveDriverLocations.entries) {
        if (processedDriverIds.contains(entry.key)) continue;
        final loc = entry.value;
        final livePos = LatLng(loc.latitude, loc.longitude);
        final fallbackDriver = DriverModel(
          id: entry.key,
          fullName: 'Driver (${entry.key.substring(0, entry.key.length > 6 ? 6 : entry.key.length)})',
          isActive: loc.isOnline,
          createdAt: '',
          latitude: loc.latitude,
          longitude: loc.longitude,
        );

        markers.add(
          Marker(
            point: livePos,
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedItem = {
                    'driver': fallbackDriver,
                    'liveLocation': loc,
                    'position': livePos,
                    'delivery': null,
                    'customer': null,
                  };
                  _selectedItemType = 'driver';
                });
              },
              child: Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x9910B981), blurRadius: 16, spreadRadius: 2, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Polyline> _buildRoutePolylines() {
    if (!_showRoutes) return [];
    final List<Polyline> lines = [];

    for (var del in widget.deliveries) {
      final isOut = del.status.toLowerCase().contains('out') ||
          del.status.toLowerCase().contains('accepted') ||
          del.status.toLowerCase().contains('assigned');
      if (!isOut) continue;

      final customer = widget.customers.firstWhere(
        (c) => c.fullName.toLowerCase().contains(del.customerName.toLowerCase()) ||
            del.customerName.toLowerCase().contains(c.fullName.toLowerCase()),
        orElse: () => CustomerModel(
          id: 'c1',
          fullName: del.customerName,
          phone: '—',
          address: 'Victoria, Laguna',
          rfidUid: '',
          isRfidActive: false,
          isActive: true,
          createdAt: '',
          latitude: _stationCenter.latitude + 0.005,
          longitude: _stationCenter.longitude + 0.005,
        ),
      );

      final targetPos = LatLng(customer.latitude, customer.longitude);

      final driver = widget.drivers.firstWhere(
        (d) => d.fullName.toLowerCase().contains(del.driverName.toLowerCase()) ||
            del.driverName.toLowerCase().contains(d.fullName.toLowerCase()),
        orElse: () => DriverModel(
          id: 'd1',
          fullName: del.driverName,
          isActive: true,
          createdAt: '',
          latitude: _stationCenter.latitude,
          longitude: _stationCenter.longitude,
        ),
      );

      final startPos = _getDriverPosition(driver);
      final points = LocationHelper.getRoutePoints(startPos, targetPos);

      lines.add(
        Polyline(
          points: points,
          strokeWidth: 3.5,
          color: const Color(0xFF38BDF8).withValues(alpha: 0.85),
        ),
      );
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double pagePadding = screenWidth >= 1200
        ? 28.0
        : screenWidth >= 768
            ? 20.0
            : 12.0;

    int activeDispatches = widget.deliveries
        .where((d) => d.status.toLowerCase().contains('out') ||
            d.status.toLowerCase().contains('accepted') ||
            d.status.toLowerCase().contains('assigned'))
        .length;

    int outOfBoundaryCustomers = widget.customers
        .where((c) => _calculateDistanceInKm(_stationCenter, LatLng(c.latitude, c.longitude)) > _geofenceRadiusKm)
        .length;

    final filteredCustomers = widget.customers.where((c) {
      if (_customerSearchQuery.isEmpty) return true;
      final q = _customerSearchQuery.toLowerCase();
      return c.fullName.toLowerCase().contains(q) || c.address.toLowerCase().contains(q);
    }).toList();

    Widget summaryStrip = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'Station Center',
                  value: _stationAddress,
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF38BDF8),
                  onTap: _openEditStationModal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Proximity Geofence',
                  value: '${_geofenceRadiusKm.toStringAsFixed(1)} km Radius',
                  icon: Icons.radar_rounded,
                  color: const Color(0xFF7DD3FC),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Active Dispatches',
                  value: '$activeDispatches Live Tracks',
                  icon: Icons.two_wheeler_rounded,
                  color: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  label: 'Boundary Flagged',
                  value: '$outOfBoundaryCustomers Outside',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFCD34D),
                ),
              ),
            ],
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _buildSummaryCard(
                  label: 'Station',
                  value: _stationAddress,
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF38BDF8),
                  onTap: _openEditStationModal,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _buildSummaryCard(
                  label: 'Geofence',
                  value: '${_geofenceRadiusKm.toStringAsFixed(1)} km',
                  icon: Icons.radar_rounded,
                  color: const Color(0xFF7DD3FC),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _buildSummaryCard(
                  label: 'Dispatches',
                  value: '$activeDispatches Live',
                  icon: Icons.two_wheeler_rounded,
                  color: const Color(0xFF34D399),
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: _buildSummaryCard(
                  label: 'Flagged',
                  value: '$outOfBoundaryCustomers Outside',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFCD34D),
                ),
              ),
            ],
          );
        }
      },
    );

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Map Tracking & Geofence Control',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                    const SizedBox(height: 4),
                    Text(
                      'Interactive map with $_stationName station location, operational boundary radius, live drivers, and customer residence pins.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5A5E63)),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openEditStationModal,
                    icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                    label: const Text('Configure Station'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _loadInitialStationSettings();
                      _fetchInitialDriverLocations();
                      widget.onRefresh();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          summaryStrip,
          const SizedBox(height: 16),

          // Main Canvas Layout
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 950;

                final mapWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.0),
                      boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 6))],
                    ),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: widget.initialFocusCustomer != null 
                                ? LatLng(widget.initialFocusCustomer!.latitude, widget.initialFocusCustomer!.longitude) 
                                : _stationCenter,
                            initialZoom: widget.initialFocusCustomer != null ? 16.0 : 13.5,
                            minZoom: 9.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.aquasync.admin',
                            ),
                            if (_showGeofence)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _stationCenter,
                                    radius: _geofenceRadiusKm * 1000,
                                    useRadiusInMeter: true,
                                    color: const Color(0x280284C7),
                                    borderColor: const Color(0xFF38BDF8),
                                    borderStrokeWidth: 2.0,
                                  ),
                                ],
                              ),
                            PolylineLayer(
                              polylines: _buildRoutePolylines(),
                            ),
                            MarkerLayer(
                              markers: _buildMapMarkers(),
                            ),
                          ],
                        ),

                        // Floating Map Quick Control Badge & Realtime Indicator
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFA082A45),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x3838BDF8)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.water_drop_rounded, size: 18, color: Color(0xFF38BDF8)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_stationName Center',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF38BDF8)),
                                      tooltip: 'Recenter on Station',
                                      onPressed: () {
                                        _mapController.move(_stationCenter, 13.5);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFA0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isConnectingRealtime
                                          ? 'Connecting Supabase Realtime...'
                                          : 'REALTIME SUPABASE ACTIVE (${_liveDriverLocations.length} Drivers Tracked)',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selected Item Overlay Drawer
                        if (_selectedItemType.isNotEmpty)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFA082A45),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.2),
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 6)),
                                    ],
                                  ),
                                  child: Builder(builder: (context) {
                                    if (_selectedItemType == 'customer' && _selectedItem is CustomerModel) {
                                      final cust = _selectedItem as CustomerModel;
                                      final custPos = LatLng(cust.latitude, cust.longitude);
                                      final dist = _calculateDistanceInKm(_stationCenter, custPos);
                                      final inside = dist <= _geofenceRadiusKm;

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: inside ? const Color(0x3310B981) : const Color(0x33F59E0B),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: inside ? const Color(0xFF34D399) : const Color(0xFFFCD34D)),
                                                  image: cust.avatarUrl != null && cust.avatarUrl!.isNotEmpty
                                                      ? DecorationImage(image: NetworkImage(cust.avatarUrl!), fit: BoxFit.cover)
                                                      : null,
                                                ),
                                                alignment: Alignment.center,
                                                child: cust.avatarUrl == null || cust.avatarUrl!.isEmpty
                                                    ? Icon(Icons.home_rounded, color: inside ? const Color(0xFF34D399) : const Color(0xFFFCD34D), size: 20)
                                                    : null,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(cust.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: inside ? const Color(0x3310B981) : const Color(0x33F59E0B),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            inside ? 'IN BOUNDARY' : 'OUTSIDE GEOFENCE',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                              color: inside ? const Color(0xFF34D399) : const Color(0xFFFCD34D),
                                                            ),
                                                          ),
                                                        ),
                                                        if (cust.rfidUid.isNotEmpty) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0x3338BDF8),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              'RFID: ${cust.rfidUid}',
                                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Phone: ${cust.phone}  •  ${cust.address} (${dist.toStringAsFixed(2)} km from station)',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedItemType = '';
                                                    _selectedItem = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  _mapController.move(custPos, 16.0);
                                                },
                                                icon: const Icon(Icons.my_location_rounded, size: 14),
                                                label: const Text('Center Map', style: TextStyle(fontSize: 11)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF38BDF8),
                                                  side: const BorderSide(color: Color(0xFF38BDF8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  _showCustomerDetailsDialog(cust);
                                                },
                                                icon: const Icon(Icons.person_search_rounded, size: 14),
                                                label: const Text('View Full Customer Profile & Orders', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0284C7),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    } else if (_selectedItemType == 'driver' && _selectedItem is Map) {
                                      final driver = _selectedItem['driver'] as DriverModel;
                                      final liveLoc = _selectedItem['liveLocation'] as DriverLocationModel?;
                                      final pos = _selectedItem['position'] as LatLng;
                                      final del = _selectedItem['delivery'] as DeliveryModel?;
                                      final hasLiveFix = liveLoc != null;

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: hasLiveFix ? const Color(0x3310B981) : const Color(0x330284C7),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: hasLiveFix ? const Color(0xFF34D399) : const Color(0xFF38BDF8)),
                                                  image: driver.avatarUrl != null && driver.avatarUrl!.isNotEmpty
                                                      ? DecorationImage(image: NetworkImage(driver.avatarUrl!), fit: BoxFit.cover)
                                                      : null,
                                                ),
                                                alignment: Alignment.center,
                                                child: driver.avatarUrl == null || driver.avatarUrl!.isEmpty
                                                    ? Icon(Icons.two_wheeler_rounded, color: hasLiveFix ? const Color(0xFF34D399) : const Color(0xFF38BDF8), size: 20)
                                                    : null,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 16),
                                                        const SizedBox(width: 4),
                                                        Text(driver.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: hasLiveFix ? const Color(0x3310B981) : const Color(0x33F59E0B),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            hasLiveFix ? 'LIVE GPS ONLINE' : 'LAST KNOWN DB POS',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                              color: hasLiveFix ? const Color(0xFF34D399) : const Color(0xFFFCD34D),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Phone: ${driver.phone ?? '—'}  •  Coords: (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'
                                                      '${del != null ? '  •  Dispatched: ${del.orderNumber}' : ''}',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedItemType = '';
                                                    _selectedItem = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  _mapController.move(pos, 16.0);
                                                },
                                                icon: const Icon(Icons.my_location_rounded, size: 14),
                                                label: const Text('Center Map', style: TextStyle(fontSize: 11)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF38BDF8),
                                                  side: const BorderSide(color: Color(0xFF38BDF8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  _showDriverDetailsDialog(driver);
                                                },
                                                icon: const Icon(Icons.badge_rounded, size: 14),
                                                label: const Text('View Full Driver Profile & Stats', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF0284C7),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    } else if (_selectedItemType == 'station') {
                                      return Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: Color(0x330284C7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.water_drop_rounded, color: Color(0xFF38BDF8), size: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.water_drop, color: Colors.white, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text('$_stationName Center', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  ],
                                                ),
                                                Text('Address: $_stationAddress • Radius: ${_geofenceRadiusKm.toStringAsFixed(1)} km',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD))),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _openEditStationModal,
                                            icon: const Icon(Icons.edit_location_alt_rounded, size: 14),
                                            label: const Text('Configure Station', style: TextStyle(fontSize: 11)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0284C7),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              setState(() {
                                                _selectedItemType = '';
                                                _selectedItem = null;
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                final sidePanelWidget = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.30), width: 1.0),
                    boxShadow: const [BoxShadow(color: Color(0x140B1D2A), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Fixed Section: Station & Geofence Control
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0098DA)),
                                    SizedBox(width: 8),
                                    Text('GEOFENCE CONTROL',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF0098DA))),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings_rounded, size: 22, color: Color(0xFF0098DA)),
                                  tooltip: 'Configure Station Coordinates',
                                  onPressed: _openEditStationModal,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Station Info & Coverage Radius Compact Combined Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0098DA).withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.water_drop_rounded, size: 18, color: Color(0xFF0098DA)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_stationName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1D2A))),
                                            const SizedBox(height: 2),
                                            Text('$_stationAddress • (${_stationCenter.latitude.toStringAsFixed(3)}, ${_stationCenter.longitude.toStringAsFixed(3)})',
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF5A5E63))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0098DA).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF0098DA).withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          '${_geofenceRadiusKm.toStringAsFixed(1)} km',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0098DA)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _openEditStationModal,
                                      icon: const Icon(Icons.settings_suggest_rounded, size: 15),
                                      label: const Text('Configure Station & Geofence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0098DA),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(color: Color(0xFFE2E8F0), height: 24),

                            // MAP OVERLAY TOGGLES
                            const Text('MAP OVERLAYS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF0098DA))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildPremiumFilterChip('Geofence', _showGeofence, Icons.radar_rounded, (v) => setState(() => _showGeofence = v)),
                                _buildPremiumFilterChip('Customers', _showCustomers, Icons.home_rounded, (v) => setState(() => _showCustomers = v)),
                                _buildPremiumFilterChip('Drivers', _showDrivers, Icons.two_wheeler_rounded, (v) => setState(() => _showDrivers = v)),
                                _buildPremiumFilterChip('Routes', _showRoutes, Icons.alt_route_rounded, (v) => setState(() => _showRoutes = v)),
                              ],
                            ),

                            const Divider(color: Color(0xFFE2E8F0), height: 24),

                            // REGISTERED CUSTOMERS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('REGISTERED CUSTOMERS',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF0098DA))),
                                Text('${filteredCustomers.length} Total', style: const TextStyle(fontSize: 11, color: Color(0xFF5A5E63))),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Search Box
                            TextField(
                              onChanged: (v) => setState(() => _customerSearchQuery = v),
                              style: const TextStyle(color: Color(0xFF0B1D2A), fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                hintText: 'Search customer name or address...',
                                hintStyle: const TextStyle(color: Color(0xFF5A5E63), fontSize: 12),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0098DA), size: 18),
                                filled: true,
                                fillColor: const Color(0xFFE6F3FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.0)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF5A5E63), width: 0.6)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0098DA), width: 1.5)),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      if (filteredCustomers.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text('No matching customers found.', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cust = filteredCustomers[index];
                              final custPos = LatLng(cust.latitude, cust.longitude);
                              final dist = _calculateDistanceInKm(_stationCenter, custPos);
                              final inside = dist <= _geofenceRadiusKm;
                              final isSelected = _selectedItemType == 'customer' && (_selectedItem is CustomerModel) && (_selectedItem as CustomerModel).id == cust.id;

                              return GestureDetector(
                                onTap: () {
                                  _mapController.move(custPos, 15.5);
                                  setState(() {
                                    _selectedItem = cust;
                                    _selectedItemType = 'customer';
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: inside ? const Color(0x2210B981) : const Color(0x22F59E0B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.home_rounded, size: 16, color: inside ? const Color(0xFF059669) : const Color(0xFFD97706)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cust.fullName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                            const SizedBox(height: 2),
                                            Text('${dist.toStringAsFixed(1)} km • ${cust.address}', maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: inside ? const Color(0x2210B981) : const Color(0x22F59E0B),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          inside ? 'In' : 'Out',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: inside ? const Color(0xFF059669) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: filteredCustomers.length,
                          ),
                        ),
                    ],
                  ),
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 65, child: mapWidget),
                      const SizedBox(width: 16),
                      Expanded(flex: 35, child: sidePanelWidget),
                    ],
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 450, child: mapWidget),
                        const SizedBox(height: 16),
                        SizedBox(height: 550, child: sidePanelWidget),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
