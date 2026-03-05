import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/pharmacy.dart';
import '../widgets/language_toggle.dart';
import '../widgets/pharmacy_map_card.dart';
import '../widgets/section_card.dart';
import '../widgets/theme_toggle_button.dart';

class CommunityMapScreen extends StatelessWidget {
  const CommunityMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pharmacies = appState.pharmacies;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('map_title')),
        actions: const [LanguageToggle(dense: true), ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(l10n.t('community_map_intro'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          PharmacyMapCard(pharmacies: pharmacies),
          const SizedBox(height: 24),
          SectionCard(
            icon: Icons.public_rounded,
            title: l10n.t('map_subtitle'),
            subtitle:
                '${pharmacies.length} ${l10n.t('community_map_pharmacies')}',
            child: Column(
              children: pharmacies
                  .map(
                    (pharmacy) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _CommunityPharmacyTile(
                        pharmacy: pharmacy,
                        distanceLabel: l10n.distanceAway(
                          appState.distanceFromPatient(pharmacy.id),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
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
  });

  final Pharmacy pharmacy;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ],
                ),
              ),
              Text(
                distanceLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.phone, label: pharmacy.phone),
              _InfoChip(icon: Icons.location_pin, label: distanceLabel),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
