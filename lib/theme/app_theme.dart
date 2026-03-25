import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppColors {
  // Primary: Vibrant Green
  static const primary = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);

  // Accents
  static const accentBlue = Color(0xFF3B82F6);
  static const accentLime = Color(0xFF10B981);
  static const accentTeal = Color(0xFF06B6D4);
  static const accentCoral = Color(0xFFEF4444);
  static const accentPink = Color(0xFFF43F5E);
  static const accentGold = Color(0xFFF59E0B);
  static const accentGreen = Color(0xFF22C55E);

  // Text Colors
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);

  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFECFDF5);
  static const divider = Color(0xFFE2E8F0);

  // Dark mode
  static const nightSurface = Color(0xFF0F172A);
  static const nightSurfaceAlt = Color(0xFF1E293B);
  static const nightCard = Color(0xFF334155);
  static const nightTextPrimary = Color(0xFFF1F5F9);
  static const nightTextSecondary = Color(0xFFCBD5E1);
  static const nightDivider = Color(0xFF475569);
  static const nightPrimary = Color(0xFF10B981);
}

class AppRadii {
  static const button = BorderRadius.all(Radius.circular(14));
  static const card = BorderRadius.all(Radius.circular(18));
  static const chip = BorderRadius.all(Radius.circular(12));
  static const input = BorderRadius.all(Radius.circular(12));
  static const sheet = BorderRadius.all(Radius.circular(20));
}

class AppShadows {
  static const level1 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 14,
      offset: Offset(0, 8),
    ),
  ];

  static const level2 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 16),
    ),
  ];
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardHighlight = LinearGradient(
    colors: [AppColors.accentLime, AppColors.accentLime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.nunitoTextTheme(
      const TextTheme(
        displaySmall:
            TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
        headlineSmall:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accentTeal,
      onSecondary: AppColors.textPrimary,
      tertiary: AppColors.accentLime,
      onTertiary: AppColors.textPrimary,
      error: AppColors.accentCoral,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.divider,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surfaceAlt,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceAlt,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardThemeData( 
        color: Color(0xFFFFFFFF),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFFFFFFF),
        border: OutlineInputBorder(borderRadius: AppRadii.input),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
      dividerColor: AppColors.divider,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.chip),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.nunitoTextTheme(
      const TextTheme(
        displaySmall:
            TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
        headlineSmall:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ).apply(
      bodyColor: AppColors.nightTextPrimary,
      displayColor: AppColors.nightTextPrimary,
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.nightPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.accentTeal,
      onSecondary: AppColors.nightTextPrimary,
      tertiary: AppColors.accentLime,
      onTertiary: AppColors.nightTextPrimary,
      error: AppColors.accentCoral,
      onError: Colors.white,
      surface: AppColors.nightSurfaceAlt,
      onSurface: AppColors.nightTextPrimary,
      onSurfaceVariant: AppColors.nightTextSecondary,
      outline: AppColors.nightDivider,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.nightSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.nightSurface,
        foregroundColor: AppColors.nightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.nightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.nightTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.nightPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardThemeData( 
        color: AppColors.nightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.nightCard,
        border: OutlineInputBorder(borderRadius: AppRadii.input),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: AppColors.nightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: AppColors.nightPrimary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: AppColors.nightTextSecondary),
      ),
      dividerColor: AppColors.nightDivider,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.nightPrimary,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.nightSurfaceAlt,
        selectedColor: AppColors.nightPrimary,
        labelStyle: TextStyle(color: AppColors.nightTextPrimary),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.chip),
      ),
    );
  }
}