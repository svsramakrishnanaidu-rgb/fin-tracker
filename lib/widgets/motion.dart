import 'package:flutter/widgets.dart';

/// Central helpers so every animation in FinTrack respects the system
/// "remove animations" accessibility setting.
extension MotionContext on BuildContext {
  bool get isMotionReduced =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  Duration motion(Duration duration) =>
      isMotionReduced ? Duration.zero : duration;
}
