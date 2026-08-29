import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/vpn_service.dart';
import '../services/subscription_manager.dart';
import '../models/user_profile.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final aiServiceProvider = Provider<AiService>((ref) => AiService());
final vpnServiceProvider = Provider<VpnService>((ref) => VpnService());
final subscriptionManagerProvider = Provider<SubscriptionManager>((ref) => SubscriptionManager());

final currentProfileProvider = StateProvider<UserProfile?>((ref) => null);

final profilesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getProfiles();
});
