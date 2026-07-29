import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_surface.dart';
import 'liquid_glass_tokens.dart';

/// Pressable Liquid Glass control with lens-compression micro-interaction.
class LiquidGlassButton extends StatefulWidget {
  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 92,
    this.width,
    this.borderRadius = LiquidGlassTokens.radiusComfort,
    this.enableHaptics = true,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double height;
  final double? width;
  final double borderRadius;
  final bool enableHaptics;

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  static const _spring = Cubic(0.22, 1.56, 0.36, 1);

  late final AnimationController _press;
  late final Animation<double> _pressT;

  bool _hovered = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _pressT = CurvedAnimation(
      parent: _press,
      curve: Curves.easeOutCubic,
      reverseCurve: _spring,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _down() async {
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    _press.duration = const Duration(milliseconds: 100);
    await _press.forward();
  }

  Future<void> _up() async {
    _press.reverseDuration = const Duration(milliseconds: 280);
    await _press.reverse();
  }

  Future<void> _tap() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_press.value < 1) await _down();
      if (!mounted) return;
      await _up();
      if (!mounted) return;
      widget.onPressed();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _pressT,
        builder: (context, _) {
          final p = _pressT.value;
          final hover = _hovered ? 1.015 : 1.0;
          // Scale 1 → 0.96, slight Y squash for “bend”
          final scale = hover * (1.0 - 0.04 * p);
          final squish = 1.0 - 0.018 * p;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(scale, scale * squish, 1),
            filterQuality: FilterQuality.medium,
            child: SizedBox(
              height: widget.height,
              width: widget.width ?? double.infinity,
              child: LiquidGlassSurface(
                borderRadius: widget.borderRadius,
                press: p,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: _tap,
                    onTapDown: (_) => _down(),
                    onTapCancel: _up,
                    onTapUp: (_) {},
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    splashColor: LiquidGlassTokens.neonBlue.withValues(
                      alpha: 0.10,
                    ),
                    highlightColor: Colors.white.withValues(alpha: 0.14),
                    child: Center(child: widget.child),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Convenience label styled for Liquid Glass on light UI.
class LiquidGlassLabel extends StatelessWidget {
  const LiquidGlassLabel(
    this.text, {
    super.key,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (style ??
              const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 17 / 13,
                letterSpacing: -0.12,
              ))
          .copyWith(
        fontWeight: FontWeight.w700,
        color: LiquidGlassTokens.ink,
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: 0.65),
            blurRadius: 6,
          ),
          Shadow(
            color: LiquidGlassTokens.neonBlue.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}
