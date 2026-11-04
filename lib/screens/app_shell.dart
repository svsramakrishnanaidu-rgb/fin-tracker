import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'add_expense_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';

/// Hosts the three main destinations plus the global add-expense action.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _isOpeningForm = false;

  static const List<String> _labels = <String>['Home', 'Summary', 'Settings'];
  static const List<IconData> _icons = <IconData>[
    Icons.grid_view_rounded,
    Icons.donut_large_rounded,
    Icons.tune_rounded,
  ];

  Future<void> _openAddExpense() async {
    // Guard against duplicate navigation from rapid taps.
    if (_isOpeningForm) return;
    _isOpeningForm = true;
    try {
      final bool? saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const AddExpenseScreen()),
      );
      if (!mounted) return;
      if (saved == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Expense saved to this device'),
              duration: Duration(seconds: 2),
            ),
          );
      }
    } finally {
      _isOpeningForm = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeScreen(),
          SummaryScreen(),
          SettingsScreen(),
        ],
      ),
      // Settings has no list to add to, and the button would cover its rows.
      floatingActionButton: _index == 2
          ? null
          : _AddExpenseButton(onPressed: _openAddExpense),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.elevated,
          border: Border(
            top: BorderSide(color: colors.divider.withValues(alpha: 0.7)),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: colors.isLight ? 0.06 : 0.4,
              ),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List<Widget>.generate(3, (int i) {
                final bool selected = _index == i;
                return Expanded(
                  child: Semantics(
                    selected: selected,
                    button: true,
                    label: '${_labels[i]} tab',
                    child: InkWell(
                      onTap: () {
                        if (_index != i) setState(() => _index = i);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          AnimatedContainer(
                            duration: context.motion(
                              const Duration(milliseconds: 220),
                            ),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary.withValues(alpha: 0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Icon(
                              _icons[i],
                              size: 21,
                              color: selected
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: context.motion(
                              const Duration(milliseconds: 200),
                            ),
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  fontSize: 10.5,
                                  letterSpacing: 0.2,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selected
                                      ? colors.primary
                                      : colors.textSecondary,
                                ),
                            child: Text(_labels[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill shaped add button with a neon glow and press feedback.
class _AddExpenseButton extends StatefulWidget {
  const _AddExpenseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AddExpenseButton> createState() => _AddExpenseButtonState();
}

class _AddExpenseButtonState extends State<_AddExpenseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: context.motion(const Duration(milliseconds: 120)),
      curve: Curves.easeOut,
      child: Semantics(
        button: true,
        label: 'Add expense',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                colors: <Color>[
                  colors.primary,
                  Color.lerp(colors.primary, colors.secondary, 0.28)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.42),
                  blurRadius: 26,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.add_rounded, size: 22, color: colors.onPrimary),
                const SizedBox(width: 7),
                Text(
                  'Add',
                  style: text.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
