import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/ekb_image_cache.dart';
import '/theme/ekb_typography.dart';
import '/components/shimmer_widgets.dart';
import '/backend/supabase/database/tables/listings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Product card matching the home screen (`dbdd`) design.
class EkbListingCard extends StatelessWidget {
  const EkbListingCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.priceText,
    this.imageUrl,
    this.publishedAt,
    this.showDescription = true,
  });

  factory EkbListingCard.fromListingsRow(ListingsRow row, {bool showDescription = true}) {
    return EkbListingCard(
      id: row.id ?? '0',
      title: row.title,
      description: row.description,
      priceText: row.price?.toStringAsFixed(0),
      imageUrl: row.img,
      publishedAt: row.createdAt,
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

  static const placeholderAsset = 'assets/images/zag.jpg';

  final String id;
  final String? title;
  final String? description;
  final String? priceText;
  final String? imageUrl;
  final DateTime? publishedAt;
  final bool showDescription;

  String _formatPublishedAt(BuildContext context) {
    if (publishedAt == null) return '';
    return dateTimeFormat(
      'relative',
      publishedAt,
      locale: FFLocalizations.of(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final publishedLabel = _formatPublishedAt(context);

    return InkWell(
      onTap: () {
        context.pushNamed(
          PagpageWidget.routeName,
          queryParameters: {
            'idproductpage': serializeParam(id, ParamType.String),
          }.withoutNulls,
        );
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: cardShadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: _ListingImage(imageUrl: imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueOrDefault<String>(
                      title,
                      FFLocalizations.of(context).getText('srchttl1'),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EkbTypography.listingTitle,
                  ),
                  if (showDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      valueOrDefault<String>(
                        description,
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
                          valueOrDefault<String>(priceText, '0'),
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

class _ListingImage extends StatelessWidget {
  const _ListingImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const _PlaceholderImage();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cardWidth = MediaQuery.sizeOf(context).width / 2;
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
      errorWidget: (_, __, ___) => const _PlaceholderImage(),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.scale(
        scale: 1.85,
        child: Image.asset(
          EkbListingCard.placeholderAsset,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
