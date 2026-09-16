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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
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
                        child: _CreateTab(
                          label: createLabel,
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

class _CreateTab extends StatelessWidget {
  const _CreateTab({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Center(
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B6EF5),
                  EkbBottomNavBar._headerBlue,
                  Color(0xFF1A45C7),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: EkbBottomNavBar._headerBlue.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.active,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  static const double _iconSize = 26.0;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        active ? EkbBottomNavBar._activeBlue : EkbBottomNavBar._inactive;
    final size = active ? _iconSize + 1 : _iconSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? activeIcon : icon,
            size: size,
            color: labelColor,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: EkbTypography.navLabel.copyWith(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: labelColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
