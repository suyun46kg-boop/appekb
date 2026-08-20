import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/components/ekbkg_logo.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'welcome_model.dart';

export 'welcome_model.dart';

/// First-run welcome — logo bloom → EKBKG → fly top → aurora + Start.
class WelcomeWidget extends StatefulWidget {
  const WelcomeWidget({super.key});

  static String routeName = 'welcome';
  static String routePath = '/welcome';

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget>
    with TickerProviderStateMixin {
  late WelcomeModel _model;
  late final AnimationController _intro;
  late final AnimationController _aurora;

  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);
  static const _brand = Color(0xFF3D66F0);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeModel());
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _intro.forward();
    });
  }

  Future<void> _openHome() async {
    FFAppState().hasSeenWelcome = true;
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _intro.dispose();
    _aurora.dispose();
    _model.dispose();
    super.dispose();
  }

  /// Absolute millisecond interval → 0..1 (HTML timeline).
  double _ms(double ms, double start, double end, [Curve c = Curves.easeOut]) {
    if (ms <= start) return 0;
    if (ms >= end) return 1;
    return c.transform((ms - start) / (end - start));
  }

  Widget _langButton(String code, String label) {
    final active = FFLocalizations.of(context).languageCode == code;
    return InkWell(
      onTap: () => setAppLanguage(context, code),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: active ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final title = FFLocalizations.of(context).getText('wlc1title');
    final startLabel = FFLocalizations.of(context).getText('wlc1start');

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _aurora]),
        builder: (context, _) {
          final t = _intro.value;
          final ms = t * 3200;

          final logoWrap = _ms(ms, 0, 380, Curves.easeOut);
          // Softer name + hold, then long smooth fly
          final nameIn = _ms(ms, 720, 1450, Curves.easeInOutCubic);
          final fly = _ms(ms, 1650, 2700, Curves.easeInOutCubic);
          final auroraOp = _ms(ms, 2300, 2800, Curves.easeOut);
          final heroOp = _ms(ms, 2450, 2950, Curves.easeOutCubic);
          final ctaOp = _ms(ms, 2650, 3100, Curves.easeOutCubic);
          final langOp = _ms(ms, 2400, 2850, Curves.easeOut);

          const logoBig = 72.0;
          const logoSmall = 28.0;
          const nameBig = 28.0;
          const nameSmall = 17.0;
          const gapBig = 12.0;
          const gapSmall = 8.0;

          final logoSize = ui.lerpDouble(logoBig, logoSmall, fly)!;
          final nameSize = ui.lerpDouble(nameBig, nameSmall, fly)!;
          final nameGap = ui.lerpDouble(gapBig, gapSmall, fly)!;

          // Stable widths (no * nameIn) — avoids position jitter
          final nameW = title.length * nameBig * 0.58;
          final fullClusterW = logoBig + gapBig + nameW;

          final logoOnlyLeft = (size.width - logoBig) / 2;
          final clusterLeft = (size.width - fullClusterW) / 2;
          final startTop = (size.height - logoBig) / 2;

          // Logo stays centered, then gently shifts as name appears
          final settledLeft = ui.lerpDouble(logoOnlyLeft, clusterLeft, nameIn)!;
          final brandLeft = ui.lerpDouble(settledLeft, 24, fly)!;
          final brandTop = ui.lerpDouble(startTop, top + 16, fly)!;

          return Stack(
            children: [
              // Aurora
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height * 0.45,
                child: Opacity(
                  opacity: auroraOp,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _AuroraPainter(time: _aurora.value),
                    ),
                  ),
                ),
              ),

              // Brand cluster
              Positioned(
                left: brandLeft,
                top: brandTop,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: logoWrap.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.82 + 0.18 * logoWrap,
                        child: SizedBox(
                          width: logoSize,
                          height: logoSize,
                          child: CustomPaint(
                            painter: _BloomLogoPainter(ms: ms),
                          ),
                        ),
                      ),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: nameIn.clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsets.only(left: nameGap),
                          child: Opacity(
                            opacity: nameIn.clamp(0.0, 1.0),
                            child: Text(
                              title,
                              maxLines: 1,
                              softWrap: false,
                              style: GoogleFonts.inter(
                                fontSize: nameSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: _textPrimary,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Landing content
              Padding(
                padding: EdgeInsets.fromLTRB(24, top + 12, 24, 24 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        Opacity(
                          opacity: langOp,
                          child: Row(
                            children: [
                              _langButton(
                                'ky',
                                FFLocalizations.of(context)
                                    .getText('l8qpitx7' /* KG */),
                              ),
                              const SizedBox(width: 8),
                              _langButton(
                                'ru',
                                FFLocalizations.of(context)
                                    .getText('qai395nv' /* RU */),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    Opacity(
                      opacity: heroOp,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - heroOp)),
                        child: Column(
                          children: [
                            Text(
                              FFLocalizations.of(context).getText('wlc1hero1'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -1,
                                color: _textPrimary,
                              ),
                            ),
                            _GradientText(
                              FFLocalizations.of(context).getText('wlc1hero2'),
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -1,
                              ),
                              progress: _aurora.value,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              FFLocalizations.of(context).getText('wlc1sub'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                    Opacity(
                      opacity: ctaOp,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - ctaOp)),
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: ctaOp > 0.5 ? _openHome : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _brand,
                              disabledBackgroundColor:
                                  _brand.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              startLabel,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style, required this.progress});

  final String text;
  final TextStyle style;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shift = (math.sin(progress * math.pi * 2) + 1) / 2;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-1 + shift * 0.5, 0),
          end: Alignment(1 + shift * 0.3, 0),
          colors: const [
            Color(0xFF1A56DB),
            Color(0xFF3D66F0),
            Color(0xFF5B8DEF),
            Color(0xFF93B4F8),
          ],
        ).createShader(bounds);
      },
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

/// Yellow sunflower bloom — matches HTML: core then petals scale from center.
class _BloomLogoPainter extends CustomPainter {
  _BloomLogoPainter({required this.ms});

  final double ms;

  /// cubic-bezier(.34, 1.4, .64, 1) ≈ HTML core curve
  static const _coreCurve = Cubic(0.34, 1.4, 0.64, 1.0);
  static const _petalCurve = Cubic(0.16, 1.0, 0.3, 1.0);

  static final _petal = Path()
    ..moveTo(0, -15)
    ..cubicTo(7.6, -9.8, 7.6, 9.8, 0, 15)
    ..cubicTo(-7.6, 9.8, -7.6, -9.8, 0, -15)
    ..close();

  double _seg(double start, double dur, Curve curve) {
    if (ms <= start) return 0;
    if (ms >= start + dur) return 1;
    return curve.transform((ms - start) / dur);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    canvas.scale(s);
    final paint = Paint()..style = PaintingStyle.fill;

    // Core — HTML: scale 0.35→1, opacity 0→1, delay 50ms, dur 400ms
    final coreT = _seg(50, 400, _coreCurve);
    if (coreT > 0) {
      canvas.save();
      canvas.translate(60, 60);
      canvas.scale(0.35 + 0.65 * coreT);
      paint.color = EkbkgLogo.brandYellow.withValues(alpha: coreT.clamp(0.0, 1.0));
      canvas.drawCircle(Offset.zero, 18, paint);
      canvas.restore();
    }

    // Petals — HTML: scale 0.2→1, delays 100 + i*40ms, dur 400ms
    for (var i = 0; i < 12; i++) {
      final petalT = _seg(100.0 + i * 40.0, 400, _petalCurve);
      if (petalT <= 0) continue;

      final angle = i * math.pi / 6;
      canvas.save();
      canvas.translate(60, 60);
      canvas.rotate(angle);
      canvas.translate(0, -37);
      // Scale from petal center (path is centered on origin) — like fill-box
      canvas.scale(0.2 + 0.8 * petalT);
      paint.color =
          EkbkgLogo.brandYellow.withValues(alpha: petalT.clamp(0.0, 1.0));
      canvas.drawPath(_petal, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BloomLogoPainter oldDelegate) =>
      oldDelegate.ms != ms;
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time * math.pi * 2;
    // Soft single-hue brand wash — no loud multi-color blobs
    final breathe = 0.92 + 0.08 * math.sin(t);

    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, size.height * 0.15),
        Offset(size.width * 0.5, size.height),
        [
          const Color(0x001A56DB),
          Color.fromRGBO(61, 102, 240, 0.10 * breathe),
          Color.fromRGBO(26, 86, 219, 0.18 * breathe),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, paint);

    // One very soft highlight, same blue family
    canvas.drawCircle(
      Offset(
        size.width * (0.5 + 0.04 * math.sin(t * 0.6)),
        size.height * 0.85,
      ),
      size.width * 0.55,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56)
        ..color = Color.fromRGBO(147, 180, 248, 0.22 * breathe),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.time != time;
}
