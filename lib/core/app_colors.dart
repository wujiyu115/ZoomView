import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color fg;
  final Color fg2;
  final Color muted;
  final Color border;
  final Color accent;
  final Color accentSubtle;
  final Color danger;
  final Color urlBg;
  final Color toolbarBg;
  final Color zoomBg;
  final Color contentBg;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceElevated,
    required this.fg,
    required this.fg2,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentSubtle,
    required this.danger,
    required this.urlBg,
    required this.toolbarBg,
    required this.zoomBg,
    required this.contentBg,
  });

  static const light = AppColors(
    bg: Color(0xFFF3F5F8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    fg: Color(0xFF1B1F24),
    fg2: Color(0xFF57606A),
    muted: Color(0xFF8B949E),
    border: Color(0xFFD8DEE4),
    accent: Color(0xFF0969DA),
    accentSubtle: Color(0x140969DA),
    danger: Color(0xFFCF222E),
    urlBg: Color(0xFFE8ECF0),
    toolbarBg: Color(0xE0F3F5F8),
    zoomBg: Color(0xFFEBEEF2),
    contentBg: Color(0xFFF0F1F3),
  );

  static const dark = AppColors(
    bg: Color(0xFF161B22),
    surface: Color(0xFF21262D),
    surfaceElevated: Color(0xFF2D333B),
    fg: Color(0xFFE6EDF3),
    fg2: Color(0xFF8B949E),
    muted: Color(0xFF6E7681),
    border: Color(0xFF30363D),
    accent: Color(0xFF58A6FF),
    accentSubtle: Color(0x1458A6FF),
    danger: Color(0xFFF85149),
    urlBg: Color(0xFF21262D),
    toolbarBg: Color(0xE0161B22),
    zoomBg: Color(0xFF21262D),
    contentBg: Color(0xFF0D1117),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceElevated,
    Color? fg,
    Color? fg2,
    Color? muted,
    Color? border,
    Color? accent,
    Color? accentSubtle,
    Color? danger,
    Color? urlBg,
    Color? toolbarBg,
    Color? zoomBg,
    Color? contentBg,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      fg: fg ?? this.fg,
      fg2: fg2 ?? this.fg2,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      danger: danger ?? this.danger,
      urlBg: urlBg ?? this.urlBg,
      toolbarBg: toolbarBg ?? this.toolbarBg,
      zoomBg: zoomBg ?? this.zoomBg,
      contentBg: contentBg ?? this.contentBg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fg2: Color.lerp(fg2, other.fg2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      urlBg: Color.lerp(urlBg, other.urlBg, t)!,
      toolbarBg: Color.lerp(toolbarBg, other.toolbarBg, t)!,
      zoomBg: Color.lerp(zoomBg, other.zoomBg, t)!,
      contentBg: Color.lerp(contentBg, other.contentBg, t)!,
    );
  }
}
