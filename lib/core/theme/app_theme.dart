import 'package:flutter/material.dart';

abstract final class AppColors {
  static const red = Color(0xFFF23846);
  static const redDark = Color(0xFFC9152A);
  static const brandYellow = Color(0xFFFDCD04);
  static const blush = Color(0xFFFFE9EC);
  static const dark = Color(0xFF171315);
  static const cream = Colors.white;
  static const navigationBlue = Color(0xFF1597E5);
  static const muted = Color(0xFF746A6D);

  // Compatibility alias for existing screens while the visual system uses red.
  static const orange = red;
}

/// Shared type roles for every Hungry Spot screen.
///
/// Using these roles keeps headings, product names, prices, forms, buttons,
/// and navigation labels aligned as the application grows.
abstract final class AppTypography {
  static const screenTitle = TextStyle(
    fontSize: 27,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
  );
  static const heroTitle = TextStyle(
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w800,
    color: AppColors.dark,
  );
  static const pageHeader = TextStyle(
    fontSize: 22,
    height: 1.18,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
  );
  static const sectionTitle = TextStyle(
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
  );
  static const itemTitle = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.dark,
  );
  static const label = TextStyle(
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );
  static const button = TextStyle(
    fontSize: 14,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
  static const caption = TextStyle(
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );
  static const navLabel = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
  static const price = TextStyle(
    fontSize: 17,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const totalPrice = TextStyle(
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: AppColors.dark,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.red,
      primary: AppColors.red,
      surface: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.red.withValues(alpha: .10),
      highlightColor: AppColors.red.withValues(alpha: .04),
      hoverColor: AppColors.red.withValues(alpha: .04),
      focusColor: AppColors.red.withValues(alpha: .08),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.pageHeader,
      ),
      fontFamily: 'Plus Jakarta Sans',
      textTheme: const TextTheme(
        displaySmall: AppTypography.heroTitle,
        headlineLarge: AppTypography.screenTitle,
        headlineMedium: AppTypography.screenTitle,
        headlineSmall: AppTypography.pageHeader,
        titleLarge: AppTypography.sectionTitle,
        titleMedium: AppTypography.itemTitle,
        titleSmall: AppTypography.label,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.navLabel,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(AppTypography.navLabel),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedLabelStyle: AppTypography.navLabel,
        unselectedLabelStyle: AppTypography.navLabel,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        labelStyle: AppTypography.label,
        hintStyle: AppTypography.body,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE9DED5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: AppTypography.button,
          overlayColor: Colors.white.withValues(alpha: .16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: AppTypography.button,
          overlayColor: AppColors.red.withValues(alpha: .10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTypography.button,
          overlayColor: AppColors.red.withValues(alpha: .09),
        ),
      ),
    );
  }
}
