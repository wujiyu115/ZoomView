class AppConstants {
  AppConstants._();

  static const String desktopUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/18.4 Safari/605.1.15';

  static const String mobileUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) CriOS/136.0.7103.56 Mobile/15E148 Safari/604.1';

  static const double minZoom = 0.5;
  static const double maxZoom = 3.0;
  static const double defaultZoom = 1.0;
  static const double zoomStep = 0.1;
  static const int defaultViewportWidth = 1920;

  static const String defaultHomeUrl = 'https://www.google.com';

  static const Map<String, String> searchEngines = {
    'Google': 'https://www.google.com/search?q=%s',
    'Bing': 'https://www.bing.com/search?q=%s',
    'DuckDuckGo': 'https://duckduckgo.com/?q=%s',
  };

  static const int maxConcurrentDownloads = 3;
}
