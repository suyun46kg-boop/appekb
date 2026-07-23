import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CategoryBlockBackground extends StatefulWidget {
  const CategoryBlockBackground({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.showBorder = true,
    this.showShadow = true,
    this.showTopHighlight = true,
    this.bokehCount = 6,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final bool showBorder;
  final bool showShadow;
  final bool showTopHighlight;
  final int bokehCount;

  @override
  State<CategoryBlockBackground> createState() =>
      _CategoryBlockBackgroundState();
}

class _CategoryBlockBackgroundState extends State<CategoryBlockBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  final _random = math.Random();
  late List<_Bokeh> _bokeh;
  final List<_Streak> _streaks = [];
  double _time = 0;
  double _nextStreakAt = 2;

  void _spawnStreaks() {
    _streaks.add(_Streak.random(_random));
    if (_random.nextDouble() < 0.3) {
      _streaks.add(_Streak.random(_random));
    }
  }

  @override
  void initState() {
    super.initState();
    _bokeh = List.generate(widget.bokehCount, (_) => _Bokeh.random(_random));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tickParticles);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) {
      _particleController.stop();
    } else if (!_particleController.isAnimating) {
      _particleController.repeat();
    }
  }

  void _tickParticles() {
    const dt = 1 / 60.0;
    _time += dt;
    _nextStreakAt -= dt;
    if (_nextStreakAt <= 0) {
      _spawnStreaks();
      _nextStreakAt = 1 + _random.nextDouble() * 2;
    }
    _streaks.removeWhere((s) => s.life >= s.maxLife);
    for (final s in _streaks) {
      s.life += 1;
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: const LinearGradient(
          begin: Alignment(-0.75, -1),
          end: Alignment(0.85, 1),
          stops: [0.0, 0.55, 1.0],
          colors: [
            Color(0xFF3D66F0),
            Color(0xFF2450E8),
            Color(0xFF143BA8),
          ],
        ),
        border: widget.showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.25))
            : null,
        boxShadow: widget.showShadow
            ? const [
                BoxShadow(
                  color: Color(0x591E46DC),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) => CustomPaint(
                    painter: _CategoryParticlePainter(
                      time: _time,
                      bokeh: _bokeh,
                      streaks: _streaks,
                      random: _random,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showTopHighlight)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _Bokeh {
  _Bokeh({
    required this.x,
    required this.y,
    required this.r,
    required this.cycle,
    required this.cycleSpeed,
    required this.driftX,
    required this.driftY,
    required this.maxAlpha,
  });

  double x;
  double y;
  final double r;
  final double cycle;
  final double cycleSpeed;
  final double driftX;
  final double driftY;
  final double maxAlpha;

  factory _Bokeh.random(math.Random random) {
    return _Bokeh(
      x: random.nextDouble(),
      y: random.nextDouble(),
      r: random.nextDouble() * 18 + 14,
      cycle: random.nextDouble() * math.pi * 2,
      cycleSpeed: 0.25 + random.nextDouble() * 0.3,
      driftX: (random.nextDouble() - 0.5) * 0.08,
      driftY: (random.nextDouble() - 0.5) * 0.08,
      maxAlpha: 0.08 + random.nextDouble() * 0.06,
    );
  }
}

class _Streak {
  _Streak({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.len,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  double life = 0;
  final double maxLife = 40;
  final double len;

  factory _Streak.random(math.Random random) {
    final fromLeft = random.nextBool();
    return _Streak(
      x: fromLeft ? -0.05 : 1.05,
      y: random.nextDouble() * 0.6,
      vx: (fromLeft ? 1 : -1) * (2.5 + random.nextDouble() * 1.5),
      vy: 0.8 + random.nextDouble() * 0.6,
      len: 18 + random.nextDouble() * 10,
    );
  }
}

class _CategoryParticlePainter extends CustomPainter {
  _CategoryParticlePainter({
    required this.time,
    required this.bokeh,
    required this.streaks,
    required this.random,
  });

  final double time;
  final List<_Bokeh> bokeh;
  final List<_Streak> streaks;
  final math.Random random;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    for (final b in bokeh) {
      b.x += b.driftX / size.width;
      b.y += b.driftY / size.height;
      if (b.x < -b.r / size.width) b.x = 1 + b.r / size.width;
      if (b.x > 1 + b.r / size.width) b.x = -b.r / size.width;
      if (b.y < -b.r / size.height) b.y = 1 + b.r / size.height;
      if (b.y > 1 + b.r / size.height) b.y = -b.r / size.height;

      final pulse = 0.6 + 0.4 * math.sin(time * b.cycleSpeed + b.cycle);
      final alpha = b.maxAlpha * pulse;
      final center = Offset(b.x * size.width, b.y * size.height);
      final radius = b.r;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        );
      canvas.drawCircle(center, radius, paint);
    }

    for (final st in streaks) {
      st.x += st.vx / size.width;
      st.y += st.vy / size.height;
      final alpha = 1 - st.life / st.maxLife;
      final start = Offset(st.x * size.width, st.y * size.height);
      final end = Offset(
        start.dx - st.vx * (st.len / 3),
        start.dy - st.vy * (st.len / 3),
      );
      final paint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          start,
          end,
          [
            Colors.white.withValues(alpha: alpha * 0.85),
            const Color(0x007896FF),
          ],
        );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryParticlePainter oldDelegate) => true;
}

/// Animated blue app bar shell shared across screens.
class EkbAppBarBackground extends StatelessWidget {
  const EkbAppBarBackground({
    super.key,
    required this.child,
    required this.padding,
    this.borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    ),
    this.bokehCount = 5,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadiusGeometry borderRadius;
  final int bokehCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CategoryBlockBackground(
        borderRadius: borderRadius,
        showBorder: false,
        showShadow: false,
        bokehCount: bokehCount,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
