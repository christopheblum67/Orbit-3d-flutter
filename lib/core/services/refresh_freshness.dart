const subscriptionRefreshInterval = Duration(hours: 8);

/// Mesure du démarrage : ignore le garde-fou de fraîcheur.
const _forceStartupRefresh = bool.fromEnvironment('FORCE_STARTUP_REFRESH');

bool isSubscriptionRefreshFresh(DateTime? timestamp, {DateTime? now}) {
  if (_forceStartupRefresh || timestamp == null) return false;
  final age = (now ?? DateTime.now()).difference(timestamp);
  return !age.isNegative && age < subscriptionRefreshInterval;
}
