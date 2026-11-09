/// Budget partagé de requêtes EPG de repli pour une session.
class EpgFallbackBudget {
  static const int maxRequests = 40;

  int _remaining = maxRequests;
  int _consumed = 0;

  int get remaining => _remaining;
  int get consumed => _consumed;

  bool tryConsume() {
    if (_remaining <= 0) return false;
    _remaining--;
    _consumed++;
    return true;
  }

  void reset() {
    _remaining = maxRequests;
    _consumed = 0;
  }
}
