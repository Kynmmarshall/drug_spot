import 'package:flutter/material.dart';

class DashboardActionBar extends StatelessWidget {
  const DashboardActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children
              .map(
                (child) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
