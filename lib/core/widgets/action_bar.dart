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
  final int flex;
  final _ActionButtonKind _kind;

  const ActionButton.primary({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.flex = 1,
  }) : _kind = _ActionButtonKind.primary;

  const ActionButton.tonal({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.flex = 1,
  }) : _kind = _ActionButtonKind.tonal;

  const ActionButton.danger({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.flex = 1,
  }) : _kind = _ActionButtonKind.danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const minSize = Size.fromHeight(52);

    Widget btn;
    switch (_kind) {
      case _ActionButtonKind.primary:
        btn = FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      case _ActionButtonKind.tonal:
        btn = FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
          ),
        );
      case _ActionButtonKind.danger:
        btn = OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: scheme.error),
          label: Text(label, style: TextStyle(color: scheme.error)),
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            shape: shape,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
          ),
        );
    }
    return Expanded(flex: flex, child: btn);
  }
}

enum _ActionButtonKind { primary, tonal, danger }
