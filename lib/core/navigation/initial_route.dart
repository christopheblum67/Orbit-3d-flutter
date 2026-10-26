String initialRouteFor({
  required bool onboardingDone,
  required bool legalNoticeDone,
}) {
  if (onboardingDone) return '/profiles';
  return legalNoticeDone ? '/onboarding' : '/legal?flow=first';
}
