import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'dbdd_model.dart';
export 'dbdd_model.dart';

class _DbddCategory {
  const _DbddCategory(
    this.assetPath,
    this.labelKey,
    this.catId, {
    this.iconOffset = Offset.zero,
    this.iconSize = 47,
  });
  final String assetPath;
  final String labelKey;
  final int catId;
  final Offset iconOffset;
  final double iconSize;
}

class _PulsingPlaceholder extends StatefulWidget {
  const _PulsingPlaceholder();

  static const _color = Color(0xFFE2E8F0);

  @override
  State<_PulsingPlaceholder> createState() => _PulsingPlaceholderState();
}

class _PulsingPlaceholderState extends State<_PulsingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0.45)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(color: _PulsingPlaceholder._color),
    );
  }
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

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _titleColor = Color(0xFF334155);
  static const _text2 = Color(0xFF475569);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _categoryText = Color(0xFF0C2447);
  static const _pageHPad = 20.0;
  static const _listingPlaceholder = 'assets/images/zag.jpg';

  static const _categories = [
    _DbddCategory('assets/images/categories/category_apartment.png', 'cukp48gd', 3),
    _DbddCategory('assets/images/categories/category_job.png', 'me5sh2dc', 2),
    _DbddCategory('assets/images/categories/category_border.png', '4lwpgqmm', 14),
    _DbddCategory('assets/images/categories/category_auto.png', 'r4qsbrdp', 1),
    _DbddCategory('assets/images/categories/category_ticket.png', 'vp95t6yz', 13),
    _DbddCategory('assets/images/categories/category_services.png', 'ccc9cors', 4),
    _DbddCategory('assets/images/categories/category_sale.png', 'pnpqtuk7', 9),
    _DbddCategory('assets/images/categories/category_parttime.png', 'noun7do1', 5),
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5FE8), Color(0xFF1341B0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
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
            style: GoogleFonts.inter(
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
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
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _text3,
                ),
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

  Widget _sectionTitle(BuildContext context, String key) {
    return Text(
      FFLocalizations.of(context).getText(key),
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _titleColor,
        letterSpacing: -0.2,
        height: 1.2,
      ),
    );
  }

  Widget _categoryTile(BuildContext context, _DbddCategory cat) {
    return InkWell(
      onTap: () {
        context.pushNamed(
          TovarypocategoyWidget.routeName,
          queryParameters: {
            'paramcatid': serializeParam(cat.catId, ParamType.int),
          }.withoutNulls,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 59,
            height: 59,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Transform.translate(
                  offset: cat.iconOffset,
                  child: Image.asset(
                    cat.assetPath,
                    width: cat.iconSize,
                    height: cat.iconSize,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            FFLocalizations.of(context).getText(cat.labelKey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _text,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPublishedAt(BuildContext context, dynamic item) {
    final raw = getJsonField(item, r'''$.created_at''')?.toString();
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return dateTimeFormat(
      'relative',
      parsed,
      locale: FFLocalizations.of(context).languageCode,
    );
  }

  Widget _bannerShimmer() {
    return const _PulsingPlaceholder();
  }

  Widget _bannerSkeleton() {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _bannerShimmer(),
    );
  }

  Widget _bannerCarousel(BuildContext context) {
    return FutureBuilder<List<CaruselRow>>(
      future: _carouselFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _bannerSkeleton();
        }
        final slides = snapshot.data!;
        if (slides.isEmpty) {
          return const SizedBox(height: 168);
        }

        _model.pageViewController ??= PageController();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _ensureCarouselAutoScroll(slides.length);
          }
        });

        return Container(
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
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
                      await launchURL(slide.links!);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: valueOrDefault<String>(
                            slide.images,
                            'https://images.unsplash.com/photo-1555215695-3004980ad54e',
                          ),
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
    );
  }

  Widget _listingPlaceholderImage() {
    return ClipRect(
      child: Transform.scale(
        scale: 1.85,
        child: Image.asset(
          _listingPlaceholder,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _listingImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _listingPlaceholderImage();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cardWidth = MediaQuery.sizeOf(context).width / 2;
    final memCacheWidth = (cardWidth * dpr).round();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: memCacheWidth,
      fadeInDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => _bannerShimmer(),
      errorWidget: (_, __, ___) => _listingPlaceholderImage(),
    );
  }

  Widget _listingCard(BuildContext context, dynamic item) {
    final publishedAt = _formatPublishedAt(context, item);

    return InkWell(
      onTap: () {
        context.pushNamed(
          PagpageWidget.routeName,
          queryParameters: {
            'idproductpage': serializeParam(
              valueOrDefault<String>(
                getJsonField(item, r'''$.id''')?.toString(),
                '0',
              ),
              ParamType.String,
            ),
          }.withoutNulls,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 125,
              width: double.infinity,
              child: _listingImage(
                context,
                getJsonField(item, r'''$.img''')?.toString(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueOrDefault<String>(
                      getJsonField(item, r'''$.title''')?.toString(),
                      FFLocalizations.of(context).getText('srchttl1'),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      FFAppState().searchText = '';
                      safeSetState(() {});
                    },
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            valueOrDefault<String>(
                              getJsonField(item, r'''$.price''')?.toString(),
                              '0',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _titleColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Text(
                          FFLocalizations.of(context)
                              .getText('gf7pmm28' /* р */),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valueOrDefault<String>(
                      getJsonField(item, r'''$.description''')?.toString(),
                      FFLocalizations.of(context).getText('srchdes1'),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _text2,
                      height: 1.4,
                    ),
                  ),
                  if (publishedAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 10,
                          color: _text3,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            publishedAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _text3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            _pageHPad, 20, _pageHPad, 0),
                        child: _bannerCarousel(context),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _pageHPad, 20, _pageHPad, 0),
                        child: _sectionTitle(
                          context,
                          'zvs9dp80' /* Категории */,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _pageHPad, 16, _pageHPad, 0),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 0,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) => Center(
                            child: _categoryTile(
                              context,
                              _categories[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            _pageHPad, 0, _pageHPad, 0),
                        child: _sectionTitle(
                          context,
                          'xy92q7cu' /* Свежие объявления */,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(5, 12, 5, 0),
                      sliver: PagedSliverGrid<ApiPagingParams, dynamic>(
                        pagingController: _model.setGridViewController2(
                          (nextPageMarker) => GlavniapiCall.call(
                            offsetl: valueOrDefault<int>(
                              nextPageMarker.numItems,
                              0,
                            ),
                          ),
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        builderDelegate: PagedChildBuilderDelegate<dynamic>(
                          firstPageProgressIndicatorBuilder: (_) =>
                              const _ListingSkeletonGrid(),
                          firstPageErrorIndicatorBuilder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              FFLocalizations.of(context).getText('dbdderr1'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: _text2, fontSize: 14),
                            ),
                          ),
                          newPageProgressIndicatorBuilder: (_) => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          noItemsFoundIndicatorBuilder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              FFLocalizations.of(context).getText('dbddemp1'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: _text2, fontSize: 14),
                            ),
                          ),
                          itemBuilder: (context, item, index) =>
                              _listingCard(context, item),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
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
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _ListingSkeletonCard(),
    );
  }
}

class _ListingSkeletonCard extends StatelessWidget {
  const _ListingSkeletonCard();

  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(
            width: double.infinity,
            height: 125,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 13),
                SizedBox(height: 8),
                _ShimmerBox(width: 80, height: 16),
                SizedBox(height: 8),
                _ShimmerBox(width: double.infinity, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  static const _base = Color(0xFFE7ECF5);
  static const _highlight = Color(0xFFF6F8FC);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _base,
        borderRadius: borderRadius,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: _highlight,
        );
  }
}
