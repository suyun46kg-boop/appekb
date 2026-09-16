import '/dbdd/category_block_background.dart';
import '/components/ekb_listing_card.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/category_utils.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '/theme/ekb_breakpoints.dart';
import '/theme/ekb_typography.dart';
import 'tovarypocategoy_model.dart';
export 'tovarypocategoy_model.dart';

class _CategoryPageData {
  const _CategoryPageData({
    required this.category,
    required this.subcategories,
  });

  final CategoriesRow? category;
  final List<CategoriesRow> subcategories;
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
  late final Future<_CategoryPageData> _pageDataFuture;

  /// null = чип «Все».
  int? _selectedSubId;

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text2 = Color(0xFF475569);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _pageHPad = 20.0;

  int get _rootId => valueOrDefault<int>(widget.paramcatid, 1);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TovarypocategoyModel());
    _pageDataFuture = _loadPageData();
  }

  Future<_CategoryPageData> _loadPageData() async {
    final rows = await CategoriesTable().querySingleRow(
      queryFn: (q) => q.eqOrNull('id1', _rootId),
    );
    List<CategoriesRow> subs = const [];
    try {
      subs = await CategoriesTable().queryRows(
        queryFn: (q) =>
            q.eq('parent_id1', _rootId).order('id1', ascending: true),
      );
    } catch (_) {
      // Колонка parent_id1 ещё не применена в Supabase — лента без чипов.
    }
    return _CategoryPageData(
      category: rows.isNotEmpty ? rows.first : null,
      subcategories: subs,
    );
  }

  void _selectSubcategory(int? subId) {
    if (_selectedSubId == subId) return;
    setState(() => _selectedSubId = subId);
    // Обновляем apiCall в build, затем перезапрашиваем первую страницу.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _model.gridViewPagingController?.refresh();
    });
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: EkbBreakpoints.maxHeaderWidth),
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
        ),
      ),
    );
  }

  Widget _subcategoryChips(List<CategoriesRow> subs) {
    if (subs.isEmpty) return const SizedBox.shrink();

    final items = <({String label, int? id})>[
      (label: FFLocalizations.of(context).getText('srchall1'), id: null),
      ...subs.map((s) => (label: s.name, id: s.id1)),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: EkbBreakpoints.maxHeaderWidth),
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _pageHPad),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = _selectedSubId == item.id;
              return Center(
                child: _chip(
                  label: item.label,
                  selected: selected,
                  onTap: () => _selectSubcategory(item.id),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0x1A1A56DB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0x661A56DB) : _border,
            width: 1,
          ),
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: EkbTypography.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            height: 18 / 14,
            color: selected ? EkbTypography.brandBlue : EkbTypography.textPrimary,
          ),
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
        body: FutureBuilder<_CategoryPageData>(
          future: _pageDataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  _header(
                    context,
                    FFLocalizations.of(context)
                        .getText('au4pejr1' /* категория */),
                  ),
                  const Expanded(
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
                ],
              );
            }

            final data = snapshot.data!;
            final title = valueOrDefault<String>(
              data.category?.name,
              FFLocalizations.of(context).getText('au4pejr1' /* категория */),
            );
            final subs = data.subcategories;
            final childIds = subs.map((s) => s.id1).toList();
            final categoryFilter = buildCategoryIdFilter(
              rootId: _rootId,
              childIds: childIds,
              selectedSubId: _selectedSubId,
            );

            final screenWidth = MediaQuery.sizeOf(context).width;
            final hPad = screenWidth > EkbBreakpoints.maxContentWidth
                ? (screenWidth - EkbBreakpoints.maxContentWidth) / 2 + 8
                : 8.0;

            return Column(
              children: [
                _header(context, title),
                if (subs.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _subcategoryChips(subs),
                  const SizedBox(height: 10),
                ],
                Expanded(
                  child: CustomScrollView(
                    scrollCacheExtent: ScrollCacheExtent.pixels(600), slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          subs.isEmpty ? 12 : 8,
                          hPad,
                          0,
                        ),
                        sliver: PagedSliverGrid<ApiPagingParams, dynamic>(
                          pagingController: _model.setGridViewController(
                            (nextPageMarker) => ApibirCall.call(
                              offset: nextPageMarker.numItems,
                              categoryId: categoryFilter,
                            ),
                          ),
                          gridDelegate: EkbBreakpoints.listingGridDelegate(),
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
                                EkbListingCard.fromJson(item),
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
                _ShimmerBox(width: double.infinity, height: 11),
                SizedBox(height: 8),
                _ShimmerBox(width: 80, height: 16),
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
