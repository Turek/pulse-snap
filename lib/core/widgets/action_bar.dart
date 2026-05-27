import 'package:flutter/material.dart';

/// Bottom action bar used on Review + Reading Detail. Sits inside a
/// Scaffold's [bottomNavigationBar] slot, respects safe-area, and gives
/// the buttons a consistent height and rhythm.
class ActionBar extends StatelessWidget {
  final List<Widget> children;
  const ActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: children),
        ),
      ),
    );
  }
}

/// Material 3 button used inside [ActionBar]. Three intents:
/// - `primary`   – filled, highest emphasis (Save / Edit)
/// - `tonal`     – filled tonal, medium emphasis (Cancel / Retake)
/// - `danger`    – outlined with error tint (Delete)
class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final _ActionButtonKind _kind;

  const ActionButton.primary({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : _kind = _ActionButtonKind.primary;

  const ActionButton.tonal({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : _kind = _ActionButtonKind.tonal;

  const ActionButton.danger({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  }) : _kind = _ActionButtonKind.danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const shape = StadiumBorder();
    const minSize = Size.fromHeight(48);

    Widget btn;
    switch (_kind) {
      case _ActionButtonKind.primary:
        // DESIGN.md button-primary — filled brand primary, white text.
        btn = FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label, overflow: TextOverflow.ellipsis),
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      case _ActionButtonKind.tonal:
        // DESIGN.md button-secondary — tonal primary-container.
        btn = FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label, overflow: TextOverflow.ellipsis),
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      case _ActionButtonKind.danger:
        btn = FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: scheme.onErrorContainer),
          label: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
        );
    }
    return Expanded(child: btn);
  }
}

enum _ActionButtonKind { primary, tonal, danger }
