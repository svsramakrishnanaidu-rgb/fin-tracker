import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The FinTrack monogram: an ascending ledger mark inside a soft gradient tile.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 38, this.showGlow = false});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.primary.withValues(alpha: 0.95),
            colors.primary.withValues(alpha: 0.55),
            colors.secondary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: showGlow
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
                  blurRadius: size * 0.8,
                  spreadRadius: size * 0.05,
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _BrandMarkPainter(
          ink: colors.onPrimary,
          accent: colors.secondary,
        ),
        size: Size.square(size),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.ink, required this.accent});

  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Three ascending bars = a rising balance, the core FinTrack idea.
    final Paint bar = Paint()
      ..color = ink.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final double barWidth = w * 0.13;
    final double gap = w * 0.09;
    final double startX = w * 0.28;
    final double bottom = h * 0.7;
    final List<double> heights = <double>[h * 0.16, h * 0.27, h * 0.39];

    for (int i = 0; i < heights.length; i++) {
      final double left = startX + i * (barWidth + gap);
      final Rect rect = Rect.fromLTRB(
        left,
        bottom - heights[i],
        left + barWidth,
        bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth * 0.55)),
        bar,
      );
    }

    // A single dot above the tallest bar reads as the "next" data point.
    canvas.drawCircle(
      Offset(startX + 2 * (barWidth + gap) + barWidth / 2, bottom - h * 0.47),
      w * 0.045,
      Paint()..color = ink.withValues(alpha: 0.55),
    );

    // Baseline.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          w * 0.26,
          bottom + h * 0.045,
          w * 0.74,
          bottom + h * 0.09,
        ),
        Radius.circular(h * 0.03),
      ),
      Paint()..color = ink.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.accent != accent;
}

/// Wordmark used in the dashboard header.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppBrandMark(size: compact ? 32 : 38, showGlow: true),
        SizedBox(width: compact ? 10 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 17 : 19,
                  letterSpacing: -0.3,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Fin',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  TextSpan(
                    text: 'Track',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              Text(
                'TRACK SMARTER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 2.2,
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
