/// A content item is new for 72 hours after its provider's addition date.
bool isRecentlyAdded(DateTime? addedDate, {DateTime? now}) {
  if (addedDate == null) return false;
  final age = (now ?? DateTime.now()).difference(addedDate);
  return !age.isNegative && age < const Duration(days: 3);
}
