import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';
import '../models/user_type.dart';
import '../widgets/language_toggle.dart';
import '../widgets/medicine_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'profile_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final _searchController = TextEditingController();
  double _maxDistance = 18;
  final Set<String> _activeFilters = {};

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
      appBar: AppBar(
        title: Text(l10n.t('patient_dashboard_title')),
        actions: [
          const LanguageToggle(dense: true),
          const ThemeToggleButton(),
          IconButton(
            tooltip: l10n.t('profile_picture'),
            iconSize: 40,
            icon: CircleAvatar(
              backgroundImage: NetworkImage(appState.patientProfile.avatarUrl),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(userType: UserType.patient),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
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
                            pharmacy: appState.pharmacyById(
                              medicine.pharmacyId,
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
