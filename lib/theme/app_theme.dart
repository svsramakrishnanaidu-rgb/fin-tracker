import 'package:flutter/material.dart';

import '../models/expense_category.dart';

/// The four FinTrack visual themes. The selected value is persisted locally.
enum AppThemePreset {
  signatureAmoled('Signature AMOLED', 'Rich blacks with neon green light'),
  premiumLight('Premium Light', 'Daylight surfaces, deep green ink'),
  midnightFinance('Midnight Finance', 'Deep navy with aqua highlights'),
  obsidianGold('Obsidian Gold', 'Obsidian black with warm gold');

  const AppThemePreset(this.label, this.description);

  final String label;
  final String description;

  bool get isLight => this == AppThemePreset.premiumLight;

  static AppThemePreset fromStorage(String? value) {
    for (final AppThemePreset preset in AppThemePreset.values) {
      if (preset.name == value) return preset;
    }
    return AppThemePreset.signatureAmoled;
  }
}

/// Raw colour values for one theme. Widgets must never read these directly:
/// they go through [AppColors] in the widget tree.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.elevated,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.danger,
    required this.success,
    required this.heroGradient,
  });

  final Brightness brightness;
  final Color background;
  final Color elevated;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color danger;
  final Color success;
  final List<Color> heroGradient;
}

const Map<AppThemePreset, AppPalette> _palettes = <AppThemePreset, AppPalette>{
  AppThemePreset.signatureAmoled: AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF050608),
    elevated: Color(0xFF101318),
    surface: Color(0xFF171B22),
    primary: Color(0xFF00E676),
    secondary: Color(0xFF8B5CF6),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    divider: Color(0xFF252B35),
    danger: Color(0xFFFF5252),
    success: Color(0xFF00E676),
    heroGradient: <Color>[
      Color(0xFF123024),
      Color(0xFF101318),
      Color(0xFF1D1533),
    ],
  ),
  AppThemePreset.premiumLight: AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF6F8FB),
    elevated: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF137C56),
    secondary: Color(0xFF7054CD),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF667085),
    divider: Color(0xFFE3E8F0),
    danger: Color(0xFFD92D20),
    success: Color(0xFF137C56),
    heroGradient: <Color>[
      Color(0xFFE4F5EC),
      Color(0xFFF2EDFC),
      Color(0xFFFFFFFF),
    ],
  ),
  AppThemePreset.midnightFinance: AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF090D1A),
    elevated: Color(0xFF101728),
    surface: Color(0xFF141C2E),
    primary: Color(0xFF57D9C4),
    secondary: Color(0xFF8C9EFF),
    textPrimary: Color(0xFFF7F9FF),
    textSecondary: Color(0xFF9AAAC4),
    divider: Color(0xFF24304A),
    danger: Color(0xFFFF6B6B),
    success: Color(0xFF57D9C4),
    heroGradient: <Color>[
      Color(0xFF102C3C),
      Color(0xFF111A30),
      Color(0xFF1C2148),
    ],
  ),
  AppThemePreset.obsidianGold: AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF080808),
    elevated: Color(0xFF121212),
    surface: Color(0xFF181818),
    primary: Color(0xFFD9B86C),
    secondary: Color(0xFFB4A0E5),
    textPrimary: Color(0xFFF7F2E9),
    textSecondary: Color(0xFFB9B2A6),
    divider: Color(0xFF2A2A2A),
    danger: Color(0xFFFF5C5C),
    success: Color(0xFFD9B86C),
    heroGradient: <Color>[
      Color(0xFF2C2314),
      Color(0xFF161311),
      Color(0xFF241C30),
    ],
  ),
};

AppPalette paletteOf(AppThemePreset preset) => _palettes[preset]!;

/// Semantic colours exposed to widgets through [ThemeData.extensions].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.elevated,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.danger,
    required this.success,
    required this.heroGradient,
    required this.isLight,
  });

  final Color background;
  final Color elevated;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color danger;
  final Color success;
  final List<Color> heroGradient;
  final bool isLight;

  /// Text/icon colour that stays legible on top of [primary].
  Color get onPrimary =>
      primary.computeLuminance() > 0.5 ? const Color(0xFF06120C) : Colors.white;

  LinearGradient get hero => LinearGradient(
    colors: heroGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? elevated,
    Color? surface,
    Color? primary,
    Color? secondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? danger,
    Color? success,
    List<Color>? heroGradient,
    bool? isLight,
  }) {
    return AppColors(
      background: background ?? this.background,
      elevated: elevated ?? this.elevated,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      heroGradient: heroGradient ?? this.heroGradient,
      isLight: isLight ?? this.isLight,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    List<Color> lerpGradient() {
      final int length = heroGradient.length < other.heroGradient.length
          ? heroGradient.length
          : other.heroGradient.length;
      return List<Color>.generate(
        length,
        (int i) => Color.lerp(heroGradient[i], other.heroGradient[i], t)!,
      );
    }

    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      heroGradient: lerpGradient(),
      isLight: t < 0.5 ? isLight : other.isLight,
    );
  }
}

/// Convenience access for widgets: `context.colors.primary`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Icon and accent for a category. Category accents are fixed across themes so
/// analytics stay readable, and are declared here instead of in widgets.
@immutable
class CategoryStyle {
  const CategoryStyle(this.icon, this.tint);

  final IconData icon;
  final Color tint;
}

const Map<ExpenseCategory, CategoryStyle> categoryStyles =
    <ExpenseCategory, CategoryStyle>{
      ExpenseCategory.food: CategoryStyle(
        Icons.restaurant_rounded,
        Color(0xFFFF8A5B),
      ),
      ExpenseCategory.travel: CategoryStyle(
        Icons.flight_takeoff_rounded,
        Color(0xFF5B9DFF),
      ),
      ExpenseCategory.shopping: CategoryStyle(
        Icons.shopping_bag_rounded,
        Color(0xFFA78BFA),
      ),
      ExpenseCategory.bills: CategoryStyle(
        Icons.receipt_long_rounded,
        Color(0xFFF5B942),
      ),
      ExpenseCategory.education: CategoryStyle(
        Icons.school_rounded,
        Color(0xFF4FC3F7),
      ),
      ExpenseCategory.health: CategoryStyle(
        Icons.favorite_rounded,
        Color(0xFFFF6B8A),
      ),
      ExpenseCategory.entertainment: CategoryStyle(
        Icons.movie_rounded,
        Color(0xFFC77DFF),
      ),
      ExpenseCategory.groceries: CategoryStyle(
        Icons.local_grocery_store_rounded,
        Color(0xFF00E676),
      ),
      ExpenseCategory.other: CategoryStyle(
        Icons.category_rounded,
        Color(0xFF94A3B8),
      ),
    };

CategoryStyle styleOf(ExpenseCategory category) => categoryStyles[category]!;

/// Typography scale. Balance figures are 34-40sp bold, headings 26-30sp.
TextTheme _buildTextTheme(AppPalette p) {
  final Color primaryText = p.textPrimary;
  final Color secondary = p.textSecondary;
  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.4,
      height: 1.05,
      color: primaryText,
    ),
    displayMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      height: 1.1,
      color: primaryText,
    ),
    displaySmall: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      height: 1.1,
      color: primaryText,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      height: 1.15,
      color: primaryText,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      height: 1.2,
      color: primaryText,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: primaryText,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: primaryText,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: primaryText,
    ),
    bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: primaryText),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: primaryText),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: secondary),
    labelLarge: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: primaryText,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: secondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: secondary,
    ),
  );
}

/// Builds the complete [ThemeData] for a preset, seeded from its accent colour.
class AppTheme {
  const AppTheme._();

  static const double radiusSmall = 12;
  static const double radiusMedium = 18;
  static const double radiusLarge = 24;

  static ThemeData build(AppThemePreset preset) {
    final AppPalette p = paletteOf(preset);
    final bool isDark = p.brightness == Brightness.dark;

    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: p.brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.primary.computeLuminance() > 0.5
              ? const Color(0xFF06120C)
              : Colors.white,
          secondary: p.secondary,
          onSecondary: p.secondary.computeLuminance() > 0.5
              ? const Color(0xFF120A22)
              : Colors.white,
          surface: p.surface,
          onSurface: p.textPrimary,
          onSurfaceVariant: p.textSecondary,
          outline: p.divider,
          outlineVariant: p.divider,
          error: p.danger,
          onError: Colors.white,
          surfaceContainerHighest: p.elevated,
          surfaceContainerHigh: p.elevated,
          shadow: Colors.black,
        );

    final TextTheme textTheme = _buildTextTheme(p);
    final Color onAccent = scheme.onPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      fontFamily: 'Outfit',
      textTheme: textTheme,
      primaryColor: p.primary,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColors(
          background: p.background,
          elevated: p.elevated,
          surface: p.surface,
          primary: p.primary,
          secondary: p.secondary,
          textPrimary: p.textPrimary,
          textSecondary: p.textSecondary,
          divider: p.divider,
          danger: p.danger,
          success: p.success,
          heroGradient: p.heroGradient,
          isLight: !isDark,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.textPrimary,
        iconTheme: IconThemeData(color: p.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: p.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: p.divider.withValues(alpha: 0.7)),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: p.textSecondary.withValues(alpha: 0.8),
          fontSize: 15,
        ),
        labelStyle: TextStyle(color: p.textSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: p.primary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: _border(p.divider),
        enabledBorder: _border(p.divider),
        focusedBorder: _border(p.primary, width: 1.6),
        errorBorder: _border(p.danger, width: 1.3),
        focusedErrorBorder: _border(p.danger, width: 1.6),
        disabledBorder: _border(p.divider.withValues(alpha: 0.5)),
        errorStyle: TextStyle(
          color: p.danger,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: onAccent,
          disabledBackgroundColor: p.primary.withValues(alpha: 0.35),
          disabledForegroundColor: onAccent.withValues(alpha: 0.7),
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.divider),
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: onAccent,
        elevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.5,
          height: 1.45,
          color: p.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.elevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? p.surface : p.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? p.textPrimary : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        headerBackgroundColor: p.surface,
        headerForegroundColor: p.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return onAccent;
          }
          if (states.contains(WidgetState.disabled)) {
            return p.textSecondary.withValues(alpha: 0.4);
          }
          return p.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? p.primary
              : Colors.transparent;
        }),
        todayForegroundColor: WidgetStatePropertyAll<Color>(p.primary),
        todayBorder: BorderSide(color: p.primary, width: 1.2),
        yearForegroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) return onAccent;
          return p.textPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          return states.contains(WidgetState.selected)
              ? p.primary
              : Colors.transparent;
        }),
        dividerColor: p.divider,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.divider,
        circularTrackColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: p.divider),
        ),
        textStyle: TextStyle(color: p.textPrimary, fontSize: 12.5),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
