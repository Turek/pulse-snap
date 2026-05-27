import 'package:flutter/material.dart';

/// One shared surface treatment used everywhere meaningful content lives:
/// rounded corners, a subtle accent-coloured gradient, light border. This
/// is the design language across the app — use this instead of raw [Card]
/// so every section feels like part of the same family.
class TintedCard extends StatelessWidget {
  final Color accent;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const TintedCard({
    super.key,
    required this.accent,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return ClipRRect(borderRadius: BorderRadius.circular(radius), child: content);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Semantic accent colour palette used by [TintedCard] across the app.
/// Pick by what the section *means*, not by what colour you want today.
/// Tokens align with the DESIGN.md brand palette.
class SectionAccent {
  /// Primary brand periwinkle — calendars, hero surfaces.
  static const sky = Color(0xFF6B5EAE);

  /// Tertiary sage — averages, healthy-state cards.
  static const health = Color(0xFF49A17A);

  /// Secondary dusty rose — accents for warm/secondary surfaces.
  static const sand = Color(0xFF944A6B);

  /// Neutral slate — list rows, dense data backgrounds.
  static const slate = Color(0xFF79747E);
}
