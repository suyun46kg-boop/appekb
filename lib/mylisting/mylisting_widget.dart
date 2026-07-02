import 'dart:async';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mylisting_model.dart';
export 'mylisting_model.dart';

class MylistingWidget extends StatefulWidget {
  const MylistingWidget({
    super.key,
    required this.mylisid,
  });

  final String? mylisid;

  static String routeName = 'mylisting';
  static String routePath = '/mylisting';

  @override
  State<MylistingWidget> createState() => _MylistingWidgetState();
}

class _MylistingWidgetState extends State<MylistingWidget> {
  late MylistingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _red = Color(0xFFEF4444);
  static const _listingPlaceholder = 'assets/images/zag.jpg';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MylistingModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _reload() {
    safeSetState(() => _model.requestCompleter = null);
  }

  Future<void> _editListing(String id) async {
    await context.pushNamed(
      CreateListingPageCopyWidget.routeName,
      queryParameters: {
        'editListingId': serializeParam(id, ParamType.String),
      }.withoutNulls,
    );
    _reload();
  }

  Future<void> _deleteListing(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Удалить объявление?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Это действие нельзя отменить.',
          style: GoogleFonts.inter(color: _text3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Отмена',
              style: GoogleFonts.inter(color: _text3, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Удалить',
              style: GoogleFonts.inter(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ListingsTable().delete(
      matchingRows: (rows) => rows.eqOrNull('id', id),
    );
    _reload();
  }

  Widget _placeholderImage() {
    return ClipRect(
      child: Transform.scale(
        scale: 1.5,
        child: Image.asset(
          _listingPlaceholder,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _listingImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholderImage();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => Container(color: _border),
      errorWidget: (_, __, ___) => _placeholderImage(),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _listingCard(ListingsRow listing) {
    return InkWell(
      onTap: () => context.pushNamed(
        PagpageWidget.routeName,
        queryParameters: {
          'idproductpage': serializeParam(listing.id, ParamType.String),
        }.withoutNulls,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                height: 104,
                child: _listingImage(listing.img),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valueOrDefault<String>(listing.title, 'объявление'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${valueOrDefault<String>(listing.price?.toStringAsFixed(0), '0')} р',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _actionButton(
                            icon: Icons.edit_rounded,
                            color: _blue,
                            onTap: () => _editListing(listing.id!),
                          ),
                          const SizedBox(width: 8),
                          _actionButton(
                            icon: Icons.delete_outline_rounded,
                            color: _red,
                            onTap: () => _deleteListing(listing.id!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 14, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5FE8), Color(0xFF1341B0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.safePop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            FFLocalizations.of(context).getText(
              'wmxh68pv' /* маи обявдении */,
            ),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: FutureBuilder<List<ListingsRow>>(
                future:
                    (_model.requestCompleter ??= Completer<List<ListingsRow>>()
                          ..complete(ListingsTable().queryRows(
                            queryFn: (q) => q.eqOrNull(
                              'user_id',
                              currentUserUid,
                            ),
                          )))
                        .future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_blue),
                      ),
                    );
                  }

                  final listings = List<ListingsRow>.from(snapshot.data!)
                    ..sort((a, b) {
                      final aDate = a.createdAt ?? DateTime(0);
                      final bDate = b.createdAt ?? DateTime(0);
                      return bDate.compareTo(aDate);
                    });

                  if (listings.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'У вас пока нет объявлений',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: _text3,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: listings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _listingCard(listings[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
