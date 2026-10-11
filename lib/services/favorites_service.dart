import 'package:shared_preferences/shared_preferences.dart';

/// Locally stored "liked" listings. Favorites live only on the device
/// (SharedPreferences), the same way across every screen that shows a
/// heart icon (home grid, search, category, listing page, favorites tab).
class FavoritesService {
  FavoritesService._();

  static const _prefsKey = 'favorite_listing_ids';

  static Set<String>? _cache;

  static Future<Set<String>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    _cache = (prefs.getStringList(_prefsKey) ?? []).toSet();
    return _cache!;
  }

  static Future<void> _save(Set<String> ids) async {
    _cache = ids;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.toList());
  }

  static Future<bool> isFavorite(String id) async {
    final ids = await _load();
    return ids.contains(id);
  }

  /// Toggles favorite state for [id] and returns the new state.
  static Future<bool> toggle(String id) async {
    final ids = await _load();
    final nowFavorite = !ids.contains(id);
    if (nowFavorite) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    await _save(ids);
    return nowFavorite;
  }

  static Future<void> remove(String id) async {
    final ids = await _load();
    if (ids.remove(id)) {
      await _save(ids);
    }
  }

  static Future<List<String>> getIds() async {
    final ids = await _load();
    return ids.toList();
  }
}
