import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.latoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.lato(fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 48),
        headlineLarge: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.01 * 32),
        titleLarge: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w600), // Map to headline-lg-mobile
        titleMedium: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.05 * 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.onSurface),
        titleTextStyle: TextStyle(
          fontFamily: 'Lato',
          color: AppColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest, // Equivalent to white in this theme
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
        hintStyle: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
