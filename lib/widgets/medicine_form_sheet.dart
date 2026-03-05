import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';

class MedicineFormSheet extends StatefulWidget {
  const MedicineFormSheet({
    super.key,
    required this.pharmacy,
    this.medicine,
    required this.onSubmit,
  });

  final Pharmacy pharmacy;
  final Medicine? medicine;
  final ValueChanged<Medicine> onSubmit;

  @override
  State<MedicineFormSheet> createState() => _MedicineFormSheetState();
}

class _MedicineFormSheetState extends State<MedicineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.medicine?.name ?? '',
  );
  late final TextEditingController _priceController = TextEditingController(
    text: widget.medicine?.price.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.medicine == null
                ? l10n.t('add_medicine')
                : l10n.t('update_medicine'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.t('medicine_name'),
                    prefixIcon: const Icon(Icons.medication_outlined),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? l10n.t('medicine_name')
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.t('medicine_price'),
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (value) =>
                      value == null || double.tryParse(value) == null
                      ? l10n.t('medicine_price')
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.t('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _handleSubmit,
                  child: Text(l10n.t('save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final appState = context.appState;
    final medicine = Medicine(
      id: widget.medicine?.id ?? 'med-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      pharmacyId: widget.pharmacy.id,
      distanceKm: appState.distanceFromPatient(widget.pharmacy.id),
    );
    widget.onSubmit(medicine);
    Navigator.of(context).pop();
  }
}
