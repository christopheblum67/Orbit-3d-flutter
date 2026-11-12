import 'dart:convert';

import 'package:orbit_3d_flutter/models/subscription.dart';

/// Only portable source settings are synced; activation and test results stay local.
class SubscriptionCloudRecord {
  const SubscriptionCloudRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.m3uUrl,
    required this.createdAt,
  });

  final String id;
  final String name;
  final SubscriptionType type;
  final String? baseUrl;
  final String? username;
  final String? password;
  final String? m3uUrl;
  final DateTime createdAt;

  factory SubscriptionCloudRecord.fromSubscription(
    Subscription subscription,
    String? password,
  ) =>
      SubscriptionCloudRecord(
        id: subscription.id,
        name: subscription.name,
        type: subscription.type,
        baseUrl: subscription.baseUrl,
        username: subscription.username,
        password:
            subscription.type == SubscriptionType.xtream ? password : null,
        m3uUrl: subscription.m3uUrl,
        createdAt: subscription.createdAt,
      );

  String encode() => jsonEncode({
        'id': id,
        'name': name,
        'type': type.name,
        'baseUrl': baseUrl,
        'username': username,
        'password': password,
        'm3uUrl': m3uUrl,
        'createdAt': createdAt.toIso8601String(),
      });

  factory SubscriptionCloudRecord.decode(String id, String json) {
    final value = jsonDecode(json);
    if (value is! Map<String, dynamic> ||
        !value.keys.toSet().containsAll({
          'id',
          'name',
          'type',
          'baseUrl',
          'username',
          'password',
          'm3uUrl',
          'createdAt',
        }) ||
        id.isEmpty ||
        value['id'] != id ||
        value['name'] is! String ||
        value['type'] is! String ||
        !SubscriptionType.values.any((type) => type.name == value['type']) ||
        (value['type'] == SubscriptionType.m3u.name &&
            value['password'] != null) ||
        value['createdAt'] is! String ||
        DateTime.tryParse(value['createdAt'] as String) == null ||
        ['baseUrl', 'username', 'password', 'm3uUrl'].any(
          (field) => value[field] != null && value[field] is! String,
        )) {
      throw const FormatException('Abonnement cloud invalide.');
    }
    return SubscriptionCloudRecord(
      id: id,
      name: value['name'] as String,
      type: SubscriptionType.values.byName(value['type'] as String),
      baseUrl: value['baseUrl'] as String?,
      username: value['username'] as String?,
      password: value['password'] as String?,
      m3uUrl: value['m3uUrl'] as String?,
      createdAt: DateTime.parse(value['createdAt'] as String),
    );
  }

  Subscription toSubscription(Subscription? existing) => Subscription(
        id: id,
        name: name,
        type: type,
        baseUrl: baseUrl,
        username: username,
        password: '',
        m3uUrl: m3uUrl,
        isActive: existing?.isActive ?? false,
        createdAt: createdAt,
        lastTestedAt: existing?.lastTestedAt,
        lastTestResult: existing?.lastTestResult ?? TestResultStatus.untested,
        lastTestLatencyMs: existing?.lastTestLatencyMs,
        lastTestError: existing?.lastTestError,
        validUntil: existing?.validUntil,
      );
}
