import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/app_language.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.t('settings_subtitle'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),

          // Theme
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFF4F46E5),
            title: l10n.t('settings_theme'),
            subtitle: isDark ? l10n.t('settings_theme_dark') : l10n.t('settings_theme_light'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => appState.toggleTheme(),
            ),
          ),
          const SizedBox(height: 12),

          // Language
          _SettingsTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF38BDF8),
            title: l10n.t('settings_language'),
            subtitle: appState.language == AppLanguage.en ? 'English' : 'Français',
            trailing: SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(value: AppLanguage.en, label: Text('EN')),
                ButtonSegment(value: AppLanguage.fr, label: Text('FR')),
              ],
              selected: {appState.language},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              onSelectionChanged: (s) => appState.setLanguage(s.first),
            ),
          ),
          const SizedBox(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.t('settings_logout')),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await context.appState.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
