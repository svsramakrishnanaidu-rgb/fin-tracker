import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// Wrap of category chips with animated selection feedback.
class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory> onChanged;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values
              .map((ExpenseCategory category) {
                final bool isSelected = category == selected;
                final CategoryStyle style = styleOf(category);
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: category.label,
                  child: AnimatedContainer(
                    duration: context.motion(const Duration(milliseconds: 180)),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? style.tint.withValues(
                              alpha: colors.isLight ? 0.16 : 0.15,
                            )
                          : colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? style.tint.withValues(alpha: 0.75)
                            : (errorText != null
                                  ? colors.danger.withValues(alpha: 0.6)
                                  : colors.divider),
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: isSelected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: style.tint.withValues(alpha: 0.18),
                                blurRadius: 14,
                                spreadRadius: -2,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: enabled ? () => onChanged(category) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                style.icon,
                                size: 17,
                                color: isSelected
                                    ? style.tint
                                    : colors.textSecondary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                category.label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? colors.textPrimary
                                          : colors.textSecondary,
                                    ),
                              ),
                              if (isSelected) ...<Widget>[
                                const SizedBox(width: 5),
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: style.tint,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: colors.danger,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    errorText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.danger,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
