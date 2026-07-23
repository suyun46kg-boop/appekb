import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/theme/ekb_typography.dart';

/// Full-width bottom navigation docked to the screen edge.
class EkbBottomNavBar extends StatelessWidget {
  const EkbBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onHomeTap,
    required this.onSearchTap,
    required this.onCreateTap,
    required this.onListingsTap,
    required this.onProfileTap,
    required this.homeLabel,
    required this.searchLabel,
    required this.createLabel,
    required this.listingsLabel,
    required this.profileLabel,
  });

  /// Tab index in [dbdd, searchpage22, mylisting, Profile] order.
  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onSearchTap;
  final VoidCallback onCreateTap;
  final VoidCallback onListingsTap;
  final VoidCallback onProfileTap;
  final String homeLabel;
  final String searchLabel;
  final String createLabel;
  final String listingsLabel;
  final String profileLabel;

  static const _activeBlue = Color(0x991A56DB);
  static const _headerBlue = Color(0xFF2450E8);
  static const _inactive = Color(0xFF374151);
  static const _barHeight = 62.0;

  // iOS-style liquid glass tokens (reduced blur on iOS for GPU stability)
  static const _glassBlur = 36.0;
  static const _glassBlurIOS = 18.0;
  static const _glassTintTop = Color(0xFFF9F9FB);
  static const _glassTintBottom = Color(0xFFEFEFF4);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final useHeavyBlur = !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.iOS;
    final blurSigma = useHeavyBlur ? _glassBlur : _glassBlurIOS;

    final barContent = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _glassTintTop.withValues(alpha: useHeavyBlur ? 0.94 : 0.97),
            _glassTintBottom.withValues(alpha: useHeavyBlur ? 0.92 : 0.96),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.52),
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _NavTab(
                      active: currentIndex == 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: homeLabel,
                      onTap: onHomeTap,
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      active: currentIndex == 1,
                      icon: Icons.search_rounded,
                      activeIcon: Icons.search_rounded,
                      label: searchLabel,
                      onTap: onSearchTap,
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      active: false,
                      icon: Icons.add_circle_outline_rounded,
                      activeIcon: Icons.add_circle_rounded,
                      label: createLabel,
                      spinIcon: true,
                      iconColor: _headerBlue,
                      onTap: onCreateTap,
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      active: currentIndex == 2,
                      icon: Icons.list_alt_outlined,
                      activeIcon: Icons.list_alt_rounded,
                      label: listingsLabel,
                      onTap: onListingsTap,
                    ),
                  ),
                  Expanded(
                    child: _NavTab(
                      active: currentIndex == 3,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: profileLabel,
                      onTap: onProfileTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!useHeavyBlur) {
      return barContent;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: barContent,
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  const _NavTab({
    required this.active,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.spinIcon = false,
    this.iconColor,
  });

  final bool active;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final double iconSize = 26;
  final bool spinIcon;
  final Color? iconColor;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  AnimationController? _spin;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.spinIcon) {
      return;
    }
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    if (disableMotion) {
      _spin?.stop();
      return;
    }
    _spin ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );
    if (!_spin!.isAnimating) {
      _spin!.repeat();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  Widget _buildIcon(Color color, double iconSize) {
    final icon = Icon(
      widget.active ? widget.activeIcon : widget.icon,
      size: iconSize,
      color: color,
    );

    if (_spin == null) {
      return icon;
    }

    return AnimatedBuilder(
      animation: _spin!,
      builder: (context, child) => Transform.rotate(
        angle: _spin!.value * 2 * pi,
        child: child,
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final labelColor =
        active ? EkbBottomNavBar._activeBlue : EkbBottomNavBar._inactive;
    final iconColor = widget.iconColor ?? labelColor;
    final iconSize = active ? widget.iconSize + 1 : widget.iconSize;
    final iconChild = _buildIcon(iconColor, iconSize);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.spinIcon)
              iconChild
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey(active),
                  child: iconChild,
                ),
              ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: EkbTypography.navLabel.copyWith(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: labelColor,
                letterSpacing: -0.1,
              ),
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
