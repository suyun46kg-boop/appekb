import 'package:flutter/material.dart';

/// Visual tokens for Apple-like Liquid Glass (concept-faithful, not flat glassmorphism).
abstract final class LiquidGlassTokens {
  static const double radiusCompact = 28;
  static const double radiusComfort = 32;
  static const double radiusPill = 34;

  /// Soft periwinkle used in premium liquid-glass concepts.
  static const Color neonBlue = Color(0xFF3B82F6);
  static const Color neonBlueDeep = Color(0xFF1D4ED8);
  static const Color neonBlueSoft = Color(0xFF93C5FD);
  static const Color neonBlueHot = Color(0xFF60A5FA);

  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1C1C1E);

  /// Outer soft elevation — never hard / single-shadow.
  static List<BoxShadow> outerRest({required double press}) {
    // press: 0 = rest, 1 = fully pressed → shadows collapse (glass “sinks”).
    final t = press.clamp(0.0, 1.0);
    final lift = 1.0 - t;
    return [
      BoxShadow(
        color: const Color(0x14000000),
        blurRadius: 6 + 4 * lift,
        offset: Offset(0, 2 + 2 * lift),
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.10 * lift + 0.03),
        blurRadius: 18 * lift + 5,
        offset: Offset(0, 8 * lift + 2),
        spreadRadius: -5,
      ),
      BoxShadow(
        color: Color.fromRGBO(255, 255, 255, 0.55 * lift),
        blurRadius: 1.5,
        offset: const Offset(0, -0.5),
      ),
      // Bright blue neon bloom
      BoxShadow(
        color: Color.fromRGBO(59, 130, 246, 0.55 * lift + 0.28),
        blurRadius: 22 + 14 * lift,
        offset: Offset(0, 4 * lift),
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Color.fromRGBO(37, 99, 235, 0.35 * lift + 0.18),
        blurRadius: 36 + 10 * lift,
        offset: const Offset(0, 0),
        spreadRadius: 0,
      ),
    ];
  }
}
