import 'package:flutter/material.dart';

import 'liquid_glass_tokens.dart';

/// Soft caustic / ambient light field under the glass (gives blur something to refract).
class LiquidGlassAmbientField extends StatelessWidget {
  const LiquidGlassAmbientField({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _AmbientFieldPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _AmbientFieldPainter extends CustomPainter {
  const _AmbientFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base cool wash — brighter blue core
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFDBEAFE),
          Color(0xFF93C5FD),
          Color(0xFF60A5FA),
          Color(0xFFBFDBFE),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    // Specular caustic blob (top-left light)
    final caustic = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.55, -0.75),
        radius: 1.05,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          LiquidGlassTokens.neonBlueHot.withValues(alpha: 0.75),
          LiquidGlassTokens.neonBlue.withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.28, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, caustic);

    // Bottom-right blue light pool — hot
    final pool = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, 0.95),
        radius: 1.05,
        colors: [
          LiquidGlassTokens.neonBlueDeep.withValues(alpha: 0.75),
          LiquidGlassTokens.neonBlue.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, pool);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws true-feeling inner shadows (Flutter has no inset BoxShadow).
class LiquidGlassInnerShadowPainter extends CustomPainter {
  const LiquidGlassInnerShadowPainter({
    required this.radius,
    required this.press,
  });

  final double radius;
  final double press;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    final t = press.clamp(0.0, 1.0);

    // Top inner white (bevel) — strengthens on press (glass compresses / glare).
    final top = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.55 + 0.25 * t),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.42));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.42), top);

    // Bottom inner dark (thickness)
    final bottom = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.black.withValues(alpha: 0.14 + 0.06 * t),
          Colors.black.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.45, size.width, size.height * 0.55),
      bottom,
    );

    // Side rim darkening (lens edge)
    final side = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.black.withValues(alpha: 0.06),
          Colors.transparent,
          Colors.transparent,
          Colors.black.withValues(alpha: 0.07),
        ],
        stops: const [0.0, 0.12, 0.88, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, side);

    canvas.restore();

    // Hairline specular stroke
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.85),
          Colors.white.withValues(alpha: 0.25),
          LiquidGlassTokens.neonBlueSoft.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.15),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect.deflate(0.35), stroke);
  }

  @override
  bool shouldRepaint(covariant LiquidGlassInnerShadowPainter oldDelegate) =>
      oldDelegate.press != press || oldDelegate.radius != radius;
}
