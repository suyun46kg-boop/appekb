import 'package:flutter/material.dart';

/// EKB Typography System v1 — Marketplace Inter
/// Spec: design/typography-system-v1/TYPOGRAPHY.md
abstract final class EkbTypography {
  static const _fontFamily = 'Inter';

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color brandBlue = Color(0xFF1A56DB);

  /// Bundled Inter — safe on iOS without network font fetch.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// 28 / 700 / 34 — заголовок экрана
  static TextStyle get screenTitle => inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        color: textPrimary,
        letterSpacing: -0.02 * 28,
      );

  /// 22 / 700 / 28 — заголовок раздела
  static TextStyle get sectionTitle => inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        color: textPrimary,
        letterSpacing: -0.015 * 22,
      );

  /// 16 / 600 / 22 — название объявления (max 2 lines)
  static TextStyle get listingTitle => inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 22 / 16,
        color: textPrimary,
      );

  /// 14 / 400 / 20 — описание (max 2 lines)
  static TextStyle get listingDesc => inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: textSecondary,
      );

  /// 18 / 700 / 22 — цена
  static TextStyle get price => inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 22 / 18,
        color: const Color(0xFF4B5563),
        letterSpacing: -0.3,
      );

  /// 13 / 500 / 18 — дата / город
  static TextStyle get meta => inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 18 / 13,
        color: textMuted,
      );

  /// 13 / 500 / 17 — категории
  static TextStyle get category => inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 17 / 13,
        color: textPrimary,
        letterSpacing: -0.12,
      );

  /// 16 / 400 / 20 — поиск
  static TextStyle get search => inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 20 / 16,
        color: textPrimary,
      );

  /// Placeholder в поиске
  static TextStyle get searchHint => search.copyWith(color: textMuted);

  /// 11 / 600 / 14 — нижний навбар
  static TextStyle get navLabel => inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        color: textPrimary,
        letterSpacing: -0.1,
      );
}
