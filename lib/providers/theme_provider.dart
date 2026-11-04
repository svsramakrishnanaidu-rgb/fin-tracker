import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Holds the selected visual theme and persists it locally.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({AppThemePreset? preset})
    : _preset = preset ?? AppThemePreset.signatureAmoled;

  /// Reads the saved theme synchronously so the first frame already uses it.
  factory ThemeProvider.fromPreferences(SharedPreferences prefs) {
    return ThemeProvider(
      preset: AppThemePreset.fromStorage(prefs.getString(storageKey)),
    );
  }

  static const String storageKey = 'fintrack.theme.v1';

  AppThemePreset _preset;

  AppThemePreset get preset => _preset;
  ThemeData get theme => AppTheme.build(_preset);

  Future<void> select(AppThemePreset preset) async {
    if (preset == _preset) return;
    _preset = preset;
    notifyListeners();
    await _persist(preset);
  }

  /// Persistence is best effort: the UI already reflects the new theme, and a
  /// failed preference write must not interrupt the session.
  Future<void> _persist(AppThemePreset preset) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, preset.name);
    } catch (error) {
      debugPrint('FinTrack: theme preference was not saved ($error)');
    }
  }
}
