import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';

class MedicineFormData {
  const MedicineFormData({
    required this.name,
    required this.price,
    required this.description,
    this.imageFile,
  });

  final String name;
  final double price;
  final String description;
  final File? imageFile;
}

class MedicineFormSheet extends StatefulWidget {
  const MedicineFormSheet({
    super.key,
    required this.pharmacy,
    this.medicine,
    required this.onSubmit,
  });

  final Pharmacy pharmacy;
  final Medicine? medicine;
  final ValueChanged<MedicineFormData> onSubmit;

  @override
  State<MedicineFormSheet> createState() => _MedicineFormSheetState();
}

class _MedicineFormSheetState extends State<MedicineFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.medicine?.name ?? '');
  late final _priceCtrl = TextEditingController(
    text: widget.medicine?.price.toStringAsFixed(0) ?? '',
  );
  late final _descCtrl =
      TextEditingController(text: widget.medicine?.description ?? '');

  File? _imageFile;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final existingImageUrl = widget.medicine?.imageUrl;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        32,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text(
            widget.medicine == null
                ? l10n.t('add_medicine')
                : l10n.t('update_medicine'),
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),

          // ── Image picker ──
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
                image: _imageFile != null
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : (existingImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(existingImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null),
              ),
              child: _imageFile == null && existingImageUrl == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('med_add_image'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Form fields ──
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.t('medicine_name'),
                    prefixIcon: const Icon(Icons.medication_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.t('medicine_name')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.t('medicine_price'),
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  validator: (v) =>
                      v == null || double.tryParse(v) == null
                          ? l10n.t('medicine_price')
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.t('medicine_description'),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.description_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Actions ──
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      MedicineFormData(
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        description: _descCtrl.text.trim(),
        imageFile: _imageFile,
      ),
    );
    Navigator.of(context).pop();
  }
}
