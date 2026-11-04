import 'package:flutter/material.dart';

import '../models/expense_category.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'motion.dart';

/// Animated donut built from real category totals. No chart dependency: the
/// segments are drawn with arcs so it stays crisp at any size.
class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({
    super.key,
    required this.entries,
    required this.totalMinor,
    this.size = 232,
  });

  final List<MapEntry<ExpenseCategory, int>> entries;
  final int totalMinor;
  final double size;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool changed =
        oldWidget.totalMinor != widget.totalMinor ||
        oldWidget.entries.length != widget.entries.length;
    if (changed) _controller.forward(from: 0);
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

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? child) {
              return CustomPaint(
                size: Size.square(widget.size),
                painter: _DonutPainter(
                  entries: widget.entries,
                  totalMinor: widget.totalMinor,
                  progress: reduced ? 1 : _controller.value,
                  track: colors.divider.withValues(alpha: 0.45),
                  gapColor: colors.elevated,
                ),
              );
            },
          ),
          IgnorePointer(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.size * 0.58),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'TOTAL',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatCurrency(widget.totalMinor),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.entries.length == 1
                        ? '1 category'
                        : '${widget.entries.length} categories',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.entries,
    required this.totalMinor,
    required this.progress,
    required this.track,
    required this.gapColor,
  });

  final List<MapEntry<ExpenseCategory, int>> entries;
  final int totalMinor;
  final double progress;
  final Color track;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.09;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - stroke) / 2 - 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (totalMinor <= 0 || entries.isEmpty) return;

    final double gap = 0.055; // radians between segments
    double start = -1.5707963267948966; // -pi/2, start at the top

    for (final MapEntry<ExpenseCategory, int> entry in entries) {
      final double share = entry.value / totalMinor;
      final double fullSweep = share * 6.283185307179586;
      final double sweep = (fullSweep - gap) * progress;
      if (sweep > 0.004) {
        final CategoryStyle style = styleOf(entry.key);
        final Paint paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = style.tint;
        canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      }
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.totalMinor != totalMinor ||
      oldDelegate.entries.length != entries.length ||
      oldDelegate.track != track;
}
