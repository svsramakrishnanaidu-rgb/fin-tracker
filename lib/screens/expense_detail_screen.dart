import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/expense_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/expense_card.dart' show RevealOnMount;
import 'add_expense_screen.dart';

/// Screen 3 - the full record for one transaction, with edit and delete.
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  Future<void> _edit(BuildContext context, Expense expense) async {
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddExpenseScreen(expense: expense),
      ),
    );
    if (updated != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Expense updated')));
  }

  Future<void> _delete(BuildContext context, Expense expense) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete this expense?'),
          content: Text(
            '${formatCurrency(expense.amountMinor)} · ${expense.category.label} on '
            '${formatDateShort(expense.date)} will be removed from this device. '
            "This can't be undone.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final ExpenseProvider provider = context.read<ExpenseProvider>();
    try {
      await provider.deleteExpense(expense.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Expense deleted')));
      Navigator.of(context).pop();
    } on StorageException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: context.colors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final ExpenseProvider provider = context.watch<ExpenseProvider>();
    final Expense? expense = provider.findById(expenseId);

    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.search_off_rounded,
                  size: 34,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'This expense is no longer available.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Back to dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final CategoryStyle style = styleOf(expense.category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense details'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit expense',
            onPressed: () => _edit(context, expense),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Delete expense',
            onPressed: () => _delete(context, expense),
            icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                    children: <Widget>[
                      RevealOnMount(
                        index: 0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: colors.hero,
                            border: Border.all(
                              color: style.tint.withValues(alpha: 0.2),
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: style.tint.withValues(alpha: 0.16),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: style.tint.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: style.tint.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Icon(
                                  style.icon,
                                  size: 28,
                                  color: style.tint,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.07,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: colors.divider.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  expense.category.label.toUpperCase(),
                                  style: text.labelSmall?.copyWith(
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w600,
                                    color: style.tint,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  formatCurrency(expense.amountMinor),
                                  style: text.displayMedium?.copyWith(
                                    fontSize: 38,
                                    letterSpacing: -1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 13,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${formatDateFull(expense.date)} · ${formatTime(expense.date)}',
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      style: text.bodySmall?.copyWith(
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'RECORD',
                        style: text.labelSmall?.copyWith(
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RevealOnMount(
                        index: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.elevated,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colors.divider.withValues(alpha: 0.65),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              _DetailRow(
                                icon: Icons.category_rounded,
                                label: 'Category',
                                value: expense.category.label,
                              ),
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.event_rounded,
                                label: 'Date',
                                value: formatDateFull(expense.date),
                              ),
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.schedule_rounded,
                                label: 'Time',
                                value: formatTime(expense.date),
                              ),
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.save_alt_rounded,
                                label: 'Recorded',
                                value:
                                    '${formatDateShort(expense.createdAt)}, ${formatTime(expense.createdAt)}',
                              ),
                              const Divider(height: 1),
                              _DetailRow(
                                icon: Icons.fingerprint_rounded,
                                label: 'Transaction ID',
                                value: expense.shortId,
                                mono: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'NOTE',
                        style: text.labelSmall?.copyWith(
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RevealOnMount(
                        index: 2,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colors.divider.withValues(alpha: 0.7),
                            ),
                          ),
                          child: expense.note.trim().isEmpty
                              ? Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.notes_rounded,
                                      size: 16,
                                      color: colors.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'No note was added for this expense.',
                                      style: text.bodySmall?.copyWith(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              : SelectableText(
                                  expense.note,
                                  style: text.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.55,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _DetailActions(
              onEdit: () => _edit(context, expense),
              onDelete: () => _delete(context, expense),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.divider.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.danger,
                        side: BorderSide(
                          color: colors.danger.withValues(alpha: 0.5),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.titleSmall?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: mono ? 0.8 : 0,
                fontFeatures: mono
                    ? const <FontFeature>[FontFeature.tabularFigures()]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
