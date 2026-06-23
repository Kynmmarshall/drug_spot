import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/user_type.dart';
import '../widgets/dashboard_action_bar.dart';
import '../widgets/medicine_form_sheet.dart';
import '../widgets/medicine_tile.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/section_card.dart';
import 'community_map_screen.dart';
import 'medicine_detail_screen.dart';
import 'profile_screen.dart';
import 'my_medicines_screen.dart';
import 'pharmacy_requests_screen.dart';
import 'settings_screen.dart';

class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final owned = appState.medicinesByPharmacy(appState.primaryPharmacyId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('pharmacy_dashboard_title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicineSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.t('add_medicine')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          const SizedBox(height: 8),
          _DashboardStats(
            ownedMedicines: owned,
            onOpenRequests: () => _openRequestsScreen(context),
            onOpenManagedMeds: () => _openMyMedicinesScreen(context),
          ),
          const SizedBox(height: 24),
          SectionCard(
            icon: Icons.medication_liquid,
            title: l10n.t('medicine_all_section'),
            subtitle: l10n.resultsCount(appState.medicines.length),
            child: Column(
              children: appState.medicines
                  .map(
                    (medicine) => MedicineTile(
                      medicine: medicine,
                      pharmacy: appState.pharmacyById(medicine.pharmacyId),
                      onTap: () => _openMedicineDetails(context, medicine),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardActionBar(
        children: [
          IconButton(
            tooltip: l10n.t('map_cta'),
            icon: const Icon(Icons.public_rounded),
            onPressed: () => _openCommunityMap(context),
          ),
          IconButton(
            tooltip: l10n.t('my_medicines_title'),
            icon: const Icon(Icons.inventory_2_rounded),
            onPressed: () => _openMyMedicinesScreen(context),
          ),
          IconButton(
            tooltip: l10n.t('settings_title'),
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          InkWell(
            onTap: () => _openProfile(context),
            child: ProfileAvatar(
              path: appState.pharmacyProfile.avatarPath,
              useAsset: appState.pharmacyProfile.useAsset,
              radius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMedicineSheet(BuildContext context, {Medicine? medicine}) {
    final appState = context.appState;
    final l10n = context.l10n;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MedicineFormSheet(
            pharmacy: appState.primaryPharmacy,
            medicine: medicine,
            onSubmit: (value) async {
              try {
                if (medicine == null) {
                  await appState.addMedicine(value);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.t('med_created'))),
                  );
                } else {
                  await appState.updateMedicine(value);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.t('med_updated'))),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
          ),
        );
      },
    );
  }

  void _openRequestsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PharmacyRequestsScreen()),
    );
  }

  void _openMyMedicinesScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyMedicinesScreen()),
    );
  }

  void _openCommunityMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityMapScreen()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(userType: UserType.pharmacy),
      ),
    );
  }

  void _openMedicineDetails(BuildContext context, Medicine medicine) {
    final appState = context.appState;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicineDetailScreen(
          medicine: medicine,
          pharmacy: appState.pharmacyById(medicine.pharmacyId),
        ),
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({
    required this.ownedMedicines,
    required this.onOpenRequests,
    required this.onOpenManagedMeds,
  });

  final List<Medicine> ownedMedicines;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenManagedMeds;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tiles = [
      _StatTile(
        icon: Icons.inventory_2_rounded,
        value: ownedMedicines.length.toString().padLeft(2, '0'),
        label: l10n.t('stats_inventory'),
        helper: l10n.t('stats_inventory_sub'),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6EE7B7)],
        ),
        onTap: onOpenManagedMeds,
      ),
      _StatTile(
        icon: Icons.message_rounded,
        value: '24',
        label: l10n.t('stats_requests'),
        helper: l10n.t('stats_requests_sub'),
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFDE047)],
        ),
        onTap: onOpenRequests,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: tiles
                .map(
                  (child) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: child,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: tiles
              .map(
                (child) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.helper,
    required this.gradient,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String helper;
  final Gradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.scrim.withValues(alpha: 0.25),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: textColor, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    helper,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
