import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_manager.dart';

final subscriptionManagerProvider = Provider<SubscriptionManager>((ref) => SubscriptionManager());
