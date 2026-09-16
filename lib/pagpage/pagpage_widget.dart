import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/ekb_listing_card.dart';
import '/services/ekb_image_cache.dart';
import '/services/moderation_service.dart';
import '/theme/ekb_breakpoints.dart';
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
  late final Future<List<ListingsRow>> _recommendationsFuture;

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
  bool _sellerBlocked = false;
  String? _resolvedSellerName;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PagpageModel());
    _listingFuture = _loadListing();
    _recommendationsFuture = _loadRecommendations();
    _loadFavoriteState();
  }

  Future<List<ListingsRow>> _loadRecommendations() async {
    final excludeId = widget.idproductpage;

    try {
      final recData = await SupaFlow.client
          .from('recommendations')
          .select('listing_id, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .limit(5) as List;

      if (recData.isNotEmpty) {
        final orderedIds = <String>[];
        final sortOrder = <String, int>{};

        for (final row in recData) {
          final id = row['listing_id']?.toString();
          if (id == null || id.isEmpty || id == excludeId) {
            continue;
          }
          orderedIds.add(id);
          sortOrder[id] = row['sort_order'] as int? ?? 0;
        }

        if (orderedIds.isNotEmpty) {
          final listings = await ListingsTable().queryRows(
            queryFn: (q) => q.inFilter('id', orderedIds),
          );

          listings.sort((a, b) {
            final aOrder = sortOrder[a.id] ?? 999;
            final bOrder = sortOrder[b.id] ?? 999;
            return aOrder.compareTo(bOrder);
          });

          final blocked = await ModerationService.getBlockedUserIds();
          final filtered = blocked.isEmpty
              ? listings
              : listings
                  .where((row) {
                    final userId = row.userId;
                    return userId == null ||
                        userId.isEmpty ||
                        !blocked.contains(userId);
                  })
                  .toList();

          return filtered.take(4).toList();
        }
      }
    } catch (_) {}

    try {
      return await ListingsTable().queryRows(
        queryFn: (q) =>
            q.neq('id', excludeId).order('created_at', ascending: false),
        limit: 8,
      ).then((rows) async {
        final blocked = await ModerationService.getBlockedUserIds();
        if (blocked.isEmpty) {
          return rows.take(4).toList();
        }
        return rows
            .where((row) {
              final userId = row.userId;
              return userId == null ||
                  userId.isEmpty ||
                  !blocked.contains(userId);
            })
            .take(4)
            .toList();
      });
    } catch (_) {
      return [];
    }
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
    if (userId != null && userId.isNotEmpty) {
      _sellerBlocked = await ModerationService.isUserBlocked(userId);
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

  void _shareListing(ListingsRow listing, [BuildContext? buttonContext]) {
    final title = valueOrDefault<String>(
        listing.title, FFLocalizations.of(context).getText('c5j5d6pi'));
    final price = valueOrDefault<String>(
      listing.price?.toStringAsFixed(0),
      '0',
    );

    Rect? originRect;
    final targetContext = buttonContext ?? context;
    try {
      final box = targetContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && !box.size.isEmpty) {
        originRect = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    if (originRect == null || originRect.isEmpty) {
      final media = MediaQuery.sizeOf(context);
      originRect = Rect.fromCenter(
        center: Offset(media.width / 2, media.height / 3),
        width: 48,
        height: 48,
      );
    }

    try {
      SharePlus.instance.share(
        ShareParams(
          text: '$title — $price р\n${listing.description ?? ''}'.trim(),
          sharePositionOrigin: originRect,
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  bool get _isLoggedIn => currentUserUid.isNotEmpty;

  void _requireLoginSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FFLocalizations.of(context).getVariableText(
            ruText: 'Войдите в аккаунт, чтобы заблокировать пользователя',
            kyText: 'Колдонуучуну бөгөттөө үчүн аккаунтка кириңиз',
          ),
        ),
      ),
    );
  }

  Future<void> _showModerationSheet(ListingsRow listing) async {
    final sellerId = listing.userId?.trim() ?? '';
    final isOwnListing =
        sellerId.isNotEmpty && sellerId == currentUserUid;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: _text),
                  title: Text(
                    FFLocalizations.of(context).getText('modreport'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showReportReasons(listing);
                  },
                ),
                if (!isOwnListing && sellerId.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
                    title: Text(
                      FFLocalizations.of(context).getText('modblock'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      if (!_isLoggedIn) {
                        _requireLoginSnack();
                        return;
                      }
                      _confirmBlockSeller(sellerId);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReportReasons(ListingsRow listing) async {
    const reasons = <(String, String)>[
      ('spam', 'modrsn01'),
      ('fraud', 'modrsn02'),
      ('prohibited', 'modrsn03'),
      ('offensive', 'modrsn04'),
      ('other', 'modrsn05'),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  FFLocalizations.of(context).getText('modrsnttl'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 8),
                ...reasons.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      FFLocalizations.of(context).getText(item.$2),
                      style: GoogleFonts.inter(fontSize: 14, color: _text),
                    ),
                    onTap: () => Navigator.pop(sheetContext, item.$1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    try {
      await ModerationService.reportListing(
        listingId: listing.id ?? widget.idproductpage,
        reason: selected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FFLocalizations.of(context).getText('modrepsok')),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FFLocalizations.of(context).getText('modreperr')),
        ),
      );
    }
  }

  Future<void> _confirmBlockSeller(String sellerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(FFLocalizations.of(context).getText('modblktit')),
        content: Text(FFLocalizations.of(context).getText('modblkmsg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(FFLocalizations.of(context).getText('mlcancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              FFLocalizations.of(context).getText('modblock'),
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ModerationService.blockUser(sellerId);
      if (!mounted) return;
      setState(() => _sellerBlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FFLocalizations.of(context).getText('modblksok')),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FFLocalizations.of(context).getText('modblkerr')),
        ),
      );
    }
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
      cacheManager: EkbImageCacheManager.instance,
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
                if (listing != null) ...[
                  _circleIconButton(
                    icon: Icons.flag_outlined,
                    onTap: () => _showModerationSheet(listing),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (btnCtx) => _circleIconButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () => _shareListing(listing, btnCtx),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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

  Widget _loadingSkeleton(BuildContext context, {bool isTablet = false}) {
    if (isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: EkbBreakpoints.maxDetailWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _shimmerBox(
                    width: double.infinity,
                    height: 380,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 260, height: 26),
                      const SizedBox(height: 16),
                      _shimmerBox(width: 140, height: 36),
                      const SizedBox(height: 24),
                      _shimmerBox(width: double.infinity, height: 180),
                      const SizedBox(height: 16),
                      _shimmerBox(width: double.infinity, height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
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

  Widget _recommendationsSection() {
    return FutureBuilder<List<ListingsRow>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return _sectionCard(
          children: [
            _sectionTitle(
              FFLocalizations.of(context).getText('pgrec1'),
            ),
            const Divider(height: 20, color: _border),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: EkbBreakpoints.listingGridDelegate(
                maxCrossAxisExtent: 220.0,
              ),
              itemBuilder: (context, index) =>
                  EkbListingCard.fromListingsRow(items[index], showDescription: false),
            ),
          ],
        );
      },
    );
  }

  Widget _tabletTopBar(BuildContext context, ListingsRow? listing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 20, color: _text),
                  const SizedBox(width: 8),
                  Text(
                    FFLocalizations.of(context).getText('notfound03' /* Назад */),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (listing != null) ...[
                _circleIconButton(
                  icon: Icons.flag_outlined,
                  background: Colors.white,
                  foreground: _text2,
                  onTap: () => _showModerationSheet(listing),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (btnCtx) => _circleIconButton(
                    icon: Icons.ios_share_rounded,
                    background: Colors.white,
                    foreground: _text2,
                    onTap: () => _shareListing(listing, btnCtx),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _circleIconButton(
                icon: _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                background: Colors.white,
                foreground: _isFavorite ? const Color(0xFFFF4D67) : _text2,
                onTap: _toggleFavorite,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    ListingsRow listing,
    String phone,
    String publishedAt,
    bool isNew,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: EkbBreakpoints.maxDetailWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tabletTopBar(context, listing),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 1.15,
                                child: GestureDetector(
                                  onTap: () =>
                                      _openFullscreenImage(listing.img),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sellerCard(listing),
                        const SizedBox(height: 16),
                        if (_sellerBlocked)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              FFLocalizations.of(context).getText('modblknote'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          )
                        else if (phone.isNotEmpty)
                          _contactButtons(phone),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
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
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: _text,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: _blue,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  FFLocalizations.of(context)
                                      .getText('gf7pmm28' /* р */),
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: _blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                FFLocalizations.of(context).getText('pgno01'),
                              ),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('jo0q04xo' /* контакты */),
                              _sellerBlocked
                                  ? FFLocalizations.of(context)
                                      .getText('modhidden')
                                  : valueOrDefault<String>(
                                      phone,
                                      FFLocalizations.of(context)
                                          .getText('pgno01'),
                                    ),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('ns1xslou' /* дата публикации */),
                              publishedAt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                      fontSize: 15,
                      color: _text2,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _recommendationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ListingsRow listing,
    double heroHeight,
    String phone,
    String publishedAt,
    bool isNew,
  ) {
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
                      _sellerBlocked
                          ? FFLocalizations.of(context)
                              .getText('modhidden')
                          : valueOrDefault<String>(
                              phone,
                              FFLocalizations.of(context)
                                  .getText('pgno01')),
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
                if (_sellerBlocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      FFLocalizations.of(context).getText('modblknote'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                  )
                else if (phone.isNotEmpty)
                  _contactButtons(phone),
                const SizedBox(height: 20),
                _recommendationsSection(),
                SizedBox(
                  height: 90 + MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        ],
      ),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = EkbBreakpoints.isTabletWidth(constraints.maxWidth);

            return FutureBuilder<ListingsRow?>(
              future: _listingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Stack(
                    children: [
                      _loadingSkeleton(context, isTablet: isTablet),
                      if (!isTablet)
                        _topActionsBar(context, null)
                      else
                        SafeArea(child: _tabletTopBar(context, null)),
                    ],
                  );
                }

                final listing = snapshot.data;
                if (listing == null) {
                  return Stack(
                    children: [
                      _notFoundView(context),
                      if (!isTablet)
                        _topActionsBar(context, null)
                      else
                        SafeArea(child: _tabletTopBar(context, null)),
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

                if (isTablet) {
                  return SafeArea(
                    child: _buildTabletLayout(
                      context,
                      listing,
                      phone,
                      publishedAt,
                      isNew,
                    ),
                  );
                }

                return _buildMobileLayout(
                  context,
                  listing,
                  heroHeight,
                  phone,
                  publishedAt,
                  isNew,
                );
              },
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
                      cacheManager: EkbImageCacheManager.instance,
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
