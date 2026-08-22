import 'dart:async';

import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Supabase auth — replaces Firebase user stream
import 'auth/supabase_auth/supabase_user_provider.dart';
import 'auth/supabase_auth/auth_util.dart';

// Firebase kept initialised to avoid runtime crashes in untouched widget files.
// Data access goes through Supabase; Firebase auth is unused.
import 'backend/firebase/firebase_config.dart';

// Supabase bootstrap
import 'backend/supabase/supabase.dart';
import 'backend/marketing/marketing_attribution.dart';

import 'backend/push_notifications/push_notifications_util.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'flutter_flow/revenue_cat_util.dart' as revenue_cat;
import 'ai_workout/coach_home/coach_home_widget.dart';
import 'pages/core_pages/feed/feed_model.dart';
import 'workout/training_home/training_home_widget.dart';
import 'web/desktop_app_shell.dart';

import '/backend/firebase_dynamic_links/firebase_dynamic_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  final appState = FFAppState();
  // These services are independent. Starting them together shortens the native
  // launch phase; the branded Flutter splash still keeps its full duration.
  await Future.wait([
    initFirebase(),
    SupaFlow.initialize(),
    appState.initializePersistedState(),
    revenue_cat.initialize(
      "appl_DrfgwejWYIWlDHMOtMqkpNwYYCS",
      "goog_ZkSqtekliAdQqKzfcaldAABjLaZ",
      debugLogEnabled: kDebugMode,
      loadDataAfterLaunch: true,
    ),
  ]);
  await initializePushNotifications();
  if (kIsWeb) {
    await captureMarketingAttribution(Uri.base);
  }

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class MyAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  late Stream<BaseAuthUser> userStream;

  // Revenue Cat login on auth change — Profile has .uid so this works.
  final authUserSub = authenticatedUserStream.listen((user) {
    revenue_cat.login(user?.uid);
  });

  final fcmTokenSub = fcmTokenRefreshStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;

    // Seed auth synchronously from Supabase's restored session so data can warm
    // up behind the splash instead of waiting for the first auth stream event.
    userStream = gymFeedSupabaseUserStream();
    final seededUser = currentUser;
    if (seededUser != null) {
      _appStateNotifier.update(seededUser);
      _warmUpUserData(seededUser);
    }
    _router = createRouter(_appStateNotifier);
    userStream.listen((user) {
      _appStateNotifier.update(user);
      _warmUpUserData(user);
    });

    // Long enough for the AnimatedSplash sequence (spin -> settle -> tagline)
    // to finish and hold before the first route replaces it.
    Future.delayed(
      const Duration(milliseconds: 4300),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  void _warmUpUserData(BaseAuthUser user) {
    if (!user.loggedIn) return;
    unawaited(registerCurrentDeviceForPush());
    unawaited(claimPendingMarketingAttribution());
    unawaited(FeedModel.warmUp().catchError((Object error, StackTrace stack) {
      debugPrint('Home feed warm-up failed: $error');
    }));
    unawaited(
      TrainingHomeWidget.warmUp().catchError((Object error, StackTrace stack) {
        debugPrint('Workout Home warm-up failed: $error');
      }),
    );
    unawaited(
      CoachHomeWidget.warmUp().catchError((Object error, StackTrace stack) {
        debugPrint('Coach stats warm-up failed: $error');
      }),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();
    fcmTokenSub.cancel();
    super.dispose();
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '',
      scrollBehavior: MyAppScrollBehavior(),
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
        Locale('en'),
        Locale('sr'),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        final routedApp = DynamicLinksHandler(
          router: _router,
          child: child!,
        );
        if (!kIsWeb) return routedApp;

        return AnimatedBuilder(
          animation: _router.routeInformationProvider,
          builder: (context, _) => DesktopAppShell(
            currentPath: _router.routeInformationProvider.value.uri.path,
            authenticated: _appStateNotifier.loggedIn,
            loading: _appStateNotifier.loading,
            router: _router,
            child: routedApp,
          ),
        );
      },
    );
  }
}
