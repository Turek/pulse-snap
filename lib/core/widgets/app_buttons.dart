import 'package:flutter/material.dart';

/// Reusable button wrappers mapped 1:1 to DESIGN.md's button tokens.
/// Use these instead of bare `FilledButton` / `TextButton` so swapping the
/// theme propagates to every button automatically.
///
/// - [PrimaryButton]      → DESIGN.md `button-primary` (filled `primary`).
/// - [SecondaryButton]    → DESIGN.md `button-secondary` (tonal `primary-container`).
/// - [TextActionButton]   → DESIGN.md `button-text` (low-emphasis).
///
/// Colors come from `Theme.of(context).colorScheme`; do NOT pass overrides.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: const StadiumBorder(),
      minimumSize: Size(expand ? double.infinity : 0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: style,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      shape: const StadiumBorder(),
      minimumSize: Size(expand ? double.infinity : 0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
    if (icon != null) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: style,
      );
    }
    return FilledButton.tonal(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class TextActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextButton.styleFrom(
      foregroundColor: scheme.primary,
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: style,
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}
