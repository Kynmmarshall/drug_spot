import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine_request.dart';
import '../widgets/profile_avatar.dart';

class PharmacyRequestsScreen extends StatelessWidget {
  const PharmacyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final requests = appState.medicineRequests;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('requests_screen_title')),
        actions: const [],
      ),
      body: requests.isEmpty
          ? _EmptyRequests(message: l10n.t('requests_screen_empty'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  l10n.t('requests_screen_subtitle'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                ...requests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _RequestTile(request: request),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final MedicineRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            path: request.avatarPath,
            useAsset: request.useAsset,
            radius: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.username,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.t('requests_contact')}: ${request.contact}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '${l10n.t('requests_medicine_label')}: ${request.medicineName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
