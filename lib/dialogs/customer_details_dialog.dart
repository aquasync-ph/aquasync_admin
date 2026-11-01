import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../utils/location_helper.dart';

class CustomerDetailsDialog extends StatelessWidget {
  final CustomerModel customer;
  final int purchasedGallons;
  final int totalOrders;
  final int completedOrders;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
    required this.purchasedGallons,
    required this.totalOrders,
    required this.completedOrders,
  });

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFBAE6FD)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRewardReady = purchasedGallons >= 15;
    final hasRfid = customer.rfidUid.isNotEmpty;

    final customerPos = LatLng(customer.latitude, customer.longitude);
    final Distance distanceCalc = const Distance();
    final double distKm = distanceCalc.as(LengthUnit.Kilometer, LocationHelper.stationCenter, customerPos);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
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
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0x330284C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x4038BDF8)),
                              image: customer.avatarUrl != null && customer.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(customer.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: customer.avatarUrl == null || customer.avatarUrl!.isEmpty
                                ? const Icon(Icons.person_rounded, color: Color(0xFF38BDF8), size: 26)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Customer Profile • ${customer.id.length >= 8 ? customer.id.substring(0, 8) : customer.id}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFBAE6FD)),
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

                  if (isRewardReady) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x6634D399)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.stars_rounded, color: Color(0xFF34D399), size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LOYALTY REWARD READY!',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD1FAE5)),
                                ),
                                Text(
                                  'Customer reached 15 qualifying gallon purchases for reward redemption.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFD1FAE5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // SECTION 1: CUSTOMER INFORMATION
                  const Text(
                    'CUSTOMER INFORMATION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Full Name', customer.fullName, isBold: true),
                        _buildDetailRow('Email Address', customer.email),
                        _buildDetailRow('Phone Number', customer.phone),
                        _buildDetailRow('Delivery Address', customer.address),
                        _buildDetailRow('GPS Pinned Coordinates', '${customer.latitude.toStringAsFixed(4)}, ${customer.longitude.toStringAsFixed(4)}', valueColor: const Color(0xFF38BDF8)),
                        _buildDetailRow('Station Distance', '${distKm.toStringAsFixed(2)} km from Victoria Station'),
                        _buildDetailRow('Registration Date', customer.createdAt),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SECTION 2: MAP PINNED LOCATION
                  const Text(
                    'PINNED DELIVERY LOCATION MAP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x6638BDF8), width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: customerPos,
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.aquasync.admin',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: LocationHelper.getRoutePoints(LocationHelper.stationCenter, customerPos),
                                    color: const Color(0xFF38BDF8),
                                    strokeWidth: 2.5,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  // Station
                                  Marker(
                                    point: LocationHelper.stationCenter,
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                  // Customer Pin
                                  Marker(
                                    point: customerPos,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFA082A45),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x3838BDF8)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distKm.toStringAsFixed(2)} km delivery route',
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

                  const SizedBox(height: 18),

                  // SECTION 3: LOYALTY SUMMARY
                  const Text(
                    'LOYALTY & RFID SUMMARY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Loyalty RFID Card UID', hasRfid ? customer.rfidUid : 'Not Assigned', valueColor: hasRfid ? const Color(0xFF38BDF8) : const Color(0xFFBAE6FD)),
                        _buildDetailRow('Card Active Status', !hasRfid ? 'Unassigned' : customer.isRfidActive ? 'Active' : 'Inactive', valueColor: !hasRfid ? const Color(0xFFBAE6FD) : customer.isRfidActive ? const Color(0xFF34D399) : const Color(0xFFFCA5A5)),
                        _buildDetailRow('Qualifying Gallons Purchased', '$purchasedGallons gallon(s)', isBold: true),
                        _buildDetailRow('Reward Progress', isRewardReady ? '15 / 15 (Reward Ready)' : '$purchasedGallons / 15 gallons', valueColor: isRewardReady ? const Color(0xFF34D399) : Colors.white),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SECTION 4: ORDER SUMMARY
                  const Text(
                    'ORDER HISTORY SUMMARY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF7DD3FC)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Total Station Orders', '$totalOrders'),
                        _buildDetailRow('Completed Deliveries', '$completedOrders', isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          shadowColor: const Color(0x330284C7),
                        ),
                        child: const Text('Close Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
