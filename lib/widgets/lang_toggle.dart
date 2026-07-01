import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/app_language.dart';

class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final isEn = appState.language == AppLanguage.en;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        onPressed: () => appState.setLanguage(
          isEn ? AppLanguage.fr : AppLanguage.en,
        ),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Text(
          isEn ? 'FR' : 'EN',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
