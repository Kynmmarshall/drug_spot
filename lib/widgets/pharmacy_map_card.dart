import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/pharmacy.dart';
import 'section_card.dart';

class PharmacyMapCard extends StatelessWidget {
  const PharmacyMapCard({super.key, required this.pharmacies});

  final List<Pharmacy> pharmacies;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.map_rounded,
      title: l10n.t('map_title'),
      subtitle: l10n.t('map_subtitle'),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 260,
              child: CustomPaint(
                painter: _CommunityMapPainter(
                  pharmacies: pharmacies,
                  theme: theme,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.t('map_legend'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: pharmacies
                .map(
                  (pharmacy) => Chip(
                    avatar: CircleAvatar(backgroundColor: pharmacy.accent),
                    label: Text(pharmacy.name),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CommunityMapPainter extends CustomPainter {
  _CommunityMapPainter({required this.pharmacies, required this.theme});

  final List<Pharmacy> pharmacies;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (var x = 0.0; x <= size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (pharmacies.isEmpty) return;

    final minLat = pharmacies.map((p) => p.lat).reduce(math.min);
    final maxLat = pharmacies.map((p) => p.lat).reduce(math.max);
    final minLng = pharmacies.map((p) => p.lng).reduce(math.min);
    final maxLng = pharmacies.map((p) => p.lng).reduce(math.max);

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (final pharmacy in pharmacies) {
      final dx =
          ((pharmacy.lng - minLng) / ((maxLng - minLng).abs() + 0.0001)) *
          size.width;
      final dy =
          size.height -
          ((pharmacy.lat - minLat) / ((maxLat - minLat).abs() + 0.0001)) *
              size.height;
      dotPaint.color = pharmacy.accent;
      canvas.drawCircle(Offset(dx, dy), 12, dotPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: pharmacy.name.split(' ').first,
          style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: 120);

      textPainter.paint(canvas, Offset(dx + 14, dy - 10));
    }
  }

  @override
  bool shouldRepaint(covariant _CommunityMapPainter oldDelegate) {
    return oldDelegate.pharmacies != pharmacies;
  }
}
