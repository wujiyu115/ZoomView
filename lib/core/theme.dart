import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: Colors.white,
      secondary: colors.accent,
      onSecondary: Colors.white,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.fg,
      outline: colors.border,
      surfaceContainerHighest: colors.urlBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 0.5,
        space: 0.5,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.fg,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.accent,
        thumbColor: Colors.white,
        inactiveTrackColor: colors.border,
        overlayColor: colors.accentSubtle,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        trackHeight: 4,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colors.fg2),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.accent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      extensions: [colors],
    );
  }
}
