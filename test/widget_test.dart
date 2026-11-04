import 'package:fintrack/models/expense.dart';
import 'package:fintrack/models/expense_category.dart';
import 'package:fintrack/providers/expense_provider.dart';
import 'package:fintrack/providers/theme_provider.dart';
import 'package:fintrack/screens/expense_detail_screen.dart';
import 'package:fintrack/screens/summary_screen.dart';
import 'package:fintrack/theme/app_theme.dart';
import 'package:fintrack/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<ExpenseProvider> readyProvider([
  List<Expense> expenses = const <Expense>[],
]) async {
  final ExpenseProvider provider = ExpenseProvider(
    storage: MemoryExpenseStorage(expenses),
  );
  await provider.load();
  return provider;
}

/// A realistic phone surface (412 x 915 logical pixels) instead of the tiny
/// 800x600 test default, so we exercise phone-like layout.
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> scrollWithin(WidgetTester tester, Finder screen, double dy) async {
  await tester.drag(
    find.descendant(of: screen, matching: find.byType(Scrollable)).first,
    Offset(0, -dy),
  );
  await tester.pumpAndSettle();
}

Future<void> openAddForm(WidgetTester tester) async {
  await tester.tap(find.text('Add'));
  await tester.pumpAndSettle();
  expect(find.text('New expense'), findsOneWidget);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('dashboard shows the empty state with working navigation', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final ExpenseProvider provider = await readyProvider();
    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('A clean slate'), findsOneWidget);
    expect(find.text('₹0.00'), findsWidgets);

    await tester.tap(find.text('Add your first expense'));
    await tester.pumpAndSettle();
    expect(find.text('New expense'), findsOneWidget);
  });

  testWidgets('form rejects empty amount and missing category', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final ExpenseProvider provider = await readyProvider();
    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    await openAddForm(tester);

    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(provider.transactionCount, 0);

    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid amount greater than ₹0.00'),
      findsOneWidget,
    );
    expect(provider.transactionCount, 0);
  });

  testWidgets('saving a valid expense updates the list and the total', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final ExpenseProvider provider = await readyProvider();
    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    await openAddForm(tester);

    await tester.enterText(find.byType(TextField).first, '450.50');
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Dinner with the team');

    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(provider.transactionCount, 1);
    expect(provider.totalMinor, 45050);
    expect(provider.expenses.single.note, 'Dinner with the team');
    expect(find.text('New expense'), findsNothing);
    expect(find.text('-₹450.50'), findsWidgets);
    expect(find.text('Dinner with the team'), findsOneWidget);
  });

  testWidgets('rapid double taps on save create exactly one expense', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final ExpenseProvider provider = await readyProvider();
    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    await openAddForm(tester);

    await tester.enterText(find.byType(TextField).first, '99');
    await tester.tap(find.text('Food'));
    await tester.pump();

    final Finder saveButton = find.text('Save expense');
    await tester.tap(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(provider.transactionCount, 1);
    expect(provider.totalMinor, 9900);
  });

  testWidgets('detail screen shows the complete note and transaction id', (
    WidgetTester tester,
  ) async {
    final String longNote =
        'Quarterly team dinner with the design and engineering groups, including '
        'travel reimbursements for two colleagues who joined from the Bengaluru '
        'office and stayed back for the planning session.';
    final Expense expense = sampleExpense(amountMinor: 132500, note: longNote);
    final ExpenseProvider provider = await readyProvider(<Expense>[expense]);

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text(longNote));
    await tester.pumpAndSettle();

    expect(find.text('Expense details'), findsOneWidget);
    expect(find.text(expense.shortId), findsOneWidget);
    expect(find.text('Food'), findsWidgets);

    await scrollWithin(tester, find.byType(ExpenseDetailScreen), 260);
    expect(find.text('Transaction ID'), findsOneWidget);
    final SelectableText noteWidget = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    expect(noteWidget.data, longNote);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting from the detail screen requires confirmation', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final Expense expense = sampleExpense(amountMinor: 50000);
    final ExpenseProvider provider = await readyProvider(<Expense>[expense]);

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text(expense.note));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this expense?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(provider.transactionCount, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(provider.transactionCount, 0);
    expect(find.text('A clean slate'), findsOneWidget);
  });

  testWidgets('storage failures keep the form open and warn the user', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final MemoryExpenseStorage storage = MemoryExpenseStorage()
      ..failOnSave = true;
    final ExpenseProvider provider = ExpenseProvider(storage: storage);
    await provider.load();

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    await openAddForm(tester);

    await tester.enterText(find.byType(TextField).first, '250');
    await tester.tap(find.text('Bills'));
    await tester.pump();
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(find.text('This device is out of storage space.'), findsOneWidget);
    expect(find.text('New expense'), findsOneWidget, reason: 'form stays open');
    expect(provider.transactionCount, 0);
  });

  testWidgets('error state offers retry and recovers', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final MemoryExpenseStorage storage = MemoryExpenseStorage()
      ..failOnLoad = true;
    final ExpenseProvider provider = ExpenseProvider(storage: storage);
    await provider.load();

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    expect(find.text('Could not load your expenses'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    storage.failOnLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your expenses'), findsNothing);
    expect(find.text('A clean slate'), findsOneWidget);
  });

  testWidgets('summary reflects stored data for the current month', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final DateTime now = DateTime.now();
    final ExpenseProvider provider = await readyProvider(<Expense>[
      sampleExpense(
        id: 'a',
        amountMinor: 40000,
        category: ExpenseCategory.food,
        date: DateTime(now.year, now.month, 2),
      ),
      sampleExpense(
        id: 'b',
        amountMinor: 60000,
        category: ExpenseCategory.travel,
        date: DateTime(now.year, now.month, 3),
      ),
    ]);

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.donut_large_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Highest spending: Travel'), findsOneWidget);
    expect(find.text(formatCurrency(100000)), findsWidgets);

    await scrollWithin(tester, find.byType(SummaryScreen), 320);
    expect(find.text('60% of spending'), findsOneWidget);
    expect(find.text('40% of spending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme switching updates the app and persists the choice', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final ExpenseProvider provider = await readyProvider();
    final ThemeProvider themeProvider = ThemeProvider();
    await tester.pumpWidget(buildTestApp(provider, theme: themeProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Premium Light'));
    await tester.pumpAndSettle();

    expect(themeProvider.preset, AppThemePreset.premiumLight);
    final BuildContext context = tester.element(find.text('Premium Light'));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      Theme.of(context).extension<AppColors>()!.background,
      const Color(0xFFF6F8FB),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeProvider.storageKey), 'premiumLight');
  });

  testWidgets('dashboard and summary survive a landscape phone layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ExpenseProvider provider = await readyProvider(<Expense>[
      sampleExpense(amountMinor: 999999),
      sampleExpense(
        id: 'x',
        amountMinor: 250000,
        category: ExpenseCategory.health,
      ),
    ]);

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.donut_large_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('category filter narrows the transaction list', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    final DateTime now = DateTime.now();
    final ExpenseProvider provider = await readyProvider(<Expense>[
      sampleExpense(
        id: 'a',
        amountMinor: 10000,
        category: ExpenseCategory.food,
        note: 'Coffee beans',
        date: DateTime(now.year, now.month, now.day, 9),
      ),
      sampleExpense(
        id: 'b',
        amountMinor: 20000,
        category: ExpenseCategory.travel,
        note: 'Metro card',
        date: DateTime(now.year, now.month, now.day, 10),
      ),
    ]);

    await tester.pumpWidget(buildTestApp(provider));
    await tester.pumpAndSettle();
    expect(find.text('Coffee beans'), findsOneWidget);
    expect(find.text('Metro card'), findsOneWidget);

    await tester.tap(find.text('Travel').first);
    await tester.pumpAndSettle();

    expect(find.text('Metro card'), findsOneWidget);
    expect(find.text('Coffee beans'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
