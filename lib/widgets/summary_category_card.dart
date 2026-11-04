import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'motion.dart';

/// Category row on the summary screen: amount, share and an animated bar.
class SummaryCategoryCard extends StatelessWidget {
  const SummaryCategoryCard({
    super.key,
    required this.category,
    required this.amountMinor,
    required this.share,
    this.index = 0,
  });

  final ExpenseCategory category;
  final int amountMinor;

  /// Fraction of total spending, 0..1.
  final double share;
  final int index;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final CategoryStyle style = styleOf(category);
    final String percent = share >= 0.1
        ? '${(share * 100).round()}%'
        : '${(share * 100).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.divider.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: style.tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(style.icon, size: 18, color: style.tint),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$percent of spending',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatCurrency(amountMinor),
                style: text.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: ColoredBox(
                          color: colors.divider.withValues(alpha: 0.55),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: share.clamp(0, 1)),
                        duration: context.motion(
                          Duration(
                            milliseconds: 620 + (index.clamp(0, 6) * 70),
                          ),
                        ),
                        curve: Curves.easeOutCubic,
                        builder:
                            (
                              BuildContext context,
                              double value,
                              Widget? child,
                            ) {
                              return Container(
                                width: constraints.maxWidth * value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      style.tint,
                                      Color.lerp(
                                        style.tint,
                                        colors.secondary,
                                        0.45,
                                      )!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              );
                            },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
