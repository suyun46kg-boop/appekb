import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'searchpage22_widget.dart' show Searchpage22Widget;
import 'package:flutter/material.dart';

/// Sorting options for the search results.
enum SearchSort {
  relevance,
  newest,
  priceAsc,
  priceDesc,
}

extension SearchSortX on SearchSort {
  String get label {
    switch (this) {
      case SearchSort.relevance:
        return 'По релевантности';
      case SearchSort.newest:
        return 'Сначала новые';
      case SearchSort.priceAsc:
        return 'Сначала дешевле';
      case SearchSort.priceDesc:
        return 'Сначала дороже';
    }
  }

  String get shortLabel {
    switch (this) {
      case SearchSort.relevance:
        return 'Релевантность';
      case SearchSort.newest:
        return 'Новые';
      case SearchSort.priceAsc:
        return 'Дешевле';
      case SearchSort.priceDesc:
        return 'Дороже';
    }
  }

  /// Value passed to the `search_listings` RPC `sort_option` argument.
  String get rpcValue {
    switch (this) {
      case SearchSort.relevance:
        return 'relevance';
      case SearchSort.newest:
        return 'newest';
      case SearchSort.priceAsc:
        return 'price_asc';
      case SearchSort.priceDesc:
        return 'price_desc';
    }
  }
}

class Searchpage22Model extends FlutterFlowModel<Searchpage22Widget> {
  /// State fields for the search page.

  // Search text field.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  /// The query that has actually been committed for searching (Enter / tap).
  String activeQuery = '';

  /// The current (debounced) text being typed. Drives the suggestions list.
  String typedText = '';

  /// Autocomplete suggestions for the current [typedText].
  List<String> suggestions = [];

  /// Whether a suggestions request is currently in flight.
  bool loadingSuggestions = false;

  /// Monotonic token used to discard stale (out-of-order) suggestion responses.
  int suggestionRequestId = 0;

  /// Recent searches kept for the lifetime of this page.
  final List<String> recentSearches = [];

  // ---- Filters & sorting ----------------------------------------------------

  SearchSort sort = SearchSort.relevance;
  double? priceMin;
  double? priceMax;
  String? filterCity;
  int? filterCategoryId;
  String? filterCategoryName;

  /// Cached filter option data (loaded lazily the first time the sheet opens).
  List<String> cities = [];
  List<CategoriesRow> categories = [];
  bool filterOptionsLoaded = false;

  int get activeFilterCount {
    var count = 0;
    if (priceMin != null || priceMax != null) count++;
    if (filterCity != null && filterCity!.isNotEmpty) count++;
    if (filterCategoryId != null) count++;
    return count;
  }

  void resetFilters() {
    priceMin = null;
    priceMax = null;
    filterCity = null;
    filterCategoryId = null;
    filterCategoryName = null;
    sort = SearchSort.relevance;
  }

  /// Removes characters that would break a PostgREST `or(...)` filter string
  /// or act as unintended `ilike` wildcards, preventing filter injection.
  String sanitizeQuery(String input) {
    return input
        .replaceAll('\\', '')
        .replaceAll('%', '')
        .replaceAll('_', '')
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .trim();
  }

  void addRecentSearch(String term) {
    final value = term.trim();
    if (value.isEmpty) {
      return;
    }
    recentSearches.removeWhere((e) => e.toLowerCase() == value.toLowerCase());
    recentSearches.insert(0, value);
    if (recentSearches.length > 8) {
      recentSearches.removeRange(8, recentSearches.length);
    }
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
