import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';
import '../models/user_type.dart';
import '../widgets/dashboard_action_bar.dart';
import '../widgets/medicine_tile.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/section_card.dart';
import 'chat_list_screen.dart';
import 'community_map_screen.dart';
import 'medicine_detail_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final _searchController = TextEditingController();
  double _maxDistance = 18;
  final Set<String> _activeFilters = {};
  bool _locationRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationRequested) {
      _locationRequested = true;
      context.appState.updateUserLocation();
    }
  }

  void _openCommunityMap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityMapScreen()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(userType: UserType.patient),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  late final List<_FilterOption> _filterOptions = [
    _FilterOption(
      id: 'nearby',
      labelKey: 'distance_chip_nearby',
      predicate: (med, _) => med.distanceKm <= 5,
    ),
    _FilterOption(
      id: 'affordable',
      labelKey: 'distance_chip_affordable',
      predicate: (med, _) => med.price <= 3000,
    ),
    _FilterOption(
      id: 'popular',
      labelKey: 'distance_chip_popular',
      predicate: (med, pharmacy) =>
          pharmacy.name.contains('Care') || med.name.contains('o'),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMedicineDetails(Medicine medicine) {
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

  Future<void> _handleRefresh() => context.appState.refreshData();

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final medicines = appState.medicines.where((medicine) {
      final byName = medicine.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final byDistance = medicine.distanceKm <= _maxDistance + 0.1;
      if (!appState.pharmacies.any((p) => p.id == medicine.pharmacyId)) {
        return false;
      }
      final pharmacy = appState.pharmacyById(medicine.pharmacyId);
      final byFilters =
          _activeFilters.isEmpty ||
          _activeFilters.every((id) {
            final option = _filterOptions.firstWhere(
              (element) => element.id == id,
            );
            return option.predicate(medicine, pharmacy);
          });
      return byName && byDistance && byFilters;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('patient_dashboard_title'))),
      body: _buildBody(appState, l10n, theme, medicines),
      bottomNavigationBar: DashboardActionBar(
        children: [
          IconButton(
            tooltip: l10n.t('map_cta'),
            icon: const Icon(Icons.public_rounded),
            onPressed: _openCommunityMap,
          ),
          IconButton(
            tooltip: l10n.t('chat_title'),
            icon: const Icon(Icons.chat_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n.t('settings_title'),
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openSettings,
          ),
          InkWell(
            onTap: _openProfile,
            child: ProfileAvatar(
              path: appState.patientProfile.avatarPath,
              useAsset: appState.patientProfile.useAsset,
              radius: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    dynamic appState,
    dynamic l10n,
    ThemeData theme,
    List<Medicine> medicines,
  ) {
    if (appState.dataLoading && appState.medicines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appState.dataError != null && appState.medicines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56,
                  color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(l10n.t('error_loading_data'),
                  style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(appState.dataError!,
                  style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: l10n.t('search_placeholder'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text(l10n.t('filter_distance'), style: theme.textTheme.titleMedium),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 35,
            divisions: 34,
            label: l10n.distanceLabel(_maxDistance),
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: _filterOptions
                .map(
                  (option) => FilterChip(
                    label: Text(l10n.t(option.labelKey)),
                    selected: _activeFilters.contains(option.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _activeFilters.add(option.id);
                        } else {
                          _activeFilters.remove(option.id);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SectionCard(
            icon: Icons.local_hospital,
            title: l10n.t('patient_all_medicines'),
            subtitle: l10n.resultsCount(medicines.length),
            child: medicines.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text(l10n.t('empty_results'))),
                  )
                : Column(
                    children: medicines
                        .map(
                          (medicine) => MedicineTile(
                            medicine: medicine,
                            pharmacy: context.appState.pharmacyById(
                              medicine.pharmacyId,
                            ),
                            onTap: () => _openMedicineDetails(medicine),
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

class _FilterOption {
  const _FilterOption({
    required this.id,
    required this.labelKey,
    required this.predicate,
  });

  final String id;
  final String labelKey;
  final bool Function(Medicine, Pharmacy) predicate;
}
