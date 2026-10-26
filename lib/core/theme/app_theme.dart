import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

abstract final class AppTheme {
  static const String _fontFamily = 'GoogleSans';

  static ThemeData get light =>
      FlexThemeData.light(
        scheme: FlexScheme.greenM3,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 8,
        fontFamily: _fontFamily,
        subThemesData: const FlexSubThemesData(
          useM2StyleDividerInM3: true,
          defaultRadius: 16,
          cardRadius: 24,
          inputDecoratorRadius: 16,
          filledButtonRadius: 16,
          outlinedButtonRadius: 16,
          textButtonRadius: 16,
          chipRadius: 999,
          dialogRadius: 24,
          bottomSheetRadius: 28,
          navigationBarHeight: 72,
          navigationBarIndicatorOpacity: 0.16,
          fabUseShape: true,
          fabRadius: 20,
          alignedDropdown: true,
        ),
        keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
      ).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F8F5),
        textTheme: _textTheme(
          FlexThemeData.light(
            scheme: FlexScheme.greenM3,
            fontFamily: _fontFamily,
          ).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusJumbo),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 72,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusLg,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusXl),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      );

  static ThemeData get dark =>
      FlexThemeData.dark(
        scheme: FlexScheme.greenM3,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 12,
        fontFamily: _fontFamily,
        subThemesData: const FlexSubThemesData(
          useM2StyleDividerInM3: true,
          defaultRadius: 16,
          cardRadius: 24,
          inputDecoratorRadius: 16,
          filledButtonRadius: 16,
          outlinedButtonRadius: 16,
          textButtonRadius: 16,
          chipRadius: 999,
          dialogRadius: 24,
          bottomSheetRadius: 28,
          navigationBarHeight: 72,
          navigationBarIndicatorOpacity: 0.18,
          fabUseShape: true,
          fabRadius: 20,
          alignedDropdown: true,
        ),
        keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
      ).copyWith(
        scaffoldBackgroundColor: const Color(0xFF07110E),
        textTheme: _textTheme(
          FlexThemeData.dark(
            scheme: FlexScheme.greenM3,
            fontFamily: _fontFamily,
          ).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusJumbo),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0C1612),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 72,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusLg,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0F1A15),
          surfaceTintColor: Colors.transparent,
          modalBackgroundColor: Color(0xFF0F1A15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      );

  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: base.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
  );
}
