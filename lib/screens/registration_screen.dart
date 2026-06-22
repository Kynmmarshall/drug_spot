import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/geo_point.dart';
import '../models/user_type.dart';
import '../services/api_service.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle_button.dart';
import 'patient_dashboard_screen.dart';
import 'pharmacy_setup_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _locating = false;
  bool _submitting = false;
  GeoPoint? _detectedPoint;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final padding = MediaQuery.of(context).viewInsets.bottom + 24;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('register_title')),
        actions: const [LanguageToggle(dense: true), ThemeToggleButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, padding),
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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: l10n.t('input_username'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.t('error_username_required')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.t('input_email'),
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.t('error_email');
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                        if (!emailRegex.hasMatch(value)) {
                          return l10n.t('error_email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.t('input_phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.t('error_phone')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.t('input_password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? l10n.t('error_password_min')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: l10n.t('input_confirm_password'),
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (value) => value == _passwordController.text
                          ? null
                          : l10n.t('error_confirm_password'),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('geolocation_hint'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _locating
                                      ? null
                                      : _handleDetectLocation,
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
                                  avatar: const Icon(
                                    Icons.location_pin,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _detectedPoint!.formatted(
                                      context.appState.language,
                                    ),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
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

    setState(() => _submitting = true);

    try {
      final appState = context.appState;
      await appState.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        userType: appState.loginType,
      );

      if (!mounted) return;

      final Widget destination;
      if (appState.currentUserType == UserType.pharmacy) {
        destination = const PharmacySetupScreen();
      } else {
        destination = const PatientDashboardScreen();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
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
