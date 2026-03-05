import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/user_profile.dart';
import '../models/user_type.dart';

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
  late String _avatarUrl;

  final _avatarOptions = const [
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final profile = _currentProfile;
    _usernameController = TextEditingController(text: profile.username);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
    _bioController = TextEditingController(text: profile.bio);
    _avatarUrl = profile.avatarUrl;
  }

  UserProfile get _currentProfile => widget.userType == UserType.pharmacy
      ? context.appState.pharmacyProfile
      : context.appState.patientProfile;

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
            child: CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(_avatarUrl),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: _avatarOptions
                .map(
                  (url) => ChoiceChip(
                    avatar: CircleAvatar(backgroundImage: NetworkImage(url)),
                    label: const SizedBox(width: 0),
                    selected: _avatarUrl == url,
                    onSelected: (_) => setState(() => _avatarUrl = url),
                  ),
                )
                .toList(),
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

  void _saveProfile() {
    final appState = context.appState;
    final profile = _currentProfile.copyWith(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      avatarUrl: _avatarUrl,
    );
    appState.updateProfile(widget.userType, profile);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.t('profile_save'))));
    Navigator.of(context).pop();
  }
}
