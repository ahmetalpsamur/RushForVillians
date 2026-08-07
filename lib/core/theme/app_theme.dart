import 'package:flutter/material.dart';

/// Uygulamanın RPG temalı renk paleti ve tema tanımı.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF13111C);
  static const Color surface = Color(0xFF1E1B2E);
  static const Color primary = Color(0xFF7C5CFF);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color hp = Color(0xFFE53E3E);
  static const Color xp = Color(0xFF3ECF8E);
  static const Color streak = Color(0xFFFFC94D);

  static const Color rarityCommon = Color(0xFF9E9E9E);
  static const Color rarityUncommon = Color(0xFF4CAF50);
  static const Color rarityRare = Color(0xFF2196F3);
  static const Color rarityEpic = Color(0xFFAB47BC);
  static const Color rarityLegendary = Color(0xFFFFB300);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.3),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
