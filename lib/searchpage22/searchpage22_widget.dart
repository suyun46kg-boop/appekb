import '/dbdd/category_block_background.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '/theme/ekb_typography.dart';
import 'searchpage22_model.dart';
export 'searchpage22_model.dart';

class Searchpage22Widget extends StatefulWidget {
  const Searchpage22Widget({super.key});

  static String routeName = 'searchpage22';
  static String routePath = '/searchpage22';

  @override
  State<Searchpage22Widget> createState() => _Searchpage22WidgetState();
}

class _Searchpage22WidgetState extends State<Searchpage22Widget> {
  late Searchpage22Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const Color _brand = Color(0xFF0679EE);
  static const Color _brandSoft = Color(0x140679EE);
  static const int _pageSize = 20;

  late PagingController<int, ListingsRow> _pagingController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Searchpage22Model());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.textFieldFocusNode!.addListener(_onSearchFocusChange);

    _pagingController = PagingController<int, ListingsRow>(firstPageKey: 0)
      ..addPageRequestListener(_onPageRequest);
  }

  @override
  void dispose() {
    EasyDebounce.cancel('searchpage22_query');
    _model.textFieldFocusNode?.removeListener(_onSearchFocusChange);
    _pagingController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (mounted) setState(() {});
  }

  /// Handles the header back button.
  ///
  /// When the page was pushed onto the stack (e.g. opened from the home
  /// search bar) we simply pop. When it is shown as a bottom-navigation tab
  /// there is nothing to pop and the URL is already `/`, so we explicitly
  /// switch back to the home tab instead of doing nothing.
  void _handleBack() {
    FocusScope.of(context).unfocus();
    if (Navigator.of(context).canPop()) {
      context.safePop();
    } else {
      context.goNamed(DbddWidget.routeName);
    }
  }

  // ---- Suggestions ----------------------------------------------------------

  void _onTextChanged(String value) {
    final term = _model.sanitizeQuery(value);
    setState(() {
      _model.typedText = term;
      // Editing the query returns to the suggestions view.
      _model.activeQuery = '';
    });
    _fetchSuggestions(term);
  }

  Future<void> _fetchSuggestions(String term) async {
    if (term.isEmpty) {
      setState(() {
        _model.suggestions = [];
        _model.loadingSuggestions = false;
      });
      return;
    }

    final requestId = ++_model.suggestionRequestId;
    setState(() => _model.loadingSuggestions = true);

    final titles = <String>[];

    // 1) Curated suggestions table.
    try {
      final rows = await SearchIndexTable().queryRows(
        queryFn: (q) => q.ilike('title', '%$term%'),
        limit: 12,
      );
      titles.addAll(rows.map((e) => e.title).whereType<String>());
    } catch (_) {}

    // 2) Fallback: real listing titles (so suggestions always work).
    if (titles.isEmpty) {
      try {
        final rows = await ListingsTable().queryRows(
          queryFn: (q) => q
              .or('title.ilike.%$term%,category_name.ilike.%$term%')
              .order('created_at', ascending: false),
          limit: 20,
        );
        titles.addAll(rows.map((e) => e.title).whereType<String>());
      } catch (_) {}
    }

    // Ignore responses that arrived out of order or after the field changed.
    if (!mounted || requestId != _model.suggestionRequestId) {
      return;
    }

    final seen = <String>{};
    final unique = <String>[];
    for (final raw in titles) {
      final title = raw.trim();
      if (title.isEmpty) {
        continue;
      }
      if (seen.add(title.toLowerCase())) {
        unique.add(title);
      }
      if (unique.length >= 8) {
        break;
      }
    }

    setState(() {
      _model.suggestions = unique;
      _model.loadingSuggestions = false;
    });
  }

  // ---- Search commit / reload -----------------------------------------------

  void _runSearch(String rawTerm) {
    final term = _model.sanitizeQuery(rawTerm);
    if (term.isEmpty) {
      return;
    }
    EasyDebounce.cancel('searchpage22_query');
    _model.suggestionRequestId++; // Invalidate any in-flight suggestion fetch.
    _model.addRecentSearch(term);
    setState(() {
      _model.typedText = term;
      _model.activeQuery = term;
      _model.loadingSuggestions = false;
    });
    _reloadResults();
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    EasyDebounce.cancel('searchpage22_query');
    _model.suggestionRequestId++;
    _model.textController?.clear();
    setState(() {
      _model.typedText = '';
      _model.activeQuery = '';
      _model.suggestions = [];
      _model.loadingSuggestions = false;
    });
  }

  /// Reloads results whenever the query, filters or sorting change.
  /// Uses the controller's own [refresh] (never recreate/dispose it while the
  /// grid is attached — that throws "used after disposed").
  void _reloadResults() {
    _pagingController.refresh();
  }

  Future<void> _onPageRequest(int offset) async {
    try {
      final items = await _fetchListingsPage(offset);
      if (!mounted) {
        return;
      }
      final isLastPage = items.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(items);
      } else {
        _pagingController.appendPage(items, offset + items.length);
      }
    } catch (error) {
      if (mounted) {
        _pagingController.error = error;
      }
    }
  }

  Future<List<ListingsRow>> _fetchListingsPage(int offset) async {
    final city = _model.filterCity;
    final data = await SupaFlow.client.rpc(
      'search_listings',
      params: {
        'search_text': _model.activeQuery,
        'min_price': _model.priceMin,
        'max_price': _model.priceMax,
        'city_filter': (city != null && city.isNotEmpty) ? city : null,
        'category_filter': _model.filterCategoryId,
        'sort_option': _model.sort.rpcValue,
        'limit_count': _pageSize,
        'offset_count': offset,
      },
    ) as List;

    return data
        .map((e) => ListingsTable().createRow(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Filter options loading -----------------------------------------------

  Future<void> _ensureFilterOptions() async {
    if (_model.filterOptionsLoaded) {
      return;
    }
    try {
      final cats = await CategoriesTable().queryRows(
        queryFn: (q) => q.order('name', ascending: true),
      );
      final cityData =
          await SupaFlow.client.from('listings').select('city') as List;
      final citySet = <String>{};
      for (final row in cityData) {
        final c = (row['city'] as String?)?.trim();
        if (c != null && c.isNotEmpty) {
          citySet.add(c);
        }
      }
      final cityList = citySet.toList()..sort();
      _model.categories = cats;
      _model.cities = cityList;
      _model.filterOptionsLoaded = true;
    } catch (_) {
      _model.filterOptionsLoaded = true;
    }
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: _model.activeQuery.isNotEmpty
                  ? _buildResults(theme)
                  : _model.typedText.isNotEmpty
                      ? _buildSuggestions(theme)
                      : _buildRecentAndSuggestions(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    final topPad = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: EkbAppBarBackground(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        padding: EdgeInsets.fromLTRB(10.0, topPad + 10.0, 16.0, 16.0),
        child: SizedBox(
          height: 48.0,
          child: Row(
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: _handleBack,
              ),
              const SizedBox(width: 8.0),
              Expanded(child: _buildSearchField(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(FlutterFlowTheme theme) {
    final bool alignLeft =
        (_model.textFieldFocusNode?.hasFocus ?? false) ||
            _model.textController.text.isNotEmpty;
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24.0,
            offset: Offset(0.0, 8.0),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6.0,
            offset: Offset(0.0, 2.0),
          ),
        ],
      ),
      child: TextFormField(
          controller: _model.textController,
          focusNode: _model.textFieldFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          textAlign: alignLeft ? TextAlign.start : TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          onChanged: (value) => EasyDebounce.debounce(
            'searchpage22_query',
            const Duration(milliseconds: 300),
            () => _onTextChanged(value),
          ),
          onFieldSubmitted: _runSearch,
          style: theme.bodyMedium.override(
            font: GoogleFonts.inter(),
            color: theme.primaryText,
            fontSize: 15.0,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: FFLocalizations.of(context).getText('srchhint1'),
            hintStyle: theme.bodyMedium.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              fontSize: 15.0,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _brand, size: 22.0),
            suffixIcon: _model.textController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.cancel_rounded,
                        color: theme.secondaryText, size: 20.0),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
    );
  }

  Widget _buildRecentAndSuggestions(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_model.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FFLocalizations.of(context).getText('srchrec1'),
                  style: theme.titleSmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    fontSize: 16.0,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _model.recentSearches.clear()),
                  child: Text(
                    FFLocalizations.of(context).getText('srchclr1'),
                    style: theme.bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: _brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            ..._model.recentSearches.map(
              (term) => _RecentTile(
                term: term,
                onTap: () {
                  _model.textController?.text = term;
                  _runSearch(term);
                },
                onRemove: () =>
                    setState(() => _model.recentSearches.remove(term)),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFF6B35), size: 20.0),
              const SizedBox(width: 6.0),
              Text(
                FFLocalizations.of(context).getText('srchpop1'),
                style: theme.titleSmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          FutureBuilder<List<SearchIndexRow>>(
            future: SearchIndexTable().queryRows(
              queryFn: (q) => q,
              limit: 12,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const _PopularTagsShimmer();
              }
              final tags = snapshot.data!
                  .map((e) => e.title)
                  .where((e) => e != null && e.isNotEmpty)
                  .cast<String>()
                  .toList();
              if (tags.isEmpty) {
                return Text(
                  FFLocalizations.of(context).getText('srchtyp1'),
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                  ),
                );
              }
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: tags
                    .map(
                      (tag) => _SuggestionChip(
                        label: tag,
                        onTap: () {
                          _model.textController?.text = tag;
                          _runSearch(tag);
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(FlutterFlowTheme theme) {
    final typed = _model.typedText;
    final items = _model.suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 3.0,
          child: _model.loadingSuggestions
              ? const _RunningLoaderBar()
              : null,
        ),
        _SuggestionRow(
          icon: Icons.search_rounded,
          label: FFLocalizations.of(context)
              .getText('srchsea1')
              .replaceAll('{term}', typed),
          highlight: typed,
          emphasize: true,
          onTap: () => _runSearch(typed),
        ),
        Divider(height: 1.0, thickness: 1.0, color: theme.alternate),
        Expanded(
          child: (items.isEmpty && _model.loadingSuggestions)
              ? const _SuggestionsListShimmer()
              : (items.isEmpty && !_model.loadingSuggestions)
                  ? _NoSuggestions(term: typed)
                  : ListView.separated(
                  padding: EdgeInsets.zero,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1.0, thickness: 1.0, color: theme.alternate),
                  itemBuilder: (context, index) => _SuggestionRow(
                    icon: Icons.north_west_rounded,
                    label: items[index],
                    highlight: typed,
                    onTap: () {
                      _model.textController?.text = items[index];
                      _runSearch(items[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResults(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultsBar(theme),
        Expanded(
          child: RefreshIndicator(
            color: _brand,
            onRefresh: () async {
              _pagingController.refresh();
              await Future.delayed(const Duration(milliseconds: 350));
            },
            child: PagedGridView<int, ListingsRow>(
              pagingController: _pagingController,
              cacheExtent: 600,
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 40.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.76,
              ),
              showNewPageProgressIndicatorAsGridChild: false,
              builderDelegate: PagedChildBuilderDelegate<ListingsRow>(
                itemBuilder: (context, item, index) =>
                    _ListingCard(row: item, theme: theme),
                firstPageProgressIndicatorBuilder: (_) =>
                    const _SkeletonGrid(),
                newPageProgressIndicatorBuilder: (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: _RunningLoaderBar(height: 4.0),
                ),
                noItemsFoundIndicatorBuilder: (_) => _EmptyState(
                  term: _model.activeQuery,
                  hasFilters: _model.activeFilterCount > 0,
                  onResetFilters: () {
                    setState(() => _model.resetFilters());
                    _pagingController.refresh();
                  },
                ),
                firstPageErrorIndicatorBuilder: (_) => _ErrorState(
                  onRetry: () => _pagingController.refresh(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsBar(FlutterFlowTheme theme) {
    final filterCount = _model.activeFilterCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 8.0),
          child: Row(
            children: [
              Expanded(
                child: _PillButton(
                  icon: Icons.swap_vert_rounded,
                  label: _model.sort.shortLabel(context),
                  onTap: _openSortSheet,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _PillButton(
                  icon: Icons.tune_rounded,
                  label: FFLocalizations.of(context).getText('srchflt1'),
                  badgeCount: filterCount,
                  active: filterCount > 0,
                  onTap: _openFilters,
                ),
              ),
            ],
          ),
        ),
        if (filterCount > 0) _buildActiveFilterChips(theme),
        const SizedBox(height: 2.0),
      ],
    );
  }

  Widget _buildActiveFilterChips(FlutterFlowTheme theme) {
    final chips = <Widget>[];

    if (_model.priceMin != null || _model.priceMax != null) {
      final min = _model.priceMin;
      final max = _model.priceMax;
      final l = FFLocalizations.of(context);
      final cur = l.getText('srchcur1');
      String label;
      if (min != null && max != null) {
        label = '${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)} $cur';
      } else if (min != null) {
        label =
            '${l.getText('srchfrm1')} ${min.toStringAsFixed(0)} $cur';
      } else {
        label =
            '${l.getText('srchto01')} ${max!.toStringAsFixed(0)} $cur';
      }
      chips.add(_ActiveFilterChip(
        label: label,
        onRemove: () {
          setState(() {
            _model.priceMin = null;
            _model.priceMax = null;
          });
          _pagingController.refresh();
        },
      ));
    }

    if (_model.filterCity != null && _model.filterCity!.isNotEmpty) {
      chips.add(_ActiveFilterChip(
        label: _model.filterCity!,
        onRemove: () {
          setState(() => _model.filterCity = null);
          _pagingController.refresh();
        },
      ));
    }

    if (_model.filterCategoryId != null) {
      chips.add(_ActiveFilterChip(
        label: _model.filterCategoryName ??
            FFLocalizations.of(context).getText('srchcat1'),
        onRemove: () {
          setState(() {
            _model.filterCategoryId = null;
            _model.filterCategoryName = null;
          });
          _pagingController.refresh();
        },
      ));
    }

    return SizedBox(
      height: 44.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }

  // ---- Sort sheet -----------------------------------------------------------

  Future<void> _openSortSheet() async {
    final theme = FlutterFlowTheme.of(context);
    final selected = await showModalBottomSheet<SearchSort>(
      context: context,
      backgroundColor: theme.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8.0),
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  FFLocalizations.of(context).getText('srchsrt1'),
                  style: theme.titleMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            ...SearchSort.values.map(
              (option) {
                final isSelected = _model.sort == option;
                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 14.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label(context),
                            style: theme.bodyMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                              color:
                                  isSelected ? _brand : theme.primaryText,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              color: _brand, size: 22.0),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );

    if (selected != null && mounted && selected != _model.sort) {
      setState(() => _model.sort = selected);
      _pagingController.refresh();
    }
  }

  // ---- Filters sheet --------------------------------------------------------

  Future<void> _openFilters() async {
    await _ensureFilterOptions();
    if (!mounted) {
      return;
    }
    final theme = FlutterFlowTheme.of(context);

    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => _FilterSheet(
        initialMin: _model.priceMin,
        initialMax: _model.priceMax,
        initialCity: _model.filterCity,
        initialCategoryId: _model.filterCategoryId,
        initialCategoryName: _model.filterCategoryName,
        cities: _model.cities,
        categories: _model.categories,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _model.priceMin = result.min;
        _model.priceMax = result.max;
        _model.filterCity = result.city;
        _model.filterCategoryId = result.categoryId;
        _model.filterCategoryName = result.categoryName;
      });
      _pagingController.refresh();
    }
  }
}

/// Result returned by [_FilterSheet] when the user taps "Показать результаты".
class _FilterResult {
  const _FilterResult({
    this.min,
    this.max,
    this.city,
    this.categoryId,
    this.categoryName,
  });

  final double? min;
  final double? max;
  final String? city;
  final int? categoryId;
  final String? categoryName;
}

/// Self-contained filter bottom sheet with its own controller lifecycle.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.cities,
    required this.categories,
    this.initialMin,
    this.initialMax,
    this.initialCity,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  final List<String> cities;
  final List<CategoriesRow> categories;
  final double? initialMin;
  final double? initialMax;
  final String? initialCity;
  final int? initialCategoryId;
  final String? initialCategoryName;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const Color _brand = Color(0xFF0679EE);

  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  String? _city;
  int? _catId;
  String? _catName;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
        text: widget.initialMin != null
            ? widget.initialMin!.toStringAsFixed(0)
            : '');
    _maxCtrl = TextEditingController(
        text: widget.initialMax != null
            ? widget.initialMax!.toStringAsFixed(0)
            : '');
    _city = widget.initialCity;
    _catId = widget.initialCategoryId;
    _catName = widget.initialCategoryName;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  double? _parse(String input) =>
      double.tryParse(input.trim().replaceAll(' ', '').replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8.0),
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 12.0, 8.0),
              child: Row(
                children: [
                  Text(
                    FFLocalizations.of(context).getText('srchflt1'),
                    style: theme.titleMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _minCtrl.clear();
                      _maxCtrl.clear();
                      _city = null;
                      _catId = null;
                      _catName = null;
                    }),
                    child: Text(
                      FFLocalizations.of(context).getText('srchrs1'),
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1.0, color: theme.alternate),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                        theme, FFLocalizations.of(context).getText('srchprc1')),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Expanded(
                            child: _priceField(theme, _minCtrl,
                                FFLocalizations.of(context).getText('srchfrm1'))),
                        const SizedBox(width: 12.0),
                        Expanded(
                            child: _priceField(theme, _maxCtrl,
                                FFLocalizations.of(context).getText('srchto01'))),
                      ],
                    ),
                    if (widget.cities.isNotEmpty) ...[
                      const SizedBox(height: 22.0),
                      _sectionTitle(
                          theme, FFLocalizations.of(context).getText('srchcty1')),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _ChoicePill(
                            label:
                                FFLocalizations.of(context).getText('srchall1'),
                            selected: _city == null,
                            onTap: () => setState(() => _city = null),
                          ),
                          ...widget.cities.map(
                            (city) => _ChoicePill(
                              label: city,
                              selected: _city == city,
                              onTap: () => setState(() => _city = city),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.categories.isNotEmpty) ...[
                      const SizedBox(height: 22.0),
                      _sectionTitle(
                          theme, FFLocalizations.of(context).getText('srchcat1')),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _ChoicePill(
                            label:
                                FFLocalizations.of(context).getText('srchall1'),
                            selected: _catId == null,
                            onTap: () => setState(() {
                              _catId = null;
                              _catName = null;
                            }),
                          ),
                          ...widget.categories.map(
                            (cat) => _ChoicePill(
                              label: cat.name,
                              selected: _catId == cat.id1,
                              onTap: () => setState(() {
                                _catId = cat.id1;
                                _catName = cat.name;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(
                      _FilterResult(
                        min: _parse(_minCtrl.text),
                        max: _parse(_maxCtrl.text),
                        city: _city,
                        categoryId: _catId,
                        categoryName: _catName,
                      ),
                    ),
                    child: Text(
                      FFLocalizations.of(context).getText('srchsho1'),
                      style: theme.titleSmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(FlutterFlowTheme theme, String text) {
    return Text(
      text,
      style: theme.titleSmall.override(
        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
        fontSize: 15.0,
      ),
    );
  }

  Widget _priceField(
    FlutterFlowTheme theme,
    TextEditingController controller,
    String hint,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: theme.bodyMedium.override(font: GoogleFonts.inter()),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.bodyMedium.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
        ),
        filled: true,
        fillColor: theme.primaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.alternate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: _brand),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44.0,
          height: 44.0,
          child: Icon(icon, color: Colors.white, size: 19.0),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final Color fg =
        active ? _Searchpage22WidgetState._brand : theme.primaryText;
    return Material(
      color: active
          ? _Searchpage22WidgetState._brandSoft
          : theme.secondaryBackground,
      borderRadius: BorderRadius.circular(14.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.0),
        onTap: onTap,
        child: Container(
          height: 44.0,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: active
                  ? const Color(0x660679EE)
                  : theme.alternate,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 19.0),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: fg,
                    fontSize: 14.0,
                  ),
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 8.0),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                  decoration: const BoxDecoration(
                    color: _Searchpage22WidgetState._brand,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 7.0, 8.0, 7.0),
      decoration: BoxDecoration(
        color: const Color(0x1A0679EE),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0x660679EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.bodySmall.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w500),
              color: _Searchpage22WidgetState._brand,
              fontSize: 13.0,
            ),
          ),
          const SizedBox(width: 4.0),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                color: _Searchpage22WidgetState._brand, size: 16.0),
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: selected
              ? _Searchpage22WidgetState._brand
              : theme.primaryBackground,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: selected
                ? _Searchpage22WidgetState._brand
                : theme.alternate,
          ),
        ),
        child: Text(
          label,
          style: theme.bodyMedium.override(
            font: GoogleFonts.inter(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
            color: selected ? Colors.white : theme.primaryText,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 4.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).alternate,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: theme.secondaryText, size: 20.0),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                term,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.inter(),
                  fontSize: 15.0,
                ),
              ),
            ),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  color: theme.secondaryText, size: 18.0),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = '',
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String highlight;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final baseStyle = theme.bodyMedium.override(
      font: GoogleFonts.inter(
          fontWeight: emphasize ? FontWeight.w600 : FontWeight.normal),
      color: emphasize ? theme.primary : theme.primaryText,
      fontSize: 15.0,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon,
                color: emphasize ? theme.primary : theme.secondaryText,
                size: 20.0),
            const SizedBox(width: 14.0),
            Expanded(
              child: (emphasize || highlight.isEmpty)
                  ? Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: baseStyle,
                    )
                  : _highlighted(theme, baseStyle),
            ),
            if (!emphasize)
              Icon(Icons.call_made_rounded,
                  color: theme.secondaryText, size: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _highlighted(FlutterFlowTheme theme, TextStyle baseStyle) {
    final lowerLabel = label.toLowerCase();
    final lowerTerm = highlight.toLowerCase();
    final start = lowerLabel.indexOf(lowerTerm);
    if (start < 0) {
      return Text(label,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final end = start + highlight.length;
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.primaryText,
    );
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: label.substring(0, start)),
          TextSpan(text: label.substring(start, end), style: boldStyle),
          TextSpan(text: label.substring(end)),
        ],
      ),
    );
  }
}

class _NoSuggestions extends StatelessWidget {
  const _NoSuggestions({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Text(
        FFLocalizations.of(context)
            .getText('srchnos1')
            .replaceAll('{term}', term),
        style: theme.bodyMedium.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
          fontSize: 14.0,
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: _Searchpage22WidgetState._brandSoft,
      borderRadius: BorderRadius.circular(22.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(22.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(color: const Color(0x330679EE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_rounded,
                  color: _Searchpage22WidgetState._brand, size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                label,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  color: _Searchpage22WidgetState._brand,
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.row, required this.theme});

  final ListingsRow row;
  final FlutterFlowTheme theme;

  // Colors matched to the home page (`dbdd`) listing card.
  static const Color _cardBlue = Color(0xFF1A56DB);
  static const Color _cardText = Color(0xFF0F172A);
  static const Color _cardText2 = Color(0xFF475569);
  static const Color _cardText3 = Color(0xFF94A3B8);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const String _placeholderAsset = 'assets/images/zag.jpg';

  String _publishedAt(BuildContext context) {
    final raw = row.createdAt;
    if (raw == null) return '';
    return dateTimeFormat(
      'relative',
      raw,
      locale: FFLocalizations.of(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final publishedAt = _publishedAt(context);
    return InkWell(
      onTap: () => context.pushNamed(
        PagpageWidget.routeName,
        queryParameters: {
          'idproductpage': serializeParam(row.id, ParamType.String),
        }.withoutNulls,
      ),
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: _cardBorder),
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
              height: 125.0,
              width: double.infinity,
              child: _listingImage(context, row.img),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueOrDefault<String>(
                        row.title,
                        FFLocalizations.of(context).getText('srchttl1')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: _cardText,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    valueOrDefault<String>(
                        row.description,
                        FFLocalizations.of(context).getText('srchdes1')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.0,
                      color: _cardText2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          valueOrDefault<String>(
                              row.price?.toStringAsFixed(0), '0'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: EkbTypography.price,
                        ),
                      ),
                      Text(
                        ' р',
                        style: EkbTypography.price,
                      ),
                    ],
                  ),
                  if (publishedAt.isNotEmpty) ...[
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 10.0, color: _cardText3),
                        const SizedBox(width: 3.0),
                        Expanded(
                          child: Text(
                            publishedAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.0,
                              color: _cardText3,
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

  Widget _listingImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholderImage();
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
      placeholder: (_, __) => const _ShimmerBox(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.zero,
      ),
      errorWidget: (_, __, ___) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return ClipRect(
      child: Transform.scale(
        scale: 1.85,
        child: Image.asset(
          _placeholderAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.term,
    this.hasFilters = false,
    this.onResetFilters,
  });

  final String term;
  final bool hasFilters;
  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                color: theme.secondaryText, size: 64.0),
            const SizedBox(height: 16.0),
            Text(
              FFLocalizations.of(context).getText('srchnon1'),
              style: theme.headlineSmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              hasFilters
                  ? FFLocalizations.of(context)
                      .getText('srchnof1')
                      .replaceAll('{term}', term)
                  : FFLocalizations.of(context)
                      .getText('srchnor1')
                      .replaceAll('{term}', term),
              textAlign: TextAlign.center,
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
              ),
            ),
            if (hasFilters && onResetFilters != null) ...[
              const SizedBox(height: 16.0),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _Searchpage22WidgetState._brand),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: onResetFilters,
                child: Text(
                  FFLocalizations.of(context).getText('srchrf1'),
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: _Searchpage22WidgetState._brand,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: theme.secondaryText, size: 56.0),
            const SizedBox(height: 16.0),
            Text(
              FFLocalizations.of(context).getText('srcherr1'),
              style: theme.titleMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _Searchpage22WidgetState._brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: onRetry,
              child: Text(
                FFLocalizations.of(context).getText('srchret1'),
                style: theme.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningLoaderBar extends StatelessWidget {
  const _RunningLoaderBar({this.height = 3.0});

  final double height;

  static const Color _base = Color(0xFFE2E8F0);
  static const Color _highlight = Color(0xFFF6F8FC);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Container(color: _base)
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1200.ms,
            color: _highlight,
          ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  static const Color _base = Color(0xFFE2E8F0);
  static const Color _highlight = Color(0xFFF6F8FC);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _base,
        borderRadius: borderRadius,
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1200.ms,
          color: _highlight,
        );
  }
}

class _PopularTagsShimmer extends StatelessWidget {
  const _PopularTagsShimmer();

  static const List<double> _widths = [72, 96, 84, 110, 78, 92];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _widths
          .map(
            (w) => _ShimmerBox(
              width: w,
              height: 38.0,
              borderRadius: BorderRadius.circular(22.0),
            ),
          )
          .toList(),
    );
  }
}

class _SuggestionsListShimmer extends StatelessWidget {
  const _SuggestionsListShimmer();

  static const List<double> _widths = [0.92, 0.78, 0.85, 0.68, 0.88];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _widths.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1.0, thickness: 1.0, color: theme.alternate),
      itemBuilder: (context, index) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              const _ShimmerBox(width: 20.0, height: 20.0),
              const SizedBox(width: 14.0),
              _ShimmerBox(
                width: screenWidth * _widths[index],
                height: 14.0,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 40.0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.76,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(
            width: double.infinity,
            height: 125.0,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 11.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: double.infinity, height: 12.0),
                SizedBox(height: 8.0),
                _ShimmerBox(width: 90.0, height: 12.0),
                SizedBox(height: 14.0),
                _ShimmerBox(width: 64.0, height: 16.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
