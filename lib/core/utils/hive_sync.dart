import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

/// Wrapper thread-safe pour les opérations Hive.
///
/// Hive n'est pas thread-safe par défaut. Cette classe fournit un mutex
/// par boîte pour sérialiser les accès concurrents (read/write).
class HiveSync {
  HiveSync._();
  static final Map<String, Completer<void>> _locks = {};

  /// Acquiert le lock exclusif pour une boîte.
  static Future<Completer<void>> _acquire(String boxName) async {
    final previous = _locks[boxName];
    final current = Completer<void>();
    _locks[boxName] = current;
    if (previous != null) await previous.future;
    return current;
  }

  /// Libère le lock.
  static void _release(String boxName, Completer<void> current) {
    if (identical(_locks[boxName], current)) _locks.remove(boxName);
    current.complete();
  }

  /// Exécute une opération de lecture thread-safe.
  static Future<T> read<T>(String boxName, T Function(Box) operation) async {
    final lock = await _acquire(boxName);
    try {
      final box = Hive.box<dynamic>(boxName);
      return operation(box);
    } finally {
      _release(boxName, lock);
    }
  }

  /// Exécute une opération d'écriture thread-safe.
  static Future<T> write<T>(String boxName, T Function(Box) operation) async {
    final lock = await _acquire(boxName);
    try {
      final box = Hive.box<dynamic>(boxName);
      return operation(box);
    } finally {
      _release(boxName, lock);
    }
  }

  /// Exécute une opération d'écriture async thread-safe.
  static Future<T> writeAsync<T>(
    String boxName,
    Future<T> Function(Box) operation,
  ) async {
    final lock = await _acquire(boxName);
    try {
      final box = Hive.box<dynamic>(boxName);
      return await operation(box);
    } finally {
      _release(boxName, lock);
    }
  }

  /// Exécute une opération thread-safe sur une boîte typée (lecture).
  static Future<T> readBox<V, T>(
    String boxName,
    T Function(Box<V>) operation,
  ) async {
    final lock = await _acquire(boxName);
    try {
      final box = Hive.box<V>(boxName);
      return operation(box);
    } finally {
      _release(boxName, lock);
    }
  }

  /// Exécute une opération d'écriture async thread-safe sur une boîte typée.
  static Future<T> writeBoxAsync<V, T>(
    String boxName,
    Future<T> Function(Box<V>) operation,
  ) async {
    final lock = await _acquire(boxName);
    try {
      final box = Hive.box<V>(boxName);
      return await operation(box);
    } finally {
      _release(boxName, lock);
    }
  }
}

/// Extension pour simplifier l'usage dans les services.
extension HiveSyncBox on Box {
  Future<T> syncRead<T>(T Function(Box) operation) =>
      HiveSync.read(name, operation);
  Future<T> syncWrite<T>(T Function(Box) operation) =>
      HiveSync.write(name, operation);
  Future<T> syncWriteAsync<T>(Future<T> Function(Box) operation) =>
      HiveSync.writeAsync(name, operation);
}
