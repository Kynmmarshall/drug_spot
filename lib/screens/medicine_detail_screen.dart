import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../widgets/section_card.dart';
import 'chat_screen.dart';

class MedicineDetailScreen extends StatefulWidget {
  const MedicineDetailScreen({
    super.key,
    required this.medicine,
    required this.pharmacy,
  });

  final Medicine medicine;
  final Pharmacy pharmacy;

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  bool _openingChat = false;

  Future<void> _openChat(int pharmacyUserId) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);

    try {
      final data = await context.appState.api.startConversation(pharmacyUserId);
      if (!mounted) return;
      final names =
          (data['participant_names'] as List? ?? []).map((v) => '$v').toList();
      final ids = (data['participant_ids'] as List? ?? [])
          .map((v) => int.tryParse('$v'))
          .whereType<int>()
          .toList();
      final myId = context.appState.api.userId ?? 0;
      final myIdx = ids.indexOf(myId);
      final otherIdx = myIdx == 0 ? 1 : 0;
      final otherName = names.length > otherIdx
          ? names[otherIdx]
          : context.l10n.t('chat_title');
      final conversationId = int.tryParse('${data['id']}');
      if (conversationId == null) {
        throw ApiException('Could not open chat. Please try again.', 0);
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherName: otherName,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _openingChat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = widget.pharmacy.accent;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('medicine_details_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          _HeroCard(
            medicine: widget.medicine,
            pharmacy: widget.pharmacy,
            accent: accent,
          ),
          const SizedBox(height: 24),
          SectionCard(
            icon: Icons.local_pharmacy,
            title: l10n.t('medicine_details_pharmacy'),
            subtitle: widget.pharmacy.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: widget.pharmacy.address,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: '${l10n.t('medicine_details_contact')}: '
                      '${widget.pharmacy.phone}',
                ),
                if (widget.pharmacy.userId != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openingChat
                          ? null
                          : () => _openChat(widget.pharmacy.userId!),
                      icon: _openingChat
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_rounded),
                      label: Text(l10n.t('chat_message_pharmacy')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.medicine,
    required this.pharmacy,
    required this.accent,
  });

  final Medicine medicine;
  final Pharmacy pharmacy;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication_liquid, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            medicine.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('medicine_details_overview'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: l10n.t('medicine_price'),
                  value: l10n.priceLabel(medicine.price),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricPill(
                  label: l10n.t('medicine_details_distance'),
                  value: l10n.distanceAway(medicine.distanceKm),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.t('assign_pharmacy')}: ${pharmacy.name}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
