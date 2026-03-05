import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/user_type.dart';
import '../widgets/language_toggle.dart';
import '../widgets/medicine_form_sheet.dart';
import '../widgets/medicine_tile.dart';
import '../widgets/pharmacy_map_card.dart';
import '../widgets/section_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'profile_screen.dart';

class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final owned = appState.medicinesByPharmacy(appState.primaryPharmacyId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('pharmacy_dashboard_title')),
        actions: [
          const LanguageToggle(dense: true),
          const ThemeToggleButton(),
          IconButton(
            tooltip: l10n.t('profile_picture'),
            iconSize: 40,
            icon: CircleAvatar(
              backgroundImage: NetworkImage(appState.pharmacyProfile.avatarUrl),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const ProfileScreen(userType: UserType.pharmacy),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicineSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.t('add_medicine')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          const SizedBox(height: 8),
          _DashboardStats(ownedMedicines: owned),
          const SizedBox(height: 24),
          SectionCard(
            icon: Icons.inventory_rounded,
            title: l10n.t('pharmacy_manage_title'),
            subtitle: l10n.t('pharmacy_manage_sub'),
            child: Column(
              children: owned
                  .map(
                    (medicine) => MedicineTile(
                      medicine: medicine,
                      pharmacy: appState.primaryPharmacy,
                      trailingActions: MedicineTileActions(
                        onEdit: () =>
                            _openMedicineSheet(context, medicine: medicine),
                        onDelete: () {
                          appState.deleteMedicine(medicine.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.t('med_deleted'))),
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          PharmacyMapCard(pharmacies: appState.pharmacies),
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
                    ),
                  )
                  .toList(),
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
            onSubmit: (value) {
              if (medicine == null) {
                appState.addMedicine(value);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.t('med_created'))));
              } else {
                appState.updateMedicine(value);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.t('med_updated'))));
              }
            },
          ),
        );
      },
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.ownedMedicines});

  final List<Medicine> ownedMedicines;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
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
      ),
      _StatTile(
        icon: Icons.message_rounded,
        value: '24',
        label: l10n.t('stats_requests'),
        helper: l10n.t('stats_requests_sub'),
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFDE047)],
        ),
      ),
      _StatTile(
        icon: Icons.radar_rounded,
        value:
            '${appState.distanceFromPatient(appState.primaryPharmacyId).toStringAsFixed(1)} km',
        label: l10n.t('stats_coverage'),
        helper: l10n.t('stats_coverage_sub'),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
        ),
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
  });

  final IconData icon;
  final String value;
  final String label;
  final String helper;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
