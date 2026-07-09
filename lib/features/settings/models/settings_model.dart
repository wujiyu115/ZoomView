enum UaMode { desktop, mobile }

class SettingsModel {
  final UaMode uaMode;
  final String searchEngine;
  final String homeUrl;
  final int viewportWidth;
  final double defaultZoom;
  final double minZoom;
  final double maxZoom;
  final bool darkMode;
  final bool devLogEnabled;
  final bool sessionRestore;

  const SettingsModel({
    this.uaMode = UaMode.desktop,
    this.searchEngine = 'Google',
    this.homeUrl = 'https://www.google.com',
    this.viewportWidth = 1920,
    this.defaultZoom = 1.0,
    this.minZoom = 0.5,
    this.maxZoom = 3.0,
    this.darkMode = true,
    this.devLogEnabled = false,
    this.sessionRestore = true,
  });

  SettingsModel copyWith({
    UaMode? uaMode,
    String? searchEngine,
    String? homeUrl,
    int? viewportWidth,
    double? defaultZoom,
    double? minZoom,
    double? maxZoom,
    bool? darkMode,
    bool? devLogEnabled,
    bool? sessionRestore,
  }) {
    return SettingsModel(
      uaMode: uaMode ?? this.uaMode,
      searchEngine: searchEngine ?? this.searchEngine,
      homeUrl: homeUrl ?? this.homeUrl,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      darkMode: darkMode ?? this.darkMode,
      devLogEnabled: devLogEnabled ?? this.devLogEnabled,
      sessionRestore: sessionRestore ?? this.sessionRestore,
    );
  }

  static SettingsModel fromMap(Map<String, String> map) {
    return SettingsModel(
      uaMode: map['ua_mode'] == 'mobile' ? UaMode.mobile : UaMode.desktop,
      searchEngine: map['search_engine'] ?? 'Google',
      homeUrl: map['home_url'] ?? 'https://www.google.com',
      viewportWidth: int.tryParse(map['viewport_width'] ?? '') ?? 1920,
      defaultZoom: double.tryParse(map['default_zoom'] ?? '') ?? 1.0,
      minZoom: double.tryParse(map['min_zoom'] ?? '') ?? 1.0,
      maxZoom: double.tryParse(map['max_zoom'] ?? '') ?? 3.0,
      darkMode: map['dark_mode'] != 'false',
      devLogEnabled: map['dev_log_enabled'] == 'true',
      sessionRestore: map['session_restore'] != 'false',
    );
  }
}
