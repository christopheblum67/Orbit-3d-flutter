import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/services/epg_fallback_budget.dart';

export 'package:orbit_3d_flutter/services/epg_fallback_budget.dart';

// Non autoDispose : naviguer entre les écrans ne doit pas renouveler le quota.
final epgFallbackBudgetProvider =
    Provider<EpgFallbackBudget>((ref) => EpgFallbackBudget());
