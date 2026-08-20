import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk image cache with a hard object cap (not MB).
///
/// Defaults in flutter_cache_manager are 200 files / 30 days — that can grow
/// toward hundreds of MB with large listing photos. We keep fewer files and
/// expire them sooner.
class EkbImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'ekbImageCache';

  static const int maxObjects = 100;
  static const Duration stalePeriod = Duration(days: 7);

  static final EkbImageCacheManager instance = EkbImageCacheManager._();

  EkbImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: stalePeriod,
            maxNrOfCacheObjects: maxObjects,
          ),
        );

  /// Clears our disk cache, the legacy default manager, and Flutter RAM cache.
  static Future<void> clearAll() async {
    await instance.emptyCache();
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
