import 'dart:math' as math;

import '../models/geo_point.dart';

class LocationService {
  Future<GeoPoint> detectUserPosition() async {
    await Future.delayed(const Duration(seconds: 1));
    final random = math.Random();
    final lat = 3.86 + random.nextDouble() * 0.06;
    final lng = 11.48 + random.nextDouble() * 0.07;
    return GeoPoint(
      lat: double.parse(lat.toStringAsFixed(3)),
      lng: double.parse(lng.toStringAsFixed(3)),
    );
  }
}
