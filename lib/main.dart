import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'components/app_update_widgets.dart';
import 'services/app_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await SupaFlow.initialize();

  await FlutterFlowTheme.initialize();

  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = ekbkyrgyzdarSupabaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final minSplash = Future.delayed(const Duration(milliseconds: 1000));
    final updateCheck = AppUpdateService.checkUpdate();

    await minSplash;
    final result = await updateCheck;

    if (!mounted) {
      return;
    }

    if (result != null && result.forceUpdate) {
      _appStateNotifier.setForceUpdate(result);
      return;
    }

    _appStateNotifier.stopShowingSplashImage();

    if (result != null && result.softUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = appNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          AppUpdateDialog.showSoft(context, result);
        }
      });
    }
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ekbkyrgyzdar',
      localizationsDelegates: [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationDelegate(),
        FallbackCupertinoLocalizationDelegate(),
      ],
      locale: _locale,
      supportedLocales: const [
        Locale('ru'),
        Locale('ky'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

class NavBarPage extends StatefulWidget {
  NavBarPage({
    Key? key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  }) : super(key: key);

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'dbdd';
  late Widget? _currentPage;

  static const _navBlue = Color(0xFF1A56DB);
  static const _navHeaderStart = Color(0xFF1E5FE8);
  static const _navHeaderEnd = Color(0xFF1341B0);
  static const _navInactive = Colors.white;
  static const _addAccentStart = Color(0xFFFF9500);
  static const _addAccentEnd = Color(0xFFFF5F00);

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  void _switchTab(int index, List<String> tabKeys) {
    safeSetState(() {
      _currentPage = null;
      _currentPageName = tabKeys[index];
    });
  }

  void _openCreateListingFlow(BuildContext context) {
    if (currentUserUid.isNotEmpty) {
      context.pushNamed(CreateListingPageCopyWidget.routeName);
    } else {
      context.pushNamed(RegistrasiaWidget.routeName);
    }
  }

  Widget _navItem({
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final fg = active ? _navBlue : _navInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(active),
                  size: 22,
                  color: fg,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, softWrap: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addNavItem({
    required bool active,
    required String label,
    required VoidCallback onTap,
  }) {
    const size = 26.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_addAccentStart, _addAccentEnd],
              ),
              border: Border.fromBorderSide(
                BorderSide(color: Colors.white, width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x66FF5F00),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    final tabKeys = ['dbdd', 'searchpage22', 'politpage', 'Profile'];
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPad),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navHeaderStart, _navHeaderEnd],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: _navItem(
              active: currentIndex == 0,
              icon: Icons.home_outlined,
              label: FFLocalizations.of(context).getText('528yx56i' /* Гланая */),
              onTap: () => _switchTab(0, tabKeys),
            ),
          ),
          Flexible(
            child: _navItem(
              active: currentIndex == 1,
              icon: Icons.search_rounded,
              label: FFLocalizations.of(context).getText('6pwnu7xf' /* Найти */),
              onTap: () => _switchTab(1, tabKeys),
            ),
          ),
          Flexible(
            child: _addNavItem(
              active: false,
              label:
                  FFLocalizations.of(context).getText('c5j5d6pi' /* обявление */),
              onTap: () => _openCreateListingFlow(context),
            ),
          ),
          Flexible(
            child: _navItem(
              active: currentIndex == 3,
              icon: Icons.person_outline,
              label: FFLocalizations.of(context).getText('wg3pzmio' /* профиль */),
              onTap: () => _switchTab(3, tabKeys),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'dbdd': DbddWidget(),
      'searchpage22': Searchpage22Widget(),
      'politpage': PolitpageWidget(),
      'Profile': ProfileWidget(),
    };
    final currentIndex = tabs.keys.toList().indexOf(_currentPageName);

    final MediaQueryData queryData = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: MediaQuery(
          data: queryData
              .removeViewInsets(removeBottom: true)
              .removeViewPadding(removeBottom: true),
          child: _currentPage ?? tabs[_currentPageName]!),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }
}
