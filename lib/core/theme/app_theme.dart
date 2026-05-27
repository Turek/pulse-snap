import 'package:flutter/material.dart';

/// PulseSnap theme — the single source of truth for brand colors and
/// typography. All screens read from `Theme.of(context).colorScheme` so
/// swapping a token here propagates everywhere.
///
/// Palette and type scale come from `DESIGN.md` at the repo root.
ThemeData buildTheme(ColorScheme? _, Brightness brightness) {
  final colorScheme = brightness == Brightness.dark
      ? _darkScheme
      : _lightScheme;

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    fontFamily: 'Roboto',
  );

  final textTheme = _buildTextTheme(colorScheme);

  const pillShape = StadiumBorder();
  final buttonMinSize = const Size(0, 48);

  return base.copyWith(
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.secondary,
      foregroundColor: colorScheme.onSecondary,
      shape: const StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pillShape,
        minimumSize: buttonMinSize,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: pillShape,
        minimumSize: buttonMinSize,
        foregroundColor: colorScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pillShape,
        minimumSize: buttonMinSize,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.onPrimaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Color schemes (light + dark) — locked to DESIGN.md brand palette.
// ──────────────────────────────────────────────────────────────────────────

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF6B5EAE),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE6E0FF),
  onPrimaryContainer: Color(0xFF22005D),
  secondary: Color(0xFF944A6B),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFD9E2),
  onSecondaryContainer: Color(0xFF3E001D),
  tertiary: Color(0xFF49A17A),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFC3F0DA),
  onTertiaryContainer: Color(0xFF00391F),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFAF9FF),
  onSurface: Color(0xFF1C1B1F),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF4F2FA),
  surfaceContainer: Color(0xFFEEECF5),
  surfaceContainerHigh: Color(0xFFE8E5F0),
  surfaceContainerHighest: Color(0xFFE2DFEA),
  surfaceDim: Color(0xFFDDD9E4),
  surfaceBright: Color(0xFFFAF9FF),
  onSurfaceVariant: Color(0xFF49454F),
  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),
  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFCFBCFF),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFCFBCFF),
  onPrimary: Color(0xFF381E72),
  primaryContainer: Color(0xFF503A93),
  onPrimaryContainer: Color(0xFFE6E0FF),
  secondary: Color(0xFFFFB0CC),
  onSecondary: Color(0xFF5B1138),
  secondaryContainer: Color(0xFF77294F),
  onSecondaryContainer: Color(0xFFFFD9E2),
  tertiary: Color(0xFFA8D5B9),
  onTertiary: Color(0xFF003920),
  tertiaryContainer: Color(0xFF1F5E3D),
  onTertiaryContainer: Color(0xFFC3F0DA),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF141318),
  onSurface: Color(0xFFE6E1E9),
  surfaceContainerLowest: Color(0xFF0E0D12),
  surfaceContainerLow: Color(0xFF1C1B20),
  surfaceContainer: Color(0xFF201F24),
  surfaceContainerHigh: Color(0xFF2A292E),
  surfaceContainerHighest: Color(0xFF353439),
  surfaceDim: Color(0xFF141318),
  surfaceBright: Color(0xFF3A383E),
  onSurfaceVariant: Color(0xFFCAC4D0),
  outline: Color(0xFF948F99),
  outlineVariant: Color(0xFF49454F),
  inverseSurface: Color(0xFFE6E1E9),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF6B5EAE),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

// ──────────────────────────────────────────────────────────────────────────
// Type scale — built directly from DESIGN.md (Roboto throughout).
// ──────────────────────────────────────────────────────────────────────────

TextTheme _buildTextTheme(ColorScheme scheme) {
  const family = 'Roboto';
  final onSurface = scheme.onSurface;
  return TextTheme(
    // headline-lg
    displayLarge: TextStyle(
      fontFamily: family,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: onSurface,
    ),
    // reading-display (40/700)
    displayMedium: TextStyle(
      fontFamily: family,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.8,
      color: onSurface,
    ),
    displaySmall: TextStyle(
      fontFamily: family,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: onSurface,
    ),
    headlineLarge: TextStyle(
      fontFamily: family,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: onSurface,
    ),
    // headline-md
    headlineMedium: TextStyle(
      fontFamily: family,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: onSurface,
    ),
    // headline-sm
    headlineSmall: TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: onSurface,
    ),
    titleLarge: TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: onSurface,
    ),
    titleMedium: TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: onSurface,
    ),
    titleSmall: TextStyle(
      fontFamily: family,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: onSurface,
    ),
    // body-lg
    bodyLarge: TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: onSurface,
    ),
    // body-md
    bodyMedium: TextStyle(
      fontFamily: family,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: onSurface,
    ),
    // body-sm
    bodySmall: TextStyle(
      fontFamily: family,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: onSurface,
    ),
    // label-lg
    labelLarge: TextStyle(
      fontFamily: family,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0.1,
      color: onSurface,
    ),
    // label-md
    labelMedium: TextStyle(
      fontFamily: family,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0.5,
      color: onSurface,
    ),
    // label-caps (used for section headers via .copyWith on labelLarge in screens
    // — see AppTextStyles.sectionCaps below).
    labelSmall: TextStyle(
      fontFamily: family,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0.5,
      color: onSurface,
    ),
  );
}

/// Named text styles that don't fit cleanly on Material's `textTheme` slots.
/// Use these from screens instead of hand-rolling fonts.
class AppTextStyles {
  AppTextStyles._();

  /// DESIGN.md `label-caps` — uppercase section headers (LATEST, etc).
  static TextStyle sectionCaps(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 1.32, // 0.12em ≈ 11 * 0.12
      color: scheme.onSurfaceVariant,
    );
  }

  /// DESIGN.md `reading-display` — 40/700 hero numbers.
  static TextStyle readingDisplay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.1,
      letterSpacing: -0.8,
      color: scheme.onSurface,
    );
  }

  /// DESIGN.md `reading-unit` — mmHg/bpm beside the hero number.
  static TextStyle readingUnit(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.0,
      color: scheme.onSurfaceVariant,
    );
  }
}
