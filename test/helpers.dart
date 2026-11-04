import 'package:fintrack/main.dart';
import 'package:fintrack/models/expense.dart';
import 'package:fintrack/models/expense_category.dart';
import 'package:fintrack/providers/expense_provider.dart';
import 'package:fintrack/providers/theme_provider.dart';
import 'package:fintrack/services/expense_storage_service.dart';
import 'package:flutter/material.dart';

/// In-memory store so provider and widget tests never touch real device storage.
class MemoryExpenseStorage implements ExpenseStorageService {
  MemoryExpenseStorage([List<Expense> initial = const <Expense>[]])
    : _data = List<Expense>.of(initial);

  List<Expense> _data;
  bool failOnLoad = false;
  bool failOnSave = false;
  int saveCalls = 0;

  List<Expense> get snapshot => List<Expense>.unmodifiable(_data);

  @override
  Future<List<Expense>> load() async {
    if (failOnLoad) {
      throw const StorageException('Saved expenses could not be read.');
    }
    return List<Expense>.of(_data);
  }

  @override
  Future<void> save(List<Expense> expenses) async {
    saveCalls++;
    if (failOnSave) {
      throw const StorageException('This device is out of storage space.');
    }
    _data = List<Expense>.of(expenses);
  }

  @override
  Future<void> clear() async {
    _data = <Expense>[];
  }
}

Expense sampleExpense({
  String? id,
  int amountMinor = 45050,
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
  String note = 'Lunch at the campus cafe',
}) {
  final DateTime when = date ?? DateTime(2026, 11, 3, 13, 20);
  return Expense(
    id: id ?? 'ft-test-$amountMinor-${category.name}',
    amountMinor: amountMinor,
    category: category,
    date: when,
    note: note,
    createdAt: when,
  );
}

Widget buildTestApp(ExpenseProvider expenses, {ThemeProvider? theme}) {
  return FinTrackApp(
    themeProvider: theme ?? ThemeProvider(),
    expenseProvider: expenses,
  );
}
