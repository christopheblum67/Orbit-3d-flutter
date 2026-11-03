String initialRouteFor({
  required bool onboardingDone,
  required bool legalNoticeDone,
}) {
  if (onboardingDone) return '/startup';
  return legalNoticeDone ? '/onboarding' : '/legal?flow=first';
}
