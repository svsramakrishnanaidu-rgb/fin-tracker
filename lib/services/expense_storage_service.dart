import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

/// Thrown when expenses cannot be read from or written to device storage.
class StorageException implements Exception {
  const StorageException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageException: $message';
}

/// Persistence contract so the provider can be tested with a fake store.
abstract class ExpenseStorageService {
  Future<List<Expense>> load();
  Future<void> save(List<Expense> expenses);
  Future<void> clear();
}

/// Stores the expense list as a JSON array in [SharedPreferences].
///
/// This is deliberately a lightweight, offline store for a small personal
/// dataset. SharedPreferences is *not* encrypted storage: the data is readable
/// by the app process only, but it is not protected against a rooted device.
class SharedPreferencesExpenseStorageService implements ExpenseStorageService {
  SharedPreferencesExpenseStorageService({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const String storageKey = 'fintrack.expenses.v1';

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<List<Expense>> load() async {
    final SharedPreferences prefs;
    try {
      prefs = await _preferences();
    } catch (error) {
      throw StorageException(
        'Could not open local storage on this device.',
        cause: error,
      );
    }

    final String? raw = prefs.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return <Expense>[];

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (error) {
      // Never silently wipe data: surface it so the list screen can offer retry.
      throw StorageException(
        'Saved expenses could not be read. The data looks damaged.',
        cause: error,
      );
    }

    if (decoded is! List) {
      throw const StorageException(
        'Saved expenses could not be read. The data looks damaged.',
      );
    }

    final List<Expense> expenses = <Expense>[];
    for (final Object? entry in decoded) {
      if (entry is! Map) continue;
      try {
        expenses.add(Expense.fromJson(Map<String, dynamic>.from(entry)));
      } on FormatException {
        // Skip a single corrupt row instead of losing the whole history.
        continue;
      }
    }
    return expenses;
  }

  @override
  Future<void> save(List<Expense> expenses) async {
    final SharedPreferences prefs;
    try {
      prefs = await _preferences();
    } catch (error) {
      throw StorageException(
        'Could not open local storage on this device.',
        cause: error,
      );
    }

    final String payload = jsonEncode(
      expenses.map((Expense e) => e.toJson()).toList(),
    );
    final bool written;
    try {
      written = await prefs.setString(storageKey, payload);
    } catch (error) {
      throw StorageException(
        'The expense could not be written to this device.',
        cause: error,
      );
    }
    if (!written) {
      throw const StorageException(
        'The expense could not be written to this device.',
      );
    }

    // Verify the write so a successful save is never reported on a bad write.
    final String? stored = prefs.getString(storageKey);
    if (stored != payload) {
      throw const StorageException(
        'The expense could not be verified after saving.',
      );
    }
  }

  @override
  Future<void> clear() async {
    final SharedPreferences prefs;
    try {
      prefs = await _preferences();
    } catch (error) {
      throw StorageException(
        'Could not open local storage on this device.',
        cause: error,
      );
    }
    final bool removed = await prefs.remove(storageKey);
    if (!removed && prefs.containsKey(storageKey)) {
      throw const StorageException('Local data could not be cleared.');
    }
  }
}
