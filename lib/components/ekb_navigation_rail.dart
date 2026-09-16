import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/components/ekbkg_logo.dart';
import '/theme/ekb_typography.dart';

/// Adaptive Navigation Rail for tablet screens (>= 720 dp).
class EkbNavigationRail extends StatelessWidget {
  const EkbNavigationRail({
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

  static const _activeBlue = Color(0xFF1A56DB);
  static const _headerBlue = Color(0xFF2450E8);
  static const _inactive = Color(0xFF4B5563);
  static const _railBg = Color(0xFFFAFBFD);
  static const _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: 92,
      decoration: const BoxDecoration(
        color: _railBg,
        border: Border(
          right: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            SizedBox(height: topPad > 0 ? 8 : 16),
            // App brand mark / logo at top
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onHomeTap();
              },
              child: const Tooltip(
                message: 'EKBKG',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: EkbkgLogo(
                    size: 38,
                    animateOnTap: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Navigation items
            _RailItem(
              active: currentIndex == 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: homeLabel,
              onTap: onHomeTap,
            ),
            const SizedBox(height: 12),
            _RailItem(
              active: currentIndex == 1,
              icon: Icons.search_rounded,
              activeIcon: Icons.search_rounded,
              label: searchLabel,
              onTap: onSearchTap,
            ),
            const SizedBox(height: 16),
            // Prominent Create Ad Action Button
            _RailCreateButton(
              label: createLabel,
              onTap: onCreateTap,
            ),
            const SizedBox(height: 16),
            _RailItem(
              active: currentIndex == 2,
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt_rounded,
              label: listingsLabel,
              onTap: onListingsTap,
            ),
            const SizedBox(height: 12),
            _RailItem(
              active: currentIndex == 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: profileLabel,
              onTap: onProfileTap,
            ),
            const Spacer(),
            SizedBox(height: bottomPad > 0 ? 8 : 16),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
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

  @override
  Widget build(BuildContext context) {
    final color = active ? EkbNavigationRail._activeBlue : EkbNavigationRail._inactive;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: active ? EkbNavigationRail._activeBlue.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 26,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: EkbTypography.navLabel.copyWith(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailCreateButton extends StatelessWidget {
  const _RailCreateButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B6EF5),
                      EkbNavigationRail._headerBlue,
                      Color(0xFF1A45C7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EkbNavigationRail._headerBlue.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: EkbTypography.navLabel.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: EkbNavigationRail._inactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
