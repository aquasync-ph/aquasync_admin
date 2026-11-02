import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/supabase_service.dart';
import '../../utils/location_helper.dart';
import '../../widgets/widgets.dart';

class SettingsPage extends StatefulWidget {
  final String adminName;
  final DateTime lastSyncTime;
  final VoidCallback? onRefresh;

  const SettingsPage({
    super.key,
    required this.adminName,
    required this.lastSyncTime,
    this.onRefresh,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedCategoryIndex = 0; // 0: All, 1: Station, 2: GCash

  // Station & Location
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _hoursController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;
  late bool _enforceGeofenceRadius;

  // Receipt & Printing
  late TextEditingController _receiptHeaderController;
  late TextEditingController _receiptFooterController;
  late bool _autoPrintReceipt;
  late bool _showQrOnReceipt;

  // GCash Payment & QR Configuration
  late bool _enableGcashPayment;
  late TextEditingController _gcashNameController;
  late TextEditingController _gcashNumberController;
  late TextEditingController _gcashQrImageUrlController;
  late TextEditingController _gcashQrRawStringController;
  bool _isUploadingGcashQr = false;

  // Notifications & Alerts
  late bool _newOrderSound;
  late bool _lowStockSound;
  late bool _driverEmergencySound;
  late int _autoRefreshIntervalSec;

  // Security & Staff
  late bool _requireAdminForDebt;
  late bool _allowCashierDriverAssign;
  late TextEditingController _maxCashierRefundController;
  late bool _requireRfidGallonRelease;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFromService();
    _fetchAndReloadSettings();
  }

  Future<void> _fetchAndReloadSettings() async {
    try {
      await SupabaseService.fetchStationSettings();
      if (mounted) {
        setState(() {
          _updateControllersFromService();
        });
      }
    } catch (_) {}
  }

  void _updateControllersFromService() {
    _nameController.text = SupabaseService.stationName;
    _addressController.text = SupabaseService.stationAddress;
    _phoneController.text = SupabaseService.stationPhone;
    _hoursController.text = SupabaseService.stationHours;
    _latController.text = SupabaseService.stationLatitude.toString();
    _lngController.text = SupabaseService.stationLongitude.toString();
    _radiusController.text = SupabaseService.stationGeofenceRadiusKm.toString();
    _enforceGeofenceRadius = SupabaseService.enforceGeofenceRadius;

    _receiptHeaderController.text = SupabaseService.receiptHeader;
    _receiptFooterController.text = SupabaseService.receiptFooter;
    _autoPrintReceipt = SupabaseService.autoPrintReceipt;
    _showQrOnReceipt = SupabaseService.showQrOnReceipt;

    _enableGcashPayment = SupabaseService.enableGcashPayment;
    _gcashNameController.text = SupabaseService.gcashName;
    _gcashNumberController.text = SupabaseService.gcashNumber;
    _gcashQrImageUrlController.text = SupabaseService.gcashQrImageUrl;
    _gcashQrRawStringController.text = SupabaseService.gcashQrRawString;

    _newOrderSound = SupabaseService.newOrderSound;
    _lowStockSound = SupabaseService.lowStockSound;
    _driverEmergencySound = SupabaseService.driverEmergencySound;
    _autoRefreshIntervalSec = SupabaseService.autoRefreshIntervalSec;

    _requireAdminForDebt = SupabaseService.requireAdminForDebt;
    _allowCashierDriverAssign = SupabaseService.allowCashierDriverAssign;
    _maxCashierRefundController.text = SupabaseService.maxCashierRefundLimit.toStringAsFixed(2);
    _requireRfidGallonRelease = SupabaseService.requireRfidGallonRelease;
  }

  void _loadFromService() {
    _nameController = TextEditingController(text: SupabaseService.stationName);
    _addressController = TextEditingController(text: SupabaseService.stationAddress);
    _phoneController = TextEditingController(text: SupabaseService.stationPhone);
    _hoursController = TextEditingController(text: SupabaseService.stationHours);
    _latController = TextEditingController(text: SupabaseService.stationLatitude.toString());
    _lngController = TextEditingController(text: SupabaseService.stationLongitude.toString());
    _radiusController = TextEditingController(text: SupabaseService.stationGeofenceRadiusKm.toString());
    _enforceGeofenceRadius = SupabaseService.enforceGeofenceRadius;

    _receiptHeaderController = TextEditingController(text: SupabaseService.receiptHeader);
    _receiptFooterController = TextEditingController(text: SupabaseService.receiptFooter);
    _autoPrintReceipt = SupabaseService.autoPrintReceipt;
    _showQrOnReceipt = SupabaseService.showQrOnReceipt;

    _enableGcashPayment = SupabaseService.enableGcashPayment;
    _gcashNameController = TextEditingController(text: SupabaseService.gcashName);
    _gcashNumberController = TextEditingController(text: SupabaseService.gcashNumber);
    _gcashQrImageUrlController = TextEditingController(text: SupabaseService.gcashQrImageUrl);
    _gcashQrRawStringController = TextEditingController(text: SupabaseService.gcashQrRawString);

    _newOrderSound = SupabaseService.newOrderSound;
    _lowStockSound = SupabaseService.lowStockSound;
    _driverEmergencySound = SupabaseService.driverEmergencySound;
    _autoRefreshIntervalSec = SupabaseService.autoRefreshIntervalSec;

    _requireAdminForDebt = SupabaseService.requireAdminForDebt;
    _allowCashierDriverAssign = SupabaseService.allowCashierDriverAssign;
    _maxCashierRefundController = TextEditingController(text: SupabaseService.maxCashierRefundLimit.toStringAsFixed(2));
    _requireRfidGallonRelease = SupabaseService.requireRfidGallonRelease;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();

    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();

    _gcashNameController.dispose();
    _gcashNumberController.dispose();
    _gcashQrImageUrlController.dispose();
    _gcashQrRawStringController.dispose();

    _maxCashierRefundController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    final hours = _hoursController.text.trim();

    final lat = double.tryParse(_latController.text.trim()) ?? SupabaseService.stationLatitude;
    final lng = double.tryParse(_lngController.text.trim()) ?? SupabaseService.stationLongitude;
    final radius = double.tryParse(_radiusController.text.trim()) ?? SupabaseService.stationGeofenceRadiusKm;

    final recHeader = _receiptHeaderController.text.trim();
    final recFooter = _receiptFooterController.text.trim();
    final maxRefund = double.tryParse(_maxCashierRefundController.text.trim()) ?? SupabaseService.maxCashierRefundLimit;

    final gcashName = _gcashNameController.text.trim();
    final gcashNum = _gcashNumberController.text.trim();
    final gcashQrUrl = _gcashQrImageUrlController.text.trim();
    final gcashQrRaw = _gcashQrRawStringController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      SweetAlert.showGlobalError('Station name and address cannot be empty.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await SupabaseService.saveStationSettings(
        latitude: lat,
        longitude: lng,
        geofenceRadiusKm: radius,
        enforceGeofence: _enforceGeofenceRadius,
        name: name,
        address: address,
        phone: phone,
        hours: hours,
        recHeader: recHeader,
        recFooter: recFooter,
        autoPrint: _autoPrintReceipt,
        showQr: _showQrOnReceipt,
        soundOrder: _newOrderSound,
        soundStock: _lowStockSound,
        soundSos: _driverEmergencySound,
        refreshInterval: _autoRefreshIntervalSec,
        adminDebt: _requireAdminForDebt,
        cashierDriverAssign: _allowCashierDriverAssign,
        cashierRefund: maxRefund,
        rfidGallonRelease: _requireRfidGallonRelease,
        enableGcash: _enableGcashPayment,
        gcashAccName: gcashName,
        gcashAccNumber: gcashNum,
        gcashQrUrl: gcashQrUrl,
        gcashQrRaw: gcashQrRaw,
      );

      if (success) {
        SweetAlert.showGlobalSuccess('Station & System settings updated successfully!');
        widget.onRefresh?.call();
      } else {
        SweetAlert.showGlobalError('Failed to save settings to Supabase database.');
      }
    } catch (e) {
      SweetAlert.showGlobalError('Error saving settings: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetToDefaults() {
    setState(() {
      _nameController.text = 'Aqua Pure Water Station';
      _addressController.text = 'Victoria, Laguna';
      _phoneController.text = '+63 917 888 9999';
      _hoursController.text = '07:00 AM - 06:00 PM';
      _latController.text = '14.2289';
      _lngController.text = '121.3283';
      _radiusController.text = '8.0';
      _enforceGeofenceRadius = true;

      _receiptHeaderController.text = 'Aqua Pure Water Refilling Station';
      _receiptFooterController.text = 'Thank you for choosing AquaSync! Safe & Clean Water Always.';
      _autoPrintReceipt = true;
      _showQrOnReceipt = true;

      _enableGcashPayment = true;
      _gcashNameController.text = 'Aqua Pure Water Station';
      _gcashNumberController.text = '+63 917 888 9999';
      _gcashQrImageUrlController.text = '';
      _gcashQrRawStringController.text = '';

      _newOrderSound = true;
      _lowStockSound = true;
      _driverEmergencySound = true;
      _autoRefreshIntervalSec = 30;

      _requireAdminForDebt = false;
      _allowCashierDriverAssign = true;
      _maxCashierRefundController.text = '1000.00';
      _requireRfidGallonRelease = true;
    });
    SweetAlert.showToast('Reset input fields to recommended defaults.', type: SweetAlertType.info);
  }

  Future<void> _pickAndUploadGcashQrImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _isUploadingGcashQr = true);

        final uploadedUrl = await SupabaseService.uploadGcashQrImage(file);

        setState(() {
          _gcashQrImageUrlController.text = uploadedUrl;
        });

        SweetAlert.showGlobalSuccess('GCash QR image uploaded successfully!');
      }
    } catch (e) {
      SweetAlert.showGlobalError('Failed to upload GCash QR image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingGcashQr = false);
    }
  }

  void _openMapPickerModal() {
    double initLat = double.tryParse(_latController.text.trim()) ?? SupabaseService.stationLatitude;
    double initLng = double.tryParse(_lngController.text.trim()) ?? SupabaseService.stationLongitude;
    double initRadius = double.tryParse(_radiusController.text.trim()) ?? SupabaseService.stationGeofenceRadiusKm;

    LatLng tempPos = LatLng(initLat, initLng);
    double tempRadius = initRadius;
    final MapController modalMapCtrl = MapController();
    bool isGeocoding = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1.2),
              ),
              title: const Row(
                children: [
                  Icon(Icons.pin_drop_rounded, color: Color(0xFF0284C7), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Pin Business Station Location',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Click or tap anywhere on the map below to pin your refill station coordinates.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Color(0x20000000), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: modalMapCtrl,
                                options: MapOptions(
                                  initialCenter: tempPos,
                                  initialZoom: 14.0,
                                  onTap: (_, point) async {
                                    setModalState(() {
                                      tempPos = point;
                                      isGeocoding = true;
                                    });
                                    final rev = await LocationHelper.reverseGeocode(point.latitude, point.longitude);
                                    setModalState(() {
                                      isGeocoding = false;
                                      if (rev != null && rev.isNotEmpty) {
                                        _addressController.text = rev;
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
                                        point: tempPos,
                                        radius: tempRadius * 1000,
                                        useRadiusInMeter: true,
                                        color: const Color(0x280284C7),
                                        borderColor: const Color(0xFF0284C7),
                                        borderStrokeWidth: 2.0,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: tempPos,
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
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 6),
                                      Text(
                                        isGeocoding ? 'Fetching address...' : 'Click/Tap anywhere on map to pin station location',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.pin_drop_rounded, size: 13, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pinned: ${tempPos.latitude.toStringAsFixed(4)}, ${tempPos.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Interactive Geofence Radius Slider
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.radar_rounded, size: 16, color: Color(0xFF0284C7)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Geofence Coverage Radius',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF0284C7), width: 1.0),
                                  ),
                                  child: Text(
                                    '${tempRadius.toStringAsFixed(1)} km (${(tempRadius * 1000).toInt()} m)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text(
                                  '0.5 km',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: const SliderThemeData(
                                      activeTrackColor: Color(0xFF0284C7),
                                      inactiveTrackColor: Color(0xFFE2E8F0),
                                      thumbColor: Color(0xFF0284C7),
                                      overlayColor: Color(0x330284C7),
                                      valueIndicatorColor: Color(0xFF0284C7),
                                      valueIndicatorTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      trackHeight: 5,
                                    ),
                                    child: Slider(
                                      value: tempRadius.clamp(0.5, 30.0),
                                      min: 0.5,
                                      max: 30.0,
                                      divisions: 59,
                                      label: '${tempRadius.toStringAsFixed(1)} km',
                                      onChanged: (val) {
                                        setModalState(() {
                                          tempRadius = double.parse(val.toStringAsFixed(1));
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const Text(
                                  '30.0 km',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [0.5, 1.0, 2.0, 3.0, 5.0, 8.0, 10.0, 15.0, 20.0, 25.0, 30.0].map((preset) {
                                  final isSelected = (tempRadius - preset).abs() < 0.05;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          tempRadius = preset;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          '${preset < 1 ? preset.toStringAsFixed(1) : preset.toInt()} km',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : const Color(0xFF475569),
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
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569))),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Apply Coordinates'),
                  onPressed: () {
                    setState(() {
                      _latController.text = tempPos.latitude.toStringAsFixed(5);
                      _lngController.text = tempPos.longitude.toStringAsFixed(5);
                      _radiusController.text = tempRadius.toStringAsFixed(1);
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    String? hintText,
    String? suffixText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          suffixText: suffixText,
          suffixStyle: const TextStyle(color: Color(0xFF0284C7), fontSize: 12),
          hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
          labelStyle: const TextStyle(color: Color(0xFF0284C7), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFFE0F2FE),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
    Color iconColor = const Color(0xFF0284C7),
    VoidCallback? onTest,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
              ],
            ),
          ),
          if (onTest != null) ...[
            TextButton.icon(
              onPressed: onTest,
              icon: const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF0284C7)),
              label: const Text('Test', style: TextStyle(color: Color(0xFF0284C7), fontSize: 11)),
            ),
            const SizedBox(width: 8),
          ],
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF0284C7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(int index, String title, IconData icon) {
    final isSelected = _selectedCategoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0284C7).withValues(alpha: 0.3),
          ),
          boxShadow: [BoxShadow(color: const Color(0x0A000000), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF0284C7)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(16),
      accentColor: iconColor,
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
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

    final showAll = _selectedCategoryIndex == 0;

    return Padding(
      padding: EdgeInsets.all(pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System & Station Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    SizedBox(height: 4),
                    Text('Configure station parameters, delivery operational rules, and GCash payment QR details.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0284C7),
                      side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Refresh Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0284C7),
                      side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_isSaving ? 'Saving...' : 'Save All Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Category Pills Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill(0, 'All Settings', Icons.grid_view_rounded),
                _buildCategoryPill(1, 'Station & Location', Icons.storefront_rounded),
                _buildCategoryPill(2, 'GCash & Payment QR', Icons.qr_code_scanner_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: STATION IDENTIFICATION & LOCATION
                  if (showAll || _selectedCategoryIndex == 1)
                    _buildCardContainer(
                      title: 'STATION IDENTIFICATION & LOCATION',
                      icon: Icons.storefront_rounded,
                      iconColor: const Color(0xFF0284C7),
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Station Name', _nameController, hintText: 'Aqua Pure Water Station')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Station Phone / Contact', _phoneController, hintText: '+63 917 888 9999')),
                          ],
                        ),
                        _buildTextField('Station Address & Landmark', _addressController, hintText: 'Victoria, Laguna'),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Operating Hours', _hoursController, hintText: '07:00 AM - 06:00 PM')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                'Geofence Radius (km)',
                                _radiusController,
                                isNumber: true,
                                suffixText: 'km',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Center Latitude', _latController, isNumber: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField('Center Longitude', _lngController, isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildToggleTile(
                          title: 'Enforce Proximity Radius (Strict Order Acceptance)',
                          subtitle: 'Restrict customer orders on user side to be within the geofence service radius',
                          value: _enforceGeofenceRadius,
                          icon: Icons.radar_rounded,
                          iconColor: const Color(0xFF0284C7),
                          onChanged: (val) => setState(() => _enforceGeofenceRadius = val),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _openMapPickerModal,
                              icon: const Icon(Icons.pin_drop_rounded, size: 16),
                              label: const Text('Pin Station Location on Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _latController.text = '14.2289';
                                  _lngController.text = '121.3283';
                                  _radiusController.text = '8.0';
                                  _addressController.text = 'Victoria, Laguna';
                                });
                                SweetAlert.showToast('Applied Victoria, Laguna preset location!', type: SweetAlertType.success);
                              },
                              icon: const Icon(Icons.my_location_rounded, size: 15, color: Color(0xFF0284C7)),
                              label: const Text('Set Victoria, Laguna Preset', style: TextStyle(color: Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // CARD 2: GCASH & DIGITAL PAYMENT QR SETTINGS
                  if (showAll || _selectedCategoryIndex == 2)
                    _buildCardContainer(
                      title: 'GCASH & DIGITAL PAYMENT QR SETTINGS',
                      icon: Icons.qr_code_scanner_rounded,
                      iconColor: const Color(0xFF0284C7),
                      children: [
                        _buildToggleTile(
                          title: 'Enable GCash Digital Payment Method',
                          subtitle: 'Allow cashiers and mobile app users to select GCash and view payment QR details',
                          value: _enableGcashPayment,
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: const Color(0xFF0284C7),
                          onChanged: (val) => setState(() => _enableGcashPayment = val),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'GCash Account Name / Merchant Name',
                                _gcashNameController,
                                hintText: 'e.g. Aqua Pure Refilling Station',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                'GCash Mobile / Account Number',
                                _gcashNumberController,
                                hintText: 'e.g. 0917 888 9999',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // QR Code Image Upload & Live Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.qr_code_2_rounded, color: Color(0xFF0284C7), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'GCash Payment QR Code Image',
                                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Upload your official GCash Merchant QR screenshot or QR image. This will be saved to Supabase and fetched by cashiers and mobile app customers.',
                                style: TextStyle(color: Color(0xFF475569), fontSize: 11),
                              ),
                              const SizedBox(height: 14),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Live Preview Box
                                  Container(
                                    width: 160,
                                    height: 160,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 1.2),
                                    ),
                                    child: _isUploadingGcashQr
                                        ? const Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                                SizedBox(height: 8),
                                                Text('Uploading QR...', style: TextStyle(color: Color(0xFF475569), fontSize: 10)),
                                              ],
                                            ),
                                          )
                                        : _gcashQrImageUrlController.text.trim().isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _gcashQrImageUrlController.text.trim(),
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, _, _) => const Center(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.broken_image_rounded, color: Colors.amber, size: 28),
                                                        SizedBox(height: 4),
                                                        Text('Invalid Image URL', style: TextStyle(color: Colors.amber, fontSize: 9)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : (_gcashQrRawStringController.text.trim().isNotEmpty || _gcashNumberController.text.trim().isNotEmpty)
                                                ? Center(
                                                    child: QrImageView(
                                                      data: _gcashQrRawStringController.text.trim().isNotEmpty
                                                          ? _gcashQrRawStringController.text.trim()
                                                          : _gcashNumberController.text.trim(),
                                                      version: QrVersions.auto,
                                                      size: 140.0,
                                                      backgroundColor: Colors.white,
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.qr_code_2_rounded, color: Color(0xFF94A3B8), size: 40),
                                                        SizedBox(height: 6),
                                                        Text('No QR Code Uploaded', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                                                      ],
                                                    ),
                                                  ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Actions and Options
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _isUploadingGcashQr ? null : _pickAndUploadGcashQrImage,
                                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                                              label: Text(_gcashQrImageUrlController.text.isEmpty ? 'Upload QR Image' : 'Change QR Image'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0284C7),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            if (_gcashQrImageUrlController.text.isNotEmpty)
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  setState(() => _gcashQrImageUrlController.clear());
                                                  SweetAlert.showToast('Cleared GCash QR Image URL.', type: SweetAlertType.info);
                                                },
                                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                                label: const Text('Clear QR Image'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFFDC2626),
                                                  side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          'Direct QR Image Public URL (Optional)',
                                          _gcashQrImageUrlController,
                                          hintText: 'https://.../gcash_qr.png',
                                        ),
                                        _buildTextField(
                                          'Raw QR Payload / GCash Link / Reference Text (Optional)',
                                          _gcashQrRawStringController,
                                          hintText: 'e.g. 00020101021226... or gcash account payload',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Interactive Simulated Card Preview for Cashier & User Apps
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x140284C7), blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0284C7), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text('GCash Payment Live Badge', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                                        SizedBox(width: 8),
                                        Icon(Icons.verified_rounded, color: Color(0xFF0284C7), size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Account Name: ${_gcashNameController.text.trim().isEmpty ? "Not set" : _gcashNameController.text.trim()}',
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Mobile Number: ${_gcashNumberController.text.trim().isEmpty ? "Not set" : _gcashNumberController.text.trim()}',
                                      style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _enableGcashPayment ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _enableGcashPayment ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  _enableGcashPayment ? 'Active on Apps' : 'Disabled',
                                  style: TextStyle(color: _enableGcashPayment ? const Color(0xFF166534) : const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Bottom Save Action Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ready to save your configuration?', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                            SizedBox(height: 2),
                            Text('Changes are saved to Supabase cloud and applied immediately across all station cashiers & drivers.',
                                style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(_isSaving ? 'Saving Changes...' : 'Save Station Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
