import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _text2 = Color(0xFF475569);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _listingPlaceholder = 'assets/images/zag.jpg';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PagpageModel());
    _listingFuture = _loadListing();
  }

  Future<ListingsRow?> _loadListing() async {
    final rows = await ListingsTable().querySingleRow(
      queryFn: (q) => q.eqOrNull('id', widget.idproductpage),
    );
    return rows.isNotEmpty ? rows.first : null;
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

  Widget _backButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
        child: InkWell(
          onTap: () => context.pop(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: _text3),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _blue,
                  ),
                ),
              );
            }

            final listing = snapshot.data;
            final phone = listing?.phonnumber ?? '';
            final publishedAt = listing?.createdAt != null
                ? dateTimeFormat(
                    'yMMMd',
                    listing!.createdAt,
                    locale: FFLocalizations.of(context).languageCode,
                  )
                : 'Нет';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: _heroImage(listing?.img),
                      ),
                      _backButton(context),
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
                                listing?.title,
                                'объявление',
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
                                    listing?.price?.toStringAsFixed(0),
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
                                listing?.categoryName,
                                'Нет',
                              ),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('z3v0tnuw' /* адрес */),
                              valueOrDefault<String>(listing?.city, 'Нет'),
                            ),
                            const Divider(height: 1, color: _border),
                            _infoRow(
                              FFLocalizations.of(context)
                                  .getText('jo0q04xo' /* контакты */),
                              valueOrDefault<String>(phone, 'Нет'),
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
                                listing?.description,
                                'пусто',
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _text2,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (phone.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await launchUrl(
                                  Uri(scheme: 'tel', path: phone),
                                );
                              },
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
                        const SizedBox(height: 32),
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
