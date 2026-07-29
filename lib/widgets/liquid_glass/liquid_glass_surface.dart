import 'dart:ui';

import 'package:flutter/material.dart';

import 'liquid_glass_painters.dart';
import 'liquid_glass_tokens.dart';

/// Multi-layer Liquid Glass surface (lens / thick glass, not flat glassmorphism).
///
/// Layer stack (back → front):
/// 1 Background field (ambient caustics)
/// 2 Internal blur of that field
/// 3 Backdrop blur (page content, if any)
/// 4 Glass body gradient
/// 5 Blue light pool
/// 6 Ambient light wash
/// 7 Reflection band
/// 8 White highlight rim
/// 9 Inner shadows + hairline (painter)
/// 10 Child content
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = LiquidGlassTokens.radiusComfort,
    this.press = 0,
    this.tintStrength = 1,
  });

  final Widget child;
  final double borderRadius;
  final double press;
  final double tintStrength;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final t = press.clamp(0.0, 1.0);
    // On press: glass densifies slightly (less airy, more contact).
    final bodyTop = 0.42 - 0.10 * t;
    final bodyBottom = 0.18 - 0.04 * t;
    final blueGlow = 0.72 + 0.2 * t;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: LiquidGlassTokens.outerRest(press: t),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- 1 + 8 ambient / blue light field under the lens ---
            const LiquidGlassAmbientField(),

            // --- 3 Internal blur (thick glass refraction of own field) ---
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 18 + 6 * t,
                sigmaY: 18 + 6 * t,
                tileMode: TileMode.decal,
              ),
              child: Transform.scale(
                scale: 1.18,
                child: const LiquidGlassAmbientField(),
              ),
            ),

            // --- 1 Background blur of whatever sits behind this widget ---
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 22,
                sigmaY: 22,
                tileMode: TileMode.clamp,
              ),
              child: const ColoredBox(color: Color(0x00FFFFFF)),
            ),

            // --- 2 Glass body — brighter blue tint ---
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: bodyTop * tintStrength),
                    LiquidGlassTokens.neonBlueHot
                        .withValues(alpha: 0.42 * tintStrength),
                    LiquidGlassTokens.neonBlue
                        .withValues(alpha: 0.38 * tintStrength + bodyBottom),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // --- 9 Blue light layer — max bright ---
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, -0.4),
                    radius: 1.2,
                    colors: [
                      LiquidGlassTokens.neonBlueHot
                          .withValues(alpha: 0.75 * blueGlow),
                      LiquidGlassTokens.neonBlue
                          .withValues(alpha: 0.45 * blueGlow),
                      LiquidGlassTokens.neonBlueDeep
                          .withValues(alpha: 0.2 * blueGlow),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // --- 8 Ambient light layer (top-left soft fill) ---
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.7, -0.9),
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.55 + 0.2 * t),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // --- 7 Reflection layer (diagonal specular sheet) ---
            IgnorePointer(
              child: Opacity(
                opacity: 0.55 + 0.25 * t,
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: const Alignment(-1.0, -1.0),
                    end: const Alignment(0.4, 0.35),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.15, 0.42, 0.62],
                  ).createShader(bounds),
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),

            // --- 4 White highlight (primary top rim) ---
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.34,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.72 + 0.18 * t),
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- 5 Bottom shadow / denser glass foot ---
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.4,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          LiquidGlassTokens.neonBlueDeep
                              .withValues(alpha: 0.16 + 0.08 * t),
                          Colors.black.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- 6 Inner shadow + hairline stroke ---
            IgnorePointer(
              child: CustomPaint(
                painter: LiquidGlassInnerShadowPainter(
                  radius: borderRadius,
                  press: t,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // Content
            child,
          ],
        ),
      ),
    );
  }
}
