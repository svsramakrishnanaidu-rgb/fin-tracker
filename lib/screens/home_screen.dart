import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../services/expense_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_brand_mark.dart';
import '../widgets/balance_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/motion.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

/// Screen 1 - the dashboard: header, hero total, filters and the real
/// transaction list with loading, error, empty and data states.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ExpenseCategory? _filter;

  Future<void> _openDetail(Expense expense) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
      ),
    );
  }

  Future<void> _openAdd() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddExpenseScreen()),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Expense saved to this device'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _confirmReset(ExpenseProvider provider) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset local data?'),
          content: const Text(
            'This deletes every stored expense on this device so FinTrack can '
            'start fresh. This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await provider.clearAll();
    } on StorageException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final AppColors colors = context.colors;
    final DateTime now = DateTime.now();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 660),
          child: RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.elevated,
            onRefresh: provider.load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  sliver: SliverToBoxAdapter(child: _DashboardHeader(now: now)),
                ),
                ..._buildSlivers(provider, now),
                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(ExpenseProvider provider, DateTime now) {
    const EdgeInsets inset = EdgeInsets.fromLTRB(18, 0, 18, 0);

    if (provider.hasError) {
      return <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          sliver: SliverToBoxAdapter(
            child: _ErrorPanel(
              message:
                  provider.errorMessage ?? 'Your expenses could not be loaded.',
              onRetry: provider.load,
              onReset: () => _confirmReset(provider),
            ),
          ),
        ),
      ];
    }

    if (provider.isLoading) {
      return <Widget>[
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
          sliver: SliverToBoxAdapter(child: _SkeletonTotalCard()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const _SkeletonRow(),
              const SizedBox(height: 10),
              const _SkeletonRow(),
              const SizedBox(height: 10),
              const _SkeletonRow(),
            ]),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        sliver: SliverToBoxAdapter(
          child: BalanceCard(
            totalMinor: provider.totalMinor,
            monthMinor: provider.monthTotalMinor(now),
            transactionCount: provider.transactionCount,
          ),
        ),
      ),
      if (provider.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.only(top: 14),
          sliver: SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 360),
              child: EmptyState(
                title: 'A clean slate',
                message: 'No expenses yet. Add your first one and FinTrack will keep the totals, categories and insights in sync.',
                actionLabel: 'Add your first expense',
                onAction: _openAdd,
              ),
            ),
          ),
        )
      else ...<Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
          sliver: SliverToBoxAdapter(child: _buildFilters(provider)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          sliver: SliverToBoxAdapter(child: _buildListHeading(provider)),
        ),
        SliverPadding(padding: inset, sliver: _buildList(provider, now)),
      ],
    ];
  }

  Widget _buildFilters(ExpenseProvider provider) {
    final List<ExpenseCategory> available = provider.categoryTotals
        .map((MapEntry<ExpenseCategory, int> entry) => entry.key)
        .toList(growable: false);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: <Widget>[
          _FilterChip(
            label: 'All',
            count: provider.transactionCount,
            selected: _filter == null,
            onTap: () => setState(() => _filter = null),
          ),
          for (final ExpenseCategory category in available) ...<Widget>[
            const SizedBox(width: 8),
            _FilterChip(
              label: category.label,
              count: provider.expenses
                  .where((Expense expense) => expense.category == category)
                  .length,
              tint: styleOf(category).tint,
              selected: _filter == category,
              onTap: () => setState(
                () => _filter = _filter == category ? null : category,
              ),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildListHeading(ExpenseProvider provider) {
    final AppColors colors = context.colors;
    final int visibleCount = _filter == null
        ? provider.transactionCount
        : provider.expenses
              .where((Expense expense) => expense.category == _filter)
              .length;

    return Row(
      children: <Widget>[
        Text(
          _filter == null ? 'Transactions' : _filter!.label,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontSize: 18, letterSpacing: -0.3),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$visibleCount',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ),
        const Spacer(),
        if (_filter != null)
          TextButton(
            onPressed: () => setState(() => _filter = null),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildList(ExpenseProvider provider, DateTime now) {
    final List<Expense> visible = provider.expenses
        .where(
          (Expense expense) => _filter == null || expense.category == _filter,
        )
        .toList(growable: false);

    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: <Widget>[
              Icon(
                Icons.filter_alt_off_rounded,
                size: 30,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                'Nothing in ${_filter?.label ?? 'this view'} yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.colors.textSecondary),
              ),
              TextButton(
                onPressed: () => setState(() => _filter = null),
                child: const Text('Show all transactions'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> children = <Widget>[];
    String? lastDay;
    int index = 0;
    for (final Expense expense in visible) {
      final String day = formatDayHeader(expense.date, now);
      if (day != lastDay) {
        children.add(
          _DayHeader(label: day, amountMinor: _dayTotal(visible, expense.date)),
        );
        lastDay = day;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: ExpenseCard(
            expense: expense,
            index: index,
            onTap: () => _openDetail(expense),
          ),
        ),
      );
      index++;
    }

    return SliverList(delegate: SliverChildListDelegate(children));
  }

  int _dayTotal(List<Expense> expenses, DateTime day) {
    int total = 0;
    for (final Expense expense in expenses) {
      if (expense.date.year == day.year &&
          expense.date.month == day.month &&
          expense.date.day == day.day) {
        total += expense.amountMinor;
      }
    }
    return total;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const AppWordmark(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                greetingFor(now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatDateShort(now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Local profile · your data never leaves this device',
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  colors.secondary.withValues(alpha: 0.28),
                  colors.primary.withValues(alpha: 0.22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: colors.divider),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 21,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color accent = tint ?? colors.primary;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter, $count transactions',
      child: AnimatedContainer(
        duration: context.motion(const Duration(milliseconds: 180)),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : colors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.65) : colors.divider,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? accent : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.amountMinor});

  final String label;
  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: colors.divider.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatCurrency(amountMinor, decimals: false),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.onReset,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storage_rounded, color: colors.danger, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load your expenses',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                  ),
                  child: const Text('Reset data'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonTotalCard extends StatelessWidget {
  const _SkeletonTotalCard();

  @override
  Widget build(BuildContext context) {
    return const _Pulse(height: 186, radius: 28);
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const _Pulse(height: 68, radius: 20);
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool reduced = context.isMotionReduced;
    if (reduced) _controller.stop();

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double opacity = reduced ? 0.55 : 0.35 + _controller.value * 0.3;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: colors.elevated.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: colors.divider.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
