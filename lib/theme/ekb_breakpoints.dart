import 'package:flutter/material.dart';

/// Responsive breakpoints and layout tokens for EKBKG.
abstract final class EkbBreakpoints {
  /// Threshold between phone and tablet window sizes.
  static const double phone = 720.0;

  /// Threshold for large tablets in landscape or desktop windows.
  static const double tabletLandscape = 1024.0;

  // Maximum readable content widths
  static const double maxContentWidth = 1200.0;
  static const double maxDetailWidth = 960.0;
  static const double maxListWidth = 760.0;
  static const double maxFormWidth = 680.0;
  static const double maxAuthWidth = 480.0;
  static const double maxModalWidth = 560.0;
  static const double maxHeaderWidth = 1080.0;

  /// Whether current context has a tablet-sized width (>= 720 dp).
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= phone;
  }

  /// Whether a specific width is tablet-sized (>= 720 dp).
  static bool isTabletWidth(double width) {
    return width >= phone;
  }

  /// Calculates dynamic column count for a given container width.
  static int gridColumnsForWidth(
    double width, {
    double maxExtent = 230.0,
    double spacing = 12.0,
    int minColumns = 2,
  }) {
    if (width <= 0) return minColumns;
    final cols = ((width + spacing) / (maxExtent + spacing)).floor();
    return cols < minColumns ? minColumns : cols;
  }

  /// Standard responsive grid delegate for listing grids across the app.
  static SliverGridDelegateWithMaxCrossAxisExtent listingGridDelegate({
    double maxCrossAxisExtent = 230.0,
    double crossAxisSpacing = 12.0,
    double mainAxisSpacing = 12.0,
    double childAspectRatio = 0.66,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}
