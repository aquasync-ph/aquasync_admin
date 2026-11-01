import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPreset {
  final String name;
  final String barangay;
  final LatLng position;
  final String fullAddress;

  const LocationPreset({
    required this.name,
    required this.barangay,
    required this.position,
    required this.fullAddress,
  });
}

class LocationHelper {
  static const LatLng stationCenter = LatLng(14.2289, 121.3283);

  static const List<LocationPreset> victoriaPresets = [
    LocationPreset(
      name: 'Nanhaya (Station)',
      barangay: 'Nanhaya',
      position: LatLng(14.2289, 121.3283),
      fullAddress: 'AquaSync Station, Nanhaya, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'Bangkulas',
      barangay: 'Bangkulas',
      position: LatLng(14.2265, 121.3230),
      fullAddress: 'Barangay Bangkulas, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'San Francisco',
      barangay: 'San Francisco',
      position: LatLng(14.2312, 121.3315),
      fullAddress: 'Barangay San Francisco, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'Poblacion',
      barangay: 'Poblacion',
      position: LatLng(14.2270, 121.3290),
      fullAddress: 'Poblacion, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'Masapang',
      barangay: 'Masapang',
      position: LatLng(14.2195, 121.3150),
      fullAddress: 'Barangay Masapang, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'San Roque',
      barangay: 'San Roque',
      position: LatLng(14.2350, 121.3350),
      fullAddress: 'Barangay San Roque, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'San Andres',
      barangay: 'San Andres',
      position: LatLng(14.2230, 121.3260),
      fullAddress: 'Barangay San Andres, Victoria, Laguna',
    ),
    LocationPreset(
      name: 'Santa Cruz',
      barangay: 'Santa Cruz',
      position: LatLng(14.2500, 121.4167),
      fullAddress: 'Santa Cruz, Laguna',
    ),
  ];

  /// Forward geocoding: Convert an address string into GPS LatLng
  static Future<LatLng?> geocodeAddress(String queryStr) async {
    final clean = queryStr.trim();
    if (clean.isEmpty) return null;

    // Search query enrichment for Victoria/Laguna context if user typed a short street/barangay
    String searchQuery = clean;
    final lower = clean.toLowerCase();
    if (!lower.contains('laguna') && !lower.contains('philippines')) {
      searchQuery = '$clean, Victoria, Laguna, Philippines';
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=1',
    );

    try {
      final res = await http.get(
        url,
        headers: {
          'User-Agent': 'AquaSyncAdminDashboard/1.0 (com.aquasync.admin)',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    // Fallback: Check local preset matches if online geocoding fails or timed out
    for (var preset in victoriaPresets) {
      if (clean.toLowerCase().contains(preset.barangay.toLowerCase())) {
        return preset.position;
      }
    }

    return null;
  }

  /// Reverse geocoding: Convert GPS LatLng into a readable street/address string
  static Future<String?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
    );

    try {
      final res = await http.get(
        url,
        headers: {
          'User-Agent': 'AquaSyncAdminDashboard/1.0 (com.aquasync.admin)',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final addressObj = data['address'] as Map<String, dynamic>?;
        if (addressObj != null) {
          final road = addressObj['road'] ?? addressObj['pedestrian'] ?? addressObj['suburb'];
          final village = addressObj['village'] ?? addressObj['quarter'] ?? addressObj['neighbourhood'] ?? addressObj['suburb'];
          final town = addressObj['town'] ?? addressObj['city'] ?? addressObj['municipality'] ?? 'Victoria';
          final state = addressObj['state'] ?? 'Laguna';

          final parts = <String>[];
          if (road != null && road.toString().isNotEmpty) parts.add(road.toString());
          if (village != null && village.toString().isNotEmpty && village != road) parts.add(village.toString());
          if (town != null && town.toString().isNotEmpty) parts.add(town.toString());
          if (state != null && state.toString().isNotEmpty) parts.add(state.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
        final displayName = data['display_name']?.toString();
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    // Fallback preset lookup by proximity
    final Distance distance = const Distance();
    LocationPreset? nearest;
    double minKm = double.infinity;

    for (var preset in victoriaPresets) {
      final km = distance.as(LengthUnit.Kilometer, LatLng(lat, lon), preset.position);
      if (km < minKm) {
        minKm = km;
        nearest = preset;
      }
    }

    if (nearest != null && minKm < 1.0) {
      return nearest.fullAddress;
    }

    return 'Pin (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}), Victoria, Laguna';
  }

  static final Map<String, List<LatLng>> routeCache = {};

  /// Generate orthogonal street-grid points (90-degree street turns)
  static List<LatLng> getOrthogonalStreetPoints(LatLng start, LatLng target) {
    final midLon = (start.longitude + target.longitude) / 2;
    return [
      start,
      LatLng(start.latitude, midLon),
      LatLng(target.latitude, midLon),
      target,
    ];
  }

  /// Fetch actual street route from OSRM API
  static Future<List<LatLng>> getStreetRoutePoints(LatLng start, LatLng target) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${target.longitude},${target.latitude}?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coords = geometry['coordinates'] as List?;
          if (coords != null && coords.isNotEmpty) {
            return coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing error: $e');
    }
    return getOrthogonalStreetPoints(start, target);
  }

  /// Get route points (synchronously returns orthogonal or cached street points, fetches OSRM in background)
  static List<LatLng> getRoutePoints(LatLng start, LatLng target) {
    final cacheKey = '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}->${target.latitude.toStringAsFixed(4)},${target.longitude.toStringAsFixed(4)}';
    if (routeCache.containsKey(cacheKey)) {
      return routeCache[cacheKey]!;
    }

    final orthogonal = getOrthogonalStreetPoints(start, target);
    routeCache[cacheKey] = orthogonal;

    getStreetRoutePoints(start, target).then((pts) {
      if (pts.isNotEmpty) {
        routeCache[cacheKey] = pts;
      }
    });

    return orthogonal;
  }
}
