import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_model.dart';
export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'Profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const _bg = Color(0xFFF1F4FB);
  static const _blue = Color(0xFF1A56DB);
  static const _text = Color(0xFF0F172A);
  static const _text3 = Color(0xFF94A3B8);
  static const _border = Color(0xFFE2E8F0);
  static const _pageHPad = 20.0;

  String? _userName;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final rows = await UserTable().querySingleRow(
      queryFn: (q) => q.eqOrNull('id', currentUserUid),
    );
    if (!mounted) return;
    if (rows.isNotEmpty && (rows.first.name?.trim().isNotEmpty ?? false)) {
      safeSetState(() => _userName = rows.first.name!.trim());
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _userInitials() {
    final name = _userName ?? currentUserEmail.split('@').first;
    if (name.isEmpty || name == '...') return '?';
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.substring(0, 1).toUpperCase();
  }

  Widget _header(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final displayName = valueOrDefault<String>(_userName, '...');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(_pageHPad, topPad + 14, _pageHPad, 52),
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
      child: Column(
        children: [
          Text(
            FFLocalizations.of(context).getText('wg3pzmio' /* профиль */),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String photoUrl) {
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, __, ___) => _avatarFallback(),
              )
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(0xFFEEF3FF),
      alignment: Alignment.center,
      child: Text(
        _userInitials(),
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _blue,
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _text3,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 74,
            endIndent: 16,
            color: _border,
          ),
      ],
    );
  }

  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          GoRouter.of(context).prepareAuthEvent();
          await authManager.signOut();
          if (!context.mounted) return;
          GoRouter.of(context).clearRedirectLocation();

          FFAppState().hh1 = false;
          safeSetState(() {});

          context.goNamedAuth(DbddWidget.routeName, context.mounted);
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          FFLocalizations.of(context).getText('jfhc2a2b' /* Выйти */),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFFECACA)),
          backgroundColor: const Color(0xFFFFF1F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = currentUserPhoto;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _bg,
        body: Column(
          children: [
            _header(context),
            Transform.translate(
              offset: const Offset(0, -36),
              child: _avatar(photoUrl),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    _pageHPad,
                    0,
                    _pageHPad,
                    100,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
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
                        child: Column(
                          children: [
                            _menuTile(
                              icon: Icons.list_alt_rounded,
                              iconColor: _blue,
                              iconBg: const Color(0xFFEEF3FF),
                              title: FFLocalizations.of(context).getText(
                                'kiy9k1h8' /* маи обиявлении */,
                              ),
                              onTap: () {
                                context.pushNamed(
                                  MylistingWidget.routeName,
                                  queryParameters: {
                                    'mylisid': serializeParam(
                                      currentUserUid,
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                );
                              },
                            ),
                            _menuTile(
                              icon: Icons.support_agent_rounded,
                              iconColor: const Color(0xFF0E7490),
                              iconBg: const Color(0xFFEAFDFF),
                              title: FFLocalizations.of(context).getText(
                                'wrj9lx0v' /* поддержка */,
                              ),
                              onTap: () {},
                            ),
                            _menuTile(
                              icon: Icons.privacy_tip_outlined,
                              iconColor: const Color(0xFF6D28D9),
                              iconBg: const Color(0xFFF2ECFF),
                              title: FFLocalizations.of(context).getText(
                                '6ay3t2sd' /* политика конфиденциальности */,
                              ),
                              showDivider: false,
                              onTap: () async {
                                await launchURL(
                                  'https://telegra.ph/Ekaterinburg-Kyrgyzdar-06-20',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _logoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
