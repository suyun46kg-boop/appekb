import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'index.dart';
import 'components/app_update_widgets.dart';
import 'components/ekb_bottom_nav.dart';
import 'components/ekb_navigation_rail.dart';
import 'services/app_update_service.dart';
import 'services/push_notification_service.dart';
import 'theme/ekb_breakpoints.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();
  }

  await _safeInit('localizations', FFLocalizations.initialize);
  await _safeInit('supabase', SupaFlow.initialize);
  await _safeInit('push', PushNotificationService.initialize);
  await _safeInit('theme', FlutterFlowTheme.initialize);

  final appState = FFAppState();
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

Future<void> _safeInit(String name, Future<void> Function() init) async {
  try {
    await init();
  } catch (e, stack) {
    debugPrint('$name init failed: $e\n$stack');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale = FFLocalizations.getStoredLocale();

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
    currentUser = EkbkyrgyzdarSupabaseUser(SupaFlow.client.auth.currentUser);
    _appStateNotifier.update(currentUser!);
    _appStateNotifier.stopShowingSplashImage();
    _router = createRouter(_appStateNotifier);
    userStream = ekbkyrgyzdarSupabaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final result = await AppUpdateService.checkUpdate();

    if (!mounted) {
      return;
    }

    if (result != null && result.forceUpdate) {
      _appStateNotifier.setForceUpdate(result);
      return;
    }

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

  void setThemeMode(ThemeMode mode) {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EKBKG',
      localizationsDelegates: const [
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
        fontFamily: 'Inter',
      ),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

class NavBarPage extends StatefulWidget {
  const NavBarPage({
    super.key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  });

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  _NavBarPageState createState() => _NavBarPageState();
}

/// This is the private State class that goes with NavBarPage.
class _NavBarPageState extends State<NavBarPage> {
  String _currentPageName = 'dbdd';
  Widget? _currentPage;
  final Map<int, Widget> _tabCache = {};

  static const _tabKeys = ['dbdd', 'searchpage22', 'mylisting', 'Profile'];

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
  }

  Widget _createTab(int index) {
    switch (index) {
      case 0:
        return const DbddWidget();
      case 1:
        return const Searchpage22Widget();
      case 2:
        return MylistingWidget(mylisid: currentUserUid);
      case 3:
        return const ProfileWidget();
      default:
        return const DbddWidget();
    }
  }

  Widget _tabBody(int currentIndex) {
    return _tabCache.putIfAbsent(currentIndex, () => _createTab(currentIndex));
  }

  void _switchTab(int index) {
    HapticFeedback.selectionClick();
    safeSetState(() {
      _currentPage = null;
      _currentPageName = _tabKeys[index];
    });
  }

  void _openCreateListingFlow(BuildContext context) {
    if (currentUserUid.isNotEmpty) {
      context.pushNamed(CreateListingPageCopyWidget.routeName);
    } else {
      context.pushNamed(RegistrasiaWidget.routeName);
    }
  }

  void _openMyListings(BuildContext context) {
    if (currentUserUid.isEmpty) {
      context.pushNamed(RegistrasiaWidget.routeName);
      return;
    }
    _switchTab(2);
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return EkbBottomNavBar(
      currentIndex: currentIndex,
      homeLabel: FFLocalizations.of(context).getText('528yx56i' /* Гланая */),
      searchLabel: FFLocalizations.of(context).getText('6pwnu7xf' /* Найти */),
      createLabel: FFLocalizations.of(context).getText('c5j5d6pi' /* обявление */),
      listingsLabel: FFLocalizations.of(context).getText('wmxh68pv' /* мои объявления */),
      profileLabel: FFLocalizations.of(context).getText('wg3pzmio' /* профиль */),
      onHomeTap: () => _switchTab(0),
      onSearchTap: () => _switchTab(1),
      onCreateTap: () => _openCreateListingFlow(context),
      onListingsTap: () => _openMyListings(context),
      onProfileTap: () => _switchTab(3),
    );
  }

  Widget _buildNavigationRail(BuildContext context, int currentIndex) {
    return EkbNavigationRail(
      currentIndex: currentIndex,
      homeLabel: FFLocalizations.of(context).getText('528yx56i' /* Гланая */),
      searchLabel: FFLocalizations.of(context).getText('6pwnu7xf' /* Найти */),
      createLabel: FFLocalizations.of(context).getText('c5j5d6pi' /* обявление */),
      listingsLabel: FFLocalizations.of(context).getText('wmxh68pv' /* мои объявления */),
      profileLabel: FFLocalizations.of(context).getText('wg3pzmio' /* профиль */),
      onHomeTap: () => _switchTab(0),
      onSearchTap: () => _switchTab(1),
      onCreateTap: () => _openCreateListingFlow(context),
      onListingsTap: () => _openMyListings(context),
      onProfileTap: () => _switchTab(3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabKeys.indexOf(_currentPageName);

    final MediaQueryData queryData = MediaQuery.of(context);
    final bodyChild = _currentPage ??
        _tabBody(currentIndex.clamp(0, _tabKeys.length - 1));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = EkbBreakpoints.isTabletWidth(constraints.maxWidth);

        if (isTablet) {
          return Scaffold(
            resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
            body: Row(
              children: [
                _buildNavigationRail(context, currentIndex),
                Expanded(child: bodyChild),
              ],
            ),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
          body: MediaQuery(
              data: queryData
                  .removeViewInsets(removeBottom: true)
                  .removeViewPadding(removeBottom: true),
              child: bodyChild),
          extendBody: false,
          bottomNavigationBar: _buildBottomNav(context, currentIndex),
        );
      },
    );
  }
}
