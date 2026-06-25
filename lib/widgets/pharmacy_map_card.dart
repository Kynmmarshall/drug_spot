import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/context_extensions.dart';
import '../models/pharmacy.dart';

class PharmacyMapCard extends StatelessWidget {
  const PharmacyMapCard({super.key, required this.pharmacies});

  final List<Pharmacy> pharmacies;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final userLoc = appState.userLocation;
    final theme = Theme.of(context);

    final center = pharmacies.isEmpty
        ? LatLng(userLoc.lat, userLoc.lng)
        : LatLng(
            pharmacies.map((p) => p.lat).reduce((a, b) => a + b) /
                pharmacies.length,
            pharmacies.map((p) => p.lng).reduce((a, b) => a + b) /
                pharmacies.length,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.drugspot.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(userLoc.lat, userLoc.lng),
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ),
                ...pharmacies.map(
                  (pharmacy) => Marker(
                    point: LatLng(pharmacy.lat, pharmacy.lng),
                    width: 44,
                    height: 44,
                    child: _PharmacyPin(pharmacy: pharmacy),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyPin extends StatelessWidget {
  const _PharmacyPin({required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: pharmacy.name,
      child: Container(
        decoration: BoxDecoration(
          color: pharmacy.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: pharmacy.accent.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 20),
      ),
    );
  }
}
