import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared shimmer primitives used across home, search, and listing screens.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  static const base = Color(0xFFE7ECF5);
  static const highlight = Color(0xFFF6F8FC);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: borderRadius,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: highlight,
        );
  }
}

class RunningLoaderBar extends StatelessWidget {
  const RunningLoaderBar({super.key, this.height = 3.0});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Container(color: ShimmerBox.base)
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1200.ms,
            color: ShimmerBox.highlight,
          ),
    );
  }
}
