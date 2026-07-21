import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// EKBKG sunflower mark — geometry from web/logo.svg (logo.html).
class EkbkgLogo extends StatelessWidget {
  const EkbkgLogo({
    super.key,
    this.size = 120,
    this.color = brandYellow,
  });

  final double size;
  final Color color;

  static const Color brandYellow = Color(0xFFFFCC00);

  /// Paints the logo into [canvas] using the 120×120 viewBox from logo.svg.
  static void paint(Canvas canvas, {Color color = brandYellow}) {
    const viewSize = 120.0;
    const center = Offset(60, 60);
    const coreRadius = 18.0;
    const petalDistance = 37.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -petalDistance);
      canvas.drawPath(_petalPath, paint);
      canvas.restore();
    }

    canvas.drawCircle(center, coreRadius, paint);
  }

  static final _petalPath = Path()
    ..moveTo(0, -15)
    ..cubicTo(7.6, -9.8, 7.6, 9.8, 0, 15)
    ..cubicTo(-7.6, 9.8, -7.6, -9.8, 0, -15)
    ..close();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EkbkgLogoPainter(color: color),
      ),
    );
  }
}

class _EkbkgLogoPainter extends CustomPainter {
  _EkbkgLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.scale(scale);
    EkbkgLogo.paint(canvas, color: color);
  }

  @override
  bool shouldRepaint(covariant _EkbkgLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Renders logo to PNG bytes (used by splash asset generator).
Future<Uint8List> ekbkgLogoPngBytes(
  double size, {
  Color color = EkbkgLogo.brandYellow,
  double logoScale = 1.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final drawSize = size * logoScale;
  final offset = (size - drawSize) / 2;
  canvas.translate(offset, offset);
  canvas.scale(drawSize / 120.0);
  EkbkgLogo.paint(canvas, color: color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.ceil(), size.ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('Failed to encode EKBKG logo PNG');
  }
  return bytes.buffer.asUint8List();
}
