import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/context_extensions.dart';
import '../models/pharmacy.dart';
import '../widgets/section_card.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  Pharmacy? _selectedPharmacy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.appState.locationDetected) {
      context.appState.updateUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pharmacies = appState.pharmacies;
    final userLoc = appState.userLocation;

    if (appState.dataLoading && pharmacies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('map_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (appState.dataError != null && pharmacies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('map_title'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(l10n.t('error_loading_data'),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => appState.refreshData(),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.t('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final center = pharmacies.isEmpty
        ? LatLng(userLoc.lat, userLoc.lng)
        : LatLng(
            pharmacies.map((p) => p.lat).reduce((a, b) => a + b) /
                pharmacies.length,
            pharmacies.map((p) => p.lng).reduce((a, b) => a + b) /
                pharmacies.length,
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('map_title'))),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                onTap: (_, __) => setState(() => _selectedPharmacy = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          border:
                              Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    ...pharmacies.map(
                      (pharmacy) => Marker(
                        point: LatLng(pharmacy.lat, pharmacy.lng),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPharmacy = pharmacy),
                          child: Container(
                            decoration: BoxDecoration(
                              color: pharmacy.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedPharmacy?.id == pharmacy.id
                                    ? Colors.white
                                    : Colors.white70,
                                width:
                                    _selectedPharmacy?.id == pharmacy.id
                                        ? 3.5
                                        : 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: pharmacy.accent
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.local_pharmacy,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info panel
          if (_selectedPharmacy != null)
            _PharmacyInfoPanel(
              pharmacy: _selectedPharmacy!,
              distanceLabel: l10n.distanceAway(
                appState.distanceFromPatient(_selectedPharmacy!.id),
              ),
              onClose: () => setState(() => _selectedPharmacy = null),
            ),

          // Pharmacy list
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                SectionCard(
                  icon: Icons.public_rounded,
                  title: l10n.t('map_subtitle'),
                  subtitle:
                      '${pharmacies.length} ${l10n.t('community_map_pharmacies')}',
                  child: Column(
                    children: pharmacies
                        .map(
                          (pharmacy) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: _CommunityPharmacyTile(
                              pharmacy: pharmacy,
                              distanceLabel: l10n.distanceAway(
                                appState
                                    .distanceFromPatient(pharmacy.id),
                              ),
                              selected:
                                  _selectedPharmacy?.id == pharmacy.id,
                              onTap: () => setState(
                                  () => _selectedPharmacy = pharmacy),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyInfoPanel extends StatelessWidget {
  const _PharmacyInfoPanel({
    required this.pharmacy,
    required this.distanceLabel,
    required this.onClose,
  });

  final Pharmacy pharmacy;
  final String distanceLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: pharmacy.accent.withValues(alpha: 0.15),
            child: Icon(Icons.local_pharmacy, color: pharmacy.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pharmacy.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('${pharmacy.address}  ·  $distanceLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _CommunityPharmacyTile extends StatelessWidget {
  const _CommunityPharmacyTile({
    required this.pharmacy,
    required this.distanceLabel,
    this.selected = false,
    this.onTap,
  });

  final Pharmacy pharmacy;
  final String distanceLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? pharmacy.accent
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? pharmacy.accent.withValues(alpha: 0.06)
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: pharmacy.accent.withValues(alpha: 0.12),
              child: Icon(Icons.local_hospital, color: pharmacy.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    pharmacy.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoChip(icon: Icons.phone, label: pharmacy.phone),
                      _InfoChip(icon: Icons.location_pin, label: distanceLabel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
