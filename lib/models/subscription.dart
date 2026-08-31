import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 1)
enum SubscriptionType {
  @HiveField(0)
  xtream,
  @HiveField(1)
  m3u,
}

@HiveType(typeId: 2)
enum TestResultStatus {
  @HiveField(0)
  success,
  @HiveField(1)
  error,
  @HiveField(2)
  untested,
}

@HiveType(typeId: 3)
class Subscription extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  SubscriptionType type;

  @HiveField(3)
  String? baseUrl;

  @HiveField(4)
  String? username;

  @HiveField(5)
  String? password;

  @HiveField(6)
  String? m3uUrl;

  @HiveField(7)
  bool isActive;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime? lastTestedAt;

  @HiveField(10)
  TestResultStatus lastTestResult;

  @HiveField(11)
  int? lastTestLatencyMs;

  @HiveField(12)
  String? lastTestError;

  Subscription({
    required this.id,
    required this.name,
    required this.type,
    this.baseUrl,
    this.username,
    this.password,
    this.m3uUrl,
    this.isActive = false,
    required this.createdAt,
    this.lastTestedAt,
    this.lastTestResult = TestResultStatus.untested,
    this.lastTestLatencyMs,
    this.lastTestError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
      'm3uUrl': m3uUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastTestedAt': lastTestedAt?.toIso8601String(),
      'lastTestResult': lastTestResult.name,
      'lastTestLatencyMs': lastTestLatencyMs,
      'lastTestError': lastTestError,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SubscriptionType.xtream,
      ),
      baseUrl: map['baseUrl'],
      username: map['username'],
      password: map['password'],
      m3uUrl: map['m3uUrl'],
      isActive: map['isActive'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastTestedAt: map['lastTestedAt'] != null
          ? DateTime.tryParse(map['lastTestedAt'])
          : null,
      lastTestResult: TestResultStatus.values.firstWhere(
        (e) => e.name == map['lastTestResult'],
        orElse: () => TestResultStatus.untested,
      ),
      lastTestLatencyMs: map['lastTestLatencyMs'],
      lastTestError: map['lastTestError'],
    );
  }

  Subscription copyWith({
    String? id,
    String? name,
    SubscriptionType? type,
    String? baseUrl,
    String? username,
    String? password,
    String? m3uUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTestedAt,
    TestResultStatus? lastTestResult,
    int? lastTestLatencyMs,
    String? lastTestError,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      lastTestResult: lastTestResult ?? this.lastTestResult,
      lastTestLatencyMs: lastTestLatencyMs ?? this.lastTestLatencyMs,
      lastTestError: lastTestError ?? this.lastTestError,
    );
  }

  Map<String, String?> toSubscriptionManagerFormat() {
    if (type == SubscriptionType.xtream) {
      return {
        'type': 'xtream',
        'baseUrl': baseUrl,
        'username': username,
        'password': password,
      };
    } else {
      return {
        'type': 'm3u',
        'url': m3uUrl,
      };
    }
  }

  static Subscription fromSubscriptionManagerFormat(
    String id,
    String name,
    Map<String, String?> data,
  ) {
    final type = data['type'];
    if (type == 'xtream') {
      return Subscription(
        id: id,
        name: name,
        type: SubscriptionType.xtream,
        baseUrl: data['baseUrl'],
        username: data['username'],
        password: data['password'],
        createdAt: DateTime.now(),
      );
    } else {
      return Subscription(
        id: id,
        name: name,
        type: SubscriptionType.m3u,
        m3uUrl: data['url'],
        createdAt: DateTime.now(),
      );
    }
  }
}

class TestResult {
  final TestResultStatus status;
  final int? latencyMs;
  final String? error;

  const TestResult({
    required this.status,
    this.latencyMs,
    this.error,
  });

  TestResult.success(int latencyMs)
      : this(status: TestResultStatus.success, latencyMs: latencyMs);

  TestResult.error(String error)
      : this(status: TestResultStatus.error, error: error);
}