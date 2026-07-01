import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/geo_point.dart';
import '../models/user_type.dart';
import '../services/api_service.dart';
import '../widgets/lang_toggle.dart';
import 'patient_dashboard_screen.dart';
import 'pharmacy_dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Patient-only
  final _patientPhoneCtrl = TextEditingController();

  // Pharmacy-only
  final _pharmacyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pharmacyPhoneCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _locating = false;
  bool _submitting = false;
  GeoPoint? _detectedPoint;
  UserType _selectedType = UserType.patient;

  bool get _isPharmacy => _selectedType == UserType.pharmacy;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _patientPhoneCtrl.dispose();
    _pharmacyNameCtrl.dispose();
    _addressCtrl.dispose();
    _pharmacyPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('register_title')),
        actions: const [LangToggle()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.t('register_subtitle'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // ── Account type selector ──
              Text(
                l10n.t('register_account_type'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<UserType>(
                  segments: UserType.values
                      .map(
                        (type) => ButtonSegment<UserType>(
                          value: type,
                          label: Text(l10n.userTypeLabel(type)),
                          icon: Icon(type.icon, size: 18),
                        ),
                      )
                      .toList(),
                  selected: {_selectedType},
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  onSelectionChanged: (s) =>
                      setState(() => _selectedType = s.first),
                ),
              ),
              const SizedBox(height: 28),

              // ── Form ──
              Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: child,
                  ),
                  child: _isPharmacy
                      ? _buildPharmacyForm(context, l10n, theme)
                      : _buildPatientForm(context, l10n),
                ),
              ),

              const SizedBox(height: 36),
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
                      : Text(l10n.t('register_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Patient form ──────────────────────────────────────────────────
  Widget _buildPatientForm(BuildContext context, dynamic l10n) {
    return Column(
      key: const ValueKey('patient'),
      children: [
        TextFormField(
          controller: _usernameCtrl,
          decoration: InputDecoration(
            labelText: l10n.t('input_username'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? l10n.t('error_username_required')
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.t('input_email'),
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          validator: _emailValidator,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _patientPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.t('input_phone'),
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? l10n.t('error_phone')
              : null,
        ),
        const SizedBox(height: 16),
        ..._passwordFields(l10n),
      ],
    );
  }

  // ── Pharmacy form ─────────────────────────────────────────────────
  Widget _buildPharmacyForm(
    BuildContext context,
    dynamic l10n,
    ThemeData theme,
  ) {
    return Column(
      key: const ValueKey('pharmacy'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section: Pharmacy info ──
        _SectionHeader(
          icon: Icons.store_rounded,
          title: l10n.t('reg_pharmacy_info_section'),
          theme: theme,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pharmacyNameCtrl,
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
          controller: _addressCtrl,
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
          controller: _pharmacyPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l10n.t('input_phone'),
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? l10n.t('error_phone')
              : null,
        ),
        const SizedBox(height: 16),
        _LocationPicker(
          locating: _locating,
          detectedPoint: _detectedPoint,
          l10n: l10n,
          theme: theme,
          onDetect: _handleDetectLocation,
        ),
        const SizedBox(height: 32),

        // ── Section: Account credentials ──
        _SectionHeader(
          icon: Icons.lock_outline_rounded,
          title: l10n.t('reg_credentials_section'),
          theme: theme,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _usernameCtrl,
          decoration: InputDecoration(
            labelText: l10n.t('reg_login_username'),
            helperText: l10n.t('reg_login_username_hint'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? l10n.t('error_username_required')
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.t('input_email'),
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          validator: _emailValidator,
        ),
        const SizedBox(height: 16),
        ..._passwordFields(l10n),
      ],
    );
  }

  // ── Shared password fields ────────────────────────────────────────
  List<Widget> _passwordFields(dynamic l10n) => [
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: l10n.t('input_password'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) => v == null || v.length < 6
              ? l10n.t('error_password_min')
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: l10n.t('input_confirm_password'),
            prefixIcon: const Icon(Icons.lock_reset_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          validator: (v) => v == _passwordCtrl.text
              ? null
              : l10n.t('error_confirm_password'),
        ),
      ];

  String? _emailValidator(String? value) {
    final l10n = context.l10n;
    if (value == null || value.isEmpty) return l10n.t('error_email');
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return l10n.t('error_email');
    }
    return null;
  }

  // ── Actions ───────────────────────────────────────────────────────
  Future<void> _handleDetectLocation() async {
    setState(() => _locating = true);
    try {
      final point = await context.appState.detectLocation();
      if (!mounted) return;
      setState(() => _detectedPoint = point);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isPharmacy && _detectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('reg_location_required'))),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final appState = context.appState;

      await appState.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _isPharmacy
            ? _pharmacyPhoneCtrl.text.trim()
            : _patientPhoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        userType: _selectedType,
      );

      if (_isPharmacy) {
        await appState.createPharmacy(
          name: _pharmacyNameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          lat: _detectedPoint!.lat,
          lng: _detectedPoint!.lng,
          phone: _pharmacyPhoneCtrl.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => _isPharmacy
              ? const PharmacyDashboardScreen()
              : const PatientDashboardScreen(),
        ),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.locating,
    required this.detectedPoint,
    required this.l10n,
    required this.theme,
    required this.onDetect,
  });

  final bool locating;
  final GeoPoint? detectedPoint;
  final dynamic l10n;
  final ThemeData theme;
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: detectedPoint != null
              ? const Color(0xFF25D366).withValues(alpha: 0.5)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        color: detectedPoint != null
            ? const Color(0xFF25D366).withValues(alpha: 0.06)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('pharmacy_setup_location_hint'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: locating ? null : onDetect,
                  icon: locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    locating
                        ? l10n.t('detecting_location')
                        : l10n.t('detect_location'),
                  ),
                ),
              ),
              if (detectedPoint != null) ...[
                const SizedBox(width: 10),
                Chip(
                  avatar: const Icon(Icons.check_circle,
                      color: Color(0xFF25D366), size: 16),
                  label: Text(
                    detectedPoint!.formatted(
                      context.appState.language,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
