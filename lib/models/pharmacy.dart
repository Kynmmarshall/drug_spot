import 'package:flutter/material.dart';

import 'geo_point.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.accent,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final Color accent;

  GeoPoint get point => GeoPoint(lat: lat, lng: lng);
}
