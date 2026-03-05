import 'package:flutter/material.dart';

import '../core/context_extensions.dart';
import '../models/app_language.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final width = dense ? 120.0 : 170.0;
    return SizedBox(
      width: width,
      child: SegmentedButton<AppLanguage>(
        segments: AppLanguage.values
            .map(
              (lang) => ButtonSegment<AppLanguage>(
                value: lang,
                label: Text(lang.shortLabel),
              ),
            )
            .toList(),
        showSelectedIcon: false,
        selected: {state.language},
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            TextStyle(fontSize: dense ? 12 : 14, fontWeight: FontWeight.w600),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: dense ? 8 : 16,
              vertical: dense ? 8 : 12,
            ),
          ),
        ),
        onSelectionChanged: (selection) => state.setLanguage(selection.first),
      ),
    );
  }
}
