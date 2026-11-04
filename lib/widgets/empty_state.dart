import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// Empty state with an original line-art illustration drawn in code.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: context.motion(const Duration(milliseconds: 700)),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.94 + value * 0.06,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  height: compact ? 130 : 176,
                  width: compact ? 130 : 176,
                  child: CustomPaint(
                    painter: _EmptyIllustrationPainter(
                      line: colors.primary,
                      accent: colors.secondary,
                      surface: colors.elevated,
                      muted: colors.textSecondary,
                      isLight: colors.isLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontSize: compact ? 17 : 19,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  fontSize: 13.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...<Widget>[
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A receipt floating inside two orbits, with a soft bloom behind it.
class _EmptyIllustrationPainter extends CustomPainter {
  const _EmptyIllustrationPainter({
    required this.line,
    required this.accent,
    required this.surface,
    required this.muted,
    required this.isLight,
  });

  final Color line;
  final Color accent;
  final Color surface;
  final Color muted;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.34;

    // Bloom.
    canvas.drawCircle(
      center,
      radius * 1.5,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            line.withValues(alpha: isLight ? 0.16 : 0.14),
            line.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5)),
    );

    // Orbits.
    final Paint orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = muted.withValues(alpha: 0.28);
    canvas.drawCircle(center, radius * 1.32, orbit);

    final Paint dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.55);
    for (int i = 0; i < 12; i++) {
      final double start = i * 0.5236 + 0.32;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 1.6),
        start,
        0.16,
        false,
        dashed,
      );
    }

    // Receipt body with a torn bottom edge.
    final Rect receipt = Rect.fromCenter(
      center: center,
      width: radius * 1.28,
      height: radius * 1.7,
    );
    final RRect body = RRect.fromRectAndCorners(
      receipt,
      topLeft: Radius.circular(radius * 0.24),
      topRight: Radius.circular(radius * 0.24),
      bottomLeft: Radius.circular(radius * 0.1),
      bottomRight: Radius.circular(radius * 0.1),
    );
    canvas.drawRRect(body, Paint()..color = surface);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = line.withValues(alpha: 0.45),
    );

    // Receipt lines.
    final Paint rule = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = muted.withValues(alpha: 0.4);
    final double left = receipt.left + receipt.width * 0.18;
    final double right = receipt.right - receipt.width * 0.18;
    for (int i = 0; i < 3; i++) {
      final double y = receipt.top + receipt.height * (0.3 + i * 0.16);
      canvas.drawLine(
        Offset(left, y),
        Offset(i == 2 ? left + (right - left) * 0.45 : right, y),
        rule,
      );
    }

    // Accent amount bar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          receipt.top + receipt.height * 0.13,
          (right - left) * 0.62,
          7,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = line.withValues(alpha: 0.85),
    );

    // Coin at the lower-right, a quiet nod to currency.
    final Offset coin = Offset(
      receipt.right - radius * 0.05,
      receipt.bottom - radius * 0.12,
    );
    canvas.drawCircle(coin, radius * 0.3, Paint()..color = line);
    canvas.drawCircle(
      coin,
      radius * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = surface.withValues(alpha: 0.6),
    );
    final TextPainter glyph = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          fontSize: radius * 0.36,
          fontWeight: FontWeight.w700,
          color: isLight ? Colors.white : const Color(0xFF06120C),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, coin - Offset(glyph.width / 2, glyph.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EmptyIllustrationPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.accent != accent ||
      oldDelegate.surface != surface ||
      oldDelegate.isLight != isLight;
}
