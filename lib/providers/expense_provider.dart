import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/expense_storage_service.dart';

/// High level loading state of the expense list.
enum ExpenseLoadStatus { loading, ready, error }

/// Single source of truth for expenses, totals and category analytics.
///
/// Every screen reads from this provider, so a change made on the add, edit or
/// detail screen is reflected on the dashboard and summary immediately.
class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({ExpenseStorageService? storage})
    : _storage = storage ?? SharedPreferencesExpenseStorageService();

  final ExpenseStorageService _storage;

  List<Expense> _expenses = <Expense>[];
  ExpenseLoadStatus _status = ExpenseLoadStatus.loading;
  String? _errorMessage;
  bool _isBusy = false;

  ExpenseLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// True while a write is in flight; the UI disables actions with this.
  bool get isBusy => _isBusy;
  bool get isLoading => _status == ExpenseLoadStatus.loading;
  bool get hasError => _status == ExpenseLoadStatus.error;
  bool get isEmpty => _status == ExpenseLoadStatus.ready && _expenses.isEmpty;

  /// Expenses sorted newest first.
  UnmodifiableListView<Expense> get expenses =>
      UnmodifiableListView<Expense>(List<Expense>.unmodifiable(_sorted));

  List<Expense> _sorted = <Expense>[];

  int get transactionCount => _expenses.length;

  int get totalMinor {
    int total = 0;
    for (final Expense expense in _expenses) {
      total += expense.amountMinor;
    }
    return total;
  }

  /// Total for the calendar month containing [reference].
  int monthTotalMinor([DateTime? reference]) {
    final DateTime now = reference ?? DateTime.now();
    int total = 0;
    for (final Expense expense in _expenses) {
      if (expense.date.year == now.year && expense.date.month == now.month) {
        total += expense.amountMinor;
      }
    }
    return total;
  }

  int totalForScope({DateTime? since}) {
    if (since == null) return totalMinor;
    int total = 0;
    for (final Expense expense in _expenses) {
      if (!expense.date.isBefore(since)) total += expense.amountMinor;
    }
    return total;
  }

  /// Sum per category, highest first. Empty categories are omitted.
  List<MapEntry<ExpenseCategory, int>> get categoryTotals {
    final Map<ExpenseCategory, int> totals = <ExpenseCategory, int>{};
    for (final Expense expense in _expenses) {
      totals.update(
        expense.category,
        (int value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }
    final List<MapEntry<ExpenseCategory, int>> entries = totals.entries.toList()
      ..sort((
        MapEntry<ExpenseCategory, int> a,
        MapEntry<ExpenseCategory, int> b,
      ) {
        final int byAmount = b.value.compareTo(a.value);
        return byAmount != 0 ? byAmount : a.key.index.compareTo(b.key.index);
      });
    return entries;
  }

  ExpenseCategory? get topCategory {
    final List<MapEntry<ExpenseCategory, int>> totals = categoryTotals;
    return totals.isEmpty ? null : totals.first.key;
  }

  int get averageMinor =>
      _expenses.isEmpty ? 0 : (totalMinor / _expenses.length).round();

  /// Share of total spending for [category] as a 0..1 fraction.
  double shareOf(ExpenseCategory category) {
    final int total = totalMinor;
    if (total == 0) return 0;
    int sum = 0;
    for (final Expense expense in _expenses) {
      if (expense.category == category) sum += expense.amountMinor;
    }
    return sum / total;
  }

  Expense? findById(String id) {
    for (final Expense expense in _expenses) {
      if (expense.id == id) return expense;
    }
    return null;
  }

  /// Loads persisted expenses. Safe to call repeatedly (retry button).
  Future<void> load() async {
    _status = ExpenseLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Expense> loaded = await _storage.load();
      _expenses = loaded;
      _reindex();
      _status = ExpenseLoadStatus.ready;
    } catch (error) {
      _status = ExpenseLoadStatus.error;
      _errorMessage = error is StorageException
          ? error.message
          : 'Your expenses could not be loaded. Please try again.';
    }
    notifyListeners();
  }

  /// Adds an expense and persists the whole list.
  ///
  /// The in-memory list only changes after the write succeeds, so a failed save
  /// never leaves the UI showing data that was not stored.
  Future<void> addExpense(Expense expense) async {
    if (expense.amountMinor <= 0) {
      throw const StorageException('An expense must be greater than ₹0.00.');
    }
    final List<Expense> next = <Expense>[..._expenses, expense];
    await _persist(next);
  }

  Future<void> updateExpense(Expense expense) async {
    final List<Expense> next = _expenses
        .map((Expense entry) => entry.id == expense.id ? expense : entry)
        .toList(growable: false);
    await _persist(next);
  }

  Future<void> deleteExpense(String id) async {
    final List<Expense> next = _expenses
        .where((Expense entry) => entry.id != id)
        .toList(growable: false);
    if (next.length == _expenses.length) return;
    await _persist(next);
  }

  Future<void> clearAll() async {
    _isBusy = true;
    notifyListeners();
    try {
      await _storage.clear();
      _expenses = <Expense>[];
      _sorted = <Expense>[];
      _status = ExpenseLoadStatus.ready;
      _errorMessage = null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _persist(List<Expense> next) async {
    if (_isBusy) {
      throw const StorageException('Another change is still being saved.');
    }
    _isBusy = true;
    notifyListeners();
    try {
      await _storage.save(next);
      _expenses = next;
      _reindex();
      _status = ExpenseLoadStatus.ready;
      _errorMessage = null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _reindex() {
    _sorted = List<Expense>.of(_expenses)
      ..sort((Expense a, Expense b) {
        final int byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
  }
}
