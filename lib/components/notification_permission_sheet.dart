import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/internationalization.dart';

// Electric-blue palette for the neon look of the sheet.
const _neonTop = Color(0xFF2E8BFF);
const _neonMid = Color(0xFF1F5BFF);
const _neonDeep = Color(0xFF0B2FE0);
const _neonCyan = Color(0xFF3FD8FF);

/// Pre-permission sheet shown before the system notification prompt.
/// Pops `true` when the user wants notifications, `false` otherwise.
class NotificationPermissionSheet extends StatelessWidget {
  const NotificationPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final l10n = FFLocalizations.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Hero(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                32,
                24,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  Text(
                    l10n.getVariableText(
                      ruText: 'Успейте первым',
                      kyText: 'Биринчи болуп жетишиңиз',
                    ),
                    textAlign: TextAlign.center,
                    style: theme.headlineMedium.override(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      lineHeight: 1.15,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.getVariableText(
                        ruText:
                            'Хорошие квартиры и работу разбирают за пару часов. Сообщим сразу, как только появится новое.',
                        kyText:
                            'Жакшы батир менен жумуш бир-эки саатта эле бүтөт. Жаңысы чыгары менен дароо кабарлайбыз.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.bodyLarge.override(
                        color: theme.secondaryText,
                        lineHeight: 1.5,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 32),
                  _PrimaryButton(
                    label: l10n.getVariableText(
                      ruText: 'Включить уведомления',
                      kyText: 'Билдирмелерди күйгүзүү',
                    ),
                    onTap: () => Navigator.pop(context, true),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.secondaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: theme.bodyLarge.override(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(l10n.getVariableText(
                        ruText: 'Позже',
                        kyText: 'Кийинчерээк',
                      )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 14,
                        color: theme.secondaryText.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.getVariableText(
                            ruText:
                                'Без спама · отключить можно в любой момент',
                            kyText: 'Спамсыз · каалаган убакта өчүрсөңүз болот',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.bodySmall.override(
                            color: theme.secondaryText.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient header with a ringing bell and a live preview of notifications.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_neonTop, _neonMid, _neonDeep],
        ),
      ),
      child: Stack(
        children: [
          // Soft glow blobs for depth.
          const Positioned(
            top: -60,
            right: -40,
            child: _Glow(size: 220, opacity: 0.45, color: _neonCyan),
          ),
          const Positioned(
            bottom: -80,
            left: -50,
            child: _Glow(size: 240, opacity: 0.35, color: _neonCyan),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              children: [
                // Drag handle.
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _neonCyan.withValues(alpha: 0.75),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: _neonMid,
                    size: 32,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shake(hz: 4, rotation: 0.12, duration: 700.ms)
                    .then(delay: 2200.ms),
                const SizedBox(height: 28),
                _NotificationCard(
                  image: 'assets/images/categories/category_apartment.png',
                  title: l10n.getVariableText(
                    ruText: 'Сдаётся 1-комн. квартира',
                    kyText: 'Ижарага 1 бөлмөлүү батир',
                  ),
                  subtitle: l10n.getVariableText(
                    ruText: 'Пехотинцев · 25 000 ₽/мес',
                    kyText: 'Пехотинцев · 25 000 ₽/ай',
                  ),
                  time: l10n.getVariableText(ruText: 'сейчас', kyText: 'азыр'),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 450.ms)
                    .slideY(begin: -0.4, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                _NotificationCard(
                  image: 'assets/images/notification_preview_iphone.jpg',
                  title: l10n.getVariableText(
                    ruText: 'Продаётся iPhone 15 Pro',
                    kyText: 'iPhone 15 Pro сатылат',
                  ),
                  subtitle: l10n.getVariableText(
                    ruText: 'Отличное состояние · 35 000 ₽',
                    kyText: 'Абалы абдан жакшы · 35 000 ₽',
                  ),
                  time: l10n.getVariableText(
                    ruText: '2 мин',
                    kyText: '2 мүн',
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 450.ms)
                    .slideY(begin: -0.4, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.opacity,
    required this.color,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// iOS-style notification banner used in the preview.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String image;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _neonDeep.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(image, width: 42, height: 42, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [_neonTop, _neonMid, _neonDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: _neonMid.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: theme.titleMedium.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
