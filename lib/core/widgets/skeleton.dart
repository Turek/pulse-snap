import 'package:flutter/material.dart';

/// Minimal shimmer-free skeleton block; respects reduced-motion by being
/// static. Use as a placeholder while data loads (>300ms).
class Skeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: const [
        Skeleton(width: 80, height: 14),
        SizedBox(height: 8),
        Skeleton(height: 96, radius: 16),
        SizedBox(height: 24),
        Skeleton(width: 100, height: 14),
        SizedBox(height: 8),
        Skeleton(height: 96, radius: 12),
        SizedBox(height: 24),
        Skeleton(width: 80, height: 14),
        SizedBox(height: 8),
        Skeleton(height: 72, radius: 16),
      ],
    );
  }
}
