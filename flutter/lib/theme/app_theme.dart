import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D4);
  static const Color primaryLight = Color(0xFF9D97FF);

  // Luxury Colors
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFF3B0);
  static const Color goldDark = Color(0xFFB8960C);

  // Neon Colors
  static const Color neonBlue = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFFB400FF);
  static const Color neonPink = Color(0xFFFF007F);

  // Background Colors
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundCard = Color(0xFF1A1A2E);
  static const Color backgroundCardLight = Color(0xFF252542);
  static const Color surface = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF6B6B6B);

  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFAB00);

  // VIP Colors
  static const List<Color> vipColors = [
    Color(0xFFCD7F32), // VIP 1 - Bronze
    Color(0xFFC0C0C0), // VIP 2 - Silver
    Color(0xFFFFD700), // VIP 3 - Gold
    Color(0xFFE5E4E2), // VIP 4 - Platinum
    Color(0xFFB9F2FF), // VIP 5 - Diamond
    Color(0xFFE0115F), // VIP 6 - Ruby
    Color(0xFF50C878), // VIP 7 - Emerald
    Color(0xFF0F52BA), // VIP 8 - Sapphire
    Color(0xFFFF2400), // VIP 9 - Royal Crown
    Color(0xFFFFD700), // VIP 10 - Legendary
  ];

  // Gradients
  static const List<Color> premiumGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFFFD700),
    Color(0xFFFF8C00),
  ];

  static const List<Color> neonGradient = [
    Color(0xFF00F5FF),
    Color(0xFFB400FF),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0A0A0F),
    Color(0xFF1A1A2E),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.backgroundCardLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textHint),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      dividerTheme: const DividerThemeData(
        color: AppColors.backgroundCardLight,
        thickness: 1,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.backgroundCardLight,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.5);
          return AppColors.backgroundCardLight;
        }),
      ),
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.neonPurple,
        surface: AppColors.backgroundCard,
        error: AppColors.error,
      ),
    );
  }
}
