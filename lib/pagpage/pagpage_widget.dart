import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pagpage_model.dart';
export 'pagpage_model.dart';

class PagpageWidget extends StatefulWidget {
  const PagpageWidget({
    super.key,
    String? idproductpage,
  }) : idproductpage = idproductpage ?? '1';

  final String idproductpage;

  static String routeName = 'pagpage';
  static String routePath = '/pagpage';

  @override
  State<PagpageWidget> createState() => _PagpageWidgetState();
}

class _PagpageWidgetState extends State<PagpageWidget> {
  late PagpageModel _model;
  late final Future<ListingsRow?> _listingFuture;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const _favoritesPrefsKey = 'favorite_listing_ids';

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _text2 = Color(0xFF475569);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _shimmerBase = Color(0xFFE7ECF5);
  static const _shimmerHighlight = Color(0xFFF6F8FC);
  static const _listingPlaceholder = 'assets/images/zag.jpg';

  bool _isFavorite = false;
  String? _resolvedSellerName;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PagpageModel());
    _listingFuture = _loadListing();
    _loadFavoriteState();
  }

  Future<ListingsRow?> _loadListing() async {
    final rows = await ListingsTable().querySingleRow(
      queryFn: (q) => q.eqOrNull('id', widget.idproductpage),
    );
    final listing = rows.isNotEmpty ? rows.first : null;
    final hasUserName = listing?.userName?.trim().isNotEmpty ?? false;
    final userId = listing?.userId;
    if (!hasUserName && userId != null && userId.isNotEmpty) {
      final sellerRows = await UserTable().querySingleRow(
        queryFn: (q) => q.eqOrNull('id', userId),
      );
      if (sellerRows.isNotEmpty) {
        _resolvedSellerName = sellerRows.first.name;
      }
    }
    return listing;
  }

  Future<void> _loadFavoriteState() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesPrefsKey) ?? [];
    if (mounted) {
      setState(() {
        _isFavorite = favorites.contains(widget.idproductpage);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesPrefsKey) ?? [];
    final nowFavorite = !_isFavorite;
    if (nowFavorite) {
      favorites.add(widget.idproductpage);
    } else {
      favorites.remove(widget.idproductpage);
    }
    await prefs.setStringList(_favoritesPrefsKey, favorites.toSet().toList());
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(() => _isFavorite = nowFavorite);
    }
  }

  /// Normalizes any phone input to an 11-digit number starting with the
  /// Russian country code (7), e.g. '89991234567' -> '79991234567',
  /// '+7 999 123-45-67' -> '79991234567', '9991234567' -> '79991234567'.
  String _normalizedPhone(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = digitsOnly.length >= 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : digitsOnly.padLeft(10, '0');
    return '7$last10';
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: '+${_normalizedPhone(phone)}'));
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = _normalizedPhone(phone);
    await launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _shareListing(ListingsRow listing) {
    final title = valueOrDefault<String>(
        listing.title, FFLocalizations.of(context).getText('c5j5d6pi'));
    final price = valueOrDefault<String>(
      listing.price?.toStringAsFixed(0),
      '0',
    );
    SharePlus.instance.share(
      ShareParams(
        text: '$title — $price р\n${listing.description ?? ''}'.trim(),
      ),
    );
  }

  void _openFullscreenImage(String? imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, __) => FadeTransition(
          opacity: animation,
          child: _FullscreenImageViewer(
            imageUrl: imageUrl,
            placeholderAsset: _listingPlaceholder,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _placeholderImage() {
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

  Widget _heroImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholderImage();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => Container(color: const Color(0xFFE2E8F0)),
      errorWidget: (_, __, ___) => _placeholderImage(),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color background = const Color(0x59000000),
    Color foreground = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: 20),
      ),
    );
  }

  Widget _topActionsBar(BuildContext context, ListingsRow? listing) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _circleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
            Row(
              children: [
                if (listing != null)
                  _circleIconButton(
                    icon: Icons.ios_share_rounded,
                    onTap: () => _shareListing(listing),
                  ),
                const SizedBox(width: 8),
                _circleIconButton(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  foreground: _isFavorite ? const Color(0xFFFF4D67) : Colors.white,
                  onTap: _toggleFavorite,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _newBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        FFLocalizations.of(context).getText('newbadge01' /* Новое */),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _text,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: _text3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sellerCard(ListingsRow listing) {
    final name = valueOrDefault<String>(
      valueOrDefault<String>(listing.userName, _resolvedSellerName ?? ''),
      FFLocalizations.of(context).getText('pguser01'),
    );
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return _sectionCard(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    FFLocalizations.of(context)
                        .getText('sellerlbl1' /* Продавец */),
                    style: GoogleFonts.inter(fontSize: 12, color: _text3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _shimmerBase,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: _shimmerHighlight,
        );
  }

  Widget _loadingSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.36,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 220, height: 20),
                const SizedBox(height: 10),
                _shimmerBox(width: 120, height: 26),
                const SizedBox(height: 16),
                _shimmerBox(width: double.infinity, height: 140),
                const SizedBox(height: 12),
                _shimmerBox(width: double.infinity, height: 100),
                const SizedBox(height: 16),
                _shimmerBox(width: double.infinity, height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notFoundView(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: _text3,
            ),
            const SizedBox(height: 16),
            Text(
              FFLocalizations.of(context)
                  .getText('notfound01' /* Объявление не найдено */),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              FFLocalizations.of(context).getText(
                  'notfound02' /* Возможно, оно было удалено или снято с публикации */),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: _text3),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  FFLocalizations.of(context).getText('notfound03' /* Назад */),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactButtons(String phone) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _call(phone),
              icon: const Icon(Icons.call_rounded, size: 20),
              label: Text(
                FFLocalizations.of(context)
                    .getText('7l64c59t' /* Позванить */),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _openWhatsApp(phone),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: Text(
                FFLocalizations.of(context)
                    .getText('whatsapp1' /* WhatsApp */),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight =
        (MediaQuery.of(context).size.height * 0.38).clamp(260.0, 380.0);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _bg,
        body: FutureBuilder<ListingsRow?>(
          future: _listingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Stack(
                children: [
                  _loadingSkeleton(context),
                  _topActionsBar(context, null),
                ],
              );
            }

            final listing = snapshot.data;
            if (listing == null) {
              return Stack(
                children: [
                  _notFoundView(context),
                  _topActionsBar(context, null),
                ],
              );
            }

            final phone = listing.phonnumber ?? '';
            final publishedAt = listing.createdAt != null
                ? dateTimeFormat(
                    'yMMMd',
                    listing.createdAt,
                    locale: FFLocalizations.of(context).languageCode,
                  )
                : FFLocalizations.of(context).getText('pgno01');
            final isNew = listing.createdAt != null &&
                DateTime.now().difference(listing.createdAt!).inDays < 3;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: heroHeight,
                        child: GestureDetector(
                          onTap: () => _openFullscreenImage(listing.img),
                          child: Hero(
                            tag: 'listing-image-${listing.id}',
                            child: _heroImage(listing.img),
                          ),
                        ),
                      ),
                      if (isNew)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _newBadge(),
                        ),
                      _topActionsBar(context, listing),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionCard(
                          children: [
                            Text(
                              valueOrDefault<String>(
                                listing.title,
                                FFLocalizations.of(context).getText('c5j5d6pi'),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: _text,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  valueOrDefault<String>(
                                    listing.price?.toStringAsFixed(0),
                                    '0',
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _blue,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  FFLocalizations.of(context)
                                      .getText('gf7pmm28' /* р */),
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _sectionCard(
                          children: [
                            _sectionTitle(
                              FFLocalizations.of(context)
                                  .getText('auncdw0p' /* информации */),
                            ),
                            const Divider(height: 20, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('au4pejr1' /* категория */),
                              valueOrDefault<String>(
                                listing.categoryName,
                                FFLocalizations.of(context).getText('pgno01'),
                              ),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('z3v0tnuw' /* адрес */),
                              valueOrDefault<String>(
                                  listing.city,
                                  FFLocalizations.of(context).getText('pgno01')),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('jo0q04xo' /* контакты */),
                              valueOrDefault<String>(
                                  phone,
                                  FFLocalizations.of(context).getText('pgno01')),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('ns1xslou' /* дата публикации */),
                              publishedAt,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _sectionCard(
                          children: [
                            _sectionTitle(
                              FFLocalizations.of(context)
                                  .getText('9vvhfb6t' /* описании */),
                            ),
                            const Divider(height: 20, color: _border),
                            Text(
                              valueOrDefault<String>(
                                listing.description,
                                FFLocalizations.of(context).getText('pgempty1'),
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _text2,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _sellerCard(listing),
                        const SizedBox(height: 16),
                        if (phone.isNotEmpty) _contactButtons(phone),
                        SizedBox(
                          height: 90 + MediaQuery.of(context).padding.bottom,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  const _FullscreenImageViewer({
    required this.imageUrl,
    required this.placeholderAsset,
  });

  final String? imageUrl;
  final String placeholderAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: (imageUrl == null || imageUrl!.isEmpty)
                  ? Image.asset(placeholderAsset, fit: BoxFit.contain)
                  : CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          Image.asset(placeholderAsset, fit: BoxFit.contain),
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
