/// Routes a verified new member may visit while completing the post-email
/// questionnaire. Keep this list aligned with the actual signup sequence.
const verifiedSignupQuestionnaireLocations = <String>{
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
  '/workoutWhere',
  '/workoutLenght',
  '/allDone2',
};

/// Returns the signup redirect for the current authentication/onboarding state.
///
/// Keeping this policy outside GoRouter makes the full verification and
/// questionnaire path regression-testable without a live auth session.
String? signupOnboardingRedirect({
  required bool loggedIn,
  required bool emailVerified,
  required String matchedLocation,
  String? onboardingStage,
}) {
  if (loggedIn && !emailVerified && matchedLocation != '/emailVerification') {
    return '/emailVerification';
  }

  if (!loggedIn || !emailVerified) return null;

  if (onboardingStage == 'awaiting_email' &&
      matchedLocation != '/emailVerification') {
    return '/emailVerification';
  }

  if (onboardingStage == 'questions' &&
      !verifiedSignupQuestionnaireLocations.contains(matchedLocation)) {
    return '/allMostDone';
  }

  return null;
}
