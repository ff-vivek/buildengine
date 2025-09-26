import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightModeColors {
  // Modern tech-focused palette inspired by development tools
  static const lightPrimary = Color(0xFF0070F3); // Vercel blue
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE5F2FF);
  static const lightOnPrimaryContainer = Color(0xFF001A33);
  static const lightSecondary = Color(0xFF6366F1); // Indigo
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFF10B981); // Emerald
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightError = Color(0xFFEF4444); // Modern red
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFEF2F2);
  static const lightOnErrorContainer = Color(0xFF7F1D1D);
  static const lightInversePrimary = Color(0xFF66B3FF);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF0F172A);
  static const lightAppBarBackground = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFFFF6B35); // Orange accent
  static const lightNeutral50 = Color(0xFFF8FAFC);
  static const lightNeutral100 = Color(0xFFF1F5F9);
  static const lightNeutral200 = Color(0xFFE2E8F0);
  static const lightNeutral300 = Color(0xFFCBD5E1);
  static const lightNeutral400 = Color(0xFF94A3B8);
  static const lightNeutral500 = Color(0xFF64748B);
  static const lightNeutral600 = Color(0xFF475569);
  static const lightNeutral700 = Color(0xFF334155);
  static const lightNeutral800 = Color(0xFF1E293B);
  static const lightNeutral900 = Color(0xFF0F172A);
}

class DarkModeColors {
  // Modern dark theme for development environments
  static const darkPrimary = Color(0xFF60A5FA); // Light blue
  static const darkOnPrimary = Color(0xFF001A33);
  static const darkPrimaryContainer = Color(0xFF003D7A);
  static const darkOnPrimaryContainer = Color(0xFFE5F2FF);
  static const darkSecondary = Color(0xFFA78BFA); // Purple
  static const darkOnSecondary = Color(0xFF1E1B4B);
  static const darkTertiary = Color(0xFF34D399); // Green
  static const darkOnTertiary = Color(0xFF064E3B);
  static const darkError = Color(0xFFFF6B6B);
  static const darkOnError = Color(0xFF7F1D1D);
  static const darkErrorContainer = Color(0xFFB91C1C);
  static const darkOnErrorContainer = Color(0xFFFEF2F2);
  static const darkInversePrimary = Color(0xFF0070F3);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF0F172A);
  static const darkOnSurface = Color(0xFFF8FAFC);
  static const darkAppBarBackground = Color(0xFF0F172A);
  static const darkAccent = Color(0xFFFF8A65); // Orange accent
  static const darkNeutral50 = Color(0xFF1E293B);
  static const darkNeutral100 = Color(0xFF334155);
  static const darkNeutral200 = Color(0xFF475569);
  static const darkNeutral300 = Color(0xFF64748B);
  static const darkNeutral400 = Color(0xFF94A3B8);
  static const darkNeutral500 = Color(0xFFCBD5E1);
  static const darkNeutral600 = Color(0xFFE2E8F0);
  static const darkNeutral700 = Color(0xFFF1F5F9);
  static const darkNeutral800 = Color(0xFFF8FAFC);
  static const darkNeutral900 = Color(0xFFFFFFFF);
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: Colors.white,
    onSurface: Colors.black,
    background: Colors.white,
    onBackground: Colors.black,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
  ),
  dividerTheme: const DividerThemeData(
    color: LightModeColors.lightNeutral200,
    thickness: 1,
    space: 1,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: LightModeColors.lightNeutral200),
    ),
    margin: const EdgeInsets.all(0),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: Colors.black,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  ),
  iconTheme: const IconThemeData(color: Colors.black),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightModeColors.lightPrimary,
      foregroundColor: LightModeColors.lightOnPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: LightModeColors.lightNeutral300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LightModeColors.lightPrimary,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: LightModeColors.lightNeutral100,
    side: const BorderSide(color: LightModeColors.lightNeutral200),
    selectedColor: LightModeColors.lightPrimary.withValues(alpha: 0.1),
    labelStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  tooltipTheme: TooltipThemeData(
    textStyle: GoogleFonts.inter(color: Colors.white),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LightModeColors.lightNeutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LightModeColors.lightNeutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: LightModeColors.lightPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.inter(color: LightModeColors.lightNeutral500),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DarkModeColors.darkNeutral50,
  appBarTheme: const AppBarTheme(
    backgroundColor: DarkModeColors.darkSurface,
    foregroundColor: DarkModeColors.darkOnSurface,
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
  ),
  dividerTheme: const DividerThemeData(
    color: DarkModeColors.darkNeutral200,
    thickness: 1,
    space: 1,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: DarkModeColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: DarkModeColors.darkSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: DarkModeColors.darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: DarkModeColors.darkNeutral200),
    ),
    margin: const EdgeInsets.all(0),
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: DarkModeColors.darkNeutral400,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkModeColors.darkPrimary,
      foregroundColor: DarkModeColors.darkOnPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DarkModeColors.darkNeutral700,
      side: const BorderSide(color: DarkModeColors.darkNeutral300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: DarkModeColors.darkPrimary,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: DarkModeColors.darkNeutral100,
    side: const BorderSide(color: DarkModeColors.darkNeutral200),
    selectedColor: DarkModeColors.darkPrimary.withValues(alpha: 0.15),
    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DarkModeColors.darkNeutral800),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  tooltipTheme: TooltipThemeData(
    textStyle: GoogleFonts.inter(color: Colors.white),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkModeColors.darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DarkModeColors.darkNeutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DarkModeColors.darkNeutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DarkModeColors.darkPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: GoogleFonts.inter(color: DarkModeColors.darkNeutral400),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.normal,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.normal,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.normal,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w600,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
    ),
  ),
);
