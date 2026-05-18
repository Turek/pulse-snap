import 'package:flutter/material.dart';

ThemeData buildTheme(ColorScheme? dynamicScheme, Brightness brightness) {
  final colorScheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B6CA8),
        brightness: brightness,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    typography: Typography.material2021(),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
    ),
  );
}
