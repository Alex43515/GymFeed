import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_feed/web/desktop_app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop sidebar navigates directly through the app router',
      (tester) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'Feed',
          builder: (_, __) => const Scaffold(body: Text('Home content')),
        ),
        GoRoute(
          path: '/messages',
          name: 'Messages',
          builder: (_, __) => const Scaffold(body: Text('Messages content')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => AnimatedBuilder(
          animation: router.routeInformationProvider,
          builder: (_, __) => DesktopAppShell(
            currentPath: router.routeInformationProvider.value.uri.path,
            authenticated: true,
            loading: false,
            router: router,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home content'), findsOneWidget);
    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/messages');
    expect(find.text('Messages content'), findsOneWidget);
  });

  testWidgets('desktop shell removes inherited text underlines',
      (tester) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: 'Feed',
          builder: (_, __) => const Scaffold(body: Text('Home content')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => DesktopAppShell(
          currentPath: '/',
          authenticated: true,
          loading: false,
          router: router,
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gymFeedText = tester.element(find.text('GymFeed').first);
    expect(
      DefaultTextStyle.of(gymFeedText).style.decoration,
      TextDecoration.none,
    );
  });
}
