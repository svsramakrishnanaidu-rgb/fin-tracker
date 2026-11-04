import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'motion.dart';

/// Currency value that eases from its previous value to the new one.
///
/// Used for the dashboard total so edits visibly animate instead of jumping.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount(
    this.minorUnits, {
    super.key,
    this.style,
    this.withSymbol = true,
    this.decimals = true,
  });

  final int minorUnits;
  final TextStyle? style;
  final bool withSymbol;
  final bool decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: minorUnits.toDouble()),
      duration: context.motion(const Duration(milliseconds: 620)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Text(
          formatCurrency(
            value.round(),
            withSymbol: withSymbol,
            decimals: decimals,
          ),
          style: style ?? Theme.of(context).textTheme.displayMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
