const subscriptionRefreshInterval = Duration(minutes: 30);

bool isSubscriptionRefreshFresh(DateTime? timestamp, {DateTime? now}) {
  if (timestamp == null) return false;
  final age = (now ?? DateTime.now()).difference(timestamp);
  return !age.isNegative && age < subscriptionRefreshInterval;
}
