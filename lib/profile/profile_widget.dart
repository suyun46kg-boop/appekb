import '/auth/supabase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _ProfileWidgetState extends State<ProfileWidget>
    with TickerProviderStateMixin {
  late ProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.6, 0.6),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'dividerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 20.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 100.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 100.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 60.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 200.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 60.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 60.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'buttonOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 400.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 400.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 400.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 60.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  String _userInitials() {
    final email = currentUserEmail;
    if (email.isEmpty || email == '...') return '?';
    final name = email.split('@').first;
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.substring(0, 1).toUpperCase();
  }

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(icon, color: iconColor, size: 22.0),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    title,
                    style: theme.bodyLarge.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontStyle: theme.bodyLarge.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.bodyLarge.fontStyle,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.secondaryText,
                  size: 22.0,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1.0,
            thickness: 1.0,
            indent: 74.0,
            endIndent: 16.0,
            color: theme.alternate.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final photoUrl = currentUserPhoto;
    final hasPhoto = photoUrl.isNotEmpty;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1877F2), Color(0xFF003DA5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28.0),
                    bottomRight: Radius.circular(28.0),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 72.0),
                    child: Column(
                      children: [
                        Text(
                          FFLocalizations.of(context).getText(
                            'wg3pzmio' /* профиль */,
                          ),
                          style: theme.headlineSmall.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontStyle: theme.headlineSmall.fontStyle,
                            ),
                            color: Colors.white,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w700,
                            fontStyle: theme.headlineSmall.fontStyle,
                          ),
                        ).animateOnPageLoad(
                            animationsMap['textOnPageLoadAnimation']!),
                        const SizedBox(height: 8.0),
                        Text(
                          valueOrDefault<String>(currentUserEmail, '...'),
                          style: theme.bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                              fontStyle: theme.bodyMedium.fontStyle,
                            ),
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w400,
                            fontStyle: theme.bodyMedium.fontStyle,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0.0, -52.0),
                child: Container(
                  width: 104.0,
                  height: 104.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.secondaryBackground,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20.0,
                        color: Colors.black.withValues(alpha: 0.12),
                        offset: const Offset(0.0, 8.0),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF5BFF7B),
                      width: 3.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _avatarFallback(theme),
                            )
                          : _avatarFallback(theme),
                    ),
                  ),
                ).animateOnPageLoad(
                    animationsMap['containerOnPageLoadAnimation1']!),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0.0, -36.0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 100.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 16.0,
                                color: Colors.black.withValues(alpha: 0.06),
                                offset: const Offset(0.0, 4.0),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _menuTile(
                                context: context,
                                icon: Icons.list_alt_rounded,
                                iconColor: theme.primary,
                                iconBg: theme.accent2,
                                title: FFLocalizations.of(context).getText(
                                  'kiy9k1h8' /* маи обиявлении */,
                                ),
                                onTap: () async {
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
                              ).animateOnPageLoad(
                                  animationsMap['containerOnPageLoadAnimation2']!),
                              _menuTile(
                                context: context,
                                icon: Icons.support_agent_rounded,
                                iconColor: theme.info,
                                iconBg: theme.accent3,
                                title: FFLocalizations.of(context).getText(
                                  'wrj9lx0v' /* поддержка */,
                                ),
                                onTap: () {},
                              ).animateOnPageLoad(
                                  animationsMap['containerOnPageLoadAnimation3']!),
                              _menuTile(
                                context: context,
                                icon: Icons.privacy_tip_outlined,
                                iconColor: theme.alternate,
                                iconBg: theme.accent2,
                                title: FFLocalizations.of(context).getText(
                                  '6ay3t2sd' /* политика конфиденциальности */,
                                ),
                                showDivider: false,
                                onTap: () async {
                                  await launchURL(
                                      'https://telegra.ph/Ekaterinburg-Kyrgyzdar-06-20');
                                },
                              ).animateOnPageLoad(
                                  animationsMap['containerOnPageLoadAnimation4']!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        SizedBox(
                          width: double.infinity,
                          child: FFButtonWidget(
                            onPressed: () async {
                              GoRouter.of(context).prepareAuthEvent();
                              await authManager.signOut();
                              GoRouter.of(context).clearRedirectLocation();

                              FFAppState().hh1 = false;
                              safeSetState(() {});

                              context.goNamedAuth(
                                  DbddWidget.routeName, context.mounted);
                            },
                            text: FFLocalizations.of(context).getText(
                              'jfhc2a2b' /* Выйти */,
                            ),
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 20.0,
                            ),
                            options: FFButtonOptions(
                              height: 54.0,
                              padding: EdgeInsetsDirectional.zero,
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 8.0, 0.0),
                              color: theme.error.withValues(alpha: 0.08),
                              textStyle: theme.titleSmall.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: theme.titleSmall.fontStyle,
                                ),
                                color: theme.error,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: theme.titleSmall.fontStyle,
                              ),
                              elevation: 0.0,
                              borderSide: BorderSide(
                                color: theme.error.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ).animateOnPageLoad(
                              animationsMap['buttonOnPageLoadAnimation']!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(FlutterFlowTheme theme) {
    return Container(
      color: theme.accent2,
      alignment: Alignment.center,
      child: Text(
        _userInitials(),
        style: theme.headlineMedium.override(
          font: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontStyle: theme.headlineMedium.fontStyle,
          ),
          color: theme.primary,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w700,
          fontStyle: theme.headlineMedium.fontStyle,
        ),
      ),
    );
  }
}
