import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/geo_point.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';
import '../services/api_service.dart';
import '../widgets/profile_avatar.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userType});

  final UserType userType;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User fields
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  // Pharmacy fields
  late final TextEditingController _pharmacyNameController;
  late final TextEditingController _pharmacyAddressController;
  late final TextEditingController _pharmacyPhoneController;

  late UserProfile _baseProfile;
  late String _avatarPath;
  bool _useAsset = true;
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  String? _loadError;
  GeoPoint? _pharmacyLocation;

  static const List<String> _avatarOptions = [
    'assets/avatars/avatar_wave.svg',
    'assets/avatars/avatar_coral.svg',
    'assets/avatars/avatar_mint.svg',
    'assets/avatars/avatar_sunrise.svg',
    'assets/avatars/avatar_lagoon.svg',
    'assets/avatars/avatar_plum.svg',
    'assets/avatars/avatar_leaf.svg',
    'assets/avatars/avatar_sky.svg',
    'assets/avatars/avatar_rose.svg',
    'assets/avatars/avatar_gold.svg',
    'assets/avatars/avatar_indigo.svg',
    'assets/avatars/avatar_lime.svg',
    'assets/avatars/avatar_iris.svg',
    'assets/avatars/avatar_marigold.svg',
    'assets/avatars/avatar_pearl.svg',
    'assets/avatars/avatar_orchid.svg',
    'assets/avatars/avatar_aqua.svg',
    'assets/avatars/avatar_berry.svg',
  ];

  bool get _isPharmacy => widget.userType == UserType.pharmacy;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _pharmacyNameController = TextEditingController();
    _pharmacyAddressController = TextEditingController();
    _pharmacyPhoneController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    debugPrint('[ProfileScreen] Loading ${widget.userType.name} profile');
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await context.appState.api.getProfile();
      final profile = UserProfile.fromJson(data);
      debugPrint('[ProfileScreen] Loaded profile for ${profile.username}');
      _applyProfile(profile);
    } on ApiException catch (e) {
      if (!mounted) return;
      debugPrint('[ProfileScreen] Profile API failed: ${e.message}');
      _applyProfile(
        _isPharmacy
            ? context.appState.pharmacyProfile
            : context.appState.patientProfile,
      );
      setState(() => _loadError = e.message);
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('[ProfileScreen] Unexpected profile load error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _applyProfile(
        _isPharmacy
            ? context.appState.pharmacyProfile
            : context.appState.patientProfile,
      );
    }
  }

  void _applyProfile(UserProfile profile) {
    if (!mounted) return;
    final appState = context.appState;
    setState(() {
      _baseProfile = profile;
      _usernameController.text = profile.username;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _bioController.text = profile.bio;
      _avatarPath = profile.avatarPath.isEmpty
          ? 'assets/avatars/avatar_wave.svg'
          : profile.avatarPath;
      _useAsset = profile.useAsset || profile.avatarPath.startsWith('assets/');

      if (_isPharmacy && appState.hasPharmacy) {
        final pharmacy = appState.primaryPharmacy;
        _pharmacyNameController.text = pharmacy.name;
        _pharmacyAddressController.text = pharmacy.address;
        _pharmacyPhoneController.text = pharmacy.phone;
        _pharmacyLocation = pharmacy.point;
      }

      _loading = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyAddressController.dispose();
    _pharmacyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userTypeLabel(widget.userType))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_loadError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.onErrorContainer,
                            size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.t('profile_loaded_offline'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  l10n.t(_isPharmacy
                      ? 'profile_title_pharmacy'
                      : 'profile_title_patient'),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(l10n.t(_isPharmacy
                    ? 'profile_subtitle_pharmacy'
                    : 'profile_subtitle_patient')),

                // Avatar
                const SizedBox(height: 24),
                Center(
                  child: ProfileAvatar(
                    path: _avatarPath,
                    useAsset: _useAsset,
                    radius: 52,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 16),
                _AvatarPicker(
                  options: _avatarOptions,
                  selectedPath: _avatarPath,
                  onSelect: (path) => setState(() {
                    _avatarPath = path;
                    _useAsset = true;
                  }),
                ),

                // User fields
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.t('input_username'),
                    helperText: l10n.t('profile_username_helper'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.t('input_email'),
                    suffixIcon: const Icon(Icons.lock_outline, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.t('input_phone'),
                    helperText: l10n.t('profile_phone_helper'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(labelText: l10n.t('profile_bio')),
                ),

                // Pharmacy section
                if (_isPharmacy && context.appState.hasPharmacy) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Icon(Icons.store_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        l10n.t('profile_pharmacy_section'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.t('profile_pharmacy_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pharmacyNameController,
                    decoration: InputDecoration(
                      labelText: l10n.t('pharmacy_setup_name'),
                      prefixIcon:
                          const Icon(Icons.local_pharmacy_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pharmacyAddressController,
                    decoration: InputDecoration(
                      labelText: l10n.t('pharmacy_setup_address'),
                      prefixIcon:
                          const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pharmacyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l10n.t('profile_pharmacy_phone'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _locating ? null : _handleDetectLocation,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: Text(
                              _locating
                                  ? l10n.t('detecting_location')
                                  : l10n.t('profile_update_location'),
                            ),
                          ),
                        ),
                        if (_pharmacyLocation != null) ...[
                          const SizedBox(width: 12),
                          Chip(
                            avatar:
                                const Icon(Icons.check_circle, size: 16),
                            label: Text(
                              _pharmacyLocation!
                                  .formatted(context.appState.language),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Save
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.t('profile_save')),
                ),

                // Logout
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.t('settings_logout')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                        color: theme.colorScheme.error
                            .withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleDetectLocation() async {
    setState(() => _locating = true);
    try {
      final point = await context.appState.detectLocation();
      if (!mounted) return;
      setState(() => _pharmacyLocation = point);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleLogout() async {
    await context.appState.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    try {
      // Save user profile
      final updated = _baseProfile.copyWith(
        username: _usernameController.text.trim(),
        email: _baseProfile.email,
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        avatarPath: _avatarPath,
        useAsset: _useAsset,
      );
      final appState = context.appState;
      await appState.updateProfile(widget.userType, updated);

      // Save pharmacy details
      if (_isPharmacy && appState.hasPharmacy) {
        await appState.updatePharmacy(
          name: _pharmacyNameController.text.trim(),
          address: _pharmacyAddressController.text.trim(),
          phone: _pharmacyPhoneController.text.trim(),
          lat: _pharmacyLocation?.lat,
          lng: _pharmacyLocation?.lng,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('profile_saved'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.options,
    required this.selectedPath,
    required this.onSelect,
  });

  final List<String> options;
  final String selectedPath;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final path = options[index];
          final isSelected = path == selectedPath;
          return GestureDetector(
            onTap: () => onSelect(path),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ProfileAvatar(
                path: path,
                useAsset: true,
                radius: 28,
                backgroundColor: theme.colorScheme.surface,
              ),
            ),
          );
        },
      ),
    );
  }
}
