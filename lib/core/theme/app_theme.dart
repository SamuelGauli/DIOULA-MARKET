import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Thèmes clair & sombre de Dioula Market, fidèles aux templates
/// Foodly (clair, vert/orange) et Rive (sombre, navy).
class AppTheme {
  AppTheme._();

  // Alias rétro-compatibles (utilisés dans d'anciens écrans).
  static const Color orange = AppColors.orange;
  static const Color green = AppColors.green;

  static const _radius = 12.0;

  // ---------------- THÈME CLAIR ----------------
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.clay,
      onPrimary: Colors.white,
      secondary: AppColors.ocre,
      onSecondary: AppColors.ink,
      tertiary: AppColors.beige,
      onTertiary: AppColors.ink,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: _textTheme(base, AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.inputLight,
        border: AppColors.borderLight,
        hint: AppColors.body,
      ),
      filledButtonTheme: _filledButton(),
      elevatedButtonTheme: _elevatedButton(),
      outlinedButtonTheme: _outlinedButton(AppColors.clay),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.clay),
      ),
      cardTheme: _cardTheme(
        color: AppColors.surfaceLight,
        shadow: AppColors.shadowLight.withValues(alpha: 0.16),
      ),
      chipTheme: _chipTheme(
        bg: AppColors.clay.withValues(alpha: 0.10),
        fg: AppColors.clayDark,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderLight),
      navigationBarTheme: _navBarTheme(
        bg: Colors.white,
        unselected: AppColors.body,
      ),
    );
  }

  // ---------------- THÈME SOMBRE ----------------
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.clay,
      onPrimary: Colors.white,
      secondary: AppColors.ocre,
      onSecondary: AppColors.ink,
      tertiary: AppColors.beige,
      onTertiary: AppColors.ink,
      surface: AppColors.cardDark,
      onSurface: Colors.white,
      error: AppColors.danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _textTheme(base, Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.inputDark,
        border: AppColors.borderDark,
        hint: AppColors.bodyDark,
      ),
      filledButtonTheme: _filledButton(),
      elevatedButtonTheme: _elevatedButton(),
      outlinedButtonTheme: _outlinedButton(Colors.white),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.ocre),
      ),
      cardTheme: _cardTheme(
        color: AppColors.cardDark,
        shadow: Colors.black.withValues(alpha: 0.45),
      ),
      chipTheme: _chipTheme(
        bg: AppColors.clay.withValues(alpha: 0.18),
        fg: AppColors.ocre,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderDark),
      navigationBarTheme: _navBarTheme(
        bg: AppColors.cardDark,
        unselected: AppColors.bodyDark,
      ),
    );
  }

  // ---------------- Sous-thèmes partagés ----------------
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color hint,
  }) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: hint),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(border),
      enabledBorder: b(border),
      focusedBorder: b(AppColors.green.withValues(alpha: 0.6), 1.5),
      errorBorder: b(AppColors.danger),
      focusedErrorBorder: b(AppColors.danger, 1.5),
    );
  }

  static FilledButtonThemeData _filledButton() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius)),
        ),
      );

  static ElevatedButtonThemeData _elevatedButton() => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius)),
        ),
      );

  static OutlinedButtonThemeData _outlinedButton(Color fg) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: fg.withValues(alpha: 0.4)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius)),
        ),
      );

  static ChipThemeData _chipTheme({required Color bg, required Color fg}) =>
      ChipThemeData(
        backgroundColor: bg,
        side: BorderSide.none,
        labelStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      );

  /// Typographie Poppins avec une hiérarchie nette (titres gras).
  static TextTheme _textTheme(ThemeData base, Color color) {
    final t = GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: color, displayColor: color);
    return t.copyWith(
      headlineSmall:
          t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Cartes : coins bien arrondis + ombre douce (élévation visible).
  static CardThemeData _cardTheme({required Color color, required Color shadow}) =>
      CardThemeData(
        color: color,
        elevation: 6,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      );

  /// Bottom nav Material 3 : indicateur teinté + libellés/icônes colorés.
  static NavigationBarThemeData _navBarTheme({
    required Color bg,
    required Color unselected,
  }) =>
      NavigationBarThemeData(
        backgroundColor: bg,
        elevation: 8,
        height: 68,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.clay.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.clay
                : unselected,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.clay
                : unselected,
          ),
        ),
      );
}
