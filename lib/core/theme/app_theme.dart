import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PulseSnap visual identity:
/// - Figtree for display/headline/title (geometric, modern, clean)
/// - Noto Sans for body/label (excellent legibility, broad language coverage)
/// - Medical blue seed; Material 3 dynamic colour preferred when available
/// - Rounded 20px cards (matches [TintedCard])
ThemeData buildTheme(ColorScheme? dynamicScheme, Brightness brightness) {
  final colorScheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B6CA8),
        brightness: brightness,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );

  final headlineFont = GoogleFonts.figtree;
  final bodyFont = GoogleFonts.notoSans;

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: headlineFont(textStyle: base.textTheme.displayLarge),
      displayMedium: headlineFont(textStyle: base.textTheme.displayMedium),
      displaySmall: headlineFont(textStyle: base.textTheme.displaySmall),
      headlineLarge: headlineFont(textStyle: base.textTheme.headlineLarge),
      headlineMedium: headlineFont(textStyle: base.textTheme.headlineMedium),
      headlineSmall: headlineFont(textStyle: base.textTheme.headlineSmall),
      titleLarge: headlineFont(textStyle: base.textTheme.titleLarge),
      titleMedium: headlineFont(textStyle: base.textTheme.titleMedium),
      titleSmall: headlineFont(textStyle: base.textTheme.titleSmall),
      bodyLarge: bodyFont(textStyle: base.textTheme.bodyLarge),
      bodyMedium: bodyFont(textStyle: base.textTheme.bodyMedium),
      bodySmall: bodyFont(textStyle: base.textTheme.bodySmall),
      labelLarge: bodyFont(textStyle: base.textTheme.labelLarge),
      labelMedium: bodyFont(textStyle: base.textTheme.labelMedium),
      labelSmall: bodyFont(textStyle: base.textTheme.labelSmall),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: colorScheme.surfaceContainerLow,
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: GoogleFonts.figtree(
        textStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
