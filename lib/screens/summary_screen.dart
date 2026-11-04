import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/animated_amount.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/motion.dart';
import '../widgets/summary_category_card.dart';
import 'add_expense_screen.dart';

enum _SummaryScope { thisMonth, allTime }

/// Screen 4 - analytics: totals, category split, highest category.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  _SummaryScope _scope = _SummaryScope.thisMonth;

  Future<void> _openAdd() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime now = DateTime.now();

    final List<Expense> scoped = _scope == _SummaryScope.allTime
        ? provider.expenses.toList(growable: false)
        : provider.expenses
              .where(
                (Expense e) =>
                    e.date.year == now.year && e.date.month == now.month,
              )
              .toList(growable: false);

    int total = 0;
    final Map<ExpenseCategory, int> byCategory = <ExpenseCategory, int>{};
    for (final Expense expense in scoped) {
      total += expense.amountMinor;
      byCategory.update(
        expense.category,
        (int value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }
    final List<MapEntry<ExpenseCategory, int>> entries =
        byCategory.entries.toList()..sort(
          (
            MapEntry<ExpenseCategory, int> a,
            MapEntry<ExpenseCategory, int> b,
          ) => b.value.compareTo(a.value),
        );
    final int average = scoped.isEmpty ? 0 : (total / scoped.length).round();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Summary',
                                  style: text.headlineLarge?.copyWith(
                                    fontSize: 26,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Where your money goes',
                                  style: text.bodySmall?.copyWith(
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.insights_rounded,
                                  size: 13,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Live',
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ScopeToggle(
                        scope: _scope,
                        onChanged: (_SummaryScope value) =>
                            setState(() => _scope = value),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.hasError)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Notice(
                      icon: Icons.error_outline_rounded,
                      title: 'Summary unavailable',
                      message:
                          provider.errorMessage ??
                          'Your expenses could not be loaded.',
                      actionLabel: 'Retry',
                      onAction: provider.load,
                    ),
                  ),
                )
              else if (provider.isLoading)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 24, 18, 0),
                  sliver: SliverToBoxAdapter(child: _SummarySkeleton()),
                )
              else if (scoped.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20),
                  sliver: SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 420),
                      child: EmptyState(
                        compact: true,
                        title: _scope == _SummaryScope.thisMonth
                            ? 'Nothing recorded this month'
                            : 'No spending recorded yet',
                        message: 'Add an expense and this screen fills with a live category breakdown, averages and your highest spending category.',
                        actionLabel: 'Add an expense',
                        onAction: _openAdd,
                      ),
                    ),
                  ),
                )
              else ...<Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: _TotalPanel(
                      totalMinor: total,
                      count: scoped.length,
                      averageMinor: average,
                      topCategory: entries.first.key,
                      topShare: total == 0 ? 0 : entries.first.value / total,
                      scopeLabel: _scope == _SummaryScope.thisMonth
                          ? formatMonthYear(now)
                          : 'All time',
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                      decoration: BoxDecoration(
                        color: colors.elevated,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colors.divider.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          CategoryDonutChart(
                            entries: entries,
                            totalMinor: total,
                            size: 232,
                          ),
                          const SizedBox(height: 18),
                          _Legend(entries: entries, totalMinor: total),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: <Widget>[
                        Text(
                          'By category',
                          style: text.headlineSmall?.copyWith(fontSize: 18),
                        ),
                        const Spacer(),
                        Text(
                          '${entries.length} active',
                          style: text.bodySmall?.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      final MapEntry<ExpenseCategory, int> entry =
                          entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SummaryCategoryCard(
                          category: entry.key,
                          amountMinor: entry.value,
                          share: total == 0 ? 0 : entry.value / total,
                          index: index,
                        ),
                      );
                    }, childCount: entries.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 150)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});

  final _SummaryScope scope;
  final ValueChanged<_SummaryScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    Widget option(_SummaryScope value, String label) {
      final bool selected = scope == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: context.motion(const Duration(milliseconds: 200)),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? colors.primary : colors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.divider.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: <Widget>[
          option(_SummaryScope.thisMonth, 'This month'),
          option(_SummaryScope.allTime, 'All time'),
        ],
      ),
    );
  }
}

class _TotalPanel extends StatelessWidget {
  const _TotalPanel({
    required this.totalMinor,
    required this.count,
    required this.averageMinor,
    required this.topCategory,
    required this.topShare,
    required this.scopeLabel,
  });

  final int totalMinor;
  final int count;
  final int averageMinor;
  final ExpenseCategory topCategory;
  final double topShare;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final CategoryStyle style = styleOf(topCategory);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: colors.hero,
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'TOTAL SPEND',
                style: text.labelSmall?.copyWith(
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                scopeLabel,
                style: text.labelSmall?.copyWith(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedAmount(
              totalMinor,
              style: text.displayMedium?.copyWith(
                fontSize: 36,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _Metric(
                  label: 'Entries',
                  value: '$count',
                  icon: Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: 'Average',
                  value: formatCurrency(averageMinor, decimals: false),
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: 'Top',
                  value: topCategory.label,
                  icon: style.icon,
                  tint: style.tint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.textPrimary.withValues(
                alpha: colors.isLight ? 0.5 : 0.05,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.emoji_events_rounded, size: 16, color: style.tint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Highest spending: ${topCategory.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(fontSize: 12.5),
                  ),
                ),
                Text(
                  '${(topShare * 100).round()}%',
                  style: text.labelLarge?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: style.tint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color accent = tint ?? colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(
          alpha: colors.isLight ? 0.45 : 0.045,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: accent),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 0.4,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries, required this.totalMinor});

  final List<MapEntry<ExpenseCategory, int>> entries;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    if (entries.isEmpty || totalMinor <= 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: entries
          .map((MapEntry<ExpenseCategory, int> entry) {
            final CategoryStyle style = styleOf(entry.key);
            final String percent = (entry.value / totalMinor * 100)
                .toStringAsFixed(0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: style.tint.withValues(alpha: colors.isLight ? 0.1 : 0.1),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: style.tint.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: style.tint,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.tint,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 26, color: colors.danger),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Column(
      children: <Widget>[
        for (final double height in <double>[168, 300, 62, 62])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: colors.elevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colors.divider.withValues(alpha: 0.4),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
