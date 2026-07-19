import '/dbdd/category_block_background.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'tovarypocategoy_model.dart';
export 'tovarypocategoy_model.dart';

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

class TovarypocategoyWidget extends StatefulWidget {
  const TovarypocategoyWidget({
    super.key,
    required this.paramcatid,
  });

  final int? paramcatid;

  static String routeName = 'tovarypocategoy';
  static String routePath = '/tovarypocategoy';

  @override
  State<TovarypocategoyWidget> createState() => _TovarypocategoyWidgetState();
}

class _TovarypocategoyWidgetState extends State<TovarypocategoyWidget> {
  late TovarypocategoyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final Future<CategoriesRow?> _categoryFuture;

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _titleColor = Color(0xFF334155);
  static const _text2 = Color(0xFF475569);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _pageHPad = 20.0;
  static const _listingPlaceholder = 'assets/images/zag.jpg';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TovarypocategoyModel());
    _categoryFuture = _loadCategory();
  }

  Future<CategoriesRow?> _loadCategory() async {
    final rows = await CategoriesTable().querySingleRow(
      queryFn: (q) => q.eqOrNull(
        'id1',
        valueOrDefault<int>(widget.paramcatid, 1),
      ),
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _header(BuildContext context, String title) {
    final topPad = MediaQuery.paddingOf(context).top;

    return EkbAppBarBackground(
      padding: EdgeInsets.fromLTRB(4, topPad + 8, _pageHPad, 16),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                iconSize: 24,
                splashRadius: 22,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
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
      placeholder: (_, __) => const _PulsingPlaceholder(),
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
              color: Color(0x16000000),
              blurRadius: 12,
              offset: Offset(0, 4),
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Color(0x08000000),
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
                  Row(
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
                        FFLocalizations.of(context).getText('gf7pmm28' /* р */),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _titleColor,
                        ),
                      ),
                    ],
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
        body: FutureBuilder<CategoriesRow?>(
          future: _categoryFuture,
          builder: (context, snapshot) {
            final title = snapshot.hasData
                ? valueOrDefault<String>(
                    snapshot.data?.name,
                    FFLocalizations.of(context)
                        .getText('au4pejr1' /* категория */),
                  )
                : FFLocalizations.of(context)
                    .getText('au4pejr1' /* категория */);

            return Column(
              children: [
                _header(context, title),
                Expanded(
                  child: CustomScrollView(
                    cacheExtent: 600,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(5, 12, 5, 0),
                        sliver: PagedSliverGrid<ApiPagingParams, dynamic>(
                          pagingController: _model.setGridViewController(
                            (nextPageMarker) => ApibirCall.call(
                              offset: nextPageMarker.numItems,
                              categoryId: valueOrDefault<String>(
                                'eq.${valueOrDefault<String>(
                                  widget.paramcatid?.toString(),
                                  'eq.0',
                                )}',
                                '1',
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
                                FFLocalizations.of(context).getText('caterr1'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: _text2,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            newPageProgressIndicatorBuilder: (_) =>
                                const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _blue,
                                  ),
                                ),
                              ),
                            ),
                            noItemsFoundIndicatorBuilder: (_) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                FFLocalizations.of(context).getText('catemp1'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: _text2,
                                  fontSize: 14,
                                ),
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
            );
          },
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
