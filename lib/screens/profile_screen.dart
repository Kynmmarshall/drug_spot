import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userType});

  final UserType userType;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  late UserProfile _baseProfile;
  late String _avatarPath;
  bool _useAsset = true;
  bool _initialized = false;

  static const List<String> _avatarOptions = [
    'assets/avatars/avatar_wave.svg',
    'assets/avatars/avatar_coral.svg',
    'assets/avatars/avatar_mint.svg',
    'assets/avatars/avatar_sunrise.svg',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _baseProfile = widget.userType == UserType.pharmacy
        ? context.appState.pharmacyProfile
        : context.appState.patientProfile;
    _usernameController.text = _baseProfile.username;
    _emailController.text = _baseProfile.email;
    _phoneController.text = _baseProfile.phone;
    _bioController.text = _baseProfile.bio;
    _avatarPath = _baseProfile.avatarPath;
    _useAsset = _baseProfile.useAsset;
    _initialized = true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.userTypeLabel(widget.userType))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.t(
              widget.userType == UserType.pharmacy
                  ? 'profile_title_pharmacy'
                  : 'profile_title_patient',
            ),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t(
              widget.userType == UserType.pharmacy
                  ? 'profile_subtitle_pharmacy'
                  : 'profile_subtitle_patient',
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ProfileAvatar(
              path: _avatarPath,
              useAsset: _useAsset,
              radius: 52,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
            decoration: InputDecoration(labelText: l10n.t('input_email')),
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
            decoration: InputDecoration(labelText: l10n.t('profile_bio')),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saveProfile,
            child: Text(l10n.t('profile_save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final updated = _baseProfile.copyWith(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      avatarPath: _avatarPath,
      useAsset: _useAsset,
    );
    try {
      await context.appState.updateProfile(widget.userType, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('profile_save'))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((path) {
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
      }).toList(),
    );
  }
}
