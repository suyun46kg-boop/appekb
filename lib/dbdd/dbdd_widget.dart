import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/components/ekb_listing_card.dart';
import '/components/shimmer_widgets.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/ekb_image_cache.dart';
import '/theme/ekb_breakpoints.dart';
import '/theme/ekb_typography.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'category_block_background.dart';
import 'dbdd_model.dart';
export 'dbdd_model.dart';

/// Layered elevation tokens for the home screen.
const _shadowBanner = [
  BoxShadow(
    color: Color(0x06000000),
    blurRadius: 14,
    offset: Offset(0, 4),
    spreadRadius: -5,
  ),
];

class _DbddCategory {
  const _DbddCategory(
    this.assetPath,
    this.labelKey,
    this.catId, {
    this.iconOffset = Offset.zero,
    this.iconSize = 56,
    this.iconRotationDeg = -8,
  });
  final String assetPath;
  final String labelKey;
  final int catId;
  final Offset iconOffset;
  final double iconSize;
  final double iconRotationDeg;
}

class DbddWidget extends StatefulWidget {
  const DbddWidget({super.key});

  static String routeName = 'dbdd';
  static String routePath = '/dbdd';

  @override
  State<DbddWidget> createState() => _DbddWidgetState();
}

class _DbddWidgetState extends State<DbddWidget> {
  late DbddModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _carouselTimer;
  int? _carouselSlideCount;
  late final Future<List<CaruselRow>> _carouselFuture;

  static const _bg = Colors.white;
  static const _blue = EkbTypography.brandBlue;
  static const _text3 = EkbTypography.textMuted;
  static const _pageHPad = 20.0;

  static const _categories = [
    _DbddCategory(
      'assets/images/categories/category_apartment.png',
      'cukp48gd',
      3,
      iconOffset: Offset(0, 10),
      iconRotationDeg: 0,
      iconSize: 62,
    ),
    _DbddCategory(
      'assets/images/categories/category_job.png',
      'me5sh2dc',
      2,
      iconRotationDeg: 3,
      iconSize: 62,
    ),
    _DbddCategory(
      'assets/images/categories/category_border.png',
      '4lwpgqmm',
      14,
      iconRotationDeg: 2,
      iconSize: 64,
    ),
    _DbddCategory(
      'assets/images/categories/category_auto.png',
      'r4qsbrdp',
      1,
      iconOffset: Offset(-2, 0),
      iconRotationDeg: -3,
      iconSize: 66,
    ),
    _DbddCategory(
      'assets/images/categories/category_ticket.png',
      'vp95t6yz',
      13,
      iconRotationDeg: -6,
      iconSize: 60,
    ),
    _DbddCategory(
      'assets/images/categories/category_services.png',
      'ccc9cors',
      4,
      iconRotationDeg: -5,
      iconSize: 62,
    ),
    _DbddCategory(
      'assets/images/categories/category_sale_v2.png',
      'pnpqtuk7',
      9,
      iconRotationDeg: 2,
      iconSize: 60,
    ),
    _DbddCategory(
      'assets/images/categories/category_parttime.png',
      'noun7do1',
      5,
      iconRotationDeg: -2,
      iconSize: 60,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DbddModel());
    _carouselFuture = CaruselTable().queryRows(queryFn: (q) => q);
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  void _ensureCarouselAutoScroll(int slideCount) {
    if (_carouselSlideCount == slideCount && _carouselTimer != null) {
      return;
    }
    _carouselSlideCount = slideCount;
    _carouselTimer?.cancel();
    _carouselTimer = null;
    if (slideCount <= 1) {
      return;
    }
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      final controller = _model.pageViewController;
      if (controller == null || !controller.hasClients) {
        return;
      }
      final current = controller.page?.round() ?? 0;
      final next = (current + 1) % slideCount;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _header(BuildContext context) {
    final lang = FFLocalizations.of(context).languageCode;
    final topPad = MediaQuery.paddingOf(context).top;

    return EkbAppBarBackground(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: EkbBreakpoints.maxHeaderWidth),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                _langSwitch(context, lang),
                const SizedBox(width: 12),
                Expanded(child: _searchBar(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _langSwitch(BuildContext context, String lang) {
    Widget langBtn(String code, String label, VoidCallback onTap) {
      final active = lang == code;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: EkbTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: active ? _blue : Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          langBtn(
            'ky',
            FFLocalizations.of(context).getText('l8qpitx7' /* KG */),
            () => setAppLanguage(context, 'ky'),
          ),
          langBtn(
            'ru',
            FFLocalizations.of(context).getText('qai395nv' /* RU */),
            () => setAppLanguage(context, 'ru'),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(Searchpage22Widget.routeName),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: _shadowBanner,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded, color: _text3, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                FFLocalizations.of(context).getText('fmw9cm8g' /* Найти */),
                textAlign: TextAlign.center,
                style: EkbTypography.searchHint,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Invisible spacer mirroring the icon + gap width, so the text
            // above stays perfectly centered while the icon "follows" it.
            const SizedBox(width: 26),
          ],
        ),
      ),
    );
  }

  void _openCategoryById(BuildContext context, int catId) {
    context.pushNamed(
      TovarypocategoyWidget.routeName,
      queryParameters: {
        'paramcatid': serializeParam(catId, ParamType.int),
      }.withoutNulls,
    );
  }

  /// PNG-иконки для всех корневых категорий в bottom sheet.
  static const _sheetCategoryAssets = <int, String>{
    1: 'assets/images/categories/category_auto.png',
    2: 'assets/images/categories/category_job.png',
    3: 'assets/images/categories/category_apartment.png',
    4: 'assets/images/categories/category_services.png',
    5: 'assets/images/categories/category_parttime.png',
    6: 'assets/images/categories/category_repair.png',
    7: 'assets/images/categories/category_beauty.png',
    8: 'assets/images/categories/category_kids.png',
    9: 'assets/images/categories/category_sale_v2.png',
    11: 'assets/images/categories/category_from_kg.png',
    12: 'assets/images/categories/category_hotel.png',
    13: 'assets/images/categories/category_ticket.png',
    14: 'assets/images/categories/category_border.png',
  };

  Widget _sheetCategoryLeading(int id1) {
    final asset =
        _sheetCategoryAssets[id1] ?? 'assets/images/categories/category_sale_v2.png';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Future<void> _openCategoriesSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          FFLocalizations.of(context).getText('zvs9dp80'),
                          textAlign: TextAlign.center,
                          style: EkbTypography.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: EkbTypography.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: EkbTypography.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: FutureBuilder<List<CategoriesRow>>(
                    future: CategoriesTable().queryRows(
                      queryFn: (q) => q.order('id1', ascending: true),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        );
                      }
                      final roots =
                          snapshot.data!.where((c) => c.isRoot).toList();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        itemCount: roots.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 72,
                          color: Color(0xFFF3F4F6),
                        ),
                        itemBuilder: (itemContext, index) {
                          final cat = roots[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _openCategoryById(context, cat.id1);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    _sheetCategoryLeading(cat.id1),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: EkbTypography.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: EkbTypography.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: EkbTypography.textMuted,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryTile(BuildContext context, _DbddCategory cat) {
    const tileBg = Color(0xFFF5F5F7);
    const tileRadius = 12.0;
    const iconSize = 77.0;
    final radius = BorderRadius.circular(tileRadius);
    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: tileBg,
        borderRadius: radius,
        child: InkWell(
          onTap: () => _openCategoryById(context, cat.catId),
          borderRadius: radius,
          splashColor: Colors.black.withValues(alpha: 0.06),
          highlightColor: const Color(0xFFEDEBE9),
          child: SizedBox(
            height: 92,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -10,
                  bottom: -12,
                  width: iconSize,
                  height: iconSize,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: cat.iconRotationDeg * math.pi / 180,
                      child: Transform.translate(
                        offset: cat.iconOffset,
                        child: Image.asset(
                          cat.assetPath,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomRight,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  top: 12,
                  right: 8,
                  child: Text(
                    FFLocalizations.of(context).getText(cat.labelKey),
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EkbTypography.category,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moreCategoryTile(BuildContext context) {
    // Translucent like KG/RU + white highlights for 3D (no blue glow).
    const radius = 12.0;
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openCategoriesSheet(context),
            borderRadius: r,
            splashColor: Colors.black.withValues(alpha: 0.06),
            highlightColor: Colors.black.withValues(alpha: 0.04),
            child: Ink(
              height: 92,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.28),
                    const Color(0xFFF5F5F7).withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 0.7,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 26,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(radius),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -8,
                    top: -10,
                    width: 52,
                    height: 52,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 28,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(radius),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 1,
                    right: 1,
                    top: 0.6,
                    height: 1,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.7),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      FFLocalizations.of(context).getText('dbddmore'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: EkbTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: EkbTypography.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoriesGrid(BuildContext context) {
    // 7 категорий + плитка «ещё» = 2 ряда по 4 (на узких) или 1 ряд по 8 (на широких экранах).
    const visibleCount = 7;
    final homeCount = math.min(_categories.length, visibleCount);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 900;
    final catCols = isWide ? 8 : 4;
    final maxCatWidth = isWide ? 1080.0 : 720.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCatWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_pageHPad, 14, _pageHPad, 10),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: catCols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 92,
            ),
            itemCount: homeCount + 1,
            itemBuilder: (context, index) {
              if (index < homeCount) {
                return _categoryTile(context, _categories[index]);
              }
              return _moreCategoryTile(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _bannerShimmer() {
    return const ShimmerBox(
      width: double.infinity,
      height: double.infinity,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
  }

  Widget _bannerSkeleton([double height = 136]) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: _shadowBanner,
      ),
      clipBehavior: Clip.antiAlias,
      child: _bannerShimmer(),
    );
  }

  Widget _bannerCarousel(BuildContext context) {
    final isTablet = EkbBreakpoints.isTablet(context);
    final bannerHeight = isTablet ? 168.0 : 136.0;
    final maxBannerWidth = isTablet ? 960.0 : 720.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBannerWidth),
        child: FutureBuilder<List<CaruselRow>>(
          future: _carouselFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _bannerSkeleton(bannerHeight);
            }
            final slides = snapshot.data!;
            if (slides.isEmpty) {
              return SizedBox(height: bannerHeight);
            }

            _model.pageViewController ??= PageController();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _ensureCarouselAutoScroll(slides.length);
              }
            });

            return Container(
              height: bannerHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: _shadowBanner,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
              PageView.builder(
                controller: _model.pageViewController,
                onPageChanged: (_) => safeSetState(() {}),
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return InkWell(
                    onTap: () async {
                      if (slide.links != null &&
                          slide.links!.trim().isNotEmpty) {
                        await launchURL(slide.links!);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: valueOrDefault<String>(
                            slide.images,
                            'https://images.unsplash.com/photo-1555215695-3004980ad54e',
                          ),
                          cacheManager: EkbImageCacheManager.instance,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 250),
                          placeholder: (_, __) => _bannerShimmer(),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 12,
                right: 16,
                child: smooth_page_indicator.SmoothPageIndicator(
                  controller: _model.pageViewController!,
                  count: slides.length,
                  axisDirection: Axis.horizontal,
                  onDotClicked: (i) async {
                    await _model.pageViewController!.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOut,
                    );
                    safeSetState(() {});
                  },
                  effect: const smooth_page_indicator.ExpandingDotsEffect(
                    expansionFactor: 3.3,
                    spacing: 5,
                    radius: 3,
                    dotWidth: 6,
                    dotHeight: 6,
                    dotColor: Colors.white,
                    activeDotColor: _blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth > EkbBreakpoints.maxContentWidth
        ? (screenWidth - EkbBreakpoints.maxContentWidth) / 2 + 8
        : 8.0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _bg,
        body: SafeArea(
          top: false,
          left: false,
          right: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: CustomScrollView(
                  cacheExtent: 600,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _pageHPad, 10, _pageHPad, 0),
                        child: _bannerCarousel(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _categoriesGrid(context),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                      sliver: PagedSliverGrid<ApiPagingParams, dynamic>(
                        pagingController: _model.setGridViewController2(
                          (nextPageMarker) => GlavniapiCall.call(
                            offsetl: valueOrDefault<int>(
                              nextPageMarker.numItems,
                              0,
                            ),
                          ),
                        ),
                        gridDelegate: EkbBreakpoints.listingGridDelegate(),
                        builderDelegate: PagedChildBuilderDelegate<dynamic>(
                          firstPageProgressIndicatorBuilder: (_) =>
                              const _ListingSkeletonGrid(),
                          firstPageErrorIndicatorBuilder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              FFLocalizations.of(context).getText('dbdderr1'),
                              textAlign: TextAlign.center,
                              style: EkbTypography.listingDesc,
                            ),
                          ),
                          newPageProgressIndicatorBuilder: (_) => const Padding(
                            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                            child: RunningLoaderBar(),
                          ),
                          noItemsFoundIndicatorBuilder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              FFLocalizations.of(context).getText('dbddemp1'),
                              textAlign: TextAlign.center,
                              style: EkbTypography.listingDesc,
                            ),
                          ),
                          itemBuilder: (context, item, index) =>
                              EkbListingCard.fromJson(item),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 72),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingSkeletonGrid extends StatelessWidget {
  const _ListingSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cols = EkbBreakpoints.gridColumnsForWidth(screenWidth);
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: EkbBreakpoints.listingGridDelegate(),
      itemCount: cols * 3,
      itemBuilder: (_, __) => const _ListingSkeletonCard(),
    );
  }
}

class _ListingSkeletonCard extends StatelessWidget {
  const _ListingSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: EkbListingCard.cardShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 125,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 22),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 20),
                SizedBox(height: 8),
                ShimmerBox(width: 96, height: 24),
                SizedBox(height: 6),
                ShimmerBox(width: 120, height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

