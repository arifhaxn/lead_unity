import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5B3BDB);
  static const primaryDark = Color(0xFF4622C9);
  static const accentLime = Color(0xFFA4E96A);
  static const accentTeal = Color(0xFF49D7B7);
  static const accentCoral = Color(0xFFFF7A87);

  static const textPrimary = Color(0xFF1B1B25);
  static const textSecondary = Color(0xFF6A6A7D);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6F4FB);
  static const divider = Color(0xFFECE7F7);

  static const nightSurface = Color(0xFF141321);
  static const nightSurfaceAlt = Color(0xFF1C1B2A);
  static const nightCard = Color(0xFF222138);
  static const nightTextPrimary = Color(0xFFEDEBFF);
  static const nightTextSecondary = Color(0xFFB9B6D3);
  static const nightDivider = Color(0xFF2A2940);
  static const nightPrimary = Color(0xFF6C4DFF);
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
      color: Color(0x14332073),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const level2 = [
    BoxShadow(
      color: Color(0x1F332073),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.primary, Color(0xFF7B5CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardHighlight = LinearGradient(
    colors: [AppColors.primary, AppColors.accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
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
      background: AppColors.surfaceAlt,
      onBackground: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceVariant: AppColors.surfaceAlt,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.divider,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceAlt,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        displaySmall:
            TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
        headlineSmall:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: AppRadii.input),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
      dividerColor: AppColors.divider,
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
    const  colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.nightPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.accentTeal,
      onSecondary: AppColors.nightTextPrimary,
      tertiary: AppColors.accentLime,
      onTertiary: AppColors.nightTextPrimary,
      error: AppColors.accentCoral,
      onError: Colors.white,
      background: AppColors.nightSurface,
      onBackground: AppColors.nightTextPrimary,
      surface: AppColors.nightSurfaceAlt,
      onSurface: AppColors.nightTextPrimary,
      surfaceVariant: AppColors.nightCard,
      onSurfaceVariant: AppColors.nightTextSecondary,
      outline: AppColors.nightDivider,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.nightSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.nightSurface,
        foregroundColor: AppColors.nightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.nightTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.nightTextPrimary),
      ),
      textTheme: const TextTheme(
        displaySmall:
            TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
        headlineSmall:
            TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleLarge:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: AppColors.nightTextPrimary,
        displayColor: AppColors.nightTextPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.nightPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardTheme(
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
          borderSide:
              BorderSide(color: AppColors.nightPrimary, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: AppColors.nightTextSecondary),
      ),
      dividerColor: AppColors.nightDivider,
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
