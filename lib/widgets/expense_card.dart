import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'motion.dart';

/// One transaction row. Tapping opens the detail screen.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.index = 0,
  });

  final Expense expense;
  final VoidCallback onTap;

  /// Position in the list, used only to stagger the entrance animation.
  final int index;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final CategoryStyle style = styleOf(expense.category);
    final bool hasNote = expense.note.trim().isNotEmpty;

    final Widget card = Semantics(
      button: true,
      label:
          '${expense.category.label}, ${formatCurrency(expense.amountMinor)}, ${formatDateShort(expense.date)}${hasNote ? ', ${expense.note}' : ''}',
      child: Material(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: style.tint.withValues(alpha: 0.08),
          highlightColor: style.tint.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.divider.withValues(alpha: 0.65)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.tint.withValues(
                      alpha: colors.isLight ? 0.14 : 0.13,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: style.tint.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(style.icon, size: 20, color: style.tint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        hasNote ? expense.note.trim() : expense.category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              hasNote ? expense.category.label : 'Expense',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                fontSize: 11.5,
                                color: style.tint.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colors.textSecondary.withValues(
                                  alpha: 0.6,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Text(
                            formatTime(expense.date),
                            style: text.bodySmall?.copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '-${formatCurrency(expense.amountMinor)}',
                      style: text.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatDayHeader(expense.date, DateTime.now()),
                      maxLines: 1,
                      style: text.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return RevealOnMount(index: index, child: card);
  }
}

/// Fades and lifts a child into place on first build, staggered by [index].
class RevealOnMount extends StatelessWidget {
  const RevealOnMount({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int clamped = index.clamp(0, 6);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: context.motion(Duration(milliseconds: 240 + clamped * 55)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
