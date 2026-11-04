import 'package:fintrack/models/expense.dart';
import 'package:fintrack/models/expense_category.dart';
import 'package:fintrack/providers/expense_provider.dart';
import 'package:fintrack/providers/theme_provider.dart';
import 'package:fintrack/services/expense_storage_service.dart';
import 'package:fintrack/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseProvider', () {
    test(
      'starts empty with a ready state after loading empty storage',
      () async {
        final ExpenseProvider provider = ExpenseProvider(
          storage: MemoryExpenseStorage(),
        );
        expect(provider.status, ExpenseLoadStatus.loading);

        await provider.load();

        expect(provider.status, ExpenseLoadStatus.ready);
        expect(provider.isEmpty, isTrue);
        expect(provider.totalMinor, 0);
        expect(provider.transactionCount, 0);
        expect(provider.categoryTotals, isEmpty);
        expect(provider.topCategory, isNull);
      },
    );

    test('adds, updates and deletes expenses through storage', () async {
      final MemoryExpenseStorage storage = MemoryExpenseStorage();
      final ExpenseProvider provider = ExpenseProvider(storage: storage);
      await provider.load();

      final Expense lunch = sampleExpense(amountMinor: 25000, note: 'Lunch');
      await provider.addExpense(lunch);
      expect(provider.transactionCount, 1);
      expect(storage.snapshot.single.id, lunch.id);

      final Expense updated = lunch.copyWith(
        amountMinor: 30000,
        category: ExpenseCategory.travel,
        note: 'Train',
      );
      await provider.updateExpense(updated);
      expect(provider.totalMinor, 30000);
      expect(provider.findById(lunch.id)!.note, 'Train');
      expect(storage.snapshot.single.amountMinor, 30000);

      await provider.deleteExpense(lunch.id);
      expect(provider.transactionCount, 0);
      expect(storage.snapshot, isEmpty);
    });

    test('computes totals, category shares and the top category', () async {
      final ExpenseProvider provider = ExpenseProvider(
        storage: MemoryExpenseStorage(<Expense>[
          sampleExpense(amountMinor: 40000, category: ExpenseCategory.food),
          sampleExpense(amountMinor: 60000, category: ExpenseCategory.travel),
          sampleExpense(amountMinor: 10000, category: ExpenseCategory.food),
        ]),
      );
      await provider.load();

      expect(provider.totalMinor, 110000);
      expect(provider.transactionCount, 3);
      expect(provider.categoryTotals.first.key, ExpenseCategory.travel);
      expect(provider.categoryTotals.first.value, 60000);
      expect(provider.topCategory, ExpenseCategory.travel);
      expect(
        provider.shareOf(ExpenseCategory.food),
        closeTo(50000 / 110000, 0.0001),
      );
      expect(
        provider.shareOf(ExpenseCategory.travel),
        closeTo(60000 / 110000, 0.0001),
      );
    });

    test('month totals only include the current month', () async {
      final DateTime now = DateTime.now();
      final ExpenseProvider provider = ExpenseProvider(
        storage: MemoryExpenseStorage(<Expense>[
          sampleExpense(
            amountMinor: 10000,
            date: DateTime(now.year, now.month, 2),
          ),
          sampleExpense(
            amountMinor: 30000,
            date: DateTime(now.year, now.month, 3),
          ),
          sampleExpense(amountMinor: 50000, date: DateTime(2020, 1, 5)),
        ]),
      );
      await provider.load();

      expect(provider.totalMinor, 90000);
      expect(provider.monthTotalMinor(), 40000);
    });

    test('a failed save keeps the previous list intact', () async {
      final MemoryExpenseStorage storage = MemoryExpenseStorage();
      final ExpenseProvider provider = ExpenseProvider(storage: storage);
      await provider.load();
      await provider.addExpense(sampleExpense(amountMinor: 10000));
      expect(provider.transactionCount, 1);

      storage.failOnSave = true;
      await expectLater(
        provider.addExpense(sampleExpense(amountMinor: 20000)),
        throwsA(isA<StorageException>()),
      );

      expect(
        provider.transactionCount,
        1,
        reason: 'unsaved row must not appear',
      );
      expect(provider.totalMinor, 10000);
      expect(storage.snapshot.length, 1);
      expect(provider.isBusy, isFalse);
    });

    test('load failures surface the error state and retry recovers', () async {
      final MemoryExpenseStorage storage = MemoryExpenseStorage();
      storage.failOnLoad = true;
      final ExpenseProvider provider = ExpenseProvider(storage: storage);

      await provider.load();
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('could not be read'));

      storage.failOnLoad = false;
      await provider.load();
      expect(provider.status, ExpenseLoadStatus.ready);
      expect(provider.errorMessage, isNull);
    });

    test('sorting puts the newest transaction first', () async {
      final ExpenseProvider provider = ExpenseProvider(
        storage: MemoryExpenseStorage(<Expense>[
          sampleExpense(id: 'a', amountMinor: 100, date: DateTime(2026, 1, 1)),
          sampleExpense(id: 'b', amountMinor: 200, date: DateTime(2026, 3, 1)),
          sampleExpense(id: 'c', amountMinor: 300, date: DateTime(2026, 2, 1)),
        ]),
      );
      await provider.load();
      expect(provider.expenses.map((Expense e) => e.id).toList(), <String>[
        'b',
        'c',
        'a',
      ]);
    });
  });

  group('SharedPreferences storage', () {
    test('empty storage loads as an empty list', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferencesExpenseStorageService storage =
          SharedPreferencesExpenseStorageService();
      expect(await storage.load(), isEmpty);
    });

    test('saves and reloads expenses across provider instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ExpenseProvider first = ExpenseProvider();
      await first.load();
      await first.addExpense(
        sampleExpense(amountMinor: 123456, note: 'Persisted'),
      );

      final ExpenseProvider second = ExpenseProvider();
      await second.load();

      expect(second.transactionCount, 1);
      expect(second.totalMinor, 123456);
      expect(second.expenses.single.note, 'Persisted');
    });

    test('damaged JSON reports an error instead of wiping data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesExpenseStorageService.storageKey: '{not valid json',
      });
      final ExpenseProvider provider = ExpenseProvider();
      await provider.load();

      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('damaged'));
      expect(provider.transactionCount, 0);
    });

    test('skips a single corrupt record but keeps valid ones', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesExpenseStorageService.storageKey: '[{"id":"ok","amountMinor":500,"category":"food","date":"2026-01-01T10:00:00.000","note":"valid","createdAt":"2026-01-01T10:00:00.000"},{"id":"bad","amountMinor":-5,"date":"2026-01-01T10:00:00.000"}]',
      });
      final ExpenseProvider provider = ExpenseProvider();
      await provider.load();

      expect(provider.status, ExpenseLoadStatus.ready);
      expect(provider.transactionCount, 1);
      expect(provider.totalMinor, 500);
    });

    test('clearing removes persisted data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ExpenseProvider provider = ExpenseProvider();
      await provider.load();
      await provider.addExpense(sampleExpense());
      await provider.clearAll();

      expect(provider.transactionCount, 0);
      final ExpenseProvider reloaded = ExpenseProvider();
      await reloaded.load();
      expect(reloaded.transactionCount, 0);
    });
  });

  group('ThemeProvider', () {
    test('defaults to the signature AMOLED theme', () {
      final ThemeProvider provider = ThemeProvider();
      expect(provider.preset, AppThemePreset.signatureAmoled);
      expect(provider.theme.brightness, Brightness.dark);
    });

    test('selection persists and is restored on next launch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ThemeProvider provider = ThemeProvider();
      await provider.select(AppThemePreset.obsidianGold);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeProvider.storageKey), 'obsidianGold');
      expect(
        ThemeProvider.fromPreferences(prefs).preset,
        AppThemePreset.obsidianGold,
      );
    });

    test('every preset builds a complete theme with semantic colours', () {
      for (final AppThemePreset preset in AppThemePreset.values) {
        final theme = AppTheme.build(preset);
        expect(theme.extension<AppColors>(), isNotNull);
        expect(theme.textTheme.displayLarge?.fontFamily, 'Outfit');
        expect(theme.colorScheme.primary, paletteOf(preset).primary);
      }
    });
  });
}
