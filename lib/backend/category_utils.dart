/// Корневые категории, для которых при создании обязательна подкатегория.
const kCategoriesRequiringSubcategory = <int>{1, 2, 3}; // авто, работа, квартира

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
