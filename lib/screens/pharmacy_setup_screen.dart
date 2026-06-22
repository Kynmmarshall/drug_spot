import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/geo_point.dart';
import '../services/api_service.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle_button.dart';
import 'pharmacy_dashboard_screen.dart';

class PharmacySetupScreen extends StatefulWidget {
  const PharmacySetupScreen({super.key});

  @override
  State<PharmacySetupScreen> createState() => _PharmacySetupScreenState();
}

class _PharmacySetupScreenState extends State<PharmacySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;
  bool _locating = false;
  GeoPoint? _detectedPoint;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final padding = MediaQuery.of(context).viewInsets.bottom + 24;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('pharmacy_setup_title')),
        automaticallyImplyLeading: false,
        actions: const [LanguageToggle(dense: true), ThemeToggleButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.secondary.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.store_rounded,
                        color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('pharmacy_setup_welcome'),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.t('pharmacy_setup_subtitle'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.t('pharmacy_setup_name'),
                        prefixIcon: const Icon(Icons.local_pharmacy_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.t('pharmacy_setup_name_error')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: l10n.t('pharmacy_setup_address'),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.t('pharmacy_setup_address_error')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.t('input_phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l10n.t('error_phone')
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('pharmacy_setup_location_hint'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _locating ? null : _handleDetectLocation,
                                  icon: const Icon(Icons.my_location),
                                  label: Text(
                                    _locating
                                        ? l10n.t('detecting_location')
                                        : l10n.t('detect_location'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_detectedPoint != null)
                                Chip(
                                  avatar: const Icon(Icons.check_circle,
                                      size: 18),
                                  label: Text(
                                    _detectedPoint!.formatted(
                                        context.appState.language),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_detectedPoint == null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.t('pharmacy_setup_location_required'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.t('pharmacy_setup_submit')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDetectLocation() async {
    setState(() => _locating = true);
    final point = await context.appState.detectLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _detectedPoint = point;
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_detectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('pharmacy_setup_location_required'))),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await context.appState.createPharmacy(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        lat: _detectedPoint!.lat,
        lng: _detectedPoint!.lng,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PharmacyDashboardScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
