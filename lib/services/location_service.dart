import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

class LocationService {
  Future<GeoPoint> detectUserPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission permanently denied. Enable it in Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return GeoPoint(
      lat: double.parse(position.latitude.toStringAsFixed(6)),
      lng: double.parse(position.longitude.toStringAsFixed(6)),
    );
  }
}

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
