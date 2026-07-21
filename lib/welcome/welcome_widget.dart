import '/components/ekbkg_logo.dart';
import '/dbdd/category_block_background.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_model.dart';

export 'welcome_model.dart';

class WelcomeWidget extends StatefulWidget {
  const WelcomeWidget({super.key});

  static String routeName = 'welcome';
  static String routePath = '/welcome';

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget> {
  late WelcomeModel _model;

  static const _blue = Color(0xFF1A56DB);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go('/');
        }
      });
    });
  }

  void _openHome() {
    context.go('/');
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _langButton(String code, String label) {
    final active = FFLocalizations.of(context).languageCode == code;
    return InkWell(
      onTap: () => setAppLanguage(context, code),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: active ? 0 : 0.22),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: active ? _blue : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _welcomeLogo() {
    return const EkbkgLogo(
      size: 100,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;

    return GestureDetector(
      onTap: _openHome,
      child: Scaffold(
        body: CategoryBlockBackground(
          borderRadius: BorderRadius.zero,
          showBorder: false,
          showShadow: false,
          showTopHighlight: false,
          bokehCount: 5,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 24 + bottomPad),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _langButton(
                        'ky',
                        FFLocalizations.of(context).getText('l8qpitx7' /* KG */),
                      ),
                      const SizedBox(width: 8),
                      _langButton(
                        'ru',
                        FFLocalizations.of(context).getText('qai395nv' /* RU */),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  _welcomeLogo(),
                  const SizedBox(height: 28),
                  Text(
                    FFLocalizations.of(context).getText('wlc1title'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    FFLocalizations.of(context).getText('wlc1sub'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.45,
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
