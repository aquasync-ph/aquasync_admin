import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/supabase_service.dart';
import '../utils/location_helper.dart';

class AddCustomerDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const AddCustomerDialog({
    super.key,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final rfidCtrl = TextEditingController();

  final MapController _mapController = MapController();
  LatLng _pinnedLocation = LocationHelper.stationCenter;

  bool _isSaving = false;
  bool _isGeocoding = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addrCtrl.dispose();
    rfidCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && val.trim().length >= 4) {
        _forwardGeocodeAddress();
      }
    });
  }

  Future<void> _forwardGeocodeAddress() async {
    final query = addrCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _isGeocoding = true);
    final pos = await LocationHelper.geocodeAddress(query);
    if (!mounted) return;
    setState(() => _isGeocoding = false);

    if (pos != null) {
      setState(() => _pinnedLocation = pos);
      _mapController.move(pos, 15.5);
    }
  }

  Future<void> _reverseGeocodeLocation(LatLng pos) async {
    setState(() {
      _pinnedLocation = pos;
      _isGeocoding = true;
    });
    _mapController.move(pos, _mapController.camera.zoom);

    final address = await LocationHelper.reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      if (address != null && address.isNotEmpty) {
        addrCtrl.text = address;
      }
    });
  }

  Future<void> _submit() async {
    final nameStr = nameCtrl.text.trim();
    if (nameStr.isEmpty) {
      widget.onError('Customer Full Name cannot be empty.');
      return;
    }
    if (nameStr.length < 2) {
      widget.onError('Customer Full Name must be at least 2 characters.');
      return;
    }
    if (nameStr.length > 50) {
      widget.onError('Customer Full Name cannot exceed 50 characters.');
      return;
    }

    final phoneStr = phoneCtrl.text.trim();
    if (phoneStr.isNotEmpty && phoneStr.length != 11) {
      widget.onError('Phone number must be exactly 11 digits (e.g. 09171234567).');
      return;
    }

    final emailStr = emailCtrl.text.trim();
    if (emailStr.isNotEmpty && (!emailStr.contains('@') || !emailStr.contains('.'))) {
      widget.onError('Please enter a valid email address.');
      return;
    }
    if (emailStr.length > 80) {
      widget.onError('Email address cannot exceed 80 characters.');
      return;
    }

    final rfidStr = rfidCtrl.text.trim();
    if (rfidStr.length > 30) {
      widget.onError('RFID card UID cannot exceed 30 characters.');
      return;
    }

    final addrStr = addrCtrl.text.trim();
    if (addrStr.length > 150) {
      widget.onError('Address cannot exceed 150 characters.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.createCustomer(
        fullName: nameStr,
        phone: phoneStr,
        address: addrStr.isEmpty
            ? 'Victoria, Laguna (${_pinnedLocation.latitude.toStringAsFixed(4)}, ${_pinnedLocation.longitude.toStringAsFixed(4)})'
            : addrStr,
        email: emailStr,
        latitude: _pinnedLocation.latitude,
        longitude: _pinnedLocation.longitude,
        rfidUid: rfidStr,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            padding: const EdgeInsets.all(24),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF38BDF8), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Register New Customer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Complete profile details & automatic map delivery pinning',
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
                  Divider(height: 24, color: Colors.white.withValues(alpha: 0.18)),

                  // BASIC CUSTOMER DETAILS (2 Columns on wide dialog)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Full Name * (Max 50 chars)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: nameCtrl,
                              maxLength: 50,
                              decoration: InputDecoration(
                                hintText: 'e.g. Maria Santos',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone Number (11 digits)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: phoneCtrl,
                              maxLength: 11,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: 'e.g. 09171234567',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Address (Optional)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: emailCtrl,
                              maxLength: 80,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'e.g. maria@gmail.com',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.email_rounded, size: 18, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Loyalty RFID Card UID (Optional)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: rfidCtrl,
                              maxLength: 30,
                              decoration: InputDecoration(
                                hintText: 'e.g. RFID-8829-X12',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                                prefixIcon: const Icon(Icons.style_rounded, size: 18, color: Color(0xFF7DD3FC)),
                                counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                              ),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // DELIVERY ADDRESS FIELD & AUTO-PIN BUTTON
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Address (Max 150 chars)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_isGeocoding)
                        const Row(
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)))),
                            SizedBox(width: 6),
                            Text('Geocoding location...', style: TextStyle(fontSize: 10, color: Color(0xFF38BDF8))),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: addrCtrl,
                    maxLength: 150,
                    onChanged: _onAddressChanged,
                    decoration: InputDecoration(
                      hintText: 'e.g. House No., Street Name, Barangay, Victoria, Laguna',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
                      prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF7DD3FC)),
                      counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF7DD3FC)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded, color: Color(0xFF38BDF8)),
                        tooltip: 'Pin address on map',
                        onPressed: _forwardGeocodeAddress,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 12),

                  // INTERACTIVE AUTOMATIC PINNING MAP
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x6638BDF8), width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LocationHelper.stationCenter,
                              initialZoom: 14.5,
                              minZoom: 10.0,
                              maxZoom: 18.0,
                              onTap: (_, point) {
                                _reverseGeocodeLocation(point);
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
                                    point: LocationHelper.stationCenter,
                                    radius: 3000, // 3km station radius
                                    useRadiusInMeter: true,
                                    color: const Color(0x1A0284C7),
                                    borderColor: const Color(0xFF0284C7),
                                    borderStrokeWidth: 1.5,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  // Station Marker
                                  Marker(
                                    point: LocationHelper.stationCenter,
                                    width: 36,
                                    height: 36,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                  // Pinned Customer Location Marker
                                  Marker(
                                    point: _pinnedLocation,
                                    width: 44,
                                    height: 44,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.8, end: 1.0),
                                      duration: const Duration(milliseconds: 300),
                                      builder: (context, val, child) {
                                        return Transform.scale(
                                          scale: val,
                                          child: child,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 44,
                                      ),
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
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF38BDF8)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Click/Tap anywhere on map to pin delivery location',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
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
                                  const Icon(Icons.my_location_rounded, size: 13, color: Color(0xFF34D399)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pinned: ${_pinnedLocation.latitude.toStringAsFixed(4)}, ${_pinnedLocation.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SUBMIT BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFFBAE6FD), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                            : const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Register Customer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x330284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
