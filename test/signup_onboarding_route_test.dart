import 'package:flutter_test/flutter_test.dart';

import 'package:gym_feed/auth/supabase_auth/onboarding_route_guard.dart';

void main() {
  test('unverified signup is held on email verification', () {
    expect(
      signupOnboardingRedirect(
        loggedIn: true,
        emailVerified: false,
        matchedLocation: '/profilePicture',
        onboardingStage: 'awaiting_email',
      ),
      '/emailVerification',
    );
    expect(
      signupOnboardingRedirect(
        loggedIn: true,
        emailVerified: false,
        matchedLocation: '/emailVerification',
        onboardingStage: 'awaiting_email',
      ),
      isNull,
    );
  });

  test('verified signup can traverse the entire questionnaire in order', () {
    const routeSequence = <String>[
      '/allMostDone',
      '/profilePicture',
      '/gender2',
      '/howOldAreYou',
      '/weight',
      '/height',
      '/workOutLevel',
      '/fiveQuestions',
      '/goals',
      '/meals',
      '/foodAlergies',
      '/workoutDays',
      '/workoutWhen',
      '/workoutLenght',
      '/allDone2',
    ];

    for (final location in routeSequence) {
      expect(
        signupOnboardingRedirect(
          loggedIn: true,
          emailVerified: true,
          matchedLocation: location,
          onboardingStage: 'questions',
        ),
        isNull,
        reason: '$location must not restart signup at profile picture',
      );
    }
  });

  test('optional workout location is safe if restored to the flow', () {
    expect(
      signupOnboardingRedirect(
        loggedIn: true,
        emailVerified: true,
        matchedLocation: '/workoutWhere',
        onboardingStage: 'questions',
      ),
      isNull,
    );
  });

  test('verified questionnaire cannot escape into the main app early', () {
    expect(
      signupOnboardingRedirect(
        loggedIn: true,
        emailVerified: true,
        matchedLocation: '/feed',
        onboardingStage: 'questions',
      ),
      '/allMostDone',
    );
  });

  test('completed members are not redirected back into signup', () {
    expect(
      signupOnboardingRedirect(
        loggedIn: true,
        emailVerified: true,
        matchedLocation: '/feed',
        onboardingStage: 'answers_complete',
      ),
      isNull,
    );
  });
}
