import 'dart:math' as math;

class DistanceCalculator {
  static const double earthRadiusKm = 6371.0;

  /// Calculate distance in kilometers between two geographic coordinates using Haversine formula
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculate distance in meters
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return calculateDistanceKm(
          lat1: lat1,
          lon1: lon1,
          lat2: lat2,
          lon2: lon2,
        ) *
        1000.0;
  }

  /// Formatted human-readable distance label (e.g. "450 m away" or "1.2 km away")
  static String formatDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final km = calculateDistanceKm(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2);
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m away';
    } else {
      return '${km.toStringAsFixed(1)} km away';
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

