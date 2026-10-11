import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/category_utils.dart';
import '/components/ekb_category_scene.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Заглушка «Нет фото» для объявлений без картинки. Рисуется кодом, поэтому
/// чёткая на любом размере и переводится на оба языка. С [categoryId]
/// внутри карточки рисуется сцена этой категории вместо пейзажа.
class EkbNoPhoto extends StatelessWidget {
  const EkbNoPhoto({super.key, this.categoryId});

  final int? categoryId;

  static const _bgTop = Color(0xFFF3F6FD);
  static const _bgBottom = Color(0xFFE4EBFA);
  static const _accent = Color(0xFF1A56DB);
  static const _label = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    final id = categoryId;
    if (id == null || kCategoryIconAssets.containsKey(id)) {
      return _build(context, CategoryParents.rootOf(id));
    }
    // Подкатегория: ждём карту родителей, пока рисуем пейзаж.
    CategoryParents.ensureLoaded();
    return ValueListenableBuilder<Map<int, int>>(
      valueListenable: CategoryParents.parents,
      builder: (context, _, __) => _build(context, CategoryParents.rootOf(id)),
    );
  }

  Widget _build(BuildContext context, int? rootId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 240.0;
        // Размер «фотокарточки» в центре.
        final card = (h * 0.42).clamp(34.0, 104.0);
        // В маленьких превью подпись не читается — оставляем одну карточку.
        final showLabel = h >= 110;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _DecorPainter()),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _photoCard(card, rootId),
                    if (showLabel) ...[
                      SizedBox(height: card * 0.2),
                      Text(
                        FFLocalizations.of(context).getVariableText(
                          ruText: 'Фото пока нет',
                          kyText: 'Сүрөт азырынча жок',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: (h * 0.065).clamp(12.0, 17.0),
                          fontWeight: FontWeight.w700,
                          color: _label,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Наклонённая белая «полароидная» карточка со сценой внутри.
  Widget _photoCard(double size, int? rootId) {
    final radius = size * 0.2;
    return Transform.rotate(
      angle: -6 * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.16),
              blurRadius: size * 0.3,
              offset: Offset(0, size * 0.1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius * 0.6),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF0FF), Color(0xFFD5E0FB)],
              ),
            ),
            child: CustomPaint(painter: EkbCategoryScenePainter(rootId)),
          ),
        ),
      ),
    );
  }
}

/// Мягкие круги и точки на фоне.
class _DecorPainter extends CustomPainter {
  const _DecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);

    final blob = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08);
    canvas.drawCircle(Offset(w * 0.15, h * 0.2), s * 0.32, blob);
    canvas.drawCircle(Offset(w * 0.9, h * 0.85), s * 0.28, blob);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s * 0.012)
      ..color = EkbNoPhoto._accent.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(w * 0.84, h * 0.22), s * 0.06, ring);
    canvas.drawCircle(Offset(w * 0.12, h * 0.78), s * 0.04, ring);

    final dot = Paint()..color = EkbNoPhoto._accent.withValues(alpha: 0.14);
    for (final p in const [
      Offset(0.28, 0.12),
      Offset(0.7, 0.1),
      Offset(0.92, 0.5),
      Offset(0.06, 0.48),
      Offset(0.32, 0.9),
      Offset(0.66, 0.92),
    ]) {
      canvas.drawCircle(
        Offset(w * p.dx, h * p.dy),
        math.max(1.5, s * 0.012),
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
