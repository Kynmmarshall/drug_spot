import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../widgets/language_toggle.dart';
import '../widgets/medicine_form_sheet.dart';
import '../widgets/medicine_tile.dart';
import '../widgets/theme_toggle_button.dart';
import 'medicine_detail_screen.dart';

class MyMedicinesScreen extends StatelessWidget {
  const MyMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final owned = appState.medicinesByPharmacy(appState.primaryPharmacyId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('my_medicines_title')),
        actions: const [LanguageToggle(dense: true), ThemeToggleButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicineSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.t('add_medicine')),
      ),
      body: owned.isEmpty
          ? _EmptyState(message: l10n.t('my_medicines_empty'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: owned
                  .map(
                    (medicine) => MedicineTile(
                      medicine: medicine,
                      pharmacy: appState.primaryPharmacy,
                      onTap: () => _openDetails(context, medicine),
                      trailingActions: MedicineTileActions(
                        onEdit: () =>
                            _openMedicineSheet(context, medicine: medicine),
                        onDelete: () async {
                          try {
                            await appState.deleteMedicine(medicine.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.t('med_deleted'))),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Future<void> _openMedicineSheet(BuildContext context, {Medicine? medicine}) {
    final appState = context.appState;
    final l10n = context.l10n;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
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
      ),
    );
  }

  void _openDetails(BuildContext context, Medicine medicine) {
    final appState = context.appState;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicineDetailScreen(
          medicine: medicine,
          pharmacy: appState.primaryPharmacy,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('my_medicines_empty_hint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
