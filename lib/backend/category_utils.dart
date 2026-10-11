import 'package:flutter/foundation.dart';

import '/backend/supabase/supabase.dart';

/// Корневые категории, для которых при создании обязательна подкатегория.
const kCategoriesRequiringSubcategory = <int>{
  1,
  2,
  3
}; // авто, работа, квартира

/// PostgREST-фильтр `category_id` для ленты категории.
///
/// [selectedSubId] — выбранный чип подкатегории; `null` = «Все».
String buildCategoryIdFilter({
  required int rootId,
  required List<int> childIds,
  int? selectedSubId,
}) {
  if (selectedSubId != null) {
    return 'eq.$selectedSubId';
  }
  if (childIds.isEmpty) {
    return 'eq.$rootId';
  }
  // Включаем rootId, чтобы старые объявления без подкатегории тоже попадали в ленту.
  final ids = <int>{rootId, ...childIds}.toList()..sort();
  return 'in.(${ids.join(',')})';
}

/// PNG-иконки корневых категорий (id1 → asset).
const kCategoryIconAssets = <int, String>{
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
  13: 'assets/images/categories/category_entertainment.png',
  14: 'assets/images/categories/category_border.png',
};

/// Кэш «подкатегория → корневая категория», загружается один раз за запуск.
abstract final class CategoryParents {
  static final ValueNotifier<Map<int, int>> parents =
      ValueNotifier(const <int, int>{});
  static Future<void>? _loading;

  static void ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final rows = await CategoriesTable().queryRows(
        queryFn: (q) => q.not('parent_id1', 'is', null),
      );
      parents.value = {
        for (final r in rows)
          if (r.parentId1 != null) r.id1: r.parentId1!,
      };
    } catch (_) {
      // Нет сети или колонки — попробуем при следующем обращении.
      _loading = null;
    }
  }

  /// Корневая категория объявления (известная по [kCategoryIconAssets]);
  /// для подкатегории — её родитель. null — не удалось определить.
  static int? rootOf(int? categoryId) {
    if (categoryId == null) return null;
    var id = categoryId;
    for (var i = 0; i < 4; i++) {
      if (kCategoryIconAssets.containsKey(id)) return id;
      final parent = parents.value[id];
      if (parent == null) return null;
      id = parent;
    }
    return null;
  }
}
