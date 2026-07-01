import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';

class MedicineTile extends StatelessWidget {
  const MedicineTile({
    super.key,
    required this.medicine,
    required this.pharmacy,
    this.trailingActions,
    this.onTap,
  });

  final Medicine medicine;
  final Pharmacy pharmacy;
  final MedicineTileActions? trailingActions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final borderRadius = BorderRadius.circular(24);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: medicine.imageUrl != null
                    ? Image.network(
                        medicine.imageUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _MedicinePlaceholder(
                          accent: pharmacy.accent,
                        ),
                      )
                    : _MedicinePlaceholder(accent: pharmacy.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pharmacy.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.priceLabel(medicine.price),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.location_pin,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.distanceAway(medicine.distanceKm),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailingActions != null) trailingActions!,
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicinePlaceholder extends StatelessWidget {
  const _MedicinePlaceholder({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      color: accent.withValues(alpha: 0.18),
      child: Icon(Icons.medication_liquid, color: accent),
    );
  }
}

class MedicineTileActions extends StatelessWidget {
  const MedicineTileActions({super.key, this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onEdit,
          icon: Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
        ),
        IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        ),
      ],
    );
  }
}
