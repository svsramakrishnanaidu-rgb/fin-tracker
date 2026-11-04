import 'package:fintrack/models/expense.dart';
import 'package:fintrack/models/expense_category.dart';
import 'package:fintrack/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense model', () {
    test('round trips through JSON without losing precision', () {
      final Expense original = Expense(
        id: 'ft-1',
        amountMinor: 123456789,
        category: ExpenseCategory.groceries,
        date: DateTime(2026, 5, 25, 8, 15),
        note: 'Weekly vegetables — long note kept in full',
        createdAt: DateTime(2026, 5, 25, 8, 16),
      );

      final Expense restored = Expense.fromJson(original.toJson());

      expect(restored, equals(original));
      expect(restored.amountMinor, 123456789);
      expect(restored.note, original.note);
    });

    test('rejects malformed payloads', () {
      expect(
        () => Expense.fromJson(<String, dynamic>{
          'id': '',
          'amountMinor': 100,
          'date': DateTime(2026).toIso8601String(),
        }),
        throwsFormatException,
      );
      expect(
        () => Expense.fromJson(<String, dynamic>{
          'id': 'x',
          'amountMinor': 0,
          'date': DateTime(2026).toIso8601String(),
        }),
        throwsFormatException,
      );
      expect(
        () => Expense.fromJson(<String, dynamic>{
          'id': 'x',
          'amountMinor': 100,
          'date': 'not-a-date',
        }),
        throwsFormatException,
      );
    });

    test('unknown stored categories fall back to Other', () {
      final Expense expense = Expense.fromJson(<String, dynamic>{
        'id': 'x',
        'amountMinor': 250,
        'category': 'crypto',
        'date': DateTime(2026, 1, 2).toIso8601String(),
        'note': 'future category',
        'createdAt': DateTime(2026, 1, 2).toIso8601String(),
      });
      expect(expense.category, ExpenseCategory.other);
    });

    test('generates unique ids', () {
      final Set<String> ids = <String>{};
      for (int i = 0; i < 200; i++) {
        ids.add(
          Expense.create(
            amountMinor: 1000,
            category: ExpenseCategory.other,
            date: DateTime(2026, 1, 1),
          ).id,
        );
      }
      expect(ids.length, 200);
    });
  });

  group('currency and date formatting', () {
    test('formats amounts with Indian digit grouping', () {
      expect(formatCurrency(0), '₹0.00');
      expect(formatCurrency(45050), '₹450.50');
      expect(formatCurrency(123456789), '₹12,34,567.89');
      expect(formatCurrency(-100), '-₹1.00');
      expect(formatCurrency(123400, decimals: false), '₹1,234');
    });

    test('formats compact amounts', () {
      expect(formatCurrencyCompact(250000), '₹2.5k');
      expect(formatCurrencyCompact(15000000), '₹1.5L');
      expect(formatCurrencyCompact(250000000), '₹25.0L');
      expect(formatCurrencyCompact(2500000000), '₹2.50Cr');
    });

    test('formats dates and greetings deterministically', () {
      final DateTime date = DateTime(2026, 5, 25, 8, 15);
      expect(formatDateShort(date), '25 May 2026');
      expect(formatDateFull(date), 'Monday, 25 May 2026');
      expect(formatTime(date), '8:15 AM');
      expect(formatTime(DateTime(2026, 5, 25, 0, 5)), '12:05 AM');
      expect(formatTime(DateTime(2026, 5, 25, 13, 5)), '1:05 PM');
      expect(formatMonthYear(date), 'May 2026');
      expect(formatDayHeader(date, DateTime(2026, 5, 25, 20)), 'Today');
      expect(formatDayHeader(date, DateTime(2026, 5, 26, 9)), 'Yesterday');
      expect(formatDayHeader(date, DateTime(2026, 5, 30)), '25 May 2026');
    });
  });

  group('amount parsing', () {
    test('accepts valid positive amounts', () {
      expect(parseAmountToMinor('450'), 45000);
      expect(parseAmountToMinor('450.5'), 45050);
      expect(parseAmountToMinor(' 1,234.56 '), 123456);
      expect(parseAmountToMinor('1.234,56'), null);
      expect(parseAmountToMinor('1234,56'), 123456);
      expect(parseAmountToMinor('₹99.99'), 9999);
    });

    test('rejects empty, zero, negative and non numeric input', () {
      expect(parseAmountToMinor(''), isNull);
      expect(parseAmountToMinor('   '), isNull);
      expect(parseAmountToMinor('0'), isNull);
      expect(parseAmountToMinor('0.00'), isNull);
      expect(parseAmountToMinor('-50'), isNull);
      expect(parseAmountToMinor('abc'), isNull);
      expect(parseAmountToMinor('12.3.4'), isNull);
      expect(parseAmountToMinor('NaN'), isNull);
      expect(parseAmountToMinor('999999999999999'), isNull);
    });
  });
}
