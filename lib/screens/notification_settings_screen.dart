import 'package:flutter/material.dart';

import '../core/context_extensions.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _newMessage = true;
  bool _requestUpdate = true;
  bool _newMedicine = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.appState.api.getNotificationPreferences();
      if (!mounted) return;
      setState(() {
        _newMessage = data['new_message'] as bool? ?? true;
        _requestUpdate = data['request_update'] as bool? ?? true;
        _newMedicine = data['new_medicine'] as bool? ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(String key, bool value) async {
    try {
      await context.appState.api.updateNotificationPreferences({key: value});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('notif_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l10n.t('notif_subtitle'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),
                _NotifToggle(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  title: l10n.t('notif_messages'),
                  subtitle: l10n.t('notif_messages_sub'),
                  value: _newMessage,
                  onChanged: (v) {
                    setState(() => _newMessage = v);
                    _update('new_message', v);
                  },
                ),
                const SizedBox(height: 12),
                _NotifToggle(
                  icon: Icons.assignment_rounded,
                  iconColor: const Color(0xFFF97316),
                  title: l10n.t('notif_requests'),
                  subtitle: l10n.t('notif_requests_sub'),
                  value: _requestUpdate,
                  onChanged: (v) {
                    setState(() => _requestUpdate = v);
                    _update('request_update', v);
                  },
                ),
                const SizedBox(height: 12),
                _NotifToggle(
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFF34D399),
                  title: l10n.t('notif_medicine'),
                  subtitle: l10n.t('notif_medicine_sub'),
                  value: _newMedicine,
                  onChanged: (v) {
                    setState(() => _newMedicine = v);
                    _update('new_medicine', v);
                  },
                ),
              ],
            ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

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
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
