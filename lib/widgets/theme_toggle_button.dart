import 'package:flutter/material.dart';

import '../core/context_extensions.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final isDark = state.themeMode == ThemeMode.dark;
    return IconButton(
      tooltip: context.l10n.t(isDark ? 'light_theme' : 'dark_theme'),
      icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded),
      onPressed: state.toggleTheme,
    );
  }
}
