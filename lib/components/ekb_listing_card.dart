import '/components/ekb_no_photo.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/ekb_image_cache.dart';
import '/services/favorites_service.dart';
import '/theme/ekb_typography.dart';
import '/components/shimmer_widgets.dart';
import '/backend/supabase/database/tables/listings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Product card matching the home screen (`dbdd`) design.
class EkbListingCard extends StatefulWidget {
  const EkbListingCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.priceText,
    this.imageUrl,
    this.publishedAt,
    this.categoryId,
    this.showDescription = true,
  });

  factory EkbListingCard.fromListingsRow(ListingsRow row,
      {bool showDescription = true}) {
    return EkbListingCard(
      id: row.id ?? '0',
      title: row.title,
      description: row.description,
      priceText: row.price?.toStringAsFixed(0),
      imageUrl: row.img,
      publishedAt: row.createdAt,
      categoryId: row.categoryId,
      showDescription: showDescription,
    );
  }

  factory EkbListingCard.fromJson(dynamic item) {
    final rawDate = getJsonField(item, r'''$.created_at''')?.toString();
    return EkbListingCard(
      id: getJsonField(item, r'''$.id''')?.toString() ?? '0',
      title: getJsonField(item, r'''$.title''')?.toString(),
      description: getJsonField(item, r'''$.description''')?.toString(),
      priceText: getJsonField(item, r'''$.price''')?.toString(),
      imageUrl: getJsonField(item, r'''$.img''')?.toString(),
      publishedAt: rawDate == null || rawDate.isEmpty
          ? null
          : DateTime.tryParse(rawDate),
      categoryId: int.tryParse(
          getJsonField(item, r'''$.category_id''')?.toString() ?? ''),
    );
  }

  static const double gridAspectRatio = 0.66;
  static const double imageHeight = 125;
  static const double gridSpacing = 12;

  static const cardShadows = [
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
  ];

  final String id;
  final String? title;
  final String? description;
  final String? priceText;
  final String? imageUrl;
  final DateTime? publishedAt;
  final int? categoryId;
  final bool showDescription;

  @override
  State<EkbListingCard> createState() => _EkbListingCardState();
}

class _EkbListingCardState extends State<EkbListingCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await FavoritesService.isFavorite(widget.id);
    if (mounted) {
      setState(() => _isFavorite = isFavorite);
    }
  }

  Future<void> _toggleFavorite() async {
    final nowFavorite = await FavoritesService.toggle(widget.id);
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _isFavorite = nowFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.pushNamed(
          PagpageWidget.routeName,
          queryParameters: {
            'idproductpage': serializeParam(widget.id, ParamType.String),
          }.withoutNulls,
        );
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: EkbListingCard.cardShadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: EkbListingCard.imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ListingImage(
                    imageUrl: widget.imageUrl,
                    categoryId: widget.categoryId,
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _FavoriteButton(
                      isFavorite: _isFavorite,
                      onTap: _toggleFavorite,
                    ),
                  ),
                ],
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
                      widget.title,
                      FFLocalizations.of(context).getText('srchttl1'),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EkbTypography.listingTitle,
                  ),
                  if (widget.showDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      valueOrDefault<String>(
                        widget.description,
                        FFLocalizations.of(context).getText('srchdes1'),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EkbTypography.listingDesc,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          valueOrDefault<String>(widget.priceText, '0'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: EkbTypography.price,
                        ),
                      ),
                      Text(
                        FFLocalizations.of(context).getText('gf7pmm28' /* р */),
                        style: EkbTypography.price,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 21,
          color: isFavorite
              ? const Color(0xFFFF4D67).withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({this.imageUrl, this.categoryId});

  final String? imageUrl;
  final int? categoryId;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return EkbNoPhoto(categoryId: categoryId);
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth > 900
            ? screenWidth / 4
            : (screenWidth > 600 ? screenWidth / 3 : screenWidth / 2))
        .clamp(160.0, 320.0);
    final memCacheWidth = (cardWidth * dpr).round();

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheManager: EkbImageCacheManager.instance,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => const ShimmerBox(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.zero,
      ),
      errorWidget: (_, __, ___) => EkbNoPhoto(categoryId: categoryId),
    );
  }
}
