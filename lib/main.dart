import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ThemeProvider themeProvider = ThemeProvider();
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    themeProvider = ThemeProvider.fromPreferences(prefs);
  } catch (error) {
    debugPrint('FinTrack: preferences unavailable, using defaults ($error)');
  }

  final ExpenseProvider expenseProvider = ExpenseProvider();
  // Start loading immediately so the dashboard shows its loading state, then
  // resolves into empty or data. Failures become the error state with retry.
  unawaited(expenseProvider.load());

  runApp(
    FinTrackApp(themeProvider: themeProvider, expenseProvider: expenseProvider),
  );
}

/// Root widget: provides app state and the themed MaterialApp.
class FinTrackApp extends StatelessWidget {
  const FinTrackApp({
    super.key,
    required this.themeProvider,
    required this.expenseProvider,
  });

  final ThemeProvider themeProvider;
  final ExpenseProvider expenseProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider theme, Widget? child) {
          return MaterialApp(
            title: 'FinTrack',
            debugShowCheckedModeBanner: false,
            theme: theme.theme,
            themeAnimationDuration: const Duration(milliseconds: 380),
            themeAnimationCurve: Curves.easeOutCubic,
            home: const AppShell(),
            // Keeps very large accessibility font scales from breaking layouts
            // while still honouring a generous range of scaling.
            builder: (BuildContext context, Widget? child) {
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.6,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
