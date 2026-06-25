import 'package:flutter/material.dart';

import 'geo_point.dart';

class Pharmacy {
  const Pharmacy({
    required this.id,
    this.userId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.accent,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'].toString(),
      userId: json['user'] as int?,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      phone: json['phone'] as String,
      accent: _parseAccent(json['accent'], json['id'] as int),
    );
  }

  final String id;
  final int? userId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final Color accent;

  GeoPoint get point => GeoPoint(lat: lat, lng: lng);

  static const _palette = [
    Color(0xFF38BDF8),
    Color(0xFFFB7185),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFA78BFA),
    Color(0xFFF97316),
  ];

  static Color _parseAccent(dynamic raw, int id) {
    if (raw is String && raw.startsWith('#') && raw.length >= 7) {
      final hex = int.tryParse(raw.substring(1), radix: 16);
      if (hex != null) return Color(0xFF000000 | hex);
    }
    return _palette[id % _palette.length];
  }
}
