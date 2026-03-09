import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

class AppColors {
  // Light mode colors
  static const lightPrimary = Color(0xFFD0FD3E);
  static const lightOnPrimary = Color(0xFF000000);
  static const lightSecondary = Color(0xFF2C2C2E);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFFD0FD3E);
  static const lightBackground = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1C1C1E);
  static const lightPrimaryText = Color(0xFF1C1C1E);
  static const lightSecondaryText = Color(0xFF636366);
  static const lightHint = Color(0xFF8E8E93);
  static const lightError = Color(0xFFFF453A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightSuccess = Color(0xFF32D74B);
  static const lightDivider = Color(0xFFE5E5EA);

  // Dark mode colors
  static const darkPrimary = Color(0xFFB8F436);
  static const darkOnPrimary = Color(0xFF000000);
  static const darkSecondary = Color(0xFF2C2C2E);
  static const darkOnSecondary = Color(0xFFFFFFFF);
  static const darkAccent = Color(0xFFD0FD3E);
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkOnSurface = Color(0xFFFFFFFF);
  static const darkPrimaryText = Color(0xFFFFFFFF);
  static const darkSecondaryText = Color(0xFFA1A1A6);
  static const darkHint = Color(0xFF48484A);
  static const darkError = Color(0xFFFF453A);
  static const darkOnError = Color(0xFF000000);
  static const darkSuccess = Color(0xFF32D74B);
  static const darkDivider = Color(0xFF2C2C2E);
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnSecondary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    error: AppColors.lightError,
    onError: AppColors.lightOnError,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.lightPrimaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _buildTextTheme(Brightness.light),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: AppColors.lightOnPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: AppColors.lightOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.lightDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.lightDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    secondary: AppColors.darkSecondary,
    onSecondary: AppColors.darkOnSecondary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    error: AppColors.darkError,
    onError: AppColors.darkOnError,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkPrimaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _buildTextTheme(Brightness.dark),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: AppColors.darkOnPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkPrimary,
      side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
    ),
  ),
);

TextTheme _buildTextTheme(Brightness brightness) {
  final primaryFont = GoogleFonts.plusJakartaSans;
  final secondaryFont = GoogleFonts.inter;

  return TextTheme(
    headlineLarge: primaryFont(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1),
    headlineMedium: primaryFont(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
    headlineSmall: primaryFont(fontSize: 24, fontWeight: FontWeight.w600, height: 1.2),
    titleLarge: primaryFont(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: primaryFont(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
    titleSmall: primaryFont(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
    bodyLarge: secondaryFont(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: secondaryFont(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: secondaryFont(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: primaryFont(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
    labelMedium: primaryFont(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
    labelSmall: primaryFont(fontSize: 11, fontWeight: FontWeight.w700, height: 1.1),
  );
}
