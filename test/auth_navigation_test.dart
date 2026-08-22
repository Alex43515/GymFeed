import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/auth/base_auth_user_provider.dart';
import 'package:gym_feed/flutter_flow/nav/nav.dart';

class _FakeAuthUser extends BaseAuthUser {
  _FakeAuthUser(this.id, {this.verified = true});

  final String? id;
  final bool verified;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(uid: id);

  @override
  bool get emailVerified => verified;

  @override
  bool get loggedIn => id != null;

  @override
  Future? delete() => null;

  @override
  Future? sendEmailVerification() => null;

  @override
  Future? updateEmail(String email) => null;

  @override
  Future? updatePassword(String newPassword) => null;
}

void main() {
  final notifier = AppStateNotifier.instance;

  setUp(() {
    notifier.clearRedirectLocation();
    notifier.updateNotifyOnAuthChange(true);
    notifier.update(_FakeAuthUser(null));
  });

  tearDown(() {
    notifier.clearRedirectLocation();
    notifier.updateNotifyOnAuthChange(true);
    notifier.update(_FakeAuthUser(null));
  });

  test('explicit Supabase auth completion is immediately visible to router',
      () {
    notifier.updateNotifyOnAuthChange(false);

    notifier.completeAuthEvent(_FakeAuthUser('authenticated-user'));

    expect(notifier.loggedIn, isTrue);
    expect(notifier.user?.uid, 'authenticated-user');
    expect(notifier.notifyOnAuthChange, isTrue);
  });

  test('verification of the same uid notifies the router', () {
    var notifications = 0;
    void listener() => notifications += 1;
    notifier.addListener(listener);
    addTearDown(() => notifier.removeListener(listener));

    notifier.update(_FakeAuthUser('pending-user', verified: false));
    final beforeVerification = notifications;
    notifier.update(_FakeAuthUser('pending-user', verified: true));

    expect(notifier.emailVerified, isTrue);
    expect(notifications, beforeVerification + 1);
  });

  testWidgets('successful login replaces sign-in with Feed in one action',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/sign-in',
      routes: [
        GoRoute(
          name: 'sign-in',
          path: '/sign-in',
          builder: (context, _) => Scaffold(
            body: TextButton(
              key: const ValueKey('finish-login'),
              onPressed: () => context.goAfterAuth('feed'),
              child: const Text('Log in'),
            ),
          ),
        ),
        GoRoute(
          name: 'feed',
          path: '/feed',
          builder: (_, __) => const Scaffold(body: Text('GymFeed home')),
        ),
        GoRoute(
          name: 'deep',
          path: '/deep',
          builder: (_, __) => const Scaffold(body: Text('Protected target')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    notifier.updateNotifyOnAuthChange(false);
    notifier.completeAuthEvent(_FakeAuthUser('authenticated-user'));
    await tester.tap(find.byKey(const ValueKey('finish-login')));
    await tester.pumpAndSettle();

    expect(find.text('GymFeed home'), findsOneWidget);
    expect(find.byKey(const ValueKey('finish-login')), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/feed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful login resumes an interrupted protected destination',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/sign-in',
      routes: [
        GoRoute(
          name: 'sign-in',
          path: '/sign-in',
          builder: (context, _) => Scaffold(
            body: TextButton(
              key: const ValueKey('finish-login'),
              onPressed: () => context.goAfterAuth('feed'),
              child: const Text('Log in'),
            ),
          ),
        ),
        GoRoute(
          name: 'feed',
          path: '/feed',
          builder: (_, __) => const Scaffold(body: Text('GymFeed home')),
        ),
        GoRoute(
          name: 'deep',
          path: '/deep',
          builder: (_, __) => const Scaffold(body: Text('Protected target')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    notifier.setRedirectLocationIfUnset('/deep');
    notifier.updateNotifyOnAuthChange(false);
    notifier.completeAuthEvent(_FakeAuthUser('authenticated-user'));
    await tester.tap(find.byKey(const ValueKey('finish-login')));
    await tester.pumpAndSettle();

    expect(find.text('Protected target'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/deep');
    expect(notifier.hasRedirect(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
