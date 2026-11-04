import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'animated_amount.dart';

/// The hero card at the top of the dashboard: total spend, month spend and
/// transaction count, all driven by stored data.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalMinor,
    required this.monthMinor,
    required this.transactionCount,
  });

  final int totalMinor;
  final int monthMinor;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: colors.hero,
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.primary.withValues(
              alpha: colors.isLight ? 0.12 : 0.1,
            ),
            blurRadius: 34,
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: colors.secondary.withValues(
              alpha: colors.isLight ? 0.08 : 0.07,
            ),
            blurRadius: 40,
            offset: const Offset(-10, 20),
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroPatternPainter(
                  line: colors.textPrimary.withValues(
                    alpha: colors.isLight ? 0.05 : 0.06,
                  ),
                  glow: colors.primary.withValues(
                    alpha: colors.isLight ? 0.16 : 0.13,
                  ),
                  orbit: colors.secondary.withValues(
                    alpha: colors.isLight ? 0.12 : 0.14,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TOTAL EXPENSES',
                          style: text.labelSmall?.copyWith(
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.textPrimary.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formatMonthYear(DateTime.now()),
                              style: text.labelSmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedAmount(
                      totalMinor,
                      style: text.displayLarge?.copyWith(
                        fontSize: 38,
                        letterSpacing: -1.6,
                        height: 1.02,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _StatPill(
                        icon: Icons.trending_down_rounded,
                        label: 'This month',
                        value: formatCurrency(monthMinor),
                        tone: colors.primary,
                      ),
                      _StatPill(
                        icon: Icons.receipt_long_rounded,
                        label: transactionCount == 1
                            ? '1 entry'
                            : '$transactionCount entries',
                        value: formatCurrency(
                          totalMinor ~/
                              (transactionCount == 0 ? 1 : transactionCount),
                        ),
                        tone: colors.secondary,
                        valuePrefix: 'avg ',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.valuePrefix = '',
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final String valuePrefix;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Light themes need a light tile; a dark tint would sink the labels
        // into the gradient and break contrast.
        color: colors.isLight
            ? colors.surface.withValues(alpha: 0.72)
            : colors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: tone),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  color: colors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$valuePrefix$value',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decorative geometry: concentric orbits and a soft bloom, low contrast so it
/// never competes with the figures.
class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter({
    required this.line,
    required this.glow,
    required this.orbit,
  });

  final Color line;
  final Color glow;
  final Color orbit;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset focus = Offset(size.width * 0.82, size.height * 0.22);
    canvas.drawCircle(
      focus,
      size.width * 0.42,
      Paint()
        ..shader =
            RadialGradient(colors: <Color>[glow, glow.withValues(alpha: 0)])
                .createShader(
                  Rect.fromCircle(center: focus, radius: size.width * 0.42),
                ),
    );

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(focus, size.width * (0.16 * i), ring);
    }

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = orbit
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: focus, radius: size.width * 0.3),
      -0.9,
      1.5,
      false,
      arc,
    );

    // Diagonal hairlines in the lower-left corner.
    final Paint hairline = Paint()
      ..strokeWidth = 1
      ..color = line;
    for (int i = 0; i < 5; i++) {
      final double x = size.width * 0.04 + i * 13;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.5, 0),
        hairline,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.glow != glow ||
      oldDelegate.orbit != orbit;
}
