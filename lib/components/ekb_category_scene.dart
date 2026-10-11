import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Плоские мини-сцены категорий для заглушки «нет фото» — в стиле пейзажа:
/// голубые тона, жёлтый акцент, белые детали. Рисует в квадрате [size].
class EkbCategoryScenePainter extends CustomPainter {
  const EkbCategoryScenePainter(this.rootCategoryId);

  /// id корневой категории; неизвестный или null — пейзаж с горами.
  final int? rootCategoryId;

  static const soft = Color(0xFF8FA6DC);
  static const deep = Color(0xFF5677C9);
  static const light = Color(0xFFC3D2F3);
  static const sun = Color(0xFFFFC94D);
  static const white = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (rootCategoryId) {
      case 1:
        _auto(canvas, w, h);
      case 2:
        _job(canvas, w, h);
      case 3:
        _apartment(canvas, w, h);
      case 4:
        _services(canvas, w, h);
      case 5:
        _parttime(canvas, w, h);
      case 6:
        _repair(canvas, w, h);
      case 7:
        _beauty(canvas, w, h);
      case 8:
        _kids(canvas, w, h);
      case 9:
        _sale(canvas, w, h);
      case 11:
        _fromKg(canvas, w, h);
      case 12:
        _hotel(canvas, w, h);
      case 13:
        _entertainment(canvas, w, h);
      case 14:
        _border(canvas, w, h);
      default:
        _landscape(canvas, w, h);
    }
  }

  Paint _fill(Color c) => Paint()..color = c;

  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  RRect _rr(double l, double t, double r, double b, double radius) =>
      RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));

  void _sun(Canvas c, double w, double h, {double x = 0.76, double y = 0.26}) {
    c.drawCircle(Offset(w * x, h * y), w * 0.1, _fill(sun));
  }

  void _ground(Canvas c, double w, double h, {double top = 0.82}) {
    c.drawRect(Rect.fromLTRB(0, h * top, w, h), _fill(light));
  }

  // ── default ────────────────────────────────────────────────────────────
  void _landscape(Canvas c, double w, double h) {
    _sun(c, w, h, x: 0.72, y: 0.3);
    c.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * 0.38, h * 0.48)
        ..lineTo(w * 0.7, h)
        ..close(),
      _fill(soft),
    );
    c.drawPath(
      Path()
        ..moveTo(w * 0.35, h)
        ..lineTo(w * 0.68, h * 0.6)
        ..lineTo(w, h * 0.92)
        ..lineTo(w, h)
        ..close(),
      _fill(deep.withValues(alpha: 0.8)),
    );
  }

  // 1 · Авто: машина на дороге.
  void _auto(Canvas c, double w, double h) {
    _sun(c, w, h, x: 0.8, y: 0.22);
    _ground(c, w, h, top: 0.8);
    final dash = _stroke(white, h * 0.025);
    c.drawLine(Offset(w * 0.08, h * 0.9), Offset(w * 0.24, h * 0.9), dash);
    c.drawLine(Offset(w * 0.42, h * 0.9), Offset(w * 0.58, h * 0.9), dash);
    c.drawLine(Offset(w * 0.76, h * 0.9), Offset(w * 0.92, h * 0.9), dash);
    // Кабина.
    c.drawPath(
      Path()
        ..moveTo(w * 0.28, h * 0.56)
        ..lineTo(w * 0.36, h * 0.4)
        ..lineTo(w * 0.62, h * 0.4)
        ..lineTo(w * 0.72, h * 0.56)
        ..close(),
      _fill(soft),
    );
    c.drawRRect(
        _rr(w * 0.39, h * 0.44, w * 0.49, h * 0.55, w * 0.02), _fill(white));
    c.drawRRect(
        _rr(w * 0.52, h * 0.44, w * 0.62, h * 0.55, w * 0.02), _fill(white));
    // Кузов.
    c.drawRRect(
        _rr(w * 0.14, h * 0.54, w * 0.86, h * 0.72, w * 0.06), _fill(deep));
    c.drawCircle(Offset(w * 0.82, h * 0.6), w * 0.025, _fill(sun));
    // Колёса.
    for (final x in [0.3, 0.7]) {
      c.drawCircle(
          Offset(w * x, h * 0.73), w * 0.08, _fill(const Color(0xFF3B4F8F)));
      c.drawCircle(Offset(w * x, h * 0.73), w * 0.03, _fill(white));
    }
  }

  // 2 · Работа: портфель.
  void _job(Canvas c, double w, double h) {
    _sun(c, w, h, x: 0.82, y: 0.2);
    c.drawRRect(_rr(w * 0.38, h * 0.26, w * 0.62, h * 0.4, w * 0.05),
        _stroke(deep, w * 0.045));
    c.drawRRect(
        _rr(w * 0.16, h * 0.36, w * 0.84, h * 0.82, w * 0.08), _fill(soft));
    c.drawRect(
        Rect.fromLTRB(w * 0.16, h * 0.52, w * 0.84, h * 0.58), _fill(deep));
    c.drawRRect(
        _rr(w * 0.44, h * 0.48, w * 0.56, h * 0.62, w * 0.025), _fill(sun));
  }

  // 3 · Квартира: дом и многоэтажка.
  void _apartment(Canvas c, double w, double h) {
    _sun(c, w, h, x: 0.22, y: 0.22);
    _ground(c, w, h, top: 0.86);
    // Многоэтажка.
    c.drawRect(
        Rect.fromLTRB(w * 0.5, h * 0.2, w * 0.86, h * 0.86), _fill(deep));
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 2; col++) {
        final l = w * (0.56 + col * 0.15);
        final t = h * (0.27 + row * 0.14);
        c.drawRect(Rect.fromLTWH(l, t, w * 0.09, h * 0.08),
            _fill(row == 1 && col == 0 ? sun : white));
      }
    }
    // Домик.
    c.drawRect(
        Rect.fromLTRB(w * 0.14, h * 0.56, w * 0.46, h * 0.86), _fill(soft));
    c.drawPath(
      Path()
        ..moveTo(w * 0.1, h * 0.58)
        ..lineTo(w * 0.3, h * 0.4)
        ..lineTo(w * 0.5, h * 0.58)
        ..close(),
      _fill(deep.withValues(alpha: 0.85)),
    );
    c.drawRect(
        Rect.fromLTRB(w * 0.25, h * 0.68, w * 0.35, h * 0.86), _fill(white));
  }

  // 4 · Услуги: шестерёнка.
  void _services(Canvas c, double w, double h) {
    final center = Offset(w * 0.5, h * 0.52);
    final r = w * 0.25;
    final tooth = _fill(soft);
    for (var i = 0; i < 8; i++) {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(i * math.pi / 4);
      c.drawRRect(
          _rr(-w * 0.06, -r - w * 0.09, w * 0.06, -r + w * 0.02, w * 0.02),
          tooth);
      c.restore();
    }
    c.drawCircle(center, r, _fill(soft));
    c.drawCircle(center, r * 0.55, _fill(deep));
    c.drawCircle(center, r * 0.26, _fill(sun));
    c.drawCircle(Offset(w * 0.84, h * 0.18), w * 0.05, _fill(sun));
  }

  // 5 · Подработка: часы и монета.
  void _parttime(Canvas c, double w, double h) {
    final center = Offset(w * 0.46, h * 0.5);
    c.drawCircle(center, w * 0.3, _fill(soft));
    c.drawCircle(center, w * 0.24, _fill(white));
    final hand = _stroke(deep, w * 0.045);
    c.drawLine(center, center + Offset(0, -w * 0.15), hand);
    c.drawLine(center, center + Offset(w * 0.11, w * 0.04), hand);
    c.drawCircle(center, w * 0.035, _fill(deep));
    // Монета.
    final coin = Offset(w * 0.76, h * 0.76);
    c.drawCircle(coin, w * 0.13, _fill(sun));
    c.drawCircle(coin, w * 0.085, _stroke(const Color(0xFFE5A92B), w * 0.025));
  }

  // 6 · Ремонт: молоток.
  void _repair(Canvas c, double w, double h) {
    _sun(c, w, h, x: 0.2, y: 0.22);
    c.save();
    c.translate(w * 0.54, h * 0.52);
    c.rotate(-math.pi / 4);
    c.drawRRect(
        _rr(-w * 0.05, -h * 0.05, w * 0.05, h * 0.42, w * 0.04), _fill(sun));
    c.drawRRect(
        _rr(-w * 0.26, -h * 0.2, w * 0.2, -h * 0.02, w * 0.04), _fill(deep));
    c.drawRRect(
        _rr(w * 0.12, -h * 0.17, w * 0.28, -h * 0.05, w * 0.03), _fill(soft));
    c.restore();
  }

  // 7 · Красота: флакон и блёстки.
  void _beauty(Canvas c, double w, double h) {
    c.drawRRect(
        _rr(w * 0.32, h * 0.36, w * 0.64, h * 0.84, w * 0.08), _fill(soft));
    c.drawRRect(_rr(w * 0.38, h * 0.5, w * 0.58, h * 0.7, w * 0.03),
        _fill(white.withValues(alpha: 0.85)));
    c.drawRect(
        Rect.fromLTRB(w * 0.42, h * 0.28, w * 0.54, h * 0.37), _fill(deep));
    c.drawRRect(
        _rr(w * 0.38, h * 0.16, w * 0.58, h * 0.29, w * 0.04), _fill(deep));
    _sparkle(c, Offset(w * 0.78, h * 0.3), w * 0.09, sun);
    _sparkle(c, Offset(w * 0.18, h * 0.56), w * 0.06, sun);
    _sparkle(c, Offset(w * 0.8, h * 0.66), w * 0.045, soft);
  }

  void _sparkle(Canvas c, Offset o, double r, Color color) {
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
        ..close(),
      _fill(color),
    );
  }

  // 8 · Детям: воздушные шарики.
  void _kids(Canvas c, double w, double h) {
    final string = _stroke(deep.withValues(alpha: 0.6), w * 0.018);
    c.drawLine(Offset(w * 0.4, h * 0.58), Offset(w * 0.5, h * 0.92), string);
    c.drawLine(Offset(w * 0.66, h * 0.52), Offset(w * 0.5, h * 0.92), string);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.66, h * 0.34),
            width: w * 0.32,
            height: h * 0.38),
        _fill(sun));
    c.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.38, h * 0.4),
            width: w * 0.34,
            height: h * 0.4),
        _fill(soft));
    c.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.32, h * 0.32),
            width: w * 0.07,
            height: h * 0.1),
        _fill(white.withValues(alpha: 0.7)));
  }

  // 9 · Купи/продай: ценник.
  void _sale(Canvas c, double w, double h) {
    c.save();
    c.translate(w * 0.5, h * 0.52);
    c.rotate(-math.pi / 9);
    final tag = Path()
      ..moveTo(-w * 0.3, -h * 0.2)
      ..lineTo(w * 0.14, -h * 0.2)
      ..lineTo(w * 0.32, 0)
      ..lineTo(w * 0.14, h * 0.2)
      ..lineTo(-w * 0.3, h * 0.2)
      ..close();
    c.drawPath(tag, _fill(sun));
    c.drawCircle(Offset(w * 0.14, 0), w * 0.045, _fill(white));
    final line = _stroke(const Color(0xFFE5A92B), w * 0.035);
    c.drawLine(Offset(-w * 0.2, -h * 0.07), Offset(w * 0.02, -h * 0.07), line);
    c.drawLine(Offset(-w * 0.2, h * 0.06), Offset(-w * 0.04, h * 0.06), line);
    c.restore();
    c.drawCircle(Offset(w * 0.2, h * 0.2), w * 0.05, _fill(soft));
    c.drawCircle(Offset(w * 0.82, h * 0.82), w * 0.04, _fill(soft));
  }

  // 11 · Из Кыргызстана: юрта и горы.
  void _fromKg(Canvas c, double w, double h) {
    c.drawPath(
      Path()
        ..moveTo(w * 0.05, h * 0.7)
        ..lineTo(w * 0.3, h * 0.3)
        ..lineTo(w * 0.55, h * 0.7)
        ..close(),
      _fill(light),
    );
    c.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.43)
        ..lineTo(w * 0.3, h * 0.3)
        ..lineTo(w * 0.38, h * 0.43)
        ..close(),
      _fill(white),
    );
    _sun(c, w, h, x: 0.78, y: 0.22);
    _ground(c, w, h, top: 0.86);
    // Юрта.
    c.drawRect(
        Rect.fromLTRB(w * 0.36, h * 0.6, w * 0.88, h * 0.86), _fill(white));
    c.drawPath(
      Path()
        ..moveTo(w * 0.33, h * 0.62)
        ..quadraticBezierTo(w * 0.62, h * 0.3, w * 0.91, h * 0.62)
        ..close(),
      _fill(deep),
    );
    c.drawLine(Offset(w * 0.36, h * 0.7), Offset(w * 0.88, h * 0.7),
        _stroke(sun, w * 0.025));
    c.drawRRect(
        _rr(w * 0.56, h * 0.72, w * 0.68, h * 0.86, w * 0.02), _fill(soft));
  }

  // 12 · Гостиница: кровать.
  void _hotel(Canvas c, double w, double h) {
    c.drawCircle(Offset(w * 0.78, h * 0.22), w * 0.09, _fill(sun));
    c.drawCircle(
        Offset(w * 0.74, h * 0.19), w * 0.08, _fill(const Color(0xFFEAF0FF)));
    c.drawRRect(
        _rr(w * 0.12, h * 0.36, w * 0.24, h * 0.82, w * 0.04), _fill(deep));
    c.drawRRect(
        _rr(w * 0.12, h * 0.6, w * 0.88, h * 0.74, w * 0.03), _fill(deep));
    c.drawRRect(
        _rr(w * 0.26, h * 0.48, w * 0.44, h * 0.6, w * 0.05), _fill(white));
    c.drawRRect(
        _rr(w * 0.42, h * 0.5, w * 0.88, h * 0.62, w * 0.04), _fill(soft));
    c.drawRect(
        Rect.fromLTRB(w * 0.8, h * 0.72, w * 0.88, h * 0.82), _fill(deep));
  }

  // 13 · Развлечения: билет и звезда.
  void _entertainment(Canvas c, double w, double h) {
    c.save();
    c.translate(w * 0.5, h * 0.55);
    c.rotate(-math.pi / 12);
    final ticket = Path()
      ..addRRect(_rr(-w * 0.34, -h * 0.17, w * 0.34, h * 0.17, w * 0.05));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(-w * 0.34, 0), radius: w * 0.06))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.34, 0), radius: w * 0.06));
    c.drawPath(
        Path.combine(PathOperation.difference, ticket, notches), _fill(soft));
    final perf = _stroke(white, w * 0.02);
    for (var i = -2; i <= 2; i++) {
      c.drawLine(Offset(w * 0.14, h * i * 0.06 - h * 0.015),
          Offset(w * 0.14, h * i * 0.06 + h * 0.015), perf);
    }
    _star(c, Offset(-w * 0.1, 0), w * 0.11, sun);
    c.restore();
    _sparkle(c, Offset(w * 0.8, h * 0.2), w * 0.06, sun);
    _sparkle(c, Offset(w * 0.18, h * 0.24), w * 0.045, deep);
  }

  void _star(Canvas c, Offset o, double r, Color color) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(o.dx + rad * math.cos(a), o.dy + rad * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(p..close(), _fill(color));
  }

  // 14 · Граница: шлагбаум.
  void _border(Canvas c, double w, double h) {
    _sun(c, w, h, x: 0.8, y: 0.22);
    _ground(c, w, h, top: 0.82);
    c.drawRRect(
        _rr(w * 0.14, h * 0.4, w * 0.26, h * 0.82, w * 0.03), _fill(deep));
    c.drawCircle(Offset(w * 0.2, h * 0.4), w * 0.07, _fill(deep));
    // Стрела в полоску.
    final arm = _rr(w * 0.2, h * 0.36, w * 0.92, h * 0.46, w * 0.04);
    c.drawRRect(arm, _fill(white));
    c.save();
    c.clipRRect(arm);
    for (var i = 0; i < 4; i++) {
      final l = w * (0.3 + i * 0.17);
      c.drawRect(Rect.fromLTRB(l, h * 0.36, l + w * 0.085, h * 0.46),
          _fill(const Color(0xFFE5A92B)));
    }
    c.restore();
    c.drawCircle(Offset(w * 0.2, h * 0.41), w * 0.03, _fill(sun));
  }

  @override
  bool shouldRepaint(covariant EkbCategoryScenePainter oldDelegate) =>
      oldDelegate.rootCategoryId != rootCategoryId;
}
