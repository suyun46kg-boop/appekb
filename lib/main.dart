import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
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
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'components/app_update_widgets.dart';
import 'components/ekb_bottom_nav.dart';
import 'services/app_update_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await FFLocalizations.initialize();

  await SupaFlow.initialize();

  await PushNotificationService.initialize();

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
      themeMode: ThemeMode.light,
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

  static const _tabKeys = ['dbdd', 'searchpage22', 'mylisting', 'Profile'];

  @override
  void initState() {
    super.initState();
    _currentPageName = widget.initialPage ?? _currentPageName;
    _currentPage = widget.page;
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

  @override
  Widget build(BuildContext context) {
    final tabs = {
      'dbdd': DbddWidget(),
      'searchpage22': Searchpage22Widget(),
      'mylisting': MylistingWidget(mylisid: currentUserUid),
      'Profile': ProfileWidget(),
    };
    final currentIndex = _tabKeys.indexOf(_currentPageName);

    final MediaQueryData queryData = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: !widget.disableResizeToAvoidBottomInset,
      body: MediaQuery(
          data: queryData
              .removeViewInsets(removeBottom: true)
              .removeViewPadding(removeBottom: true),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentPageName),
              child: _currentPage ?? tabs[_currentPageName]!,
            ),
          )),
      extendBody: false,
      bottomNavigationBar: _buildBottomNav(context, currentIndex),
    );
  }
}
