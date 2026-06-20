import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => _themeFor(Brightness.light);

  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final background = isLight
        ? const Color(0xFFF4F6FB)
        : const Color(0xFF050B18);
    final surface = isLight ? Colors.white : const Color(0xFF0F172A);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: brightness,
    ).copyWith(surface: surface);

    final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: isLight ? const Color(0xFF0F172A) : Colors.white,
      displayColor: isLight ? const Color(0xFF0F172A) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF0F1A32),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
